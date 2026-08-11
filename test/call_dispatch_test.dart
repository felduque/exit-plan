import 'dart:async';

import 'package:exitplan/calls/call_booking_center.dart';
import 'package:exitplan/calls/call_dispatcher.dart';
import 'package:exitplan/calls/call_schedule.dart';
import 'package:exitplan/calls/call_scheduler.dart';
import 'package:exitplan/models/call_preset.dart';
import 'package:exitplan/permissions/call_platform_channel.dart';
import 'package:exitplan/themes/call_theme_registry.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Booking, arriving, and the rule that makes two arrival routes safe.
///
/// A booked call can come from an alarm the OS fired or from an in-process
/// timer, and both exist on purpose: the alarm survives the app being closed,
/// the timer is what makes a call due *while you are looking at the app* open
/// the call screen instead of leaving you a notification to tap. The property
/// worth pinning is that both can be armed and still only ever produce one
/// call.
void main() {
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

  /// A centre wired to fakes, recording which presets it opened.
  ({
    CallBookingCenter center,
    _FakeBackend backend,
    List<String> rang,
    List<bool> fromNotificationFlags,
  })
  makeCenter({
    BookingStore? store,
    CallPreset? Function(String)? resolve,
    bool Function()? isInForeground,
  }) {
    final _FakeBackend backend = _FakeBackend();
    final List<String> rang = <String>[];
    final List<bool> fromNotificationFlags = <bool>[];
    final CallBookingCenter center = CallBookingCenter(
      scheduler: CallScheduler(backend: backend),
      store: store,
      isInForeground: isInForeground,
    )
      // Parenthesised: without them the lambda swallows the cascade below,
      // and `onDue` gets set on the CallPreset instead of the centre.
      ..resolvePreset = resolve ?? ((String id) => preset(id: id))
      ..onDue = (CallPreset p, {required bool fromNotification}) {
        rang.add(p.id);
        fromNotificationFlags.add(fromNotification);
      };
    return (
      center: center,
      backend: backend,
      rang: rang,
      fromNotificationFlags: fromNotificationFlags,
    );
  }

  setUp(() {
    CallPlatformChannel.debugAnswers = <String, Object?>{
      'canScheduleExactAlarms': true,
      'canUseFullScreenIntent': true,
    };
  });

  tearDown(() => CallPlatformChannel.debugAnswers = null);

  group('what the dispatcher decides', () {
    test('an immediate template books nothing — the path the app has always '
        'had stays a route push, with no alarm and no notification', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();

      final ScheduleOutcome? outcome = await CallDispatcher.reschedule(
        preset(),
        center: f.center,
      );
      expect(outcome, isNull);
      expect(f.backend.scheduled, isEmpty);
      expect(f.center.pending, isEmpty);
    });

    test('a scheduled template books once', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();

      final ScheduleOutcome? outcome = await CallDispatcher.reschedule(
        preset(schedule: const AfterDelaySchedule(300)),
        center: f.center,
        now: DateTime(2026, 8, 9, 14, 0),
      );
      expect(outcome!.at, DateTime(2026, 8, 9, 14, 5));
      expect(f.backend.scheduled, hasLength(1));
      expect(f.center.isBooked('call-1'), isTrue);
    });

    test('editing a scheduled call replaces the booking rather than leaving '
        'the old one behind — two alarms for one template rings twice',
        () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();
      final CallPreset first = preset(schedule: const AfterDelaySchedule(300));
      final DateTime now = DateTime(2026, 8, 9, 14, 0);

      await CallDispatcher.reschedule(first, center: f.center, now: now);
      await CallDispatcher.reschedule(
        first.copyWith(schedule: const AfterDelaySchedule(1800)),
        center: f.center,
        now: now,
      );

      expect(f.backend.scheduled, hasLength(1));
      expect(f.backend.scheduled.single.at, DateTime(2026, 8, 9, 14, 30));
      expect(f.center.bookedAt('call-1'), DateTime(2026, 8, 9, 14, 30));
    });

    test('editing back to "now" cancels the booking rather than leaving an '
        'alarm for a call that is no longer scheduled', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();
      final CallPreset p = preset(schedule: const AfterDelaySchedule(300));

      await CallDispatcher.reschedule(p, center: f.center);
      expect(f.center.pending, isNotEmpty);

      await CallDispatcher.reschedule(
        p.copyWith(schedule: const ImmediateSchedule()),
        center: f.center,
      );
      expect(f.center.pending, isEmpty);
      expect(f.backend.scheduled, isEmpty);
    });

    test('unschedule drops the booking', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();

      await CallDispatcher.reschedule(
        preset(schedule: const AfterDelaySchedule(300)),
        center: f.center,
      );
      await CallDispatcher.unschedule('call-1', center: f.center);
      expect(f.center.pending, isEmpty);
      expect(f.backend.scheduled, isEmpty);
    });
  });

  group('the in-process timer', () {
    test('a booking that comes due while the app is open opens the call '
        'directly, with no notification to tap', () {
      fakeAsync((FakeAsync async) {
        final ({
          CallBookingCenter center,
          _FakeBackend backend,
          List<String> rang,
          List<bool> fromNotificationFlags,
        })
        f = makeCenter();

        f.center.book(
          preset(),
          DateTime.now().add(const Duration(minutes: 5)),
        );
        async.flushMicrotasks();
        expect(f.rang, isEmpty);

        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(f.rang, <String>['call-1']);
      });
    });

    test('the notification is cleared when the timer wins, so a call already '
        'on screen does not also leave an undismissable row in the shade', () {
      fakeAsync((FakeAsync async) {
        final ({
          CallBookingCenter center,
          _FakeBackend backend,
          List<String> rang,
          List<bool> fromNotificationFlags,
        })
        f = makeCenter();

        f.center.book(
          preset(),
          DateTime.now().add(const Duration(minutes: 1)),
        );
        async.elapse(const Duration(minutes: 1));
        async.flushMicrotasks();

        expect(f.backend.cancelled, isNotEmpty);
      });
    });

    test('the timer marks deliveries as not from a notification', () {
      fakeAsync((FakeAsync async) {
        final ({
          CallBookingCenter center,
          _FakeBackend backend,
          List<String> rang,
          List<bool> fromNotificationFlags,
        })
        f = makeCenter();

        f.center.book(
          preset(),
          DateTime.now().add(const Duration(seconds: 5)),
        );
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(f.rang, <String>['call-1']);
        expect(f.fromNotificationFlags, <bool>[false]);
      });
    });

    test('the timer does not deliver while the app is in the background', () {
      fakeAsync((FakeAsync async) {
        bool inForeground = false;
        final ({
          CallBookingCenter center,
          _FakeBackend backend,
          List<String> rang,
          List<bool> fromNotificationFlags,
        })
        f = makeCenter(isInForeground: () => inForeground);

        f.center.book(
          preset(),
          DateTime.now().add(const Duration(seconds: 5)),
        );
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(f.rang, isEmpty);
        expect(f.backend.cancelled, isEmpty);
      });
    });

    test('cancelling disarms the timer too, not just the alarm', () {
      fakeAsync((FakeAsync async) {
        final ({
          CallBookingCenter center,
          _FakeBackend backend,
          List<String> rang,
          List<bool> fromNotificationFlags,
        })
        f = makeCenter();

        f.center.book(
          preset(),
          DateTime.now().add(const Duration(minutes: 5)),
        );
        async.elapse(const Duration(minutes: 1));
        f.center.cancel('call-1');
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 10));
        expect(f.rang, isEmpty);
      });
    });
  });

  group('exactly one call, whichever route wins', () {
    test('the alarm and the timer cannot both open the same booking', () {
      fakeAsync((FakeAsync async) {
        final ({
          CallBookingCenter center,
          _FakeBackend backend,
          List<String> rang,
          List<bool> fromNotificationFlags,
        })
        f = makeCenter();

        f.center.book(
          preset(),
          DateTime.now().add(const Duration(seconds: 30)),
        );
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();
        expect(f.rang, hasLength(1));

        // The notification lands too — the cold-start payload stays readable
        // after the stream has already delivered it.
        f.center.deliver('call-1');
        async.flushMicrotasks();
        expect(f.rang, hasLength(1));
      });
    });

    test('a second delivery of the same booking is a no-op', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();

      await f.center.book(
        preset(),
        DateTime.now().add(const Duration(hours: 1)),
      );
      await f.center.deliver('call-1');
      await f.center.deliver('call-1');
      expect(f.rang, <String>['call-1']);
    });

    test('a notification delivery reports fromNotification as true', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();

      await f.center.book(
        preset(),
        DateTime.now().add(const Duration(hours: 1)),
      );
      await f.center.deliver('call-1', fromNotification: true);
      expect(f.rang, <String>['call-1']);
      expect(f.fromNotificationFlags, <bool>[true]);
    });

    test('a notification delivery keeps the notification ringing so the device '
        'ringtone lasts until the user answers or declines', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();

      await f.center.book(
        preset(),
        DateTime.now().add(const Duration(hours: 1)),
      );
      await f.center.deliver('call-1', fromNotification: true);
      expect(f.backend.cancelled, isEmpty);
    });

    test('re-booking the same template after it rang arms it again', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();

      await f.center.book(
        preset(),
        DateTime.now().add(const Duration(hours: 1)),
      );
      await f.center.deliver('call-1');
      expect(f.rang, hasLength(1));

      await f.center.book(
        preset(),
        DateTime.now().add(const Duration(hours: 1)),
      );
      await f.center.deliver('call-1');
      expect(f.rang, hasLength(2));
    });
  });

  group('arrival', () {
    test('an alarm for a template that has since been deleted cancels itself '
        'instead of being ignored — an orphan survives reboots and rings for a '
        'contact the user no longer has', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter(resolve: (String _) => null);

      await f.center.book(
        preset(),
        DateTime.now().add(const Duration(hours: 1)),
      );
      f.backend.cancelled.clear();
      await f.center.deliver('call-1');

      expect(f.backend.cancelled, isNotEmpty);
      expect(f.rang, isEmpty);
      expect(f.center.pending, isEmpty);
    });

    test('a delivered booking stops being pending, so the card cannot keep '
        'claiming a call that already rang', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter();

      await f.center.book(
        preset(),
        DateTime.now().add(const Duration(hours: 1)),
      );
      expect(f.center.isBooked('call-1'), isTrue);

      await f.center.deliver('call-1');
      expect(f.center.isBooked('call-1'), isFalse);
    });
  });

  group('surviving a restart', () {
    test('a booking still ahead is restored and re-armed', () {
      fakeAsync((FakeAsync async) {
        final DateTime at = DateTime.now().add(const Duration(minutes: 10));
        final ({
          CallBookingCenter center,
          _FakeBackend backend,
          List<String> rang,
          List<bool> fromNotificationFlags,
        })
        f = makeCenter(store: _MemoryStore(<String, DateTime>{'call-1': at}));

        f.center.restore();
        async.flushMicrotasks();
        expect(f.center.isBooked('call-1'), isTrue);

        async.elapse(const Duration(minutes: 10));
        async.flushMicrotasks();
        expect(f.rang, <String>['call-1']);
      });
    });

    test('a booking whose moment passed while the app was dead is dropped, '
        'not fired — the alarm owned that one, and re-ringing it could mean a '
        'call the user dealt with hours ago', () async {
      final ({
        CallBookingCenter center,
        _FakeBackend backend,
        List<String> rang,
        List<bool> fromNotificationFlags,
      })
      f = makeCenter(
        store: _MemoryStore(<String, DateTime>{
          'call-1': DateTime.now().subtract(const Duration(hours: 2)),
        }),
      );

      await f.center.restore();
      expect(f.center.pending, isEmpty);
      expect(f.rang, isEmpty);
    });
  });
}

class _MemoryStore implements BookingStore {
  _MemoryStore(this._data);

  Map<String, DateTime> _data;

  @override
  Future<Map<String, DateTime>> load() async => Map<String, DateTime>.of(_data);

  @override
  Future<void> save(Map<String, DateTime> bookings) async =>
      _data = Map<String, DateTime>.of(bookings);
}

class _FakeBackend implements CallSchedulerBackend {
  final List<({int id, DateTime at, String payload})> scheduled =
      <({int id, DateTime at, String payload})>[];
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
