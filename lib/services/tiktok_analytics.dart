import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:tiktok_events_sdk/tiktok_events_sdk.dart';

import '../core/tiktok_config.dart';

/// The app's one and only network caller: TikTok install attribution.
///
/// ## What this exists for
///
/// Paid installs are bought on TikTok, and TikTok can only report which
/// campaign produced which install if the app confirms the install from the
/// device. That confirmation is the whole feature. Nothing here measures what
/// a user does inside the app.
///
/// ## What actually leaves the device
///
/// Only what the SDK sends on its own: an install event on first open, a launch
/// event on subsequent opens, retention pings, and the advertising ID (AAID)
/// that TikTok matches against the ad click. That is the complete list.
///
/// ## What deliberately does not
///
/// This class exposes no `logEvent` wrapper, and the app calls none. Which
/// sound was fired, which category was opened, which file was imported, which
/// call preset was used, how long the app was open — none of it is collected,
/// because none of it is needed to attribute an install and all of it is the
/// sort of thing this app promises not to gather. `identify()` is likewise
/// never called: there is no account, no email and no user id to send.
///
/// If a conversion event is ever genuinely wanted, add it here, deliberately,
/// and update the Play Data Safety declaration in the same change — do not
/// reach for `TikTokEventsSdk.logEvent` from a screen.
///
/// ## Failure is not an error
///
/// Attribution is a marketing convenience; the app is a panic button. Every
/// entry point below swallows its failures, because an SDK that cannot reach
/// TikTok must never be the reason someone's excuse sound did not play.
abstract final class TikTokAnalytics {
  /// Initialises the SDK, if this build was given credentials and is running
  /// on a platform the integration covers.
  ///
  /// Safe to call unconditionally. Returns as soon as it can when tracking is
  /// not applicable, and never throws.
  static Future<void> init() async {
    if (!_isSupportedPlatform || !TikTokConfig.isConfigured) return;

    try {
      await TikTokEventsSdk.initSdk(
        // TikTok's Android SDK calls the application id the "app id" and the
        // number from Events Manager the "TikTok app id". They are not
        // interchangeable and swapping them silently attributes nothing.
        androidAppId: TikTokConfig.androidPackage,
        tikTokAndroidId: TikTokConfig.appId,
        // iOS is not part of this integration yet — the app ships on Play
        // only, and TikTok issues a separate app id per platform. Empty
        // strings are inert here because [_isSupportedPlatform] has already
        // ruled iOS out; they are what has to be filled in, together with an
        // NSUserTrackingUsageDescription in Info.plist, on the day iOS ships.
        iosAppId: '',
        tiktokIosId: '',
        // Debug builds report to the "Test Event" tab in Events Manager rather
        // than the live stream, so development cannot distort campaign data.
        isDebugMode: TikTokConfig.isDebugMode,
        logLevel: TikTokConfig.isVerbose
            ? TikTokLogLevel.debug
            : TikTokLogLevel.none,
        androidOptions: const TikTokAndroidOptions(
          // Install, launch and retention stay on: they *are* the attribution.
          // The two below are switched off because they collect beyond it.
          //
          // There is nothing to buy in this app, so purchase tracking would
          // only add a Billing dependency and a data category to declare.
          enableAutoIapTrack: false,
          // Enhanced Data Postback widens automatic collection past the
          // install signal. Off, to keep what is sent to the list documented
          // at the top of this file.
          disableAutoEnhancedDataPostbackEvent: true,
        ),
      );

      // Android authenticates from the app id at init and takes the token
      // separately, unlike iOS where it is an init parameter. A build without
      // one still attributes installs, so this is best-effort.
      if (TikTokConfig.accessToken.isNotEmpty) {
        await TikTokEventsSdk.updateAccessToken(
          accessToken: TikTokConfig.accessToken,
        );
      }
    } catch (error, stack) {
      // Never rethrow: this runs on the boot path.
      _swallow('init', error, stack);
    }
  }

  /// Pushes anything still queued to TikTok.
  ///
  /// The SDK batches on a timer, so an install recorded seconds before the user
  /// leaves can otherwise sit unsent. Worth calling when the app goes to the
  /// background; not worth caring whether it succeeded.
  static Future<void> flush() async {
    if (!_isSupportedPlatform || !TikTokConfig.isConfigured) return;
    try {
      await TikTokEventsSdk.flush();
    } catch (error, stack) {
      _swallow('flush', error, stack);
    }
  }

  /// Android only, for now. See the note on `iosAppId` in [init].
  static bool get _isSupportedPlatform => Platform.isAndroid;

  static void _swallow(String stage, Object error, StackTrace stack) {
    if (!kDebugMode) return;
    debugPrint('TikTokAnalytics.$stage failed (ignored): $error\n$stack');
  }
}
