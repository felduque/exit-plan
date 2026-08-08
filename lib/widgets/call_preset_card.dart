import 'package:flutter/material.dart';

import '../core/theme.dart';
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
  });

  final CallPreset preset;
  final VoidCallback onCall;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
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
            label: 'Edit ${preset.name}',
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
          Semantics(
            button: true,
            label: 'Ring ${preset.name}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCall,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: ExitColors.greenWash,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  size: 16,
                  color: ExitColors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
