import 'package:flutter/material.dart';

import '../calls/call_schedule.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../state/ui_flags.dart';
import 'selectors.dart';

/// When the call arrives: now, after a countdown, or at a wall-clock time.
///
/// Sits *below* the existing FUSE control rather than replacing it, because the
/// two answer different questions and collapsing them would lose one. The fuse
/// is a countdown inside a call that has already started — the incoming screen
/// is up and armed, which is what lets somebody pocket the phone mid-gesture.
/// This decides whether that screen appears at all without the app being open.
class SchedulePicker extends StatelessWidget {
  const SchedulePicker({
    super.key,
    required this.schedule,
    required this.premium,
    required this.onChanged,
    required this.onLocked,
  });

  final CallSchedule schedule;

  /// Whether the user may schedule beyond [kFreeScheduleMaxMinutes].
  final bool premium;

  final ValueChanged<CallSchedule> onChanged;

  /// Called instead of [onChanged] when a free user picks something past the
  /// free ceiling.
  final VoidCallback onLocked;

  _Mode get _mode => switch (schedule) {
    ImmediateSchedule() => _Mode.now,
    InMinutesSchedule() => _Mode.inMinutes,
    AtTimeSchedule() => _Mode.atTime,
  };

  bool _allowed(int minutes) => premium || minutes <= kFreeScheduleMaxMinutes;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedRow<_Mode>(
          caption: loc.scheduleCaption,
          options: _Mode.values,
          selected: _mode,
          labelOf: (_Mode m) => _modeLabel(m, loc),
          onChanged: (_Mode m) => _pickMode(context, m),
        ),
        if (_mode == _Mode.inMinutes) ...<Widget>[
          const SizedBox(height: 14),
          SegmentedRow<int>(
            caption: loc.scheduleInCaption,
            options: kScheduleMinuteOptions,
            selected: schedule is InMinutesSchedule
                ? (schedule as InMinutesSchedule).minutes
                : kScheduleMinuteOptions.first,
            labelOf: _minuteLabel,
            onChanged: (int minutes) {
              if (!_allowed(minutes)) {
                onLocked();
                return;
              }
              onChanged(InMinutesSchedule(minutes));
            },
          ),
        ],
        if (_mode == _Mode.atTime) ...<Widget>[
          const SizedBox(height: 14),
          _TimeField(
            schedule: schedule as AtTimeSchedule,
            onTap: () => _pickTime(context),
          ),
        ],
        if (_mode != _Mode.now) ...<Widget>[
          const SizedBox(height: 8),
          Text(loc.scheduleArrivesWhenClosed, style: ExitText.bodySmall),
        ],
      ],
    );
  }

  void _pickMode(BuildContext context, _Mode mode) {
    switch (mode) {
      case _Mode.now:
        onChanged(const ImmediateSchedule());
      case _Mode.inMinutes:
        // Lands on the shortest option, which is always inside the free tier.
        // Opening onto something the user cannot have would put a paywall in
        // front of a control they were only trying to look at.
        onChanged(InMinutesSchedule(kScheduleMinuteOptions.first));
      case _Mode.atTime:
        if (!premium) {
          onLocked();
          return;
        }
        _pickTime(context);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    if (!premium) {
      onLocked();
      return;
    }
    final CallSchedule current = schedule;
    final TimeOfDay initial = current is AtTimeSchedule
        ? TimeOfDay(hour: current.hour, minute: current.minute)
        : TimeOfDay.now();

    // Wrapped like every other blocking flow, so a tip banner cannot land on
    // the dialog's buttons.
    final TimeOfDay? picked = await withModal(
      () => showTimePicker(context: context, initialTime: initial),
    );
    if (picked == null) return;
    onChanged(AtTimeSchedule(hour: picked.hour, minute: picked.minute));
  }
}

enum _Mode { now, inMinutes, atTime }

String _modeLabel(_Mode mode, AppLocalizations loc) => switch (mode) {
  _Mode.now => loc.scheduleModeNow,
  _Mode.inMinutes => loc.scheduleModeInMinutes,
  _Mode.atTime => loc.scheduleModeAtTime,
};

/// `60` reads as an hour, because a row of minute counts ending in a
/// three-digit number is a row nobody scans correctly.
String _minuteLabel(int minutes) =>
    minutes >= 60 ? '${minutes ~/ 60}h' : '${minutes}m';

class _TimeField extends StatelessWidget {
  const _TimeField({required this.schedule, required this.onTap});

  final AtTimeSchedule schedule;
  final VoidCallback onTap;

  String get _formatted {
    final String h = schedule.hour.toString().padLeft(2, '0');
    final String m = schedule.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      radius: ExitRadius.field,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: <Widget>[
          const Icon(Icons.schedule_rounded, size: 16, color: ExitColors.mid),
          const SizedBox(width: 11),
          Expanded(child: Text(_formatted, style: sans(15, weight: 600))),
          Text(AppLocalizations.of(context).editorChange, style: mono(11)),
        ],
      ),
    );
  }
}
