import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'audio/audio_boot.dart';
import 'services/ads_service.dart';
import 'services/tiktok_analytics.dart';
import 'state/app_state.dart';

/// EXITPLAN — excuse sounds that get you out of a room or off a call.
///
/// Offline by design: no backend, no accounts, no sync. Every sound, imported
/// file, call preset and setting lives on the device and stays there. If a
/// feature here looks like it needs a server, the approach is wrong.
///
/// Two things reach the network, both for revenue and neither for the product:
///
/// * [TikTokAnalytics] reports an install, so a TikTok ad campaign can be told
///   which installs it paid for.
/// * [AdsService] loads a banner on the screens that own no firing control.
///
/// Neither sends any record of what the user does in here. Both files document
/// precisely what they do and do not send, and `_PrivacyNote` in the settings
/// screen tells the user the same thing in their words.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Neither is awaited. Attribution has to happen at first open to be worth
  // anything, and the ad SDK takes a moment to come up, but both are the least
  // important things occurring here — making the user wait on a network
  // handshake before an app they may be about to need in a hurry is ready
  // would be the wrong trade. Screens draw no banner until the SDK reports in.
  unawaited(TikTokAnalytics.init());
  unawaited(AdsService.init());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
    ),
  );

  // The native splash covers this. Nothing may read a setting before the user's
  // own settings have actually been loaded.
  await initAudio();
  final AppState state = await AppState.bootstrap();

  runApp(ExitApp(state: state));
}
