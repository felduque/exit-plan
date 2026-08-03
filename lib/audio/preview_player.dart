import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/escape_sound.dart';

/// A throwaway player for listening *inside* the app.
///
/// Deliberately not the firing engine: no black screen, no vibration, no media
/// controls, no wakelock. It stops when the audio ends, when tapped again, or
/// when the screen that owns it is disposed.
///
/// **The player owns the playing state, not the screen.** [playing] is driven by
/// the real `playerStateStream`, so a button can never claim silence while audio
/// is running or the reverse. Screens used to keep their own optimistic flag and
/// it was always wrong: starting a sound stops the previous one first, which
/// emits `playing == false` a moment *after* the screen had already marked the
/// new sound as playing — so the icon reset itself and never came back.
class PreviewPlayer {
  PreviewPlayer() {
    _stateSub = _player.playerStateStream.listen(_onState);
  }

  final AudioPlayer _player = AudioPlayer();

  /// Id of whatever is audibly playing right now, or null when nothing is.
  ///
  /// For a library sound that is [EscapeSound.id]; for the editor it is the file
  /// path handed to [loadFile]. Callers that only need a yes/no use [isPlaying].
  final ValueNotifier<String?> playing = ValueNotifier<String?>(null);

  StreamSubscription<PlayerState>? _stateSub;

  /// What was last loaded. Not the same as [playing]: this survives a pause.
  String? _currentId;

  String? get currentId => _currentId;

  bool get isPlaying => playing.value != null;

  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get duration => _player.duration;
  Duration get position => _player.position;

  void _onState(PlayerState state) {
    final bool ended = state.processingState == ProcessingState.completed;

    // A window preview repeats, because repeating is exactly what firing does.
    // When the window runs to the very end of the file there is no position
    // event left to catch, so completion is what restarts it.
    final bool looping = ended && _windowStart != null;
    if (looping) unawaited(_restartWindow());

    final bool audible =
        state.playing &&
        state.processingState != ProcessingState.idle &&
        (!ended || looping);

    playing.value = audible ? _currentId : null;
  }

  /// Starts [sound], or stops it if it is the one already playing.
  Future<void> toggle(EscapeSound sound) async {
    if (_currentId == sound.id && isPlaying) {
      await stop();
      return;
    }
    await stop();
    _currentId = sound.id;

    final UriAudioSource file = switch (sound.source) {
      BundledSource(assetPath: final String path) => AudioSource.asset(path),
      UserFileSource(path: final String path) => AudioSource.file(path),
    };
    final TrimWindow? trim = sound.trim;

    await _player.setAudioSource(
      trim == null
          ? file
          : ClippingAudioSource(child: file, start: trim.start, end: trim.end),
    );
    _play();
  }

  // --- editor use ----------------------------------------------------------

  /// Loads a file for the editor and returns its duration.
  Future<Duration?> loadFile(String path) async {
    _currentId = path;
    return _player.setAudioSource(AudioSource.file(path));
  }

  /// Plays the trim window on repeat, so the user hears exactly what will fire.
  Future<void> playWindow(Duration start, Duration end) async {
    await _player.setLoopMode(LoopMode.off);
    _windowStart = start;
    _windowEnd = end;
    _watchWindow();
    await _player.seek(start);
    _play();
  }

  /// Moves the window under a preview that is already running.
  ///
  /// Without this, dragging a handle mid-preview kept looping the bounds
  /// captured when play was pressed — you heard the old cut while looking at the
  /// new one. Does nothing when no window preview is active.
  void retargetWindow(Duration start, Duration end) {
    if (_windowEnd == null) return;
    _windowStart = start;
    _windowEnd = end;
  }

  /// Jumps to an edge the user has just finished dragging, so the next thing
  /// they hear is the cut they made.
  ///
  /// **Dragging never changes whether anything is playing.** If a preview is
  /// running it stays running, from the new edge, still looping the window. If
  /// nothing is playing, nothing starts.
  ///
  /// This used to cancel the window loop, play a 900ms blip and pause itself.
  /// Adjusting a cut you were listening to therefore killed the preview a second
  /// later, which is indistinguishable from a bug — audio that stops on its own
  /// reads as broken, not as a feature. The play button is the only thing that
  /// starts or stops sound in this editor now.
  Future<void> seekToEdge(Duration at) async {
    if (!isPlaying || _windowEnd == null) return;
    await _player.seek(at);
  }

  Duration? _windowStart;
  Duration? _windowEnd;
  StreamSubscription<Duration>? _windowSub;
  bool _restarting = false;

  void _watchWindow() {
    _windowSub?.cancel();
    _windowSub = _player.positionStream.listen((Duration position) async {
      final Duration? end = _windowEnd;
      final Duration? start = _windowStart;
      if (end == null || start == null) return;
      if (position >= end) await _player.seek(start);
    });
  }

  /// Restarts the window after the file itself ran out. Guarded because
  /// `completed` can be emitted more than once before the seek lands.
  Future<void> _restartWindow() async {
    if (_restarting) return;
    _restarting = true;
    try {
      final Duration? start = _windowStart;
      if (start == null) return;
      await _player.seek(start);
      // Never awaited — see [_play]. Awaiting it here held the `finally`
      // below until playback ended, so `_restarting` stayed true forever and
      // the window looped exactly once.
      _play();
    } catch (_) {
      // A dead player is not worth crashing the editor over.
    } finally {
      _restarting = false;
    }
  }

  /// Starts playback without waiting for it to finish.
  ///
  /// just_audio's `play()` completes when playback *ends*, is paused or is
  /// stopped — not when it begins. Nothing in this class wants to be parked
  /// for the length of the audio, so no caller may await it.
  void _play() => unawaited(_player.play().catchError((Object _) {}));

  void _cancelWindow() {
    _windowSub?.cancel();
    _windowSub = null;
    _windowStart = null;
    _windowEnd = null;
  }

  Future<void> pause() async {
    _cancelWindow();
    await _player.pause();
  }

  Future<void> stop() async {
    _cancelWindow();
    _currentId = null;
    await _player.stop();
  }

  Future<void> dispose() async {
    _cancelWindow();
    await _stateSub?.cancel();
    playing.dispose();
    await _player.dispose();
  }
}
