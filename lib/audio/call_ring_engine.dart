import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/escape_sound.dart';
import 'haptics.dart';

/// The fake-call cycle: idle → armed → ringing → active → idle, with `missed`
/// as the other way out of `ringing`.
///
/// Deliberately separate from [FireEngine]: a call has its own phase shape (it
/// answers into a live, timed state a blackout excuse never has) and does not
/// need the lock-screen media session `FireEngine` publishes — the incoming
/// call screen is the whole point of this feature, so there is nothing to hide
/// behind a neutral notification. It owns its own player rather than sharing
/// `exitAudioHandler` for that reason.
class CallRingEngine {
  /// Both collaborators are injectable and both default to the real thing.
  ///
  /// The player is a seam for the same reason [Haptics] has one: the phases
  /// this engine manages — a ring that times out into a missed call, a call
  /// that hangs itself up — are pure timing logic sitting on top of a platform
  /// channel that no widget test can reach. Without a door, the only way to
  /// check that a 30-second ring becomes a missed call is to sit and watch a
  /// phone for 30 seconds.
  CallRingEngine({CallPlayerBackend? player, Haptics? haptics})
    : _player = player ?? JustAudioCallPlayer(),
      _haptics = haptics ?? Haptics();

  /// A phone-ring vibration: a one-second buzz, a one-second rest, repeating.
  /// Android-style pattern in ms: [wait, on, off, on, ...]. `Haptics.start`
  /// repeats the whole pattern forever, same as every other user of it.
  static const List<int> kRingVibration = <int>[0, 1000, 1000];

  final CallPlayerBackend _player;
  final Haptics _haptics;

  CallEnginePhase _phase = CallEnginePhase.idle;
  Timer? _fuseTimer;
  Timer? _missedTimer;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;

  /// Copied off the preset at [arm] so the timers do not have to reach back for
  /// it. Zero means the ring never times out.
  int _ringSeconds = 0;

  /// Null means an answered call runs until somebody ends it.
  int? _autoEndSeconds;

  /// Bumped by every [arm], [answer] and [cancel]. A fuse or a ring whose
  /// generation is no longer current knows it has been overtaken — the same
  /// discipline `FireEngine`/`Haptics` use, and for the same reason: without
  /// it, answering (or hanging up) before the delay elapses left the pending
  /// ring free to start anyway, so the phone kept "receiving" a call nobody
  /// was still waiting for.
  int _generation = 0;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires on every phase, countdown or elapsed-time change.
  Stream<void> get changes => _changes.stream;

  CallEnginePhase get phase => _phase;
  Duration get elapsed => _elapsed;

  /// Arms the cycle: after [delaySeconds] the phone starts ringing [sound] on
  /// loop with [kRingVibration]. A delay of 0 rings immediately.
  ///
  /// [ringSeconds] of 0 rings until answered or declined. [autoEndSeconds] of
  /// null never hangs up on its own.
  ///
  /// [playSound] is false when the call arrived through a system notification
  /// that is already ringing the device's own ringtone; the cycle still runs
  /// so the screen and the in-call timer work, but the app does not add a
  /// second tone on top.
  Future<void> arm(
    EscapeSound sound, {
    required int delaySeconds,
    int ringSeconds = 0,
    int? autoEndSeconds,
    bool vibrate = true,
    bool playSound = true,
  }) async {
    await cancel();
    final int generation = _generation;
    _ringSeconds = ringSeconds;
    _autoEndSeconds = autoEndSeconds;
    await _setWakelock(true);

    // Armed the instant the cycle starts, delay or not — including the
    // `delaySeconds <= 0` path, which used to leave `_phase` at `idle` for
    // however long `_ring` took to actually start playing (a real bundled
    // mp3, unlike the old synthesized tones, is not instant to load). The
    // incoming-call screen renders its Accept button immediately regardless,
    // and [answer] only acts while armed or ringing — so tapping Accept
    // during that idle window used to silently do nothing: the screen still
    // moved on to the in-call view, but the ring had never actually been
    // told to stop, and finished starting moments later with nothing left
    // that could cancel it. That is "answer the call and the ringtone keeps
    // playing anyway."
    _phase = CallEnginePhase.armed;
    _notify();

    if (delaySeconds <= 0) {
      await _ring(sound, generation, vibrate: vibrate, playSound: playSound);
      return;
    }

    _fuseTimer = Timer(
      Duration(seconds: delaySeconds),
      () => _ring(sound, generation, vibrate: vibrate, playSound: playSound),
    );
  }

  Future<void> _ring(
    EscapeSound sound,
    int generation, {
    required bool vibrate,
    required bool playSound,
  }) async {
    // Overtaken before ever starting: answered or declined during the delay.
    if (generation != _generation) return;

    if (playSound) {
      try {
        await _player.load(sound.source, sound.trim);
        // Overtaken while loading: nothing may start playing on behalf of a
        // cycle that has already moved on.
        if (generation != _generation) return;

        // Starting is deliberately not awaitable — see [CallPlayerBackend.play].
        _player.play();
      } catch (_) {
        // A tone that fails to load still has to ring — silently, rather than
        // not ring at all.
      }

      // Overtaken while starting: a stop may have reached the player before
      // play() did. Undo it rather than leave it playing.
      if (generation != _generation) {
        await _player.stop();
        return;
      }
    }

    if (vibrate) {
      await _haptics.start(kRingVibration);
      if (generation != _generation) {
        await _haptics.stop();
        return;
      }
    }

    _phase = CallEnginePhase.ringing;
    _notify();

    // The unanswered path. Started only once the phone is genuinely ringing,
    // so a long delay fuse does not eat into the ring window — "ring for 30
    // seconds" means thirty seconds of noise, not thirty seconds from arming.
    if (_ringSeconds > 0) {
      _missedTimer = Timer(
        Duration(seconds: _ringSeconds),
        () => _miss(generation),
      );
    }
  }

