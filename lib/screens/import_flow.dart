import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/user_files.dart';
import 'editor_screen.dart';

/// Picks an audio file, copies it somewhere permanent, and opens the editor.
///
/// The copy matters: the path the picker returns usually lives in a cache the OS
/// may purge, so the app keeps its own copy and references only that. If the user
/// backs out of the editor without saving, that copy is deleted again.
Future<void> startImport(
  BuildContext context, {
  String? targetCategoryId,
}) async {
  final FilePickerResult? result = await FilePicker.pickFiles(
    type: FileType.audio,
  );
  if (result == null || result.files.isEmpty) return;

  final PlatformFile picked = result.files.first;
  final String? sourcePath = picked.path;
  if (sourcePath == null) return;

  final String storedPath;
  try {
    storedPath = await UserFiles.importCopy(sourcePath);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file.')),
      );
    }
    return;
  }

  if (!context.mounted) return;

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => EditorScreen(
        filePath: storedPath,
        suggestedLabel: _labelFrom(picked.name),
        targetCategoryId: targetCategoryId,
      ),
    ),
  );
}

/// Sentence case, like every other name in the app: the file name is a
/// suggestion the user is about to edit, not a label the app is asserting.
String _labelFrom(String fileName) {
  final int dot = fileName.lastIndexOf('.');
  final String base = dot > 0 ? fileName.substring(0, dot) : fileName;
  final String cleaned = base.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  if (cleaned.isEmpty) return 'My audio';
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}
