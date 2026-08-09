import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/call_preset.dart';
import '../permissions/call_platform_channel.dart';
import '../screens/incoming_call_screen.dart';
import '../state/app_state.dart';
import 'call_booking_center.dart';
import 'call_scheduler.dart';

/// Wires the booking centre to navigation and to the notification stream.
///
/// The centre decides *that* a call is due; this decides what a due call looks
/// like on screen, and it is the only place that knows a call can arrive from
/// two directions:
///
/// * **Cold start.** The alarm fired while the app was not running. Android
///   launched it, and the payload is waiting in the launch details.
/// * **Already running.** Either the in-process timer came due — the common
///   case when the user is sitting in the app waiting — or the user tapped a
///   notification that arrived while the app was backgrounded.
///
/// Whichever it is, [CallBookingCenter.deliver] guarantees exactly one call
/// screen.
class CallLaunchRouter {
  CallLaunchRouter({
    required this.navigatorKey,
    required this.state,
    required this.bookings,
    CallScheduler? scheduler,
  }) : _scheduler = scheduler ?? CallScheduler.instance;

  final GlobalKey<NavigatorState> navigatorKey;
  final AppState state;
  final CallBookingCenter bookings;
  final CallScheduler _scheduler;

  StreamSubscription<String>? _taps;

  Future<void> start() async {
    await _scheduler.init();

    bookings
      ..resolvePreset = _presetById
      ..onDue = _show;

    await bookings.restore();

    _taps = _scheduler.taps.listen(bookings.deliver);

    final String? launch = await _scheduler.launchPayload();
    if (launch != null) await bookings.deliver(launch);
  }

  void stop() {
    _taps?.cancel();
    _taps = null;
  }

  CallPreset? _presetById(String presetId) => state.callPresets
      .cast<CallPreset?>()
      .firstWhere((CallPreset? p) => p?.id == presetId, orElse: () => null);

  Future<void> _show(CallPreset preset) async {
    // Let the window sit over the keyguard and wake the display. On a cold
    // start MainActivity has already done this natively — Dart runs far too
    // late to matter for that launch — but this is what covers the case where
    // the app was already alive and the in-process timer came due.
    await CallPlatformChannel.setLockScreenMode(enabled: true);

    // Resolved after that await, not before: the navigator is the thing most
    // likely to have gone away across it.
    final NavigatorState? navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      await CallPlatformChannel.setLockScreenMode(enabled: false);
      return;
    }

    try {
      await fireCall(navigator.context, preset);
    } finally {
      await CallPlatformChannel.setLockScreenMode(enabled: false);
    }
  }
}

/// Pending bookings, on disk.
///
/// Its own key rather than a field on the preset: a booking is a transient
/// event and the template outlives it, so storing one inside the other would
/// mean rewriting the whole template list every time a call is scheduled or
/// arrives.
class PrefsBookingStore implements BookingStore {
  const PrefsBookingStore();

  static const String _key = 'exitplan.schedule.pending';

  @override
  Future<Map<String, DateTime>> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return <String, DateTime>{};

      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, DateTime>{};

      final Map<String, DateTime> out = <String, DateTime>{};
      decoded.forEach((Object? id, Object? at) {
        if (id is! String || at is! int) return;
        out[id] = DateTime.fromMillisecondsSinceEpoch(at);
      });
      return out;
    } catch (_) {
      // Same rule as every other read in this app: a bad byte on disk loses a
      // booking, it does not stop the app from starting.
      return <String, DateTime>{};
    }
  }

  @override
  Future<void> save(Map<String, DateTime> bookings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(<String, int>{
          for (final MapEntry<String, DateTime> e in bookings.entries)
            e.key: e.value.millisecondsSinceEpoch,
        }),
      );
    } catch (_) {
      // Losing a write is survivable; crashing on one is not.
    }
  }
}
