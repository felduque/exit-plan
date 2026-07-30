import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/escape_sound.dart';
import 'haptics.dart';

/// The fake-call cycle: idle → armed → ringing → active → idle.
///
/// Deliberately separate from [FireEngine]: a call has its own phase shape (it
/// answers into a live, timed state a blackout excuse never has) and does not
/// need the lock-screen media session `FireEngine` publishes — the incoming
/// call screen is the whole point of this feature, so there is nothing to hide
/// behind a neutral notification. It owns its own player rather than sharing
/// `exitAudioHandler` for that reason.
class CallRingEngine {
  CallRingEngine({Haptics? haptics}) : _haptics = haptics ?? Haptics();

  /// A phone-ring vibration: a one-second buzz, a one-second rest, repeating.
  /// Android-style pattern in ms: [wait, on, off, on, ...]. `Haptics.start`
  /// repeats the whole pattern forever, same as every other user of it.
  static const List<int> kRingVibration = <int>[0, 1000, 1000];

  final ja.AudioPlayer _player = ja.AudioPlayer();
  final Haptics _haptics;

  CallEnginePhase _phase = CallEnginePhase.idle;
  Timer? _fuseTimer;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;

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
  Future<void> arm(EscapeSound sound, {required int delaySeconds}) async {
    await cancel();
    final int generation = _generation;
    await WakelockPlus.enable();

    if (delaySeconds <= 0) {
      await _ring(sound, generation);
      return;
    }

    _phase = CallEnginePhase.armed;
    _notify();

    _fuseTimer = Timer(
      Duration(seconds: delaySeconds),
      () => _ring(sound, generation),
    );
  }

  Future<void> _ring(EscapeSound sound, int generation) async {
    // Overtaken before ever starting: answered or declined during the delay.
    if (generation != _generation) return;

    try {
      final ja.UriAudioSource file = switch (sound.source) {
        BundledSource(assetPath: final String path) => ja.AudioSource.asset(
          path,
        ),
        UserFileSource(path: final String path) => ja.AudioSource.file(path),
      };
      final TrimWindow? trim = sound.trim;
      final ja.AudioSource source = trim == null
          ? file
          : ja.ClippingAudioSource(
              child: file,
              start: trim.start,
              end: trim.end,
            );

      await _player.setLoopMode(ja.LoopMode.one);
      await _player.setAudioSource(source);
      // Overtaken while loading: nothing may start playing on behalf of a
      // cycle that has already moved on.
      if (generation != _generation) return;

      await _player.play();
      // Overtaken while starting: the stop may have reached the player before
      // play() did. Undo it rather than leave it playing.
      if (generation != _generation) {
        await _player.stop();
        return;
      }
    } catch (_) {
      // A tone that fails to load still has to ring — silently, rather than
      // not ring at all.
    }

    await _haptics.start(kRingVibration);
    if (generation != _generation) {
      await _haptics.stop();
      return;
    }

    _phase = CallEnginePhase.ringing;
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
    await _haptics.stop();
    await _player.stop();

    _phase = CallEnginePhase.active;
    _elapsed = Duration.zero;
    _notify();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      _notify();
    });
  }

  /// Declined while armed or ringing, or hung up once active. Either way,
  /// everything stops — including a ring still in flight, see [_ring] — and
  /// the cycle returns to idle.
  Future<void> cancel() async {
    _generation++;
    _fuseTimer?.cancel();
    _fuseTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;

    await _haptics.stop();
    await _player.stop();
    await WakelockPlus.disable();

    _phase = CallEnginePhase.idle;
    _elapsed = Duration.zero;
    _notify();
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

enum CallEnginePhase { idle, armed, ringing, active }
