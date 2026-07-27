import 'dart:async';

import 'package:exitplan/audio/haptics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Patterns run with `repeat: 0` — for ever, until something cancels them. So a
/// missed cancel is not a glitch, it is a phone that keeps buzzing in the room
/// the user was trying to walk out of quietly.
///
/// The bug these tests exist for: the motor starts as soon as `vibrate()`
/// reaches the platform, but the "is it running" flag used to be set only when
/// that call *returned*. A stop landing in between saw `false`, skipped the
/// cancel, and left the phone shaking after the sound had ended.
void main() {
  const List<int> pattern = <int>[0, 380, 220, 380, 900];

  test('a plain start then stop reaches the motor once each', () async {
    final _FakeVibrator motor = _FakeVibrator();
    final Haptics haptics = Haptics(motor);

    await haptics.start(pattern);
    expect(motor.vibrated, <List<int>>[pattern]);
    expect(haptics.isRunning, isTrue);

    await haptics.stop();
    expect(motor.cancels, 1);
    expect(haptics.isRunning, isFalse);
  });

  test('an empty pattern never touches the motor', () async {
    // Losing signal does not shake a phone. That is a real catalog entry, not a
    // missing value.
    final _FakeVibrator motor = _FakeVibrator();
    await Haptics(motor).start(const <int>[]);

    expect(motor.vibrated, isEmpty);
    expect(motor.cancels, 0);
  });

  test('a stop lands even when nothing is believed to be running', () async {
    // The flag is advisory. If it ever disagrees with the hardware, the
    // hardware wins, so stop always spends the platform call.
    final _FakeVibrator motor = _FakeVibrator();
    await Haptics(motor).stop();

    expect(motor.cancels, 1);
  });

  test('a stop while vibrate() is still in flight still silences it', () async {
    final _FakeVibrator motor = _FakeVibrator()..holdVibrate = true;
    final Haptics haptics = Haptics(motor);

    final Future<void> starting = haptics.start(pattern);
    await pumpEventQueue();
    // The motor is already shaking; the call has not returned.
    expect(motor.vibrated, <List<int>>[pattern]);

    await haptics.stop();
    motor.releaseVibrate();
    await starting;

    // Once for the stop, once for the overtaken start cleaning up after itself.
    expect(motor.cancels, greaterThanOrEqualTo(1));
    expect(motor.silent, isTrue);
    expect(haptics.isRunning, isFalse);
  });

  test('a stop while hasVibrator() is in flight prevents the start', () async {
    final _FakeVibrator motor = _FakeVibrator()..holdHasVibrator = true;
    final Haptics haptics = Haptics(motor);

    final Future<void> starting = haptics.start(pattern);
    await pumpEventQueue();
    await haptics.stop();
    motor.releaseHasVibrator();
    await starting;

    // Nothing may be started after a stop: there would be no one left to cancel
    // it, and the pattern repeats for ever.
    expect(motor.vibrated, isEmpty);
    expect(motor.silent, isTrue);
  });

  test('restarting after a stop works — resume from the notification', () async {
    final _FakeVibrator motor = _FakeVibrator();
    final Haptics haptics = Haptics(motor);

    await haptics.start(pattern);
    await haptics.stop();
    await haptics.start(pattern);

    expect(motor.vibrated.length, 2);
    expect(motor.silent, isFalse);
    expect(haptics.isRunning, isTrue);
  });

  test('a motor that throws leaves the state consistent', () async {
    final _FakeVibrator motor = _FakeVibrator()..throwOnVibrate = true;
    final Haptics haptics = Haptics(motor);

    await haptics.start(pattern);
    expect(haptics.isRunning, isFalse);

    // And a later stop is still delivered rather than skipped.
    await haptics.stop();
    expect(motor.cancels, 1);
  });
}

/// Stands in for the plugin, and tracks whether the hardware would be shaking.
class _FakeVibrator implements VibrationBackend {
  final List<List<int>> vibrated = <List<int>>[];
  int cancels = 0;

  /// What the physical motor would be doing right now.
  bool silent = true;

  bool holdVibrate = false;
  bool holdHasVibrator = false;
  bool throwOnVibrate = false;

  Completer<void>? _vibrateGate;
  Completer<void>? _hasVibratorGate;

  void releaseVibrate() => _vibrateGate?.complete();
  void releaseHasVibrator() => _hasVibratorGate?.complete();

  @override
  Future<bool> hasVibrator() async {
    if (holdHasVibrator) {
      final Completer<void> gate = Completer<void>();
      _hasVibratorGate = gate;
      await gate.future;
    }
    return true;
  }

  @override
  Future<void> vibrate(List<int> pattern) async {
    // The motor starts the moment the call is made, not when it returns — which
    // is the whole reason the race existed.
    vibrated.add(pattern);
    silent = false;
    if (throwOnVibrate) throw StateError('no vibrator');
    if (holdVibrate) {
      final Completer<void> gate = Completer<void>();
      _vibrateGate = gate;
      await gate.future;
    }
  }

  @override
  Future<void> cancel() async {
    cancels++;
    silent = true;
  }
}
