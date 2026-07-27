import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../models/escape_sound.dart';

/// Owns the one real player and, optionally, the media session.
///
/// Two things here are deliberate and must not be "improved":
///
/// 1. The published metadata is **neutral**. The notification shows on the lock
///    screen, where a third party can read it; "DOORBELL DING · EXITPLAN" would
///    give the excuse away. It says `Audio` and nothing else.
/// 2. Publishing the session is what keeps Android from killing background audio
///    after ~3 minutes. When the user turns lock-screen controls off we stop
///    publishing, and accept that the OS may cut the audio.
class ExitAudioHandler extends BaseAudioHandler {
  ExitAudioHandler() {
    _player.playbackEventStream.listen((_) => _broadcast());
    _player.playerStateStream.listen((_) => _broadcast());
  }

  static const MediaItem _neutralItem = MediaItem(
    id: 'exitplan',
    title: 'Audio',
  );

  final ja.AudioPlayer _player = ja.AudioPlayer();

  bool _publish = true;

  ja.AudioPlayer get player => _player;

  Stream<ja.PlayerState> get playerStateStream => _player.playerStateStream;

  bool get isPlaying => _player.playing;

  /// Loads [sound] and arms the player. A trimmed sound is wrapped in a
  /// [ja.ClippingAudioSource], so the window itself is what loops — the player
  /// handles the boundary instead of a position watcher polling for it.
  Future<void> load(
    EscapeSound sound, {
    required bool repeat,
    required double volume,
    required bool publishControls,
  }) async {
    _publish = publishControls;

    final ja.UriAudioSource file = switch (sound.source) {
      BundledSource(assetPath: final String path) => ja.AudioSource.asset(path),
      UserFileSource(path: final String path) => ja.AudioSource.file(path),
    };

    final TrimWindow? trim = sound.trim;
    final ja.AudioSource source = trim == null
        ? file
        : ja.ClippingAudioSource(child: file, start: trim.start, end: trim.end);

    await _player.setLoopMode(repeat ? ja.LoopMode.one : ja.LoopMode.off);
    await _player.setVolume(volume);
    await _player.setAudioSource(source);

    if (_publish) {
      mediaItem.add(_neutralItem);
    } else {
      mediaItem.add(null);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _publish = false;
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(
        controls: const <MediaControl>[],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  void _broadcast() {
    if (!_publish) return;
    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const <MediaAction>{
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: const <int>[0, 1],
        processingState: switch (_player.processingState) {
          ja.ProcessingState.idle => AudioProcessingState.idle,
          ja.ProcessingState.loading => AudioProcessingState.loading,
          ja.ProcessingState.buffering => AudioProcessingState.buffering,
          ja.ProcessingState.ready => AudioProcessingState.ready,
          ja.ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: _player.playing,
        updatePosition: _player.position,
      ),
    );
  }
}
