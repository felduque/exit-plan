/// When, if ever, a banner tick should sell Premium instead of showing a tip.
///
/// ## The design, in one line
///
/// The nudge is not a new interruption. It is an alternate *content source* for
/// the one banner that already exists, chosen inside `TipBanner._show`.
///
/// That buys four properties by construction rather than by discipline, which
/// matters because "remember not to be spammy" is not a mechanism:
///
/// * It inherits all four suppression gates — the splash and intro, the
///   blackout, an open modal, and the screen-level `TipsSuppressor`. It is
///   physically impossible for a promo to appear where a tip could not, and no
///   future edit can forget one of them.
/// * The app's total interruption budget does not rise by a single banner. A
///   promo *replaces* a tip; it never adds one.
/// * The existing "In-app tips" switch silences it, because that check happens
///   before this is ever consulted. Users get an honest off switch for upsells,
///   and it is one they already know about.
/// * The tip rotation cursor does not advance on a promo tick, so a nudge never
///   costs the user a tip they would otherwise have seen.
///
/// ## The contextual gate is deliberately not throttled by this
///
/// `showPremiumGate` fires when someone taps "new" at their limit. They asked a
/// question and it answers it. This file governs only the ones nobody asked
/// for.
library;

/// How many times, across the entire life of the install, an unprompted nudge
/// may ever appear.
///
/// Six. Not six per week or six per version — six, total, forever. Someone who
/// has seen it six times and not bought has answered; asking a seventh time is
/// not marketing, it is nagging, and the app still has a permanently visible
/// Premium tile on home for whenever they change their mind.
const int kMaxPremiumNudges = 6;

/// The quiet time between two nudges.
const Duration kPremiumNudgeInterval = Duration(days: 3);

/// How long a new install is left completely alone.
///
/// Someone who opened this app for the first time may be about to use it in a
/// meeting. Selling to them before they have got any value out of it is both
/// rude and ineffective.
const Duration kPremiumNudgeGrace = Duration(days: 2);

/// The nudge lines, in the order they are shown.
///
/// Written to sound like the rest of the app — `TAP AN EXIT · SCREEN GOES DARK`,
/// `STANDBY · 4 EXITS READY`. Flat, factual, no exclamation marks, nothing
/// crossed out, no countdown. Each states one true thing and stops.
const List<String> kPremiumNudges = <String>[
  'Premium removes the ads. Nothing else changes.',
  'Premium lifts the limits on fake calls and imported sounds.',
  'Premium has a one-time option. No account either way.',
  'No ads, unlimited templates and imports — that is all Premium is.',
  'Your sounds stay on this device whether or not you go Premium.',
  'Premium, once, and the ads are gone for good.',
];

/// Decides whether this banner tick is a nudge.
///
/// Pure, with the clock injected, so every rule above is testable without
/// pumping a widget or waiting three days.
///
/// Returns the line to show, or `null` to leave the tick to the tips.
abstract final class PremiumCadence {
  static String? pick({
    required bool isPremium,
    required int nudgeCount,
    required int lastNudgeAtMs,
    required int installedAtMs,
    required DateTime now,
  }) {
    // Nothing left to sell.
    if (isPremium) return null;

    // They have answered by not answering.
    if (nudgeCount >= kMaxPremiumNudges) return null;

    // A brand new install is left alone. installedAtMs of 0 means the baseline
    // has not been captured yet, which only happens before bootstrap finishes —
    // treat it as "too early" rather than "infinitely old".
    if (installedAtMs <= 0) return null;
    if (now.difference(DateTime.fromMillisecondsSinceEpoch(installedAtMs)) <
        kPremiumNudgeGrace) {
      return null;
    }

    // Not too soon after the last one. A zero here means "never nudged", which
    // must not read as "nudged at the epoch" — but that is exactly what it
    // computes to, and the answer happens to be right: infinitely long ago.
    if (lastNudgeAtMs > 0 &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastNudgeAtMs)) <
            kPremiumNudgeInterval) {
      return null;
    }

    return kPremiumNudges[nudgeCount % kPremiumNudges.length];
  }
}
