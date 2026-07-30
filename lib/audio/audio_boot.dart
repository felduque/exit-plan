import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'call_ring_engine.dart';
import 'exit_audio_handler.dart';
import 'fire_engine.dart';

/// Single instances, on purpose: `audio_service` registers exactly one handler
/// for the process, and there is only ever one thing firing.
late final ExitAudioHandler exitAudioHandler;
late final FireEngine fireEngine;

/// The fake-call engine. Kept separate from [fireEngine] — see
/// `call_ring_engine.dart` — but the two must never sound at once, so
/// whichever fires cancels the other first.
late final CallRingEngine callRingEngine;

/// Configures audio once, at startup, before anything can fire.
Future<void> initAudio() async {
  exitAudioHandler = await AudioService.init<ExitAudioHandler>(
    builder: ExitAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.exitplan.exitplan.playback',
      // Neutral on purpose: this name is visible in the system's notification
      // settings, so it must not describe what the app really does.
      androidNotificationChannelName: 'Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  fireEngine = FireEngine(exitAudioHandler);
  callRingEngine = CallRingEngine();

  final AudioSession session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration(
      // Playback category keeps the audio alive in the background.
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      // The alarm usage is what makes it ring even with the phone on silent —
      // a doorbell that stays quiet buys no excuse at all.
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: AndroidAudioUsage.alarm,
      ),
      // Exclusive focus: whatever else was playing gets out of the way, which is
      // also what the lock-screen controls need in order to work.
      androidAudioFocusGainType:
          AndroidAudioFocusGainType.gainTransientExclusive,
      androidWillPauseWhenDucked: false,
    ),
  );
  await session.setActive(true);
}
