import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// Storage for imported audio.
///
/// The picker usually hands back a path inside a temporary cache that the OS is
/// free to purge, so an imported file is copied into the app's own support
/// directory and only that copy is ever referenced.
abstract final class UserFiles {
  static final Random _rnd = Random();

  static Future<Directory> directory() async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/user_audio');
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
        'ua_${DateTime.now().microsecondsSinceEpoch}_${_rnd.nextInt(0xFFFF)}$extension';
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
