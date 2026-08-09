import 'dart:async';

import 'package:exitplan/calls/call_schedule.dart';
import 'package:exitplan/calls/call_scheduler.dart';
import 'package:exitplan/models/call_preset.dart';
import 'package:exitplan/permissions/call_platform_channel.dart';
import 'package:exitplan/themes/call_theme_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Booking, cancelling, and the two ways a booking quietly becomes something
/// less than what was asked for.
///
/// None of this is observable through a real AlarmManager from a test, and all
/// of it is a decision rather than a platform detail — which is exactly what
/// the [CallSchedulerBackend] seam is for.
void main() {
  CallPreset preset({
    String id = 'call-1',
    String name = 'Mom',
    String number = '+1 555 0100',
    CallSchedule schedule = const ImmediateSchedule(),
  }) => CallPreset(
    id: id,
    name: name,
    number: number,
    themeId: kDefaultCallThemeId,
    ringtoneSoundId: 'alarms-clock',
    schedule: schedule,
  );

  late _FakeBackend backend;
  late CallScheduler scheduler;

  setUp(() {
    backend = _FakeBackend();
    scheduler = CallScheduler(backend: backend);
    CallPlatformChannel.debugAnswers = <String, Object?>{
      'canScheduleExactAlarms': true,
      'canUseFullScreenIntent': true,
    };
  });

  tearDown(() => CallPlatformChannel.debugAnswers = null);

  group('resolving a schedule', () {
    final DateTime now = DateTime(2026, 8, 8, 14, 0);

    test('immediate resolves to nothing to schedule', () {
      expect(const ImmediateSchedule().resolve(now), isNull);
    });

    test('in-minutes counts forward from now', () {
      expect(
        const InMinutesSchedule(15).resolve(now),
        DateTime(2026, 8, 8, 14, 15),
      );
    });

    test('a time still ahead today lands today', () {
      expect(
        const AtTimeSchedule(hour: 16, minute: 30).resolve(now),
        DateTime(2026, 8, 8, 16, 30),
      );
    });

    test('a time already past rolls to tomorrow rather than firing at once — '
        'setting 08:30 in the evening means tomorrow morning', () {
      expect(
        const AtTimeSchedule(hour: 8, minute: 30).resolve(now),
        DateTime(2026, 8, 9, 8, 30),
      );
    });

    test('the current minute exactly counts as past, so it rolls forward '
        'rather than resolving to an instant already gone', () {
      expect(
        const AtTimeSchedule(hour: 14, minute: 0).resolve(now),
        DateTime(2026, 8, 9, 14, 0),
      );
    });
  });

  group('schedule serialisation', () {
    test('each kind round-trips', () {
      final List<CallSchedule> all = <CallSchedule>[
        const ImmediateSchedule(),
        const InMinutesSchedule(15),
        const AtTimeSchedule(hour: 7, minute: 5),
      ];
      for (final CallSchedule s in all) {
        final CallSchedule back = CallSchedule.fromJson(s.toJson());
        expect(back.runtimeType, s.runtimeType);
        expect(back.toJson(), s.toJson());
      }
    });

    test('anything unreadable falls back to immediate — the behaviour every '
        'template had before scheduling existed, and the only fallback that '
        'cannot surprise anyone', () {
      final List<Object?> junk = <Object?>[
        null,
        'not a map',
        <String, dynamic>{},
        <String, dynamic>{'kind': 'someday'},
        <String, dynamic>{'kind': 'in', 'minutes': -5},
        <String, dynamic>{'kind': 'in'},
        <String, dynamic>{'kind': 'at', 'hour': 25, 'minute': 0},
        <String, dynamic>{'kind': 'at', 'hour': 4, 'minute': 61},
        <String, dynamic>{'kind': 'at', 'hour': 'noon', 'minute': 0},
      ];
      for (final Object? raw in junk) {
        expect(CallSchedule.fromJson(raw), isA<ImmediateSchedule>());
      }
    });

    test('a preset carries its schedule through JSON', () {
      final CallPreset p = preset(
        schedule: const AtTimeSchedule(hour: 9, minute: 45),
      );
      final CallPreset back = CallPreset.tryFromJson(p.toJson())!;
      expect(back.schedule, isA<AtTimeSchedule>());
      expect((back.schedule as AtTimeSchedule).hour, 9);
      expect((back.schedule as AtTimeSchedule).minute, 45);
    });

    test('a template saved before scheduling existed reads as immediate', () {
      final CallPreset? back = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'platform': 'ios',
      });
      expect(back!.schedule, isA<ImmediateSchedule>());
    });
  });

  group('booking', () {
    test('carries the preset id as the payload, which is what routes the call '
        'back to the right template when it arrives', () async {
      final DateTime at = DateTime(2026, 8, 8, 15, 0);
      await scheduler.schedule(preset(), at);

      expect(backend.scheduled, hasLength(1));
      expect(backend.scheduled.single.payload, 'call-1');
      expect(backend.scheduled.single.at, at);
    });

    test('books exact and full-screen when both are permitted', () async {
      final ScheduleOutcome outcome = await scheduler.schedule(
        preset(),
        DateTime(2026, 8, 8, 15, 0),
      );
      expect(outcome.exact, isTrue);
      expect(outcome.fullScreen, isTrue);
      expect(outcome.isPerfect, isTrue);
      expect(backend.scheduled.single.exact, isTrue);
      expect(backend.scheduled.single.fullScreen, isTrue);
    });

    test('falls back to an inexact alarm rather than refusing when the exact '
        'permission is missing, and reports that it did', () async {
      CallPlatformChannel.debugAnswers = <String, Object?>{
        'canScheduleExactAlarms': false,
        'canUseFullScreenIntent': true,
      };

      final ScheduleOutcome outcome = await scheduler.schedule(
        preset(),
        DateTime(2026, 8, 8, 15, 0),
      );
      expect(outcome.exact, isFalse);
      expect(outcome.isPerfect, isFalse);
      // Still booked. Late is not the same as absent.
      expect(backend.scheduled.single.exact, isFalse);
      expect(backend.scheduled, hasLength(1));
    });

    test('drops the full-screen intent rather than refusing when Android 14 '
        'withheld it, and reports that it did', () async {
      CallPlatformChannel.debugAnswers = <String, Object?>{
        'canScheduleExactAlarms': true,
        'canUseFullScreenIntent': false,
      };

      final ScheduleOutcome outcome = await scheduler.schedule(
        preset(),
        DateTime(2026, 8, 8, 15, 0),
      );
      expect(outcome.fullScreen, isFalse);
      expect(backend.scheduled.single.fullScreen, isFalse);
      expect(backend.scheduled, hasLength(1));
    });

    test('the notification says the caller name, which is what a banner has '
        'to show for the excuse to work', () async {
      await scheduler.schedule(
        preset(name: 'Priya', number: '+34 600 000'),
        DateTime(2026, 8, 8, 15, 0),
      );
      expect(backend.scheduled.single.title, 'Priya');
      expect(backend.scheduled.single.body, '+34 600 000');
    });

    test('a template with no number still gets a body', () async {
      await scheduler.schedule(preset(number: ''), DateTime(2026, 8, 8, 15, 0));
      expect(backend.scheduled.single.body, isNotEmpty);
    });
  });

  group('cancelling', () {
    test('cancels the id derived from the preset, so a delete can reach an '
        'alarm it never stored a handle for', () async {
      await scheduler.schedule(preset(), DateTime(2026, 8, 8, 15, 0));
      final int booked = backend.scheduled.single.id;

      await scheduler.cancel('call-1');
      expect(backend.cancelled, contains(booked));
    });

    test('the derived id is stable and non-negative — Android silently drops a '
        'negative notification id', () async {
      for (final String id in <String>[
        'call-1',
        'call-1754600000000000',
        'a',
        'ünïcodé-preset',
      ]) {
        await scheduler.schedule(preset(id: id), DateTime(2026, 8, 8, 15, 0));
        final int booked = backend.scheduled.last.id;
        expect(booked, greaterThanOrEqualTo(0));

        await scheduler.cancel(id);
        expect(backend.cancelled.last, booked);
      }
    });

    test('cancelling something never booked is harmless', () async {
      await scheduler.cancel('never-existed');
      expect(backend.cancelled, hasLength(1));
    });

    test('pending reports the presets that are actually booked', () async {
      await scheduler.schedule(preset(id: 'a'), DateTime(2026, 8, 8, 15, 0));
      await scheduler.schedule(preset(id: 'b'), DateTime(2026, 8, 8, 16, 0));
      expect(await scheduler.pending(), <String>{'a', 'b'});
    });
  });

  group('the free ceiling', () {
    test('the shortest offered delay is inside it, so opening the control '
        'never lands a free user on a paywall', () {
      expect(
        kScheduleMinuteOptions.first,
        lessThanOrEqualTo(kFreeScheduleMaxMinutes),
      );
    });

    test('there is something beyond it to sell', () {
      expect(
        kScheduleMinuteOptions.any((int m) => m > kFreeScheduleMaxMinutes),
        isTrue,
      );
    });
  });
}

/// Records bookings instead of talking to AlarmManager.
class _FakeBackend implements CallSchedulerBackend {
  final List<_Booking> scheduled = <_Booking>[];
  final List<int> cancelled = <int>[];
  final StreamController<String> _taps = StreamController<String>.broadcast();

  String? launch;

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
    // Mirrors the real plugin: booking the same id twice replaces it.
    scheduled.removeWhere((_Booking b) => b.id == id);
    scheduled.add(
      _Booking(
        id: id,
        at: at,
        title: title,
        body: body,
        payload: payload,
        exact: exact,
        fullScreen: fullScreen,
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
  Future<String?> launchPayload() async => launch;
}

class _Booking {
  _Booking({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
    required this.exact,
    required this.fullScreen,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String payload;
  final bool exact;
  final bool fullScreen;
}
