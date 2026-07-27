import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/app_settings.dart';
import '../models/enums.dart';
import '../models/escape_sound.dart';
import 'exit_audio_handler.dart';
import 'haptics.dart';

/// The firing cycle: idle → armed → live → paused → done.
///
/// Only the black screen drives this. Regular screens never play the alarm; they
/// navigate to the black screen and hand it the sound, the delay and the loop
/// mode. (Previews are a separate, throwaway player.)
///
/// The hard rule this class exists to protect: **the screen never lights up on
/// its own.** Pausing, finishing or failing changes a faint line of text and
/// nothing else. The phone has to keep looking like it is in a pocket.
class FireEngine extends ChangeNotifier {
  FireEngine(this._handler, {Haptics? haptics})
    : _haptics = haptics ?? Haptics();

  final ExitAudioHandler _handler;
  final Haptics _haptics;

  FirePhase _phase = FirePhase.idle;
  int _countdown = 0;
  EscapeSound? _sound;
  AppSettings _settings = AppSettings.defaults;
  LoopChoice _loop = LoopChoice.infinite;

  Timer? _fuseTimer;
  Timer? _limitTimer;
  StreamSubscription<ja.PlayerState>? _playerSub;
  bool _sawPlaying = false;

  FirePhase get phase => _phase;

  /// Seconds left on the delay fuse while [FirePhase.armed].
  int get countdown => _countdown;

  EscapeSound? get sound => _sound;

  /// Arms the cycle. With a delay of 0 the sound fires immediately; otherwise a
  /// one-second countdown runs first so the user can pocket the phone.
  Future<void> arm(
    EscapeSound sound, {
    required int delaySeconds,
    required LoopChoice loop,
    required AppSettings settings,
  }) async {
    await cancel(notify: false);

    _sound = sound;
    _loop = loop;
    _settings = settings;

    await WakelockPlus.enable();

    if (delaySeconds <= 0) {
      await _fire();
      return;
    }

    _countdown = delaySeconds;
    _phase = FirePhase.armed;
    notifyListeners();

    _fuseTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _countdown--;
      if (_countdown > 0) {
        notifyListeners();
        return;
      }
      timer.cancel();
      _fuseTimer = null;
      _fire();
    });
  }

  Future<void> _fire() async {
    final EscapeSound? sound = _sound;
    if (sound == null) return;

    try {
      await _handler.load(
        sound,
        repeat: _loop.repeats,
        volume: _settings.playbackVolume,
        publishControls: _settings.lockScreenControls,
      );
      await _handler.play();
    } catch (_) {
      // A load failure still must not wake the screen. Go quiet and stay dark.
      _phase = FirePhase.done;
      notifyListeners();
      return;
    }

    _phase = FirePhase.live;
    notifyListeners();

    await _startVibration();
    _watchPlayer();

    final Duration? limit = _loop.limit;
    if (limit != null) {
      // Stops the vibration and the audio when it expires — and nothing else.
      //
      // Vibration first, deliberately. Pausing is a round trip through the media
      // service, and doing it first left the phone buzzing on after the room had
      // already gone quiet — which is the one moment a buzzing phone is
      // conspicuous. The two have to end together, and if either has to be late
      // it is the silence, not the shaking.
      _limitTimer = Timer(limit, () async {
        await _stopVibration();
        await _handler.pause();
        _phase = FirePhase.done;
        notifyListeners();
      });
    }
  }

  /// Mirrors pause/resume coming from the notification. The system stops the
  /// audio for us but not the vibration, so that part is cancelled by hand.
  void _watchPlayer() {
    _playerSub?.cancel();
    _playerSub = _handler.playerStateStream.listen((
      ja.PlayerState state,
    ) async {
      if (_phase != FirePhase.live && _phase != FirePhase.paused) return;

      if (state.processingState == ja.ProcessingState.completed &&
          !_loop.repeats) {
        await _stopVibration();
        _phase = FirePhase.done;
        notifyListeners();
        return;
      }

      // The stream replays its current value, and right after play() that still
      // reads playing=false. Treating it as a pause would flip the phase the
      // instant we subscribe, so a pause only counts once playback has actually
      // been observed. An idle state is teardown, not a user pause.
      if (state.processingState == ja.ProcessingState.idle) return;

      if (state.playing) {
        _sawPlaying = true;
        if (_phase == FirePhase.paused) {
          await _startVibration();
          _phase = FirePhase.live;
          notifyListeners();
        }
      } else if (_sawPlaying && _phase == FirePhase.live) {
        await _stopVibration();
        _phase = FirePhase.paused;
        notifyListeners();
      }
    });
  }

  Future<void> _startVibration() async {
    final EscapeSound? sound = _sound;
    if (sound == null || !_settings.hapticSupport) return;
    await _haptics.start(sound.vibration);
  }

  /// Always reaches the motor — see [Haptics.stop]. Cheap enough to call on
  /// every teardown, and the alternative is a phone that will not stop buzzing.
  Future<void> _stopVibration() => _haptics.stop();

  /// Tears everything down: audio, vibration, timers, media controls and the
  /// wakelock. Called when the user long-presses their way out of the dark.
  Future<void> cancel({bool notify = true}) async {
    _fuseTimer?.cancel();
    _fuseTimer = null;
    _limitTimer?.cancel();
    _limitTimer = null;
    await _playerSub?.cancel();
    _playerSub = null;

    await _stopVibration();
    await _handler.stop();
    await WakelockPlus.disable();

    _phase = FirePhase.idle;
    _countdown = 0;
    _sound = null;
    _sawPlaying = false;
    if (notify) notifyListeners();
  }
}
