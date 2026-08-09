import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/call_preset.dart';
import '../themes/call_theme_registry.dart';
import '../themes/call_visuals.dart';

/// One saved template on `CallsScreen`: photo, name, number, the OS it
/// imitates, and the two things you can do with it — ring it, or edit it.
class CallPresetCard extends StatelessWidget {
  const CallPresetCard({
    super.key,
    required this.preset,
    required this.onCall,
    required this.onEdit,
    this.bookedAt,
    this.onCancelBooking,
  }) : assert(
         bookedAt == null || onCancelBooking != null,
         'A booked call must be cancellable.',
       );

  final CallPreset preset;
  final VoidCallback onCall;
  final VoidCallback onEdit;

  /// When this template's call is booked for, or null when nothing is pending.
  final DateTime? bookedAt;

  /// Drops the booking. Required whenever [bookedAt] is set — a scheduled call
  /// the user cannot call off is a worse feature than no scheduling at all.
  final VoidCallback? onCancelBooking;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Panel(
      radius: ExitRadius.tile,
      onTap: onCall,
      onLongPress: onEdit,
      child: Row(
        children: <Widget>[
          CallAvatar(
            avatarPath: preset.avatarPath,
            name: preset.name,
            diameter: 46,
            tint: ExitColors.raise,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  preset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ExitText.tile,
                ),
                const SizedBox(height: 3),
                // A booked call replaces the usual subtitle rather than
                // sitting beside it. It is the only thing about this template
                // that is *happening* rather than merely configured, and it is
                // the answer to "did my tap do anything" — which, without it,
                // nothing on this screen gave.
                if (bookedAt != null)
                  _BookedLine(at: bookedAt!, loc: loc)
                else
                  Row(
                    children: <Widget>[
                      if (preset.number.isNotEmpty)
                        Flexible(
                          child: Text(
                            preset.number,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ExitText.bodySmall,
                          ),
                        ),
                      if (preset.number.isNotEmpty) const SizedBox(width: 8),
                      TagChip(callThemeFor(preset.themeId).name),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: loc.callPresetCardEdit(preset.name),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: ExitColors.dim,
                ),
              ),
            ),
          ),
          // While a call is booked the same circle cancels it. One control that
          // reflects the template's actual state, rather than a call button
          // that silently re-books what is already pending.
          Semantics(
            button: true,
            label: bookedAt == null
                ? loc.callPresetCardRing(preset.name)
                : loc.callPresetCardCancel(preset.name),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: bookedAt == null ? onCall : onCancelBooking,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bookedAt == null
                      ? ExitColors.greenWash
                      : ExitColors.amber.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  bookedAt == null ? Icons.call_rounded : Icons.close_rounded,
                  size: 16,
                  color: bookedAt == null
                      ? ExitColors.green
                      : ExitColors.amber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The line a booked template shows in place of its number and theme.
class _BookedLine extends StatelessWidget {
  const _BookedLine({required this.at, required this.loc});

  final DateTime at;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final String when =
        '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';

    return Row(
      children: <Widget>[
        const PulseDot(color: ExitColors.amber),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            loc.callPresetCardScheduledFor(when),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: mono(9, color: ExitColors.amber, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}
