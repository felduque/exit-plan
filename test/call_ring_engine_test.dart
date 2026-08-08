import 'package:exitplan/audio/call_ring_engine.dart';
import 'package:exitplan/audio/haptics.dart';
import 'package:exitplan/models/escape_sound.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fake-call cycle's timing rules, driven against fakes.
///
/// These are the parts that cannot be checked by looking at a phone: a ring
/// that becomes a missed call after exactly thirty seconds, a call that hangs
/// itself up, and the race a stop has to win against a start that is still in
/// flight. The first two would take a minute of sitting and watching per case;
/// the third cannot be reproduced by hand at all.
void main() {
  const EscapeSound sound = EscapeSound(
    id: 'alarms-clock',
    label: 'Clock',
    categoryId: 'alarms',
    icon: 'alarm',
    source: BundledSource('assets/audio/alarms/clock.mp3'),
  );

  late _FakePlayer player;
  late _FakeVibration vibration;
  late CallRingEngine engine;

  setUp(() {
    player = _FakePlayer();
    vibration = _FakeVibration();
    engine = CallRingEngine(player: player, haptics: Haptics(vibration));
  });

  group('arming and ringing', () {
    test('a delay of 0 reaches ringing', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0);
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.ringing);
        expect(player.playing, isTrue);
        expect(vibration.running, isTrue);
      });
    });

    test('the phase is already armed while the tone is still loading — there '
        'is no idle window in which Accept would silently do nothing', () {
      fakeAsync((FakeAsync async) {
        // A real bundled mp3 is not instant to load, and the incoming screen
        // renders its Accept button on the first frame regardless. When the
        // phase stayed `idle` across this window, tapping Accept hit an
        // [answer] that refuses to act from idle: the screen moved on to the
        // in-call view, the ring finished loading moments later with nothing
        // left that could cancel it, and the ringtone played straight through
        // the answered call.
        player.loadDelay = const Duration(milliseconds: 400);
        engine.arm(sound, delaySeconds: 0);

        async.elapse(const Duration(milliseconds: 100));
        expect(engine.phase, CallEnginePhase.armed);
        expect(player.playing, isFalse);

        // And Accept genuinely works from there.
        engine.answer();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.active);
        expect(player.playing, isFalse);
      });
    });

    test('a delay holds the ring until the fuse burns down', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 5);
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.armed);
        expect(player.playing, isFalse);

        async.elapse(const Duration(seconds: 4));
        expect(player.playing, isFalse);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.ringing);
        expect(player.playing, isTrue);
      });
    });

    test('vibrate: false rings without touching the motor', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0, vibrate: false);
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.ringing);
        expect(player.playing, isTrue);
        expect(vibration.running, isFalse);
      });
    });
  });

  group('missed calls', () {
    test('nobody answers within the window, so everything stops and the phase '
        'says missed rather than idle', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0, ringSeconds: 30);
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.ringing);

        async.elapse(const Duration(seconds: 29));
        expect(engine.phase, CallEnginePhase.ringing);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.missed);
        expect(player.playing, isFalse);
        expect(vibration.running, isFalse);
      });
    });

    test('the ring window starts when the phone starts ringing, not when the '
        'cycle is armed — a long fuse must not eat into it', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 20, ringSeconds: 30);
        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.ringing);

        // 29s after the ring began — 49s after arming. Still ringing.
        async.elapse(const Duration(seconds: 29));
        expect(engine.phase, CallEnginePhase.ringing);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.missed);
      });
    });

    test('ringSeconds of 0 rings on rather than missing immediately', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0, ringSeconds: 0);
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 10));
        expect(engine.phase, CallEnginePhase.ringing);
        expect(player.playing, isTrue);
      });
    });

    test('answering before the window closes cancels the miss, so a call that '
        'was picked up cannot later report itself as missed', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0, ringSeconds: 30);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 10));
        engine.answer();
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.active);

        async.elapse(const Duration(seconds: 60));
        expect(engine.phase, CallEnginePhase.active);
      });
    });

    test('declining before the window closes leaves it idle, not missed', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0, ringSeconds: 30);
        async.flushMicrotasks();
        engine.cancel();
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.idle);

        async.elapse(const Duration(seconds: 60));
        expect(engine.phase, CallEnginePhase.idle);
      });
    });
  });

  group('answering', () {
    test('the ring stops the instant the call is picked up', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0);
        async.flushMicrotasks();
        expect(player.playing, isTrue);

        engine.answer();
        async.flushMicrotasks();
        expect(player.playing, isFalse);
        expect(vibration.running, isFalse);
      });
    });

    test('answering during the delay cancels the ring that had not started, '
        'so the phone does not begin ringing into an answered call', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 5);
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.armed);

        engine.answer();
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.active);

        // The fuse's moment comes and goes with nothing behind it.
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();
        expect(player.playing, isFalse);
        expect(engine.phase, CallEnginePhase.active);
      });
    });

    test('the duration counts up once a second', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0);
        async.flushMicrotasks();
        engine.answer();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 5));
        expect(engine.elapsed, const Duration(seconds: 5));
      });
    });

    test('answering from idle does nothing — there is no call to pick up', () {
      fakeAsync((FakeAsync async) {
        engine.answer();
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.idle);
      });
    });
  });

  group('auto-end', () {
    test('hangs up on its own once the call reaches its length', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0, autoEndSeconds: 60);
        async.flushMicrotasks();
        engine.answer();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 59));
        expect(engine.phase, CallEnginePhase.active);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.idle);
        expect(player.playing, isFalse);
        expect(vibration.running, isFalse);
      });
    });

    test('a null auto-end runs until somebody ends it', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0);
        async.flushMicrotasks();
        engine.answer();
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 30));
        expect(engine.phase, CallEnginePhase.active);
      });
    });

    test('the clock that shows the time and the clock that ends the call are '
        'the same one, so they cannot disagree', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 0, autoEndSeconds: 30);
        async.flushMicrotasks();
        engine.answer();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 29));
        expect(engine.elapsed, const Duration(seconds: 29));
        expect(engine.phase, CallEnginePhase.active);
      });
    });
  });

  group('cancel wins every race', () {
    test('a cancel arriving while the ring is still loading leaves nothing '
        'playing', () {
      fakeAsync((FakeAsync async) {
        player.loadDelay = const Duration(milliseconds: 300);
        engine.arm(sound, delaySeconds: 0);
        async.elapse(const Duration(milliseconds: 100));

        // Mid-load: the player has been asked for the source but has not
        // returned yet.
        engine.cancel();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(engine.phase, CallEnginePhase.idle);
        expect(player.playing, isFalse);
        expect(vibration.running, isFalse);
      });
    });

    test('re-arming replaces the previous cycle rather than running two', () {
      fakeAsync((FakeAsync async) {
        engine.arm(sound, delaySeconds: 10, ringSeconds: 30);
        async.elapse(const Duration(seconds: 5));

        engine.arm(sound, delaySeconds: 0, ringSeconds: 30);
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.ringing);

        // The first cycle's fuse would have fired at t=10. If it were still
        // alive it would restart a ring behind this one.
        async.elapse(const Duration(seconds: 10));
        expect(engine.phase, CallEnginePhase.ringing);
        expect(player.loads, 1);
      });
    });

    test('cancel is idempotent and safe from idle', () {
      fakeAsync((FakeAsync async) {
        engine.cancel();
        engine.cancel();
        async.flushMicrotasks();
        expect(engine.phase, CallEnginePhase.idle);
      });
    });
  });
}

/// A [CallPlayerBackend] that records what it was asked to do.
class _FakePlayer implements CallPlayerBackend {
  bool playing = false;
  int loads = 0;

  /// Lets a test hold a load open, which is the window the generation checks
  /// in the engine exist to cover.
  Duration loadDelay = Duration.zero;

  @override
  Future<void> load(SoundSource source, TrimWindow? trim) async {
    loads++;
    if (loadDelay > Duration.zero) await Future<void>.delayed(loadDelay);
  }

  @override
  void play() => playing = true;

  @override
  Future<void> stop() async => playing = false;

  @override
  Future<void> dispose() async {}
}

/// Mirrors the seam `haptics_test` uses.
class _FakeVibration implements VibrationBackend {
  bool running = false;

  @override
  Future<bool> hasVibrator() async => true;

  @override
  Future<void> vibrate(List<int> pattern) async => running = true;

  @override
  Future<void> cancel() async => running = false;
}