  /// Nobody picked up. Everything stops, but the phase lands on [missed]
  /// rather than [idle] so the screen can say so instead of just vanishing.
  Future<void> _miss(int generation) async {
    if (generation != _generation) return;

    // Not a full [cancel]: that would bump the generation and reset the phase
    // to idle, which is exactly the state this needs to be distinguishable
    // from. Stop the noise, keep the cycle identifiable.
    _missedTimer = null;
    await _haptics.stop();
    await _player.stop();
    await _setWakelock(false);

    if (generation != _generation) return;
    _phase = CallEnginePhase.missed;
    _notify();
  }

  /// The call is picked up: the ring stops (even if it had not actually
  /// started yet — answering during the delay cancels it outright) and a live
  /// duration timer starts.
  Future<void> answer() async {
    if (_phase != CallEnginePhase.armed && _phase != CallEnginePhase.ringing) {
      return;
    }

    _generation++;
    _fuseTimer?.cancel();
    _fuseTimer = null;
    _missedTimer?.cancel();
    _missedTimer = null;
    await _haptics.stop();
    await _player.stop();

    _phase = CallEnginePhase.active;
    _elapsed = Duration.zero;
    _notify();

    final int? autoEnd = _autoEndSeconds;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      _notify();
      // Checked here rather than with a second one-shot timer: one clock means
      // the number on screen and the moment it hangs up can never disagree.
      if (autoEnd != null && _elapsed.inSeconds >= autoEnd) {
        unawaited(cancel());
      }
    });
  }

  /// Declined while armed or ringing, hung up once active, or ended by the
  /// auto-end timer. Either way, everything stops — including a ring still in
  /// flight, see [_ring] — and the cycle returns to idle.
  Future<void> cancel() async {
    _generation++;
    _fuseTimer?.cancel();
    _fuseTimer = null;
    _missedTimer?.cancel();
    _missedTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;

    await _haptics.stop();
    await _player.stop();
    await _setWakelock(false);

    _phase = CallEnginePhase.idle;
    _elapsed = Duration.zero;
    _notify();
  }

  /// Keeps the screen awake for the length of the call, and never lets that
  /// be the reason a call does not happen.
  ///
  /// This used to be a bare `await WakelockPlus.enable()` at the top of [arm],
  /// which made a nice-to-have into a hard dependency of the whole feature: the
  /// call rejects, `_phase` never leaves `idle`, and the incoming screen sits
  /// there with an Accept button wired to an engine that was never armed. A
  /// device whose wakelock plugin is unavailable — or any process with no
  /// platform channel at all — lost fake calls entirely.
  ///
  /// Same doctrine the ad and analytics services already follow: a peripheral
  /// that cannot do its job degrades, it does not take the product down with
  /// it. A call with the screen timing out is worth having; no call is not.
  Future<void> _setWakelock(bool enabled) async {
    try {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Nothing to do and nothing worth surfacing.
    }
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() async {
    await cancel();
    await _player.dispose();
    await _changes.close();
  }
}

enum CallEnginePhase {
  idle,
  armed,
  ringing,

  /// Rang for the full window and nobody answered.
  missed,

  active,
}

/// The ringtone player, behind a seam.
///
/// Mirrors [VibrationBackend]: the engine's timing rules are the interesting
/// part and they cannot be tested against a real `just_audio` player, because
/// the test binding has no platform channel to give it.
abstract interface class CallPlayerBackend {
  /// Prepares [source], clipped to [trim] when there is one, looping.
  Future<void> load(SoundSource source, TrimWindow? trim);

  /// Starts playback. **Returns void, and that is the contract, not an
  /// oversight.**
  ///
  /// `just_audio`'s own `play()` completes when playback *ends*, not when it
  /// starts — and a ringtone loops forever, so it never completes at all.
  /// Awaiting it used to strand the engine: the phase never became `ringing`,
  /// so [CallRingEngine.answer] saw a phase it refuses to act on and returned
  /// without stopping anything, while the ring carried on straight through the
  /// answered call. Making this synchronous means no caller can reintroduce
  /// that await.
  void play();

  Future<void> stop();

  Future<void> dispose();
}

/// The real one.
class JustAudioCallPlayer implements CallPlayerBackend {
  final ja.AudioPlayer _player = ja.AudioPlayer();

  @override
  Future<void> load(SoundSource source, TrimWindow? trim) async {
    final ja.UriAudioSource file = switch (source) {
      BundledSource(assetPath: final String path) => ja.AudioSource.asset(path),
      UserFileSource(path: final String path) => ja.AudioSource.file(path),
    };
    final ja.AudioSource audio = trim == null
        ? file
        : ja.ClippingAudioSource(child: file, start: trim.start, end: trim.end);

    await _player.setLoopMode(ja.LoopMode.one);
    await _player.setAudioSource(audio);
  }

  @override
  void play() => unawaited(_player.play().catchError((Object _) {}));

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
