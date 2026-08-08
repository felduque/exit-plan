/// When a fake call should arrive.
///
/// A sealed hierarchy rather than a nullable `DateTime`, because the three
/// cases behave differently enough that collapsing them loses information the
/// UI needs: "now" never touches the alarm manager at all, "in five minutes"
/// has to be resolved against the clock at save time, and "at 14:30" has to
/// know whether that is today or tomorrow.
sealed class CallSchedule {
  const CallSchedule();

  /// Resolves to a wall-clock instant, or null when there is nothing to
  /// schedule because the call happens immediately.
  DateTime? resolve(DateTime now);

  Map<String, dynamic> toJson();

  /// Tolerant parse. Anything unreadable becomes [ImmediateSchedule], which is
  /// the behaviour every template had before scheduling existed and is the only
  /// fallback that cannot surprise somebody: a call that rings when you press
  /// the button.
  static CallSchedule fromJson(Object? raw) {
    if (raw is! Map) return const ImmediateSchedule();
    switch (raw['kind']) {
      case 'in':
        final Object? minutes = raw['minutes'];
        if (minutes is int && minutes > 0) return InMinutesSchedule(minutes);
        return const ImmediateSchedule();
      case 'at':
        final Object? hour = raw['hour'];
        final Object? minute = raw['minute'];
        if (hour is int &&
            minute is int &&
            hour >= 0 &&
            hour < 24 &&
            minute >= 0 &&
            minute < 60) {
          return AtTimeSchedule(hour: hour, minute: minute);
        }
        return const ImmediateSchedule();
      default:
        return const ImmediateSchedule();
    }
  }
}

/// Rings as soon as the user asks, with the app in front of them.
///
/// This is the route the app has always had — a `Navigator.push` and an audio
/// player, no alarm, no notification, no permission. It stays exactly that.
final class ImmediateSchedule extends CallSchedule {
  const ImmediateSchedule();

  @override
  DateTime? resolve(DateTime now) => null;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'kind': 'now'};
}

/// Rings after a countdown, whether or not the app is still open.
final class InMinutesSchedule extends CallSchedule {
  const InMinutesSchedule(this.minutes);

  final int minutes;

  @override
  DateTime? resolve(DateTime now) => now.add(Duration(minutes: minutes));

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': 'in',
    'minutes': minutes,
  };
}

/// Rings at a wall-clock time, today if it is still ahead and tomorrow if it
/// is not.
///
/// Rolling forward rather than refusing is the only reading that is ever what
/// somebody meant: setting 08:30 at nine in the evening is setting tomorrow
/// morning's alarm, not making a mistake.
final class AtTimeSchedule extends CallSchedule {
  const AtTimeSchedule({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  DateTime? resolve(DateTime now) {
    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // A time in the past by less than a minute is almost certainly the user
    // meaning "now-ish" rather than "in 24 hours", but there is no way to be
    // sure, and being an hour early is a far worse failure than being a day
    // late. Roll it forward.
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': 'at',
    'hour': hour,
    'minute': minute,
  };
}

/// The delays offered in the editor.
const List<int> kScheduleMinuteOptions = <int>[1, 5, 15, 30, 60];

/// How far ahead a free user may schedule.
///
/// Ten minutes covers the case the app exists for — set it, put the phone away,
/// sit down — while a call set for this afternoon or tomorrow morning is
/// planning rather than escaping, and that is the part Premium sells.
const int kFreeScheduleMaxMinutes = 10;
