import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ads_config.dart';

/// Brings the AdMob SDK up, once, and tells the UI when it may draw a banner.
///
/// ## Nothing is drawn until this says so
///
/// [initialized] starts `false` and only ever becomes `true` after the native
/// SDK reports ready. Every [AdBannerSlot] watches it, so a build with no ads
/// configured, a platform that is not Android, and every widget test all render
/// exactly the layout the app had before ads existed.
///
/// That last one is not a testing convenience — it is the honest behaviour. The
/// SDK genuinely is not up during those first frames, and reserving space for
/// something that may never arrive would move the layout under a thumb.
///
/// ## Failure is not an error
///
/// Same doctrine as [TikTokAnalytics]. This app is a panic button; an ad SDK
/// that cannot reach Google must never be the reason a screen fails to build.
abstract final class AdsService {
  /// Whether banners may be created. Watched, not polled.
  static final ValueNotifier<bool> initialized = ValueNotifier<bool>(false);

  static bool _started = false;

  /// Safe to call unconditionally and more than once.
  static Future<void> init() async {
    if (_started || !AdsConfig.isSupportedPlatform) return;
    _started = true;

    try {
      await MobileAds.instance.initialize();

      // Non-personalised everywhere, for now. Personalised ads in the EEA need
      // a UMP consent dialog, and a consent dialog on first launch is a
      // discretion problem for this app in particular — it is the one moment
      // someone might be showing the app to a friend. Revisit if EEA revenue
      // ever justifies the flow.
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
          maxAdContentRating: MaxAdContentRating.pg,
        ),
      );

      initialized.value = true;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('AdsService.init failed (ignored): $error\n$stack');
      }
    }
  }

  /// The one ad request shape the app makes.
  static AdRequest get request => const AdRequest(nonPersonalizedAds: true);

  /// Lets a test stand in for the native SDK. Mirrors
  /// `NotificationPermission.debugSet`.
  @visibleForTesting
  static void debugSet({required bool ready, double? forcedHeight}) {
    debugForcedHeight = forcedHeight;
    initialized.value = ready;
  }

  /// When set, `AdBannerSlot` reserves this height and skips the real ad.
  ///
  /// Read by production code, so it cannot carry `@visibleForTesting` — but
  /// only [debugSet] ever writes it, and nothing in the app calls that. It is
  /// how the layout tests prove home still fits once ads go live, which is the
  /// one thing about this feature worth protecting with a test.
  static double? debugForcedHeight;
}
