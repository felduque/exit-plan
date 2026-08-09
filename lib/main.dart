import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'audio/audio_boot.dart';
import 'services/ads_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/force_update_service.dart';
import 'services/tiktok_analytics.dart';
import 'state/app_state.dart';

/// EXITPLAN — excuse sounds that get you out of a room or off a call.
///
/// Offline by design: no backend, no accounts, no sync. Every sound, imported
/// file, call preset and setting lives on the device and stays there. If a
/// feature here looks like it needs a server, the approach is wrong.
///
/// A handful of things reach the network, none of them for the product itself:
///
/// * [TikTokAnalytics] reports an install, so a TikTok ad campaign can be told
///   which installs it paid for.
/// * [AdsService] loads a banner on the screens that own no firing control.
/// * [FirebaseAnalyticsService] reports aggregate usage — screens opened,
///   sessions — never what a sound, excuse or call preset is named.
/// * [ForceUpdateService] reads one remote number, the lowest build this app
///   still runs, so a dangerously outdated install can be made to update.
///
/// None of them sends any record of what the user says or plays. Every file
/// above documents precisely what it does and does not send, and
/// `_PrivacyNote` in the settings screen tells the user the same thing in
/// their words.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Awaited, unlike the two below: `Firebase.initializeApp()` is local config
  // parsing, not a network round trip, and the analytics observer it hands
  // back has to exist before MaterialApp's first build or the very first
  // screen view (home) goes unrecorded.
  await FirebaseAnalyticsService.init();

  // None of these three is awaited. Attribution has to happen at first open
  // to be worth anything, the ad SDK takes a moment to come up, and a
  // Remote Config fetch is the one most likely to stall on bad signal — but
  // all three are the least important things occurring here. Making the user
  // wait on a network handshake before an app they may be about to need in a
  // hurry is ready would be the wrong trade. Screens draw no banner until the
  // SDK reports in, and the forced-update gate only ever appears once its own
  // fetch actually succeeds — never as a side effect of one stalling.
  unawaited(TikTokAnalytics.init());
  unawaited(AdsService.init());
  unawaited(ForceUpdateService.init());

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
