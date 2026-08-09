import 'dart:async';

import 'package:exitplan/calls/call_dispatcher.dart';
import 'package:exitplan/calls/call_launch.dart';
import 'package:exitplan/calls/call_schedule.dart';
import 'package:exitplan/calls/call_scheduler.dart';
import 'package:exitplan/models/call_preset.dart';
import 'package:exitplan/permissions/call_platform_channel.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:exitplan/themes/call_theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one decision every "ring this" gesture goes through, and what happens
/// when the call finally arrives.
///
/// These two are worth pinning together because the bug they guard against is
/// a pair: an immediate call that quietly starts booking alarms, and an alarm
/// that outlives the template it belongs to.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CallPreset preset({
    String id = 'call-1',
    CallSchedule schedule = const ImmediateSchedule(),
  }) => CallPreset(
    id: id,
    name: 'Mom',
    number: '',
    themeId: kDefaultCallThemeId,
    ringtoneSoundId: 'alarms-clock',
    schedule: schedule,
  );

  late _FakeBackend backend;
  late CallScheduler scheduler;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    backend = _FakeBackend();
    scheduler = CallScheduler(backend: backend);
    CallPlatformChannel.debugAnswers = <String, Object?>{
      'canScheduleExactAlarms': true,
      'canUseFullScreenIntent': true,
    };
  });

  tearDown(() => CallPlatformChannel.debugAnswers = null);

  group('rescheduling', () {
    test('an immediate template books nothing — the path the app has always '
        'had stays a route push, with no alarm and no notification', () async {
      final ScheduleOutcome? outcome = await CallDispatcher.reschedule(
        preset(),
        scheduler: scheduler,
      );
      expect(outcome, isNull);
      expect(backend.scheduled, isEmpty);
    });

    test('a scheduled template books once', () async {
      final ScheduleOutcome? outcome = await CallDispatcher.reschedule(
        preset(schedule: const InMinutesSchedule(5)),
        scheduler: scheduler,
        now: DateTime(2026, 8, 8, 14, 0),
      );
      expect(outcome, isNotNull);
      expect(outcome!.at, DateTime(2026, 8, 8, 14, 5));
      expect(backend.scheduled, hasLength(1));
    });

    test('editing a scheduled call replaces the booking rather than leaving '
        'the old one behind — two alarms for one template means the phone '
        'rings twice', () async {
      final CallPreset first = preset(schedule: const InMinutesSchedule(5));
      await CallDispatcher.reschedule(
        first,
        scheduler: scheduler,
        now: DateTime(2026, 8, 8, 14, 0),
      );

      await CallDispatcher.reschedule(
        first.copyWith(schedule: const InMinutesSchedule(30)),
        scheduler: scheduler,
        now: DateTime(2026, 8, 8, 14, 0),
      );

      expect(backend.scheduled, hasLength(1));
      expect(backend.scheduled.single.at, DateTime(2026, 8, 8, 14, 30));
      expect(await scheduler.pending(), <String>{'call-1'});
    });

    test(
      'editing a scheduled call back to "now" cancels the booking rather '
      'than leaving an alarm for a call that is no longer scheduled',
      () async {
        final CallPreset p = preset(schedule: const InMinutesSchedule(5));
        await CallDispatcher.reschedule(p, scheduler: scheduler);
        expect(backend.scheduled, hasLength(1));

        await CallDispatcher.reschedule(
          p.copyWith(schedule: const ImmediateSchedule()),
          scheduler: scheduler,
        );
        expect(backend.scheduled, isEmpty);
        expect(await scheduler.pending(), isEmpty);
      },
    );

    test('unschedule drops the booking', () async {
      await CallDispatcher.reschedule(
        preset(schedule: const InMinutesSchedule(5)),
        scheduler: scheduler,
      );
      await CallDispatcher.unschedule('call-1', scheduler: scheduler);
      expect(await scheduler.pending(), isEmpty);
    });
  });

  group('arrival', () {
    late AppState state;

    Future<void> pumpHost(WidgetTester tester, GlobalKey<NavigatorState> key) {
      return tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            navigatorKey: key,
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
    }

    setUp(() async {
      state = await AppState.bootstrap();
    });

    testWidgets('an alarm for a template that has since been deleted cancels '
        'itself instead of being ignored — an orphaned alarm survives reboots '
        'and rings for a contact the user no longer has', (
      WidgetTester tester,
    ) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
      await pumpHost(tester, key);

      backend.launch = 'a-template-that-is-gone';
      final CallLaunchRouter router = CallLaunchRouter(
        navigatorKey: key,
        state: state,
        scheduler: scheduler,
      );

      await router.start();
      await tester.pump();

      expect(backend.cancelled, isNotEmpty);
      router.stop();
    });

    testWidgets('the same booking is not rung twice, even though the '
        'cold-start payload is still readable after the stream delivered it', (
      WidgetTester tester,
    ) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
      await pumpHost(tester, key);

      backend.launch = 'gone';
      final CallLaunchRouter router = CallLaunchRouter(
        navigatorKey: key,
        state: state,
        scheduler: scheduler,
      );
      await router.start();
      await tester.pump();

      final int afterFirst = backend.cancelled.length;

      // The stream redelivers what the launch details already carried.
      backend.emitTap('gone');
      await tester.pump();

      expect(backend.cancelled.length, afterFirst);
      router.stop();
    });

    testWidgets('opening the app normally rings nothing', (
      WidgetTester tester,
    ) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
      await pumpHost(tester, key);

      backend.launch = null;
      final CallLaunchRouter router = CallLaunchRouter(
        navigatorKey: key,
        state: state,
        scheduler: scheduler,
      );
      await router.start();
      await tester.pump();

      expect(backend.cancelled, isEmpty);
      router.stop();
    });
  });
}

class _FakeBackend implements CallSchedulerBackend {
  final List<({int id, DateTime at, String payload})> scheduled =
      <({int id, DateTime at, String payload})>[];
  final List<int> cancelled = <int>[];
  final StreamController<String> _taps = StreamController<String>.broadcast();

  String? launch;

  void emitTap(String payload) => _taps.add(payload);

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
    required bool fullScreen,
  }) async {
    scheduled.removeWhere(
      (({int id, DateTime at, String payload}) b) => b.id == id,
    );
    scheduled.add((id: id, at: at, payload: payload));
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.removeWhere(
      (({int id, DateTime at, String payload}) b) => b.id == id,
    );
  }

  @override
  Future<Set<String>> pendingPayloads() async => scheduled
      .map((({int id, DateTime at, String payload}) b) => b.payload)
      .toSet();

  @override
  Future<String?> launchPayload() async => launch;
}
