import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/escape_sound.dart';

/// One sound in a list, with its three actions: fire (the row body), preview,
/// and pin to a quick access slot.
///
/// The row body is the fire target — the two square buttons on the right are the
/// exceptions, and they are the only things on the row that are outlined.
class SoundRow extends StatelessWidget {
  const SoundRow({
    super.key,
    required this.sound,
    required this.pinned,
    required this.previewing,
    required this.onFire,
    required this.onPreview,
    required this.onPin,
    this.onDelete,
  });

  final EscapeSound sound;
  final bool pinned;
  final bool previewing;
  final VoidCallback onFire;
  final VoidCallback onPreview;
  final VoidCallback onPin;

  /// Only user sounds can be deleted, via long press.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final bool user = sound.isUser;
    final Color accent = user
        ? ExitColors.green
        : accentForCategory(sound.categoryId);

    return Panel(
      padding: EdgeInsets.zero,
      borderColor: user ? ExitColors.greenLine : ExitColors.line,
      color: user ? ExitColors.greenWash : ExitColors.surf,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              button: true,
              label: loc.quickSlotFireSemantics(sound.label),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onFire,
                onLongPress: onDelete,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 6, 12),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: ExitColors.raise,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Icon(
                          iconFor(sound.icon),
                          size: 17,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    sound.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: ExitText.row,
                                  ),
                                ),
                                if (user) ...<Widget>[
                                  const SizedBox(width: 7),
                                  const UserBadge(),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            _subtitle(loc),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _Action(
            icon: previewing ? Icons.pause : Icons.play_arrow,
            filled: false,
            color: previewing ? accent : ExitColors.mid,
            borderColor: previewing ? ExitColors.line2 : ExitColors.line,
            iconSize: previewing ? 12 : 13,
            onTap: onPreview,
            tooltip: previewing ? loc.soundRowStopPreview : loc.soundRowPreview,
          ),
          const SizedBox(width: 8),
          _Action(
            icon: pinned ? Icons.star : Icons.star_border,
            // Pinned is the one state on the row that gets a filled well: it is
            // a fact about the home screen, not an action on this one.
            filled: pinned,
            color: pinned ? ExitColors.amber : ExitColors.dim,
            borderColor: pinned ? Colors.transparent : ExitColors.line,
            iconSize: 14,
            onTap: onPin,
            tooltip: loc.soundRowPinToSlot,
          ),
          const SizedBox(width: 13),
        ],
      ),
    );
  }

  /// A user sound has no excuse line, so its trim window takes that slot — and
  /// carries the hint that a long press deletes it, which is otherwise invisible.
  Widget _subtitle(AppLocalizations loc) {
    final String? excuse = sound.excuse;
    if (excuse != null) {
      return Text(
        '"$excuse"',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: ExitText.bodySmall,
      );
    }

    final TrimWindow? trim = sound.trim;
    if (sound.isUser) {
      final String window = trim == null
          ? loc.soundRowFullLength
          : loc.soundRowTrimRange(_clock(trim.startMs), _clock(trim.endMs));
      return Text(
        loc.soundRowHoldToDelete(window),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ExitText.bodySmall.copyWith(color: ExitColors.dim),
      );
    }
    return const SizedBox.shrink();
  }

  static String _clock(int ms) {
    final int seconds = ms ~/ 1000;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.filled,
    required this.color,
    required this.borderColor,
    required this.iconSize,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool filled;
  final Color color;
  final Color borderColor;
  final double iconSize;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // The visible square is 31px but the tap target runs the full row
        // height, so neither button needs to be aimed at.
        child: SizedBox(
          height: 60,
          child: Center(
            child: Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: filled ? ExitColors.raise : null,
                borderRadius: const BorderRadius.all(Radius.circular(9)),
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, size: iconSize, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// The row that imports an audio file straight into the current category.
class AddYourAudioRow extends StatelessWidget {
  const AddYourAudioRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).soundRowAddYourAudio,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CustomPaint(
          painter: const _DashedBorderPainter(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.add, size: 14, color: ExitColors.mid),
                SizedBox(width: 9),
                _AddLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddLabel extends StatelessWidget {
  const _AddLabel();

  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context).soundRowAddYourAudioCaption,
    style: mono(10, letterSpacing: 1),
  );
}

/// Dashed outline for the import row: it reads as a placeholder rather than as
/// one more sound to fire.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = ExitColors.line2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );

    for (final PathMetric metric in path.computeMetrics()) {
      double start = 0;
      while (start < metric.length) {
        final double end = (start + 5).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
