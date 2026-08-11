import 'dart:async';

import 'package:exitplan/calls/call_booking_center.dart';
import 'package:exitplan/calls/call_dispatcher.dart';
import 'package:exitplan/calls/call_schedule.dart';
import 'package:exitplan/calls/call_scheduler.dart';
import 'package:exitplan/models/call_preset.dart';
import 'package:exitplan/data/call_presets.dart';
import 'package:exitplan/permissions/call_platform_channel.dart';
import 'package:exitplan/screens/call_preset_editor_screen.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:exitplan/themes/call_theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_localized.dart';

/// The call template editor must save the template without scheduling or firing
/// a call. Scheduling is the list screen's job.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    CallPlatformChannel.debugAnswers = <String, Object?>{
      'canScheduleExactAlarms': true,
      'canUseFullScreenIntent': true,
    };
  });

  tearDown(() => CallPlatformChannel.debugAnswers = null);

  testWidgets('saving a delayed template does not book a call', (
    WidgetTester tester,
  ) async {
    final _FakeBackend backend = _FakeBackend();
    final CallBookingCenter bookings = CallBookingCenter(
      scheduler: CallScheduler(backend: backend),
      store: const NoBookingStore(),
    );
    CallDispatcher.bookings = bookings;
    addTearDown(() => CallDispatcher.bookings = null);

    final AppState state = await AppState.bootstrap();
    // Open the editor with a template that already has a delay configured.
    // Tapping the schedule picker in a widget test is fragile; the bug is about
    // what happens when Save is pressed, not about how the picker is operated.
    final CallPreset draft = CallPreset(
      id: newCallPresetId(),
      name: 'Mom',
      number: '',
      themeId: kDefaultCallThemeId,
      ringtoneSoundId: 'alarms-clock',
      schedule: const AfterDelaySchedule(5),
    );

    await pumpLocalized(
      tester,
      state,
      CallPresetEditorScreen(preset: draft),
    );
    await tester.pumpAndSettle();

    // Save without changing anything.
    await tester.tap(find.text('Save template'));
    await tester.pumpAndSettle();

    // The editor closed and no alarm was booked.
    expect(find.byType(CallPresetEditorScreen), findsNothing);
    expect(backend.scheduled, isEmpty);
    expect(bookings.pending, isEmpty);
  });

  testWidgets('saving cancels any previous booking for the same preset', (
    WidgetTester tester,
  ) async {
    final _FakeBackend backend = _FakeBackend();
    final CallBookingCenter bookings = CallBookingCenter(
      scheduler: CallScheduler(backend: backend),
      store: const NoBookingStore(),
    );
    CallDispatcher.bookings = bookings;
    addTearDown(() => CallDispatcher.bookings = null);

    final AppState state = await AppState.bootstrap();
    const String presetId = 'existing-call';
    final CallPreset existing = CallPreset(
      id: presetId,
      name: 'Dad',
      number: '',
      themeId: kDefaultCallThemeId,
      ringtoneSoundId: 'alarms-clock',
      schedule: const AfterDelaySchedule(60),
    );
    await state.addCallPreset(existing);
    await bookings.book(existing, DateTime.now().add(const Duration(minutes: 1)));
    expect(bookings.isBooked(presetId), isTrue);

    await pumpLocalized(
      tester,
      state,
      CallPresetEditorScreen(preset: existing),
    );
    await tester.pumpAndSettle();

    // Change the name and save.
    await tester.enterText(find.byType(TextField).first, 'Dad (work)');
    await tester.pump();
    await tester.tap(find.text('Save template'));
    await tester.pumpAndSettle();

    expect(bookings.isBooked(presetId), isFalse);
    expect(backend.scheduled, isEmpty);
  });
}

class _FakeBackend implements CallSchedulerBackend {
  final List<_Booking> scheduled = <_Booking>[];
  final List<int> cancelled = <int>[];
  final StreamController<String> _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> init() async {}

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required bool exact,
  }) async {
    scheduled.removeWhere((_Booking b) => b.id == id);
    scheduled.add(
      _Booking(
        id: id,
        at: at,
        title: title,
        body: body,
        payload: payload,
        exact: exact,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.removeWhere((_Booking b) => b.id == id);
  }

  @override
  Future<Set<String>> pendingPayloads() async =>
      scheduled.map((_Booking b) => b.payload).toSet();

  @override
  Future<String?> launchPayload() async => null;
}

class _Booking {
  _Booking({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
    required this.exact,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String payload;
  final bool exact;
}
