import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/call_preset.dart';
import 'call_scheduler.dart';

/// Every call that is booked but has not happened yet, and the two independent
/// ways it can arrive.
///
/// ## Why two
///
/// The alarm is what survives the app being closed, swiped away or the phone
/// being locked — but with the app *open*, an alarm is a bad experience: it
/// posts a notification and then nothing happens until the user taps it. Being
/// handed a notification for a call you are sitting there waiting for is
/// absurd.
///
/// So every booking arms both:
///
/// ```
/// alarm  ──┐
///          ├─→ whichever lands first opens the call; the other is guarded out
/// timer  ──┘
/// ```
///
/// The timer only exists while the process does, which is exactly the window
/// where it is the better of the two. [_fired] makes double delivery
/// impossible rather than unlikely — the cold-start payload stays readable
/// after the stream has already delivered it, so "it can only happen once" has
/// to be enforced, not assumed.
///
/// ## It is also the source of truth for the UI
///
/// The card needs to say *"scheduled, 15:42"* with a way to cancel, which means
/// somebody has to remember what is pending across a restart. That is this,
/// persisted, rather than a flag on the preset — a booking is a transient event
/// and the template outlives it.
class CallBookingCenter extends ChangeNotifier {
  CallBookingCenter({CallScheduler? scheduler, BookingStore? store})
    : _scheduler = scheduler ?? CallScheduler.instance,
      _store = store ?? const NoBookingStore();

  final CallScheduler _scheduler;
  final BookingStore _store;

  final Map<String, DateTime> _booked = <String, DateTime>{};
  final Map<String, Timer> _timers = <String, Timer>{};

  /// Bookings already delivered in this process, so the alarm and the timer
  /// cannot both open the same call.
  final Set<String> _fired = <String>{};

  /// Called when a booking comes due. Set once, by whatever owns navigation.
  void Function(CallPreset preset)? onDue;

  /// Resolves a preset id against current state. Injected rather than holding
  /// `AppState`, so this stays testable without bootstrapping storage.
  CallPreset? Function(String presetId)? resolvePreset;

  /// Every pending booking, by preset id.
  Map<String, DateTime> get pending => Map<String, DateTime>.unmodifiable(_booked);

  DateTime? bookedAt(String presetId) => _booked[presetId];

  bool isBooked(String presetId) => _booked.containsKey(presetId);

  /// Reloads what was pending before the process restarted, and re-arms the
  /// in-process timers for the ones still ahead.
  ///
  /// Bookings whose moment passed while the app was dead are **dropped, not
  /// fired**. The alarm was the thing responsible for those, and re-firing one
  /// here would ring a call the user may have already dealt with hours ago.
  Future<void> restore() async {
    final Map<String, DateTime> saved = await _store.load();
    final DateTime now = DateTime.now();

    saved.forEach((String id, DateTime at) {
      if (!at.isAfter(now)) return;
      _booked[id] = at;
      _armTimer(id, at);
    });

    if (saved.length != _booked.length) await _persist();
    notifyListeners();
  }

  /// Books [preset] for [at]: an alarm, a timer, and a row in the store.
  Future<ScheduleOutcome> book(CallPreset preset, DateTime at) async {
    final ScheduleOutcome outcome = await _scheduler.schedule(preset, at);

    _fired.remove(preset.id);
    _booked[preset.id] = at;
    _armTimer(preset.id, at);
    await _persist();
    notifyListeners();

    return outcome;
  }

  /// Drops a booking. Safe for a preset that was never booked.
  Future<void> cancel(String presetId) async {
    _timers.remove(presetId)?.cancel();
    final bool had = _booked.remove(presetId) != null;
    _fired.remove(presetId);
    await _scheduler.cancel(presetId);
    if (had) {
      await _persist();
      notifyListeners();
    }
  }

  /// A booking has arrived, from either route.
  ///
  /// Idempotent by [_fired]: the second caller does nothing at all, which is
  /// what stops the notification and the timer both pushing a call screen.
  Future<void> deliver(String presetId) async {
    if (_fired.contains(presetId)) return;
    _fired.add(presetId);

    _timers.remove(presetId)?.cancel();
    _booked.remove(presetId);
    await _persist();

    // Clears the notification whichever way this arrived. It is posted
    // `ongoing`, so nothing else will ever remove it — a call that has already
    // been dealt with must not leave a permanent row in the shade.
    await _scheduler.cancel(presetId);
    notifyListeners();

    final CallPreset? preset = resolvePreset?.call(presetId);
    // The template was deleted between booking and arrival. The alarm is
    // already cancelled above, which is the part that matters: without that it
    // would survive a reboot and ring for a contact that no longer exists.
    if (preset == null) return;

    onDue?.call(preset);
  }

  void _armTimer(String presetId, DateTime at) {
    _timers.remove(presetId)?.cancel();
    final Duration wait = at.difference(DateTime.now());
    if (wait.isNegative) return;
    _timers[presetId] = Timer(wait, () => deliver(presetId));
  }

  Future<void> _persist() => _store.save(_booked);

  @override
  void dispose() {
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}

/// Where pending bookings live between launches.
abstract interface class BookingStore {
  Future<Map<String, DateTime>> load();

  Future<void> save(Map<String, DateTime> bookings);
}

/// For tests and for any caller that does not care about surviving a restart.
class NoBookingStore implements BookingStore {
  const NoBookingStore();

  @override
  Future<Map<String, DateTime>> load() async => <String, DateTime>{};

  @override
  Future<void> save(Map<String, DateTime> bookings) async {}
}
