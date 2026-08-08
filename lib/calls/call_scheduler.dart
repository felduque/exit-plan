import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/call_preset.dart';
import '../permissions/call_platform_channel.dart';

/// Everything that has to happen for a fake call to arrive while the app is
/// closed and the phone is locked.
///
/// ## The mechanism, and why there is only one
///
/// ```
/// AlarmManager (exact, allow-while-idle)
///   └→ notification, IMPORTANCE_MAX, category "call", full-screen intent
///        ├─ screen locked or off → Android launches the activity full-screen
///        └─ phone in use          → heads-up banner; tapping it opens the app
/// ```
///
/// There is no other legitimate route. Waking an Activity from a background
/// service is blocked outright from Android 10, and `ConnectionService` — the
/// API that would give the real system call UI — requires declaring the app as
/// a telephony app, which this is not and will not claim to be.
///
/// ## Two things it degrades rather than refuses
///
/// * **No exact-alarm permission** → an inexact alarm. It still arrives; it may
///   be minutes late, batched with whatever else Android was waking for.
/// * **No full-screen-intent permission** (Android 14+, where the system holds
///   it back from non-phone apps) → the notification is posted without one, so
///   it rings and vibrates as a banner instead of taking the screen.
///
/// Both are told to the user *before* they save, not discovered afterwards.
/// Refusing outright would mean withholding a feature the device can mostly
/// perform, and a call that is two minutes late still gets somebody out of a
/// meeting.
class CallScheduler {
  CallScheduler({CallSchedulerBackend? backend})
    : _backend = backend ?? LocalNotificationsBackend();

  static final CallScheduler instance = CallScheduler();

  final CallSchedulerBackend _backend;
  bool _ready = false;

  /// The channel id carries a version because **an Android notification channel
  /// is immutable once created**. Its sound, importance and vibration are
  /// frozen at first use and cannot be edited by the app afterwards — only by
  /// the user, or by shipping a new channel. Changing any of those later means
  /// bumping this to `v2`, not editing the values in place and wondering why
  /// nothing changed on devices that already ran the app.
  static const String channelId = 'exitplan.calls.v1';

  /// Neutral on purpose, exactly like the media channel in `audio_boot.dart`.
  /// This string is visible in Android's own notification settings, where
  /// somebody scrolling past should not learn what this app is for.
  static const String channelName = 'Calls';

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    await _backend.init();
  }

  /// Whether a call scheduled right now would land on time.
  Future<bool> get canBeExact => CallPlatformChannel.canScheduleExactAlarms();

  /// Whether a scheduled call would take the whole screen or arrive as a
  /// banner.
  Future<bool> get canTakeScreen => CallPlatformChannel.canUseFullScreenIntent();

  /// Books [preset] to arrive at [at].
  ///
  /// Returns how it was actually booked, which is not always what was asked
  /// for — the caller shows that back to the user rather than assuming.
  Future<ScheduleOutcome> schedule(CallPreset preset, DateTime at) async {
    await init();

    final bool exact = await canBeExact;
    final bool fullScreen = await canTakeScreen;

    await _backend.schedule(
      id: _idFor(preset.id),
      at: at,
      title: preset.name,
      body: preset.number.isEmpty ? 'Incoming call' : preset.number,
      payload: preset.id,
      exact: exact,
      fullScreen: fullScreen,
    );

    return ScheduleOutcome(at: at, exact: exact, fullScreen: fullScreen);
  }

  Future<void> cancel(String presetId) async {
    await init();
    await _backend.cancel(_idFor(presetId));
  }

  /// Every call currently booked, by preset id.
  Future<Set<String>> pending() async {
    await init();
    return _backend.pendingPayloads();
  }

  /// The preset id a launch came from, or null if the app was opened normally.
  Future<String?> launchPayload() async {
    await init();
    return _backend.launchPayload();
  }

  /// Fires when a notification is tapped or actioned while the app is running.
  Stream<String> get taps => _backend.taps;

  /// A stable 31-bit id derived from the preset's own id.
  ///
  /// Derived rather than stored so that cancelling works from anywhere that
  /// knows the preset — including [AppState.deleteCallPreset], which must not
  /// leave an alarm behind for a template that no longer exists. Masked to 31
  /// bits because Android notification ids are signed 32-bit and a negative one
  /// is silently dropped.
  static int _idFor(String presetId) => presetId.hashCode & 0x7FFFFFFF;
}

/// What a booking actually turned into.
@immutable
class ScheduleOutcome {
  const ScheduleOutcome({
    required this.at,
    required this.exact,
    required this.fullScreen,
  });

  final DateTime at;

  /// False when the alarm was booked inexact, and may run minutes late.
  final bool exact;

  /// False when the call will arrive as a banner rather than taking the screen.
  final bool fullScreen;

  bool get isPerfect => exact && fullScreen;
}

/// The platform work, behind a seam.
///
/// Same door `CallPlayerBackend` and `VibrationBackend` have, and for the same
/// reason: the rules worth testing here — that cancelling a preset cancels its
/// alarm, that a payload survives the round trip, that a missing permission
/// picks the inexact mode — are decisions, and none of them can be observed
/// through a real `AlarmManager` from a test.
abstract interface class CallSchedulerBackend {
  Future<void> init();

  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required bool exact,
    required bool fullScreen,
  });

  Future<void> cancel(int id);

  Future<Set<String>> pendingPayloads();

  Future<String?> launchPayload();

  Stream<String> get taps;
}

/// The real one.
class LocalNotificationsBackend implements CallSchedulerBackend {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final TimezoneInfo zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // A device that will not name its zone still gets calls, just resolved
      // against UTC. Better than no scheduling at all.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              CallScheduler.channelId,
              CallScheduler.channelName,
              importance: Importance.max,
              playSound: false,
              enableVibration: false,
            ),
          );
    }
  }

  void _onResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty && !_taps.isClosed) {
      _taps.add(payload);
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required bool exact,
    required bool fullScreen,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          CallScheduler.channelId,
          CallScheduler.channelName,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: fullScreen,
          // The call screen owns the ringtone and the vibration, because it has
          // to stop them the instant Accept is pressed. A channel that also
          // played a sound would leave a second one running that nothing in the
          // app can reach.
          playSound: false,
          enableVibration: false,
          ongoing: true,
          autoCancel: false,
        ),
      ),
      // allowWhileIdle in both modes: Doze is exactly the state a phone that
      // has been sitting in a pocket for ten minutes is in, which is the
      // situation this feature exists for.
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<Set<String>> pendingPayloads() async {
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    return pending
        .map((PendingNotificationRequest r) => r.payload)
        .whereType<String>()
        .toSet();
  }

  @override
  Future<String?> launchPayload() async {
    final NotificationAppLaunchDetails? details = await _plugin
        .getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }
}
