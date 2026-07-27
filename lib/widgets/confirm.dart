import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/ui_flags.dart';

/// Confirmation for anything that deletes user content and its files.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final bool? answer = await withModal(
    () => showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title, style: sans(16, weight: 600, letterSpacing: -0.3)),
          content: Text(message, style: ExitText.body),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: sans(13, weight: 500, color: ExitColors.mid),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                confirmLabel,
                style: sans(13, weight: 600, color: ExitColors.red),
              ),
            ),
          ],
        );
      },
    ),
  );
  return answer ?? false;
}
