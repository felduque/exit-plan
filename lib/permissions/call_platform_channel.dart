import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The two questions about this device that Dart cannot answer, and the
/// actions that have to happen on a real Activity.
///
/// Thin on purpose: everything here is one platform call and a default. The
/// defaults all mean **"assume it works"**, which is the right way round —
/// `permission_handler` cannot see `SCHEDULE_EXACT_ALARM` at all, and a process
/// with no channel (every widget test, and the desktop builds) should render
/// the app as it looks when nothing is wrong rather than as a wall of warnings.
///
/// Mirrors the seam `NotificationPermission` and `AdsService` already have, for
/// the same reason: the interesting states are the ones the developer's own
/// phone is not in.
abstract final class CallPlatformChannel {
  static const MethodChannel _channel = MethodChannel('exitplan/calls');

  /// Overrides every answer below. Set only by tests.
  @visibleForTesting
  static Map<String, Object?>? debugAnswers;

  static Future<T> _ask<T>(String method, T fallback) async {
    final Map<String, Object?>? stub = debugAnswers;
    if (stub != null) return (stub[method] as T?) ?? fallback;
    try {
      return await _channel.invokeMethod<T>(method) ?? fallback;
    } catch (_) {
      // No channel, or a platform that does not implement it.
      return fallback;
    }
  }

  static Future<void> _tell(String method, [Object? argument]) async {
    if (debugAnswers != null) return;
    try {
      await _channel.invokeMethod<void>(method, argument);
    } catch (_) {
      // Opening a settings page is best-effort by nature — see the Kotlin side.
    }
  }

  /// True below Android 12, where exact alarms need no permission.
  static Future<bool> canScheduleExactAlarms() =>
      _ask<bool>('canScheduleExactAlarms', true);

  static Future<bool> isIgnoringBatteryOptimizations() =>
      _ask<bool>('isIgnoringBatteryOptimizations', true);

  static Future<void> openExactAlarmSettings() =>
      _tell('openExactAlarmSettings');

  static Future<void> openBatterySettings() => _tell('openBatterySettings');

  /// Lets the activity appear over the lock screen and wake the display.
  ///
  /// Must be turned off again when the call screen goes away — see the Kotlin
  /// side for why leaving it on is wrong.
  static Future<void> setLockScreenMode({required bool enabled}) =>
      _tell('setLockScreenMode', enabled);
}
