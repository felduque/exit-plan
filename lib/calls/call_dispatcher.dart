import 'package:flutter/widgets.dart';

import '../models/call_preset.dart';
import '../screens/incoming_call_screen.dart';
import 'call_booking_center.dart';
import 'call_scheduler.dart';

/// The single decision every "ring this" gesture goes through: does the call
/// happen here and now, or does it have to survive the app being closed?
///
/// Keeping it in one place means the immediate path stays exactly what it has
/// always been — a route push and an audio player, no alarm, no notification,
/// no permission — and that a scheduled call can never accidentally be routed
/// through it and lost the moment the user locks the phone.
abstract final class CallDispatcher {
  /// Set once at boot, by whatever owns the booking centre.
  static CallBookingCenter? bookings;

  static CallBookingCenter get _center =>
      bookings ??= CallBookingCenter();

  /// Rings [preset] according to its own schedule.
  ///
  /// Returns null for an immediate call, or how the booking actually landed for
  /// a scheduled one. **The caller must show that back to the user.** What was
  /// asked for and what the device will actually do are not always the same
  /// thing, and a booking that reports nothing is indistinguishable from a
  /// button that did not work — which is exactly how this felt before.
  static Future<ScheduleOutcome?> dispatch(
    BuildContext context,
    CallPreset preset, {
    CallBookingCenter? center,
    DateTime? now,
  }) async {
    final DateTime? at = preset.schedule.resolve(now ?? DateTime.now());

    if (at == null) {
      // Deliberately not routed through the scheduler even for a zero delay:
      // posting a notification for a call the user is looking at would leave a
      // row in the shade after they had already hung up.
      await fireCall(context, preset);
      return null;
    }

    return (center ?? _center).book(preset, at);
  }

  /// Rings [preset] immediately, whatever its schedule says.
  ///
  /// The one path that ignores the template's timing, for the case where
  /// somebody needs the excuse *now* and has no interest in what they
  /// configured last week.
  static Future<void> ringNow(BuildContext context, CallPreset preset) =>
      fireCall(context, preset);

  /// Drops a booked call. Safe for a preset that was never booked.
  static Future<void> unschedule(
    String presetId, {
    CallBookingCenter? center,
  }) => (center ?? _center).cancel(presetId);

  /// Re-books [preset] after an edit: cancels whatever was pending, then books
  /// again only if it is still a scheduled call.
  ///
  /// Editing a template back to "now" therefore cancels its alarm rather than
  /// leaving one behind for a call that is no longer scheduled.
  static Future<ScheduleOutcome?> reschedule(
    CallPreset preset, {
    CallBookingCenter? center,
    DateTime? now,
  }) async {
    final CallBookingCenter c = center ?? _center;
    await c.cancel(preset.id);

    final DateTime? at = preset.schedule.resolve(now ?? DateTime.now());
    if (at == null) return null;
    return c.book(preset, at);
  }
}
