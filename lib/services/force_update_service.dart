import 'dart:io' show Platform;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reads exactly one remote number — the lowest build this app will still run
/// — and tells the UI when the installed build has fallen below it.
///
/// ## Fails open, never closed
///
/// [updateRequired] starts `false` and only a *successful* fetch that names a
/// real minimum can ever flip it. No network, no Firebase, a timeout, a
/// missing `google-services.json` — every one of those leaves the app exactly
/// as usable as it was before this feature existed. A panic-button app that
/// could lock its own user out because a Remote Config fetch timed out would
/// have the failure mode backwards.
///
/// ## What "required" means here
///
/// `min_version_code` is a Remote Config parameter, type Number, managed from
/// the Firebase console — not shipped in this repo. `0` (its default here,
/// used if the console never sets one) means "no minimum": nothing is ever
/// blocked. Setting it above a build's own `versionCode` is the only thing
/// that turns the block on, and only for installs strictly below it.
abstract final class ForceUpdateService {
  /// Whether the installed build must update before continuing. Watched, not
  /// polled — see the gate in `app.dart`.
  static final ValueNotifier<bool> updateRequired = ValueNotifier<bool>(false);

  static bool _started = false;

  /// Safe to call unconditionally and more than once.
  static Future<void> init() async {
    if (_started || !Platform.isAndroid) return;
    _started = true;

    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Zero in debug builds: while developing, a value changed in the
          // console must show up on the very next launch, not up to 30
          // minutes later because the SDK served a cached fetch. Release
          // builds keep the real interval — nobody needs a fresh check on
          // every cold start, and it is one less network round trip on a
          // panic-button app's launch path.
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(minutes: 30),
        ),
      );
      await remoteConfig.setDefaults(<String, Object>{'min_version_code': 0});
      await remoteConfig.fetchAndActivate();

      final int minVersionCode = remoteConfig.getInt('min_version_code');
      final PackageInfo info = await PackageInfo.fromPlatform();
      final int current = int.tryParse(info.buildNumber) ?? 0;

      if (minVersionCode > 0 && current < minVersionCode) {
        updateRequired.value = true;
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('ForceUpdateService.init failed (ignored): $error\n$stack');
      }
    }
  }

  /// Lets a test stand in for the remote fetch. Mirrors `AdsService.debugSet`.
  @visibleForTesting
  static void debugSet({required bool required}) {
    updateRequired.value = required;
  }
}
