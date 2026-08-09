/// When a fake call arrives.
///
/// ## One question, asked once
///
/// This used to be two controls. `FUSE` was a countdown *inside* a call that
/// had already started — the incoming screen was up, armed, waiting — and
/// `SCHEDULE` decided whether that screen appeared at all without the app being
/// open. They read as the same question to anybody who has not seen the code,
/// and they combined into nonsense: a fuse of 5s with a schedule of 1 minute
/// opened the screen a minute later and then made the user wait another five
/// seconds while it sat there not ringing.
///
/// The fuse was also strictly worse at the job it existed for. "Arm it and
/// pocket the phone" only survived as long as the app stayed open, which is
/// exactly what an alarm fixes.
///
/// So there is one axis now: how long from the moment you fire it. The delay
/// fuse still exists for *sounds* (`DelayFuseSelector` on home and the category
/// screens) — that path has no alarm behind it and does not want one.
sealed class CallSchedule {
  const CallSchedule();

  /// Resolves to a wall-clock instant, or null when the call happens straight
  /// away and there is nothing to book.
  DateTime? resolve(DateTime now);

  Map<String, dynamic> toJson();

  /// What an older build should read out of [toJson] for its `delaySeconds`
  /// field.
  ///
  /// The pre-merge schema had a 0/5/10/30s fuse, so a short delay round-trips
  /// through a rollback perfectly and anything longer degrades to ringing at
  /// once. Costs one integer and makes going backwards lossless for the case
  /// that is actually common.
  int get legacyDelaySeconds => 0;

  /// Tolerant parse.
  ///
  /// [legacyDelaySeconds] is the old top-level fuse field, folded in here so a
  /// template saved before the merge keeps its timing. When both are present
  /// the schedule wins: it is the outer, longer wait, and the combination was
  /// never something anybody chose deliberately.
  static CallSchedule fromJson(Object? raw, {int legacyDelaySeconds = 0}) {
    final CallSchedule parsed = _parse(raw);
    if (parsed is! ImmediateSchedule) return parsed;
    if (legacyDelaySeconds > 0) return AfterDelaySchedule(legacyDelaySeconds);
    return const ImmediateSchedule();
  }

  static CallSchedule _parse(Object? raw) {
    if (raw is! Map) return const ImmediateSchedule();
    switch (raw['kind']) {
      case 'after':
        final Object? seconds = raw['seconds'];
        if (seconds is int && seconds > 0) return AfterDelaySchedule(seconds);
        return const ImmediateSchedule();
      // The pre-merge minute-based form. Still on disk for anybody who
      // scheduled a call before this version, so it stays readable for good.
      case 'in':
        final Object? minutes = raw['minutes'];
        if (minutes is int && minutes > 0) {
          return AfterDelaySchedule(minutes * 60);
        }
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

/// Rings the moment the user asks, with the app in front of them.
///
/// The only one that touches no alarm, no notification and no permission: it is
/// a route push and an audio player, exactly as it was before scheduling
/// existed.
final class ImmediateSchedule extends CallSchedule {
  const ImmediateSchedule();

  @override
  DateTime? resolve(DateTime now) => null;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'kind': 'now'};
}

/// Rings after a countdown, whether or not the app is still open.
///
/// Everything above zero books a real alarm, including the five-second case
/// that used to be handled in-process. That is deliberate: the whole complaint
/// this replaced was that closing the app lost the call, and "it works unless
/// you put your phone away" is not a promise worth keeping when the phone going
/// away is the entire use case.
final class AfterDelaySchedule extends CallSchedule {
  const AfterDelaySchedule(this.seconds);

  final int seconds;

  @override
  DateTime? resolve(DateTime now) => now.add(Duration(seconds: seconds));

  /// Only the values the old fuse could express survive a rollback; longer
  /// waits collapse to "immediately" rather than to a wrong time.
  @override
  int get legacyDelaySeconds => seconds <= 30 ? seconds : 0;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': 'after',
    'seconds': seconds,
  };
}

/// Rings at a wall-clock time, today if it is still ahead and tomorrow if not.
///
/// Rolling forward rather than refusing is the only reading that is ever what
/// somebody meant: setting 08:30 at nine in the evening is setting tomorrow
/// morning's call, not making a mistake.
final class AtTimeSchedule extends CallSchedule {
  const AtTimeSchedule({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  DateTime? resolve(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day, hour, minute);
    // A time already gone rolls to tomorrow. Being an hour early is a far worse
    // failure than being a day late.
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': 'at',
    'hour': hour,
    'minute': minute,
  };
}

/// The delays the picker offers, in seconds.
///
/// Spans what used to be two controls: the old fuse's short end, and the old
/// schedule's minutes. One row the user reads left to right.
const List<int> kScheduleDelayOptions = <int>[
  5,
  10,
  30,
  60,
  5 * 60,
  15 * 60,
  30 * 60,
  60 * 60,
];

/// How far ahead a free user may schedule.
///
/// Ten minutes covers the case the app exists for — set it, put the phone away,
/// sit down. A call set for this afternoon is planning rather than escaping,
/// and that is the part Premium sells.
const Duration kFreeScheduleMax = Duration(minutes: 10);

/// Whether [schedule] is inside the free allowance.
///
/// [AtTimeSchedule] is premium outright: it is the planning case by definition,
/// and pinning it to the ten-minute rule would mean the same time of day being
/// allowed or refused depending on when the user happened to open the editor.
bool isFreeSchedule(CallSchedule schedule) => switch (schedule) {
  ImmediateSchedule() => true,
  AfterDelaySchedule(seconds: final int s) => s <= kFreeScheduleMax.inSeconds,
  AtTimeSchedule() => false,
};
