import '../core/premium_config.dart';

/// Which product granted premium, if any.
enum PremiumSource {
  none,
  monthly,
  yearly,
  lifetime;

  /// Tolerant of anything: an unknown or absent name reads as [none], so a
  /// rolled-back build that meets a newer stored value degrades to free rather
  /// than throwing on boot.
  static PremiumSource fromName(Object? raw) {
    for (final PremiumSource value in PremiumSource.values) {
      if (value.name == raw) return value;
    }
    return PremiumSource.none;
  }

  static PremiumSource ofProduct(String productId) => switch (productId) {
    PremiumProducts.monthly => PremiumSource.monthly,
    PremiumProducts.yearly => PremiumSource.yearly,
    PremiumProducts.lifetime => PremiumSource.lifetime,
    _ => PremiumSource.none,
  };
}

/// Whether this device has premium, and what the store last told us about it.
///
/// Stored under its own key rather than as fields on [AppSettings], for two
/// reasons that are not style preferences:
///
/// * `AppSettings` is one JSON blob rewritten wholesale on every toggle. A
///   purchase arrives asynchronously on the store's stream, unattached to any
///   user gesture, so a purchase landing while someone flips a switch would let
///   one write silently erase the other. Separate keys make that impossible.
/// * `AppSettings` is what the *user* chose. This is what the *store* said.
///   Different owner, different lifetime, different key.
///
/// ## Verification is local, and that is a deliberate ceiling
///
/// There is no backend to ask, because this app has no backend and no account —
/// see the header of `lib/main.dart`. So the checks are: the store reported the
/// purchase as owned, the product id is one of ours, and a receipt string came
/// with it. A rooted device can forge that.
///
/// The cost of someone doing so is one hidden banner. The cost of the
/// alternative is a server and a login, which is a larger thing to inflict on
/// every honest user than the loss it prevents.
class Entitlement {
  const Entitlement({
    this.source = PremiumSource.none,
    this.productId,
    this.purchasedAtMs,
    this.lastVerifiedAtMs,
  });

  /// The free tier, and what any unreadable stored value decays to.
  static const Entitlement none = Entitlement();

  final PremiumSource source;

  /// The exact Play product id, kept verbatim so a receipt can be matched even
  /// if [PremiumSource] is later renamed or extended.
  final String? productId;

  final int? purchasedAtMs;

  /// When the store last confirmed this purchase is still owned. Refreshed on
  /// every delivered purchase and every successful restore.
  final int? lastVerifiedAtMs;

  bool get isActive => source != PremiumSource.none;

  /// A one-off purchase never expires, so it is never subject to [shouldLapse].
  bool get isLifetime => source == PremiumSource.lifetime;

  /// Whether a restore that completed against a live store connection and found
  /// **nothing** should revoke this entitlement.
  ///
  /// The caller must only ask this after a genuinely successful round-trip.
  /// Being offline must never reach here: this app is used in basements and on
  /// planes, and revoking a paying subscriber's premium because their phone had
  /// no signal is a far worse failure than the one this guards against.
  ///
  /// So it fails in the user's favour twice over — a grace window on top of
  /// requiring a real answer from the store. Someone who refunds keeps premium
  /// for up to [kEntitlementGrace]. That is the correct price for never
  /// wrongly revoking.
  bool shouldLapse(DateTime now) {
    if (!isActive || isLifetime) return false;
    final int? verified = lastVerifiedAtMs;
    if (verified == null) return false;
    final DateTime last = DateTime.fromMillisecondsSinceEpoch(verified);
    return now.difference(last) > kEntitlementGrace;
  }

  Entitlement copyWith({int? lastVerifiedAtMs}) => Entitlement(
    source: source,
    productId: productId,
    purchasedAtMs: purchasedAtMs,
    lastVerifiedAtMs: lastVerifiedAtMs ?? this.lastVerifiedAtMs,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'source': source.name,
    'productId': productId,
    'purchasedAtMs': purchasedAtMs,
    'lastVerifiedAtMs': lastVerifiedAtMs,
  };

  /// Anything unreadable falls back to [none]: the failure mode of a corrupt
  /// entitlement is showing ads to someone who paid, which a restore fixes in
  /// one tap. The opposite failure mode has no such recovery.
  static Entitlement fromJson(Object? raw) {
    if (raw is! Map) return none;

    final PremiumSource source = PremiumSource.fromName(raw['source']);
    if (source == PremiumSource.none) return none;

    int? readInt(String key) {
      final Object? value = raw[key];
      return value is int && value > 0 ? value : null;
    }

    final Object? productId = raw['productId'];

    return Entitlement(
      source: source,
      productId: productId is String && productId.isNotEmpty ? productId : null,
      purchasedAtMs: readInt('purchasedAtMs'),
      lastVerifiedAtMs: readInt('lastVerifiedAtMs'),
    );
  }
}
