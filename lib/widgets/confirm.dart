import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../state/ui_flags.dart';

/// Confirmation for anything that deletes user content and its files.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final bool? answer = await withModal(
    () => showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations loc = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(title, style: sans(16, weight: 600, letterSpacing: -0.3)),
          content: Text(message, style: ExitText.body),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                loc.confirmCancel,
                style: sans(13, weight: 500, color: ExitColors.mid),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                confirmLabel ?? loc.confirmDelete,
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
