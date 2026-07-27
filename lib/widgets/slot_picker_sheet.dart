import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/escape_sound.dart';
import '../state/app_state.dart';
import '../state/ui_flags.dart';

/// Asks which of the four slots to overwrite.
///
/// The user picks the slot explicitly. This is not FIFO and not "replace the
/// oldest": silently rewriting a slot the user relies on is worse than one extra
/// tap. The grid mirrors the home screen's 2x2, so the slot being replaced is
/// the one in the same position under the thumb.
Future<void> showSlotPicker(BuildContext context, EscapeSound incoming) async {
  final AppState state = AppScope.read(context);

  final int? slot = await withModal(
    () => showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x9E000000),
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: ExitColors.surf2,
            borderRadius: ExitRadius.sheet,
            border: Border(top: BorderSide(color: ExitColors.line2)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: const BoxDecoration(
                      color: ExitColors.line2,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  Text(
                    'Pin to which slot?',
                    style: sans(17, weight: 600, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      style: ExitText.body,
                      children: <InlineSpan>[
                        const TextSpan(text: 'Pinning '),
                        TextSpan(
                          text: incoming.label,
                          style: sans(11, weight: 500, height: 1.4),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 70,
                    children: <Widget>[
                      for (int i = 0; i < state.quickAccess.length; i++)
                        _SlotCell(
                          index: i,
                          current: state.quickSlotSound(i),
                          onTap: () => Navigator.of(sheetContext).pop(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: ExitRadius.field,
                        border: Border.all(color: ExitColors.line),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: sans(13, weight: 500, color: ExitColors.mid),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  if (slot == null) return;
  await state.assignQuickSlot(slot, incoming.id);
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({
    required this.index,
    required this.current,
    required this.onTap,
  });

  final int index;
  final EscapeSound current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Replace slot 0${index + 1}, ${current.label}',
      child: Panel(
        onTap: onTap,
        radius: ExitRadius.tile,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('SLOT 0${index + 1}', style: ExitText.badge),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    current.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ExitText.row,
                  ),
                ),
                if (current.isUser) ...<Widget>[
                  const SizedBox(width: 6),
                  const UserBadge(fontSize: 6.5),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
