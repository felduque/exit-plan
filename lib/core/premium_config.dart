/// Every number and identifier the premium tier is defined by, in one place.
///
/// Deliberately plain Dart with no Flutter import, so the gate arithmetic and
/// the nudge cadence can be unit-tested without pumping a widget.
///
/// None of this is a build-time define, unlike [TikTokConfig]. Product ids have
/// to match strings typed into Play Console exactly, and a typo introduced by a
/// forgotten `--dart-define` would not fail the build — it would ship a store
/// listing whose products silently never resolve.
library;

/// The Play Console product ids.
///
/// Monthly and yearly are two **separate subscription products**, not two base
/// plans of one product. Play reports a base plan purchase under its parent
/// product id, so a single product would make both tiers arrive as the same
/// `productID` and the tier would have to be recovered from the base plan.
/// Two products means `productID` alone identifies what was bought.
///
/// Lifetime is a non-consumable in-app product, not a subscription.
abstract final class PremiumProducts {
  static const String monthly = 'exitplan.premium.monthly';
  static const String yearly = 'exitplan.premium.yearly';
  static const String lifetime = 'exitplan.premium.lifetime';

  /// Everything to query from the store.
  static const Set<String> all = <String>{monthly, yearly, lifetime};

  /// The recurring ones — the only products that can ever lapse.
  static const Set<String> subscriptions = <String>{monthly, yearly};
}

/// What the free tier allows.
///
/// The bundled library is **not** on this list and never will be: all 47 sounds
/// and all 6 categories stay free for everyone. This app is a panic button, and
/// putting the escape itself behind a payment would be indefensible — quite
/// apart from breaking the quick-access slots of users who already pinned one.
///
/// These caps gate *creation only*. Nothing already on the device is ever
/// hidden, disabled or deleted by them; see [GateBaseline].
abstract final class FreeLimits {
  static const int callPresets = 2;
  static const int userSounds = 3;
  static const int userCategories = 1;
}

/// The sentinel [PremiumGate] returns for "no ceiling".
///
/// Negative rather than a huge int so an accidental comparison against it fails
/// loudly instead of quietly allowing 2^63 call presets.
const int kUnlimited = -1;

/// How long an entitlement survives without the store confirming it.
///
/// Only consulted after a *successful* store round-trip that returned nothing;
/// being offline never starts this clock. See [Entitlement.shouldLapse].
const Duration kEntitlementGrace = Duration(days: 7);
