import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import '../models/escape_sound.dart';

/// One cell of the 2x2 grid on the home screen. Tapping it fires.
///
/// The cell carries the excuse as well as the name, because the excuse is what
/// the user has to say out loud a second later — reading it here is the whole
/// rehearsal they get.
///
/// The category's colour appears as a 2px edge along the top and on the icon,
/// and nowhere else: four filled tiles would look like a game, and this app has
/// to survive being seen over a shoulder.
class QuickSlotButton extends StatelessWidget {
  const QuickSlotButton({
    super.key,
    required this.slot,
    required this.sound,
    required this.onFire,
  });

  final int slot;
  final EscapeSound sound;
  final VoidCallback onFire;

  @override
  Widget build(BuildContext context) {
    final String? excuse = sound.excuse;
    final Color accent = sound.isUser
        ? ExitColors.green
        : accentForCategory(sound.categoryId);

    return Semantics(
      button: true,
      label: 'Fire ${sound.label}',
      child: Panel(
        onTap: onFire,
        radius: ExitRadius.tile,
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
        accentTop: accent,
        // Three blocks spread across the tile: what it is at the top, what it
        // says in the middle, what it does at the bottom. The middle block is
        // the only one that changes height, so the marker stays on the same
        // line across all four tiles.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(iconFor(sound.icon), size: 22, color: accent),
                const Spacer(),
                Text('0${slot + 1}', style: ExitText.badge),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  sound.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ExitText.tile,
                ),
                // No excuse line when there is no excuse: it must not leave a
                // gap where the fire marker should be.
                if (excuse != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    '"$excuse"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ExitText.body,
                  ),
                ],
              ],
            ),
            Text(
              'TAP TO FIRE →',
              style: mono(9, color: accent, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}
