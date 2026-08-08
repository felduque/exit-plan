import 'package:flutter/widgets.dart';

import '../models/call_preset.dart';
import '../screens/incoming_call_screen.dart';
import 'call_scheduler.dart';

/// The single decision every "ring this" gesture goes through: does the call
/// happen here and now, or does it have to survive the app being closed?
///
/// Keeping it in one place means the immediate path stays exactly what it has
/// always been — a route push and an audio player, no alarm, no notification,
/// no permission — and that the scheduled path can never accidentally be taken
/// for a call the user is watching happen.
abstract final class CallDispatcher {
  /// Rings [preset] according to its own schedule.
  ///
  /// Returns null for an immediate call, or how the booking actually landed for
  /// a scheduled one. The caller shows that back to the user: what was asked
  /// for and what the device will actually do are not always the same thing,
  /// and finding out afterwards is the failure this whole feature exists to
  /// avoid.
  static Future<ScheduleOutcome?> dispatch(
    BuildContext context,
    CallPreset preset, {
    CallScheduler? scheduler,
    DateTime? now,
  }) async {
    final DateTime at0 = now ?? DateTime.now();
    final DateTime? at = preset.schedule.resolve(at0);

    if (at == null) {
      // The path the app has always had. Deliberately not routed through the
      // scheduler even with a zero delay: posting a notification for a call the
      // user is looking at would leave a banner behind after they hung up.
      await fireCall(context, preset);
      return null;
    }

    return (scheduler ?? CallScheduler.instance).schedule(preset, at);
  }

  /// Drops a booked call. Safe to call for a preset that was never scheduled.
  ///
  /// Called from every path that makes a template stop existing or stop being
  /// scheduled — deleting it, editing it back to "now" — because an alarm
  /// outliving its template is a call from a contact the user has already
  /// forgotten creating.
  static Future<void> unschedule(
    String presetId, {
    CallScheduler? scheduler,
  }) => (scheduler ?? CallScheduler.instance).cancel(presetId);

  /// Re-books [preset] after an edit: cancels whatever was pending, then
  /// schedules again only if it is still a scheduled call.
  static Future<ScheduleOutcome?> reschedule(
    CallPreset preset, {
    CallScheduler? scheduler,
    DateTime? now,
  }) async {
    final CallScheduler s = scheduler ?? CallScheduler.instance;
    await s.cancel(preset.id);

    final DateTime? at = preset.schedule.resolve(now ?? DateTime.now());
    if (at == null) return null;
    return s.schedule(preset, at);
  }
}
