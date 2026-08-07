/// AdMob identifiers, supplied at build time.
///
/// The publisher account is `pub-4512388051733069`.
///
/// Unlike [TikTokConfig], the *default here is not "off"* — it is Google's
/// official test unit. That is deliberate. A build with no ad unit id that
/// served nothing would look identical to a build whose id was mistyped, and
/// the mistake would only surface as silently missing revenue weeks later. Test
/// ads are loud: they say TEST AD across the banner.
///
/// The inverse mistake is the dangerous one. Serving *live* ads from a debug
/// session, or clicking your own ads while developing, is a well-known route to
/// an AdMob account suspension. Defaulting to test units means that can only
/// happen on purpose.
///
/// The ids live in `exitplan.env` (git-ignored, see `exitplan.env.example`)
/// alongside the TikTok credentials, and ride in on one flag:
///
/// ```
/// flutter build appbundle --release --dart-define-from-file=exitplan.env
/// ```
///
/// The AdMob **app id** is in that same file but is not read here: it has to be
/// in the Android manifest before Dart runs, so gradle parses the file too. See
/// `android/app/build.gradle.kts`.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

abstract final class AdsConfig {
  /// Google's official Android test banner unit. Publicly documented, safe to
  /// commit, and impossible to confuse with a real one.
  static const String _testBannerUnit = 'ca-app-pub-3940256099942544/9214589741';

  static const String _bannerUnit = String.fromEnvironment('ADMOB_BANNER_UNIT');

  /// One unit serves all six screens for now. Per-placement units buy nothing
  /// but reporting granularity, and can be added later as extra defines without
  /// touching any widget.
  static String get bannerUnitId =>
      _bannerUnit.isEmpty ? _testBannerUnit : _bannerUnit;

  /// True when this build will show TEST AD banners. Surfaced so a debug build
  /// can say so rather than leaving someone wondering.
  static bool get usingTestUnits => _bannerUnit.isEmpty;

  /// Android is the only platform this app ships on today, and the only one
  /// with an AdMob app id configured. iOS would need its own of both.
  static bool get isSupportedPlatform => !kIsWeb && Platform.isAndroid;
}
