import '../core/premium_config.dart';
import '../data/gate_baseline.dart';

/// The whole of the free/premium limit arithmetic, as pure functions.
///
/// No Flutter import, no state, no I/O — so the grandfathering rules can be
/// tested exhaustively without pumping a widget or mocking a store.
///
/// ## The one rule
///
/// ```
/// cap = premium ? unlimited : max(freeLimit, whatTheyAlreadyHad)
/// ```
///
/// Everything else in this file follows from that. See [GateBaseline] for why
/// the second term exists.
///
/// ## Where this is consulted
///
/// Only on the **creation** path, and only at the point where the user's intent
/// begins — before the file picker opens, before the editor is pushed. Never on
/// a read path: no sound, preset or category is ever hidden or disabled because
/// of a cap, so a user over their limit keeps everything working and is simply
/// not offered a new one.
///
/// It is deliberately not enforced inside `AppState.addUserSound` and friends.
/// A cap failing there would abort after `editor_screen` had already copied the
/// file into permanent storage and was about to replace the route, leaving an
/// orphan on disk and the user staring at a screen that saved nothing.
abstract final class PremiumGate {
  /// The ceiling that actually applies to this device.
  static int effectiveCap({
    required int freeLimit,
    required int baseline,
    required bool premium,
  }) {
    if (premium) return kUnlimited;
    return freeLimit > baseline ? freeLimit : baseline;
  }

  /// Whether one more may be created.
  static bool canAdd({required int current, required int cap}) =>
      cap == kUnlimited || current < cap;

  // --- the three gated resources -------------------------------------------

  static int callPresetCap(GateBaseline baseline, {required bool premium}) =>
      effectiveCap(
        freeLimit: FreeLimits.callPresets,
        baseline: baseline.callPresets,
        premium: premium,
      );

  static int userSoundCap(GateBaseline baseline, {required bool premium}) =>
      effectiveCap(
        freeLimit: FreeLimits.userSounds,
        baseline: baseline.userSounds,
        premium: premium,
      );

  static int userCategoryCap(GateBaseline baseline, {required bool premium}) =>
      effectiveCap(
        freeLimit: FreeLimits.userCategories,
        baseline: baseline.userCategories,
        premium: premium,
      );
}
