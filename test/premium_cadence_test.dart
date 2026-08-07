import 'package:exitplan/core/premium_cadence.dart';
import 'package:flutter_test/flutter_test.dart';

/// The nudge is the only upsell in the app that nobody asked for, so every rule
/// that keeps it rare is worth a test. These are pure — no widgets, no waiting
/// three days — because the clock is injected.
void main() {
  final DateTime now = DateTime(2026, 8, 5, 12);

  int msAgo(Duration d) => now.subtract(d).millisecondsSinceEpoch;

  /// A user who is eligible in every respect, so each test can spoil exactly
  /// one thing and see it refuse.
  String? pick({
    bool isPremium = false,
    int nudgeCount = 0,
    Duration? lastNudge,
    Duration installedAgo = const Duration(days: 30),
  }) => PremiumCadence.pick(
    isPremium: isPremium,
    nudgeCount: nudgeCount,
    lastNudgeAtMs: lastNudge == null ? 0 : msAgo(lastNudge),
    installedAtMs: msAgo(installedAgo),
    now: now,
  );

  test('an eligible free user gets the first line', () {
    expect(pick(), kPremiumNudges.first);
  });

  test('a premium user is never sold to again', () {
    expect(pick(isPremium: true), isNull);
    // Not even on their very first eligible tick.
    expect(pick(isPremium: true, nudgeCount: 0), isNull);
  });

  group('the total ceiling', () {
    test('stops for good at the limit', () {
      expect(pick(nudgeCount: kMaxPremiumNudges - 1), isNotNull);
      expect(pick(nudgeCount: kMaxPremiumNudges), isNull);
      // Not "six per version" or "six per week" — six, forever.
      expect(pick(nudgeCount: kMaxPremiumNudges + 40), isNull);
    });

    test('walks the lines in order rather than repeating one', () {
      final Set<String?> seen = <String?>{
        for (int i = 0; i < kMaxPremiumNudges; i++) pick(nudgeCount: i),
      };
      expect(seen.length, kMaxPremiumNudges);
      expect(seen.contains(null), isFalse);
    });
  });

  group('the quiet time', () {
    test('refuses inside the interval and allows just past it', () {
      expect(
        pick(
          nudgeCount: 1,
          lastNudge: kPremiumNudgeInterval - const Duration(hours: 1),
        ),
        isNull,
      );
      expect(
        pick(
          nudgeCount: 1,
          lastNudge: kPremiumNudgeInterval + const Duration(hours: 1),
        ),
        isNotNull,
      );
    });

    test('a never-nudged user is not treated as nudged at the epoch', () {
      expect(pick(lastNudge: null), isNotNull);
    });
  });

  group('the new-install grace', () {
    test('leaves a fresh install completely alone', () {
      // Someone who opened this for the first time may be about to use it in a
      // meeting. Selling before they have got any value out of it is both rude
      // and ineffective.
      expect(
        pick(installedAgo: kPremiumNudgeGrace - const Duration(hours: 1)),
        isNull,
      );
      expect(
        pick(installedAgo: kPremiumNudgeGrace + const Duration(hours: 1)),
        isNotNull,
      );
    });

    test('an uncaptured install date reads as too early, not infinitely old', () {
      // capturedAtMs is 0 only before bootstrap finishes. Treating that as the
      // epoch would make every such tick eligible.
      expect(
        PremiumCadence.pick(
          isPremium: false,
          nudgeCount: 0,
          lastNudgeAtMs: 0,
          installedAtMs: 0,
          now: now,
        ),
        isNull,
      );
    });
  });

  test('the copy stays in the app voice', () {
    for (final String line in kPremiumNudges) {
      expect(line.contains('!'), isFalse, reason: 'no shouting: "$line"');
      expect(line.length, lessThan(80), reason: 'too long for a banner: "$line"');
      expect(line.endsWith('.'), isTrue, reason: 'unfinished: "$line"');
    }
  });
}
