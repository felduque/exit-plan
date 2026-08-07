import 'package:exitplan/core/premium_config.dart';
import 'package:exitplan/data/entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

/// The entitlement decides whether someone who paid sees ads. Its two failure
/// modes are not symmetrical: showing ads to a subscriber is a bug they can fix
/// with one tap on Restore, while revoking premium from a paying user offline
/// is a bug they cannot fix at all. Every rule below is shaped by that.
void main() {
  group('parsing', () {
    test('round-trips through JSON', () {
      const Entitlement original = Entitlement(
        source: PremiumSource.yearly,
        productId: PremiumProducts.yearly,
        purchasedAtMs: 1700000000000,
        lastVerifiedAtMs: 1700000001000,
      );

      final Entitlement parsed = Entitlement.fromJson(original.toJson());

      expect(parsed.source, PremiumSource.yearly);
      expect(parsed.productId, PremiumProducts.yearly);
      expect(parsed.purchasedAtMs, 1700000000000);
      expect(parsed.lastVerifiedAtMs, 1700000001000);
      expect(parsed.isActive, isTrue);
    });

    test('anything unreadable decays to the free tier', () {
      for (final Object? garbage in <Object?>[
        null,
        'not a map',
        42,
        <String>['a', 'list'],
        <String, Object?>{},
        <String, Object?>{'source': 'platinum'}, // a tier that never existed
        <String, Object?>{'source': null},
      ]) {
        expect(
          Entitlement.fromJson(garbage).isActive,
          isFalse,
          reason: 'garbage $garbage must not grant premium',
        );
      }
    });

    test('a known tier survives corrupt companion fields', () {
      final Entitlement parsed = Entitlement.fromJson(<String, Object?>{
        'source': 'lifetime',
        'productId': '',
        'purchasedAtMs': 'yesterday',
        'lastVerifiedAtMs': -5,
      });

      expect(parsed.source, PremiumSource.lifetime);
      expect(parsed.productId, isNull);
      expect(parsed.purchasedAtMs, isNull);
      expect(parsed.lastVerifiedAtMs, isNull);
    });

    test('maps product ids to tiers, and unknown ids to none', () {
      expect(
        PremiumSource.ofProduct(PremiumProducts.monthly),
        PremiumSource.monthly,
      );
      expect(
        PremiumSource.ofProduct(PremiumProducts.lifetime),
        PremiumSource.lifetime,
      );
      expect(PremiumSource.ofProduct('com.someone.else'), PremiumSource.none);
    });
  });

  group('lapsing', () {
    final DateTime now = DateTime(2026, 8, 5);

    Entitlement verifiedAgo(PremiumSource source, Duration ago) => Entitlement(
      source: source,
      lastVerifiedAtMs: now.subtract(ago).millisecondsSinceEpoch,
    );

    test('a subscription lapses only past the grace window', () {
      final Entitlement fresh = verifiedAgo(
        PremiumSource.monthly,
        kEntitlementGrace - const Duration(hours: 1),
      );
      final Entitlement stale = verifiedAgo(
        PremiumSource.monthly,
        kEntitlementGrace + const Duration(hours: 1),
      );

      expect(fresh.shouldLapse(now), isFalse);
      expect(stale.shouldLapse(now), isTrue);
    });

    test('lifetime never lapses, however old', () {
      final Entitlement ancient = verifiedAgo(
        PremiumSource.lifetime,
        const Duration(days: 4000),
      );
      expect(ancient.shouldLapse(now), isFalse);
    });

    test('never lapses without a verification timestamp', () {
      // Nothing has confirmed this either way, so there is no clock to run out.
      // Guessing here would revoke premium from someone who just bought it.
      const Entitlement unverified = Entitlement(source: PremiumSource.yearly);
      expect(unverified.shouldLapse(now), isFalse);
    });

    test('the free tier has nothing to lapse', () {
      expect(Entitlement.none.shouldLapse(now), isFalse);
    });

    test('a fresh verification resets the clock', () {
      final Entitlement stale = verifiedAgo(
        PremiumSource.yearly,
        kEntitlementGrace * 2,
      );
      expect(stale.shouldLapse(now), isTrue);

      final Entitlement renewed = stale.copyWith(
        lastVerifiedAtMs: now.millisecondsSinceEpoch,
      );
      expect(renewed.shouldLapse(now), isFalse);
      expect(renewed.source, PremiumSource.yearly);
    });
  });
}
