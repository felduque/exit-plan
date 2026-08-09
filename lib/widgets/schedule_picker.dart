import 'package:flutter/material.dart';

import '../calls/call_schedule.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../state/ui_flags.dart';
import 'selectors.dart';

/// When the call arrives. **The only timing control the editor has.**
///
/// It used to be two: a `FUSE` row of seconds and a `SCHEDULE` row of minutes.
/// They asked the same question in two grammars and combined into nonsense —
/// a fuse of 5s with a schedule of 1 minute opened the call a minute later and
/// then sat there for another five seconds before ringing. Nobody chose that;
/// it was just what happened when both controls were on screen.
///
/// So one row of delays, from five seconds to an hour, plus a time of day.
/// (The delay fuse still exists for *sounds* — that path fires from the home
/// screen with no alarm behind it and wants none.)
class SchedulePicker extends StatelessWidget {
  const SchedulePicker({
    super.key,
    required this.schedule,
    required this.premium,
    required this.onChanged,
    required this.onLocked,
  });

  final CallSchedule schedule;

  /// Whether the user may go past [kFreeScheduleMax].
  final bool premium;

  final ValueChanged<CallSchedule> onChanged;

  /// Called instead of [onChanged] when a free user reaches past the ceiling.
  final VoidCallback onLocked;

  int? get _selectedSeconds =>
      schedule is AfterDelaySchedule ? (schedule as AfterDelaySchedule).seconds : null;

  bool _allowed(CallSchedule candidate) => premium || isFreeSchedule(candidate);

  void _pick(CallSchedule candidate) {
    if (!_allowed(candidate)) {
      onLocked();
      return;
    }
    onChanged(candidate);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final CallSchedule current = schedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(loc.scheduleCaption, style: ExitText.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: <Widget>[
            _Chip(
              label: loc.scheduleModeNow,
              selected: current is ImmediateSchedule,
              locked: false,
              onTap: () => _pick(const ImmediateSchedule()),
            ),
            for (final int seconds in kScheduleDelayOptions)
              _Chip(
                label: _delayLabel(seconds),
                selected: _selectedSeconds == seconds,
                locked: !premium &&
                    !isFreeSchedule(AfterDelaySchedule(seconds)),
                onTap: () => _pick(AfterDelaySchedule(seconds)),
              ),
            _Chip(
              label: current is AtTimeSchedule
                  ? _clock(current)
                  : loc.scheduleModeAtTime,
              selected: current is AtTimeSchedule,
              locked: !premium,
              onTap: () => _pickTime(context),
            ),
          ],
        ),
        if (current is! ImmediateSchedule) ...<Widget>[
          const SizedBox(height: 10),
          Text(loc.scheduleArrivesWhenClosed, style: ExitText.bodySmall),
        ],
      ],
    );
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

String _clock(AtTimeSchedule s) =>
    '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';

/// Seconds under a minute, then minutes, then hours — whichever reads shortest.
/// A row of "3600s" is a row nobody scans correctly.
String _delayLabel(int seconds) {
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${seconds ~/ 60}m';
  return '${seconds ~/ 3600}h';
}

/// A [Wrap] of chips rather than a [SegmentedRow]: nine options do not fit in
/// one segmented track on a 360dp phone, and squeezing them would make every
/// cell too small to hit.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? ExitColors.raise : ExitColors.surf,
            borderRadius: ExitRadius.chip,
            border: Border.all(
              color: selected ? ExitColors.line2 : ExitColors.line,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: mono(
                    11,
                    color: selected ? ExitColors.hi : ExitColors.mid,
                    letterSpacing: 0.5,
                  ),
                ),
                // A padlock rather than a hidden or greyed-out chip: the point
                // is that the option exists and costs money, which a disabled
                // control does not say.
                if (locked) ...<Widget>[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.lock_outline,
                    size: 11,
                    color: ExitColors.amber,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
