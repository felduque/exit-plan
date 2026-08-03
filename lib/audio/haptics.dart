import 'package:vibration/vibration.dart';

/// The vibration motor, and the one place allowed to touch it.
///
/// Patterns are started with `repeat: 0`, which on Android means *repeat for
/// ever* — the buzz has to last as long as the excuse, and the excuse has no
/// fixed length. That makes stopping it the safety-critical half of this class:
/// a missed cancel is not a cosmetic glitch, it is a phone that will not stop
/// buzzing in a room the user was trying to leave quietly.
///
/// So three rules hold here, and all exist because of a real bug:
///
/// 1. **[stop] always reaches the motor.** It never trusts a flag saying nothing
///    is running. Cancelling an idle vibrator costs one no-op platform call;
///    getting it wrong costs the user their excuse.
/// 2. **A stop always beats a start in flight.** Starting takes two platform
///    round-trips, and the motor is already running before the second one
///    returns. A stop landing in that window used to be swallowed, so the sound
///    ended and the phone kept going. Generations make the late start clean up
///    after itself instead.
/// 3. **A stop does not just ask the motor to cancel.** Some OEM vibrator HALs
///    are known not to honour a plain cancel on a repeating, alarm-attributed
///    pattern — the exact shape every pattern here is. [PluginVibration.cancel]
///    also overwrites the motor with a fresh, effectively-silent vibration,
///    since a device pre-empting its own running effect is a promise `vibrate`
///    keeps even on the hardware where `cancel` alone does not.
class Haptics {
  /// The backend is positional so tests can swap it; nothing in the app passes
  /// one.
  Haptics([this._backend = const PluginVibration()]);

  final VibrationBackend _backend;

  /// Bumped by every [start] and every [stop]. A start whose generation is no
  /// longer current knows it has been overtaken.
  int _generation = 0;

  bool _running = false;

  /// Whether a pattern is believed to be running. Advisory only — nothing here
  /// may skip a cancel because of it.
  bool get isRunning => _running;

  /// Starts [pattern] on repeat. An empty pattern is a sound that deliberately
  /// does not vibrate (losing signal does not shake a phone), not an error.
  Future<void> start(List<int> pattern) async {
    if (pattern.isEmpty) return;

    final int generation = ++_generation;
    // Claimed before the platform call, not after: from here on a stop will
    // reach the motor even if this start has not returned yet.
    _running = true;

    try {
      if (!await _backend.hasVibrator()) {
        if (generation == _generation) _running = false;
        return;
      }
      // Overtaken while asking. Starting now would strand a pattern nobody is
      // left to cancel.
      if (generation != _generation) return;

      await _backend.vibrate(pattern);

      // Overtaken while starting: the stop already fired its cancel, and it may
      // have reached the motor before this vibrate did. Undo it.
      if (generation != _generation) await _backend.cancel();
    } catch (_) {
      if (generation == _generation) _running = false;
    }
  }

  /// Silences the motor. Safe to call at any time, including when nothing is
  /// running or while a [start] is still in flight.
  Future<void> stop() async {
    _generation++;
    _running = false;
    try {
      await _backend.cancel();
    } catch (_) {
      // A vibrator that refuses to be cancelled is not worth crashing over —
      // and there is nothing else to try.
    }
  }
}

/// Seam over the `vibration` plugin, so the ordering rules above can be tested
/// without a device.
abstract interface class VibrationBackend {
  Future<bool> hasVibrator();

  /// Android-style pattern in ms: [wait, on, off, on, ...], repeating.
  Future<void> vibrate(List<int> pattern);

  Future<void> cancel();
}

class PluginVibration implements VibrationBackend {
  const PluginVibration();

  @override
  Future<bool> hasVibrator() => Vibration.hasVibrator();

  @override
  Future<void> vibrate(List<int> pattern) =>
      Vibration.vibrate(pattern: pattern, repeat: 0);

  /// `Vibration.cancel()` alone is not always enough: a repeating pattern
  /// started with the alarm audio attribute (see [vibrate]) is known to
  /// ignore a plain cancel on some OEM vibrator HALs — the pattern keeps
  /// looping until the app dies. A fresh, effectively-silent vibration
  /// always pre-empts whatever the motor is currently doing, which is a
  /// guarantee `vibrate()` itself keeps even on the hardware where `cancel()`
  /// does not, so it runs right after as a second line of defence.
  @override
  Future<void> cancel() async {
    await Vibration.cancel();
    try {
      await Vibration.vibrate(duration: 1, amplitude: 1);
    } catch (_) {
      // Best-effort belt and braces on top of the cancel() above.
    }
  }
}
