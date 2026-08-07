import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/premium_config.dart';
import '../data/entitlement.dart';

/// What the store is currently doing, for the premium screen to render.
enum BillingPhase {
  /// Products loaded, nothing in flight.
  idle,

  /// Asking Play what the products cost.
  loading,

  /// A purchase is in flight, or awaiting a parent's approval.
  pending,

  /// The last attempt failed. [BillingService.error] says how.
  error,

  /// Play Billing is not on this device at all.
  unavailable,
}

/// Talks to Play Billing, and nothing else.
///
/// A singleton because the billing connection is a property of the process, not
/// of a screen — the same reasoning as [NotificationPermission], whose shape
/// this mirrors.
///
/// ## It never writes storage
///
/// It resolves a purchase into an [Entitlement] and hands it to the callback
/// given at [start]. `AppState` owns the write, so there is exactly one place in
/// the app that can change whether someone is premium, and purchases follow the
/// same mutate → notify → save path as every other piece of state.
///
/// ## Purchases arrive unprompted
///
/// Play replays unfinished purchases the moment the connection opens — a
/// purchase completed on another device, a subscription that renewed, a payment
/// that finally cleared. So the stream is subscribed *before* anything else
/// here runs. An unsubscribed stream drops them silently, and the user is left
/// having paid for nothing.
class BillingService extends ChangeNotifier {
  BillingService._();

  static final BillingService instance = BillingService._();

  /// Resolved on use, never in a field initialiser.
  ///
  /// Touching `InAppPurchase.instance` registers the platform implementation,
  /// and on Android that opens a Play connection immediately. As a field it
  /// would fire the moment anything referenced [instance] — including a widget
  /// test that only wanted to set a phase — and throw a channel error in a
  /// process that has no plugins at all.
  InAppPurchase get _store => InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  void Function(Entitlement)? _onEntitlement;

  BillingPhase _phase = BillingPhase.loading;
  String? _error;
  List<ProductDetails> _products = <ProductDetails>[];

  BillingPhase get phase => _phase;
  String? get error => _error;

  /// Whatever Play actually returned, in a stable order: the cheapest
  /// commitment first, the one-off last.
  List<ProductDetails> get products => List<ProductDetails>.unmodifiable(
    _products..sort((ProductDetails a, ProductDetails b) =>
        _rank(a.id).compareTo(_rank(b.id))),
  );

  static int _rank(String id) => switch (id) {
    PremiumProducts.monthly => 0,
    PremiumProducts.yearly => 1,
    PremiumProducts.lifetime => 2,
    _ => 3,
  };

  /// Called once, from the app root.
  void start({required void Function(Entitlement) onEntitlement}) {
    if (_subscription != null) return;
    _onEntitlement = onEntitlement;

    // First, before isAvailable() — see the class doc.
    _subscription = _store.purchaseStream.listen(
      _handle,
      onError: (Object e) => _fail(e.toString()),
    );

    unawaited(_connect());
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _connect() async {
    bool available;
    try {
      available = await _store.isAvailable();
    } catch (_) {
      // No plugin channel (tests, desktop), or Play refusing to answer.
      available = false;
    }

    if (!available) {
      _set(BillingPhase.unavailable);
      return;
    }

    await loadProducts();

    // Silently regains premium after a reinstall or a device swap, without the
    // user having to find a button. Failures here are ignored on purpose: a
    // restore that cannot reach Play must never revoke anything.
    try {
      await _store.restorePurchases();
    } catch (_) {
      // Nothing to do. The stored entitlement stands.
    }
  }

  Future<void> loadProducts() async {
    _set(BillingPhase.loading);
    try {
      final ProductDetailsResponse response = await _store.queryProductDetails(
        PremiumProducts.all,
      );

      // notFoundIDs is normal while a product is still propagating through Play
      // Console, so it is not an error — show whatever did resolve rather than
      // blanking the screen over one missing tier.
      if (kDebugMode && response.notFoundIDs.isNotEmpty) {
        debugPrint('Billing: not found in Play — ${response.notFoundIDs}');
      }

      if (response.productDetails.isEmpty) {
        _fail(response.error?.message ?? 'No products available right now.');
        return;
      }

      _products = response.productDetails;
      _set(BillingPhase.idle);
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// Starts a purchase. Everything after this arrives on the stream.
  ///
  /// `buyNonConsumable` is correct for all three products: on Android
  /// subscriptions go through it too, and it is the call that does *not*
  /// consume. Using `buyConsumable` for the lifetime unlock would let Play
  /// consume it, and the user would lose what they bought.
  Future<void> buy(ProductDetails product) async {
    _set(BillingPhase.pending);
    try {
      await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// The explicit button. Results arrive on the stream as `restored`.
  Future<void> restore() async {
    _set(BillingPhase.pending);
    try {
      await _store.restorePurchases();
      // No purchase means no stream event, so the phase has to be cleared here
      // or the screen would spin forever on an account that owns nothing.
      _set(BillingPhase.idle);
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> _handle(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _set(BillingPhase.pending);
        case PurchaseStatus.error:
          _fail(purchase.error?.message ?? 'The purchase did not go through.');
        case PurchaseStatus.canceled:
          _set(BillingPhase.idle);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final Entitlement? granted = _resolve(purchase);
          if (granted != null) {
            _onEntitlement?.call(granted);
            _set(BillingPhase.idle);
          }
      }

      // Outside the switch, unconditionally, errors and unknown products
      // included. Play auto-refunds a purchase that is never completed after
      // three days — so a `completePurchase` skipped on any branch is money
      // taken from someone who then loses what they bought. This must not move
      // inside a case.
      if (purchase.pendingCompletePurchase) {
        try {
          await _store.completePurchase(purchase);
        } catch (_) {
          // Retried by Play on the next connection.
        }
      }
    }
  }

  /// Local verification, and a deliberate ceiling — see [Entitlement].
  ///
  /// There is no server to ask because this app has none. So: the store says it
  /// is owned, the product is one of ours, and a receipt came with it. Signature
  /// checking is not done, because the key would ship in the same APK as the
  /// check and would prove nothing.
  Entitlement? _resolve(PurchaseDetails purchase) {
    final PremiumSource source = PremiumSource.ofProduct(purchase.productID);
    if (source == PremiumSource.none) return null;
    if (purchase.verificationData.serverVerificationData.isEmpty) return null;

    final int now = DateTime.now().millisecondsSinceEpoch;
    return Entitlement(
      source: source,
      productId: purchase.productID,
      purchasedAtMs:
          int.tryParse(purchase.transactionDate ?? '') ?? now,
      lastVerifiedAtMs: now,
    );
  }

  void _set(BillingPhase next) {
    if (_phase == next && _error == null) return;
    _phase = next;
    _error = null;
    notifyListeners();
  }

  void _fail(String message) {
    _phase = BillingPhase.error;
    _error = message;
    notifyListeners();
  }

  /// Test seam, same door [NotificationPermission] has: the plugin channel does
  /// not exist under the test binding, and the states worth checking (a device
  /// with no Play Billing, a purchase mid-flight) are exactly the ones that
  /// would otherwise rot unnoticed.
  @visibleForTesting
  void debugSet({
    BillingPhase phase = BillingPhase.idle,
    String? error,
    List<ProductDetails> products = const <ProductDetails>[],
  }) {
    _phase = phase;
    _error = error;
    _products = products;
    notifyListeners();
  }
}
