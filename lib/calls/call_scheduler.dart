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
///   └→ notification, IMPORTANCE_MAX, category "call", ringtone, insistent
///        └→ heads-up banner that rings until answered; tapping it opens the
///           call screen, over the keyguard if the phone is locked
/// ```
///
/// There is no other legitimate route. Waking an Activity from a background
/// service is blocked outright from Android 10, and `ConnectionService` — the
/// API that would give the real system call UI — requires declaring the app as
/// a telephony app, which this is not and will not claim to be.
///
/// ## Why the call no longer takes the screen by itself
///
/// It used to: the notification carried a full-screen intent and Android
/// launched the call screen unprompted. Play rejected that in version 11
/// (1.6.0) — `USE_FULL_SCREEN_INTENT` is admitted only from apps whose core
/// purpose is real calls or alarms, and a simulated call does not qualify
/// however identical the result. The permission is gone from the manifest, so
/// the notification is now posted without one on every Android version.
///
/// What survives is most of it. The banner still rings the device's ringtone,
/// still vibrates in the call pattern, and still repeats until it is answered
/// (`FLAG_INSISTENT`), so the phone behaves like a ringing phone. The one lost
/// step is automatic: somebody has to tap the notification. From there the call
/// screen is unchanged, keyguard and all.
///
/// ## What it still degrades rather than refuses
///
/// **No exact-alarm permission** → an inexact alarm. It still arrives; it may
/// be minutes late, batched with whatever else Android was waking for. This is
/// told to the user *before* they save, not discovered afterwards: refusing
/// outright would mean withholding a feature the device can mostly perform, and
/// a call that is two minutes late still gets somebody out of a meeting.
class CallScheduler {
  CallScheduler({CallSchedulerBackend? backend})
    : _backend = backend ?? LocalNotificationsBackend();

  static final CallScheduler instance = CallScheduler();

  final CallSchedulerBackend _backend;
  bool _ready = false;

  /// The channel id carries a version because **an Android notification channel
  /// is immutable once created**. Its sound, importance and vibration are
  /// frozen at first use and cannot be edited by the app afterwards — only by
  /// the user, or by shipping a new channel.
  ///
  /// `v1` was silent, and that was a mistake worth recording. The reasoning was
  /// "the call screen owns the ringtone, so a channel sound would double up" —
  /// true when a full-screen intent fires, and completely wrong when it does
  /// not. On Android 14+, where the system withheld that permission from
  /// non-phone apps, every scheduled call arrived as a mute, undismissable row
  /// in the shade. It read as the call never arriving at all.
  ///
  /// That is now the only path there is, on every version, so this channel's
  /// sound *is* the ring of a scheduled call rather than a backstop for one.
  ///
  /// Bumping the id is the only way to change it: devices that already ran v1
  /// keep its frozen settings for ever otherwise.
  static const String channelId = 'exitplan.calls.v2';

  /// The channel v1 left behind on every device that ran it. Deleted on boot —
  /// an app with a dead "Calls" channel sitting in Android's notification
  /// settings invites the user to configure something that does nothing.
  static const String _retiredChannelId = 'exitplan.calls.v1';

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

  /// Books [preset] to arrive at [at].
  ///
  /// Returns how it was actually booked, which is not always what was asked
  /// for — the caller shows that back to the user rather than assuming.
  Future<ScheduleOutcome> schedule(CallPreset preset, DateTime at) async {
    await init();

    final bool exact = await canBeExact;

    await _backend.schedule(
      id: _idFor(preset.id),
      at: at,
      title: preset.name,
      body: preset.number.isEmpty ? 'Incoming call' : preset.number,
      payload: preset.id,
      exact: exact,
    );

    return ScheduleOutcome(at: at, exact: exact);
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
  const ScheduleOutcome({required this.at, required this.exact});

  final DateTime at;

  /// False when the alarm was booked inexact, and may run minutes late.
  final bool exact;
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
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await android?.deleteNotificationChannel(
        channelId: CallScheduler._retiredChannelId,
      );

      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          CallScheduler.channelId,
          CallScheduler.channelName,
          importance: Importance.max,
          playSound: true,
          // The device's own ringtone rather than a bundled tone. The preset's
          // chosen ringtone belongs to the call *screen*, which can stop it the
          // instant Accept is pressed; this one has to be something Android can
          // start and stop by itself, because it plays in a process that may
          // not be running.
          sound: const UriAndroidNotificationSound(_ringtoneUri),
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
          enableVibration: true,
          vibrationPattern: _ringVibration,
        ),
      );
    }
  }

  /// Android's default ringtone.
  static const String _ringtoneUri = 'content://settings/system/ringtone';

  /// A phone-ring buzz: wait, on, off, on. Mirrors
  /// `CallRingEngine.kRingVibration` so the notification and the call screen
  /// feel like the same event.
  static final Int64List _ringVibration = Int64List.fromList(
    <int>[0, 1000, 1000, 1000],
  );

  /// `Notification.FLAG_INSISTENT`.
  static final Int32List _insistent = Int32List.fromList(<int>[4]);

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
          // No fullScreenIntent, on any Android version. The permission it
          // needs is gone from the manifest — see the class doc — and asking
          // for one without it is a no-op the system logs a warning about.
          // `category: call` still earns the banner the ranking of a call.
          playSound: true,
          sound: const UriAndroidNotificationSound(_ringtoneUri),
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
          enableVibration: true,
          vibrationPattern: _ringVibration,
          // FLAG_INSISTENT: repeat the sound until the notification is
          // cancelled, which is what makes this ring like a call rather than
          // chirp once like a message. Safe only because something always
          // cancels it — `CallBookingCenter.deliver` does, on whichever route
          // the call arrives by. Without that guarantee this would be a phone
          // that never stops ringing.
          additionalFlags: _insistent,
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
