import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The wide row at the bottom of the home screen that opens the whole library.
///
/// It replaces a grid of category cards: browsing is a second-order action here,
/// so it gets one line and a count rather than a screen's worth of tiles. Counts
/// always come from the merged library, so imported audio is included.
class BrowseRow extends StatelessWidget {
  const BrowseRow({
    super.key,
    required this.categoryCount,
    required this.soundCount,
    required this.onTap,
  });

  final int categoryCount;
  final int soundCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Browse all sounds',
      child: Panel(
        onTap: onTap,
        radius: ExitRadius.tile,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            const Icon(Icons.segment, size: 18, color: ExitColors.mid),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Browse all', style: sans(13, weight: 600)),
                  const SizedBox(height: 3),
                  Text(
                    '$categoryCount CATEGORIES · $soundCount SOUNDS',
                    style: mono(9, letterSpacing: 1),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: ExitColors.dim),
          ],
        ),
      ),
    );
  }
}
