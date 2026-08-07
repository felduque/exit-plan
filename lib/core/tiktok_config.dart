/// Credentials for the TikTok Events SDK, supplied at build time.
///
/// Nothing here is hardcoded on purpose. The access token is a secret that
/// grants write access to the app's event stream in TikTok Events Manager, and
/// a value committed to a repository is a value that can never be un-committed
/// — rotating it later would not remove it from the history. So it arrives
/// through `--dart-define`, and a build that forgets to pass it simply ships
/// with tracking off rather than with a stale token baked in.
///
/// They live in `exitplan.env` (git-ignored, see `exitplan.env.example`)
/// alongside the AdMob ids, and ride in on one flag:
///
/// ```
/// flutter build appbundle --release --dart-define-from-file=exitplan.env
/// ```
library;

import 'package:flutter/foundation.dart';

/// The build-time TikTok credentials, and whether they add up to a usable set.
abstract final class TikTokConfig {
  /// The numeric TikTok App ID from Events Manager. Not a secret — it is
  /// visible in any network capture — but it lives with the token so that a
  /// build either has the whole set or none of it.
  static const String appId = String.fromEnvironment('TIKTOK_APP_ID');

  /// The `TTK…` access token from Events Manager. Secret.
  ///
  /// Optional on Android: the native SDK authenticates the install/launch
  /// events from [appId] alone, and the token is applied afterwards through
  /// `updateAccessToken` (see lib/services/tiktok_analytics.dart). It becomes
  /// required the day iOS ships, where it is an init parameter. A build with an
  /// app id and no token still attributes installs correctly.
  static const String accessToken = String.fromEnvironment(
    'TIKTOK_ACCESS_TOKEN',
  );

  /// The Android application id, which TikTok's Android SDK wants as its
  /// "app id" — distinct from [appId], which it calls the *TikTok* app id.
  ///
  /// Must stay in step with `applicationId` in android/app/build.gradle.kts.
  /// TikTok matches installs against the Play listing under this exact string,
  /// so a typo here does not fail loudly, it just attributes nothing.
  static const String androidPackage = 'com.dg.developer.exitplan';

  /// Whether enough was supplied to initialise the SDK at all.
  ///
  /// False for a plain `flutter run`, for a CI build with no access to the
  /// secret, and for anyone who clones the repository — all of which then
  /// behave exactly like the app did before the SDK existed: no init, no
  /// network call, nothing.
  static bool get isConfigured => appId.isNotEmpty;

  /// Routes events to the "Test Event" tab in Events Manager instead of the
  /// live stream, so a debug session cannot pollute campaign data.
  ///
  /// Note that the Test Event route has to be switched on for the app in Events
  /// Manager first; until it is, TikTok rejects debug-flagged events outright
  /// rather than filing them somewhere harmless.
  static bool get isDebugMode => kDebugMode;

  /// Whether the native SDK should log what it is doing.
  ///
  /// On by default in debug builds. The `--dart-define` exists for the case
  /// that is otherwise undiagnosable: attribution failing in a *release* build,
  /// where the SDK is silent and the only symptom is an empty Events Manager.
  /// Turning it on prints the event batches and TikTok's replies to logcat:
  ///
  /// ```
  /// flutter build apk --release --dart-define-from-file=exitplan.env \
  ///   --dart-define=TIKTOK_VERBOSE=true
  /// adb logcat | grep TTSDK
  /// ```
  ///
  /// Leave it off for anything that ships — the logs name the advertising ID.
  static bool get isVerbose =>
      kDebugMode || const bool.fromEnvironment('TIKTOK_VERBOSE');
}
