import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// Storage for picked caller photos. Same shape as `UserFiles`: the picker
/// usually hands back a path inside a temporary cache the OS is free to purge,
/// so a picked photo is copied into the app's own support directory and only
/// that copy is ever referenced by a [CallPreset].
abstract final class CallAvatarFiles {
  static final Random _rnd = Random();

  static Future<Directory> directory() async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/call_avatars');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Copies [sourcePath] into persistent storage and returns the new path.
  static Future<String> importCopy(String sourcePath) async {
    final Directory dir = await directory();
    final String extension = _extensionOf(sourcePath);
    final String name =
        'av_${DateTime.now().microsecondsSinceEpoch}_${_rnd.nextInt(0xFFFF)}$extension';
    final String target = '${dir.path}/$name';
    await File(sourcePath).copy(target);
    return target;
  }

  /// Best-effort delete: a missing file is not an error worth surfacing.
  static Future<void> delete(String path) async {
    try {
      final File file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Ignored on purpose.
    }
  }

  static String _extensionOf(String path) {
    final int dot = path.lastIndexOf('.');
    if (dot < 0 || dot < path.length - 6) return '';
    return path.substring(dot).toLowerCase();
  }
}
