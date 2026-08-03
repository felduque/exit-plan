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
  Timer? _pauseDebounce;
  StreamSubscription<ja.PlayerState>? _playerSub;
  bool _sawPlaying = false;

  /// Bumped by every [arm] and [cancel]. The fuse timer's call into [_fire]
  /// is fire-and-forget — nothing awaits it — so if it lands in the same
  /// instant the user holds their way out, [_fire] and [cancel] used to run
  /// as two uncoordinated chains with no rule for which one won. When
  /// `_fire`'s chain finished *after* `cancel`'s, it quietly started the
  /// sound and the vibration for real, on a screen that had already popped
  /// — which reads as "it starts vibrating right after I'm done," because
  /// that is exactly what happened. A generation captured at arm time and
  /// checked before every state change `_fire` makes is the same fix
  /// `CallRingEngine` already needed for its own fuse.
  int _generation = 0;

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
    final int generation = _generation;

    _sound = sound;
    _loop = loop;
    _settings = settings;

    await WakelockPlus.enable();

    if (delaySeconds <= 0) {
      await _fire(generation);
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
      _fire(generation);
    });
  }

  Future<void> _fire(int generation) async {
    // Overtaken before ever starting: cancelled during the fuse, or a hold
    // finished right as the countdown hit zero.
    if (generation != _generation) return;

    final EscapeSound? sound = _sound;
    if (sound == null) return;

    try {
      await _handler.load(
        sound,
        repeat: _loop.repeats,
        volume: _settings.playbackVolume,
        publishControls: _settings.lockScreenControls,
      );
    } catch (_) {
      if (generation != _generation) return;
      // A load failure still must not wake the screen. Go quiet and stay dark.
      _phase = FirePhase.done;
      notifyListeners();
      return;
    }

    // Overtaken while loading: a cancel already moved the engine on (and may
    // already own a newer cycle of its own), so this one may not claim
    // `live` — it only has to undo what it just started.
    if (generation != _generation) {
      await _handler.stop();
      return;
    }

    _phase = FirePhase.live;
    notifyListeners();

    // Subscribed before playback starts, so no completion can slip past while
    // this is still attaching.
    _watchPlayer();

    // **`play()` is deliberately not awaited.** just_audio documents its
    // future as completing "when the playback completes or is paused or
    // stopped" — it does *not* resolve once playback begins. Awaiting it
    // here parked the rest of this method until the sound was already over:
    // with a one-shot loop the vibration was started at the exact moment the
    // audio ended (and then buzzed on forever, since patterns repeat), and
    // with an infinite loop the future never completed at all, so the phase
    // never went live, nothing watched the player, and a timed loop never
    // got its stop timer.
    unawaited(_handler.play().catchError((Object _) {}));

    await _startVibration();

    // Overtaken while vibration was starting: undo both, and leave the
    // player subscription to whoever cancelled this cycle — cancel() already
    // ran and cleared it, so it is safe to drop here too.
    if (generation != _generation) {
      await _stopVibration();
      await _handler.stop();
      await _playerSub?.cancel();
      _playerSub = null;
      return;
    }

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
        if (generation != _generation) return;
        _pauseDebounce?.cancel();
        _pauseDebounce = null;
        await _stopVibration();
        await _handler.pause();
        _phase = FirePhase.done;
        notifyListeners();
      });
    }
  }

  /// Mirrors pause/resume coming from the notification. The system stops the
  /// audio for us but not the vibration, so that part is cancelled by hand.
  ///
  /// A real pause holds; a loop restart does not. Real, bundled mp3s are not
  /// the hand-crossfaded, gapless WAV loops the old synthesized set was —
  /// looping a short clip with `LoopMode.one` can hiccup for a beat at the
  /// seam (encoder padding, a brief rebuffer), and that hiccup surfaces here
  /// as the exact same `playing: false` a real pause does. Treating it as one
  /// used to stop the vibration and immediately restart it on *every* loop of
  /// a short sound — audible as the buzz stopping the instant the sound loops
  /// and starting again a beat later, which reads exactly like "it keeps
  /// vibrating after the sound already ended." [_pauseDebounce] holds off
  /// acting on a drop until it has lasted long enough to be a real pause
  /// rather than a seam.
  void _watchPlayer() {
    _playerSub?.cancel();
    _playerSub = _handler.playerStateStream.listen((
      ja.PlayerState state,
    ) async {
      if (_phase != FirePhase.live && _phase != FirePhase.paused) return;

      if (state.processingState == ja.ProcessingState.completed &&
          !_loop.repeats) {
        _pauseDebounce?.cancel();
        _pauseDebounce = null;
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
        // A resume inside the grace window means the drop was just a loop
        // seam — cancel the pending pause before it ever acts.
        _pauseDebounce?.cancel();
        _pauseDebounce = null;
        if (_phase == FirePhase.paused) {
          await _startVibration();
          _phase = FirePhase.live;
          notifyListeners();
        }
      } else if (_sawPlaying && _phase == FirePhase.live) {
        _pauseDebounce?.cancel();
        _pauseDebounce = Timer(const Duration(milliseconds: 400), () async {
          // Re-checked on fire, not assumed: by the time this runs the engine
          // may already have moved on (a real pause raced a cancel/teardown).
          if (_phase != FirePhase.live) return;
          await _stopVibration();
          _phase = FirePhase.paused;
          notifyListeners();
        });
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
    _generation++;
    _fuseTimer?.cancel();
    _fuseTimer = null;
    _limitTimer?.cancel();
    _limitTimer = null;
    _pauseDebounce?.cancel();
    _pauseDebounce = null;
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
