/// What the user already had the first time this device ran a build that knows
/// about free-tier limits.
///
/// ## Why this exists
///
/// Until v1.2.0 the app had no limits at all: call presets, imported sounds and
/// user categories were unbounded. Somebody who has been using it since v1.1.0
/// may hold nine call presets. Introducing a cap of two without this snapshot
/// would either delete their work or hide it behind a paywall they never agreed
/// to — taking away something already given, which is the one move that
/// reliably earns one-star reviews and deserves them.
///
/// So the cap is `max(freeLimit, baseline)`. A user who had nine keeps nine.
/// A fresh install baselines at zero and gets the plain free tier.
///
/// ## Captured exactly once
///
/// Written on the first bootstrap that finds no stored value, *before* anything
/// in that process can add another item, and never rewritten. If it were
/// recomputed it would ratchet upward every launch and the cap would never
/// apply to anyone.
///
/// It deliberately does **not** fall when the user deletes something. Whoever
/// earned the right to nine keeps it, and can tidy up and re-add. Tracking a
/// high-water mark instead would be more code for a meaner result.
///
/// ## Known limitation
///
/// A reinstall, or clearing app data, loses this and drops a long-time user to
/// the plain free tier. There is no fix without a backend or an account, and
/// this app has neither by design. Nothing in the UI may therefore claim the
/// app remembers anything across a reinstall.
class GateBaseline {
  const GateBaseline({
    required this.callPresets,
    required this.userSounds,
    required this.userCategories,
    required this.capturedAtMs,
    this.version = currentVersion,
  });

  /// Bumping this is how a future release deliberately re-baselines everyone,
  /// should the free limits ever be redefined rather than merely retuned.
  static const int currentVersion = 1;

  /// A device with nothing yet — a fresh install, and the safe default for an
  /// unreadable stored value.
  static const GateBaseline empty = GateBaseline(
    callPresets: 0,
    userSounds: 0,
    userCategories: 0,
    capturedAtMs: 0,
  );

  final int callPresets;
  final int userSounds;
  final int userCategories;

  /// Doubles as "when this install became known to us", which is what the
  /// upsell grace window is measured from — so no separate install-date key is
  /// needed.
  final int capturedAtMs;

  final int version;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'callPresets': callPresets,
    'userSounds': userSounds,
    'userCategories': userCategories,
    'capturedAtMs': capturedAtMs,
    'version': version,
  };

  /// Returns `null` when nothing usable is stored, which is the signal to
  /// capture a fresh snapshot. A partially corrupt record still yields a
  /// baseline: reading a count as zero only ever tightens a cap toward the
  /// published free tier, never past it.
  static GateBaseline? tryFromJson(Object? raw) {
    if (raw is! Map) return null;

    int readCount(String key) {
      final Object? value = raw[key];
      return value is int && value > 0 ? value : 0;
    }

    final Object? captured = raw['capturedAtMs'];
    final Object? version = raw['version'];

    return GateBaseline(
      callPresets: readCount('callPresets'),
      userSounds: readCount('userSounds'),
      userCategories: readCount('userCategories'),
      capturedAtMs: captured is int && captured > 0 ? captured : 0,
      version: version is int && version > 0 ? version : currentVersion,
    );
  }
}
