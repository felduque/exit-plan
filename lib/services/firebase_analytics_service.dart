import 'dart:io' show Platform;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Brings Firebase up and hands back a `NavigatorObserver` that logs
/// `screen_view` automatically, so the app's day-to-day usage — sessions,
/// active users, which screens get opened — shows up in Firebase Analytics
/// with no manual instrumentation anywhere else.
///
/// ## Nothing named, nothing typed
///
/// This is aggregate usage only. It reports that *a* screen was viewed, never
/// which sound played, what a call preset was named, or anything the user
/// typed — the same doctrine [TikTokAnalytics] already applies to install
/// attribution.
///
/// ## Failure is not an error
///
/// Same doctrine as every other network-touching service in this app: a
/// device that cannot reach Firebase must never be the reason a screen fails
/// to build. See [ForceUpdateService] for the one Firebase feature that would
/// otherwise be tempted to block on network — it fails open for the same
/// reason.
abstract final class FirebaseAnalyticsService {
  static bool _started = false;
  static FirebaseAnalyticsObserver? _observer;

  /// Null until [init] succeeds. `app.dart` only adds this to
  /// `navigatorObservers` once it exists, so a build with no
  /// `google-services.json` — or a device that can't reach Firebase — just
  /// runs with no screen tracking, not a crash.
  static FirebaseAnalyticsObserver? get observer => _observer;

  /// Safe to call unconditionally and more than once. Awaited in `main.dart`,
  /// unlike the fire-and-forget `unawaited()` calls for TikTok/AdMob: the
  /// observer has to exist before `MaterialApp` builds for the first time, or
  /// the very first `screen_view` (home) is missed. `Firebase.initializeApp()`
  /// itself is local config parsing, not a network round trip, so this costs
  /// about what `initAudio()` already does.
  static Future<void> init() async {
    if (_started || !Platform.isAndroid) return;
    _started = true;

    try {
      await Firebase.initializeApp();
      _observer = FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('FirebaseAnalyticsService.init failed (ignored): $error\n$stack');
      }
    }
  }
}
