import 'dart:io';
import 'dart:typed_data';

import 'package:exitplan/data/system_catalog.dart';
import 'package:exitplan/models/escape_sound.dart';
import 'package:exitplan/models/exit_category.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps the catalog and the bundled mp3s in sync, and checks each file is
/// actually audio rather than an empty or truncated placeholder.
void main() {
  test('every bundled sound has a real mp3 behind it', () {
    for (final ExitCategory category in kSystemCategories) {
      for (final EscapeSound sound in category.sounds) {
        final BundledSource source = sound.source as BundledSource;
        expect(source.assetPath, endsWith('.mp3'), reason: source.assetPath);

        final File file = File(source.assetPath);
        expect(file.existsSync(), isTrue, reason: source.assetPath);

        final Uint8List bytes = file.readAsBytesSync();
        // Real audio, not a stub: the smallest file in the migrated pack is
        // still tens of kilobytes.
        expect(bytes.length, greaterThan(10 * 1024), reason: source.assetPath);

        // Either an ID3 tag or a bare MPEG frame sync — the two shapes an mp3
        // this pack ships in actually starts with.
        final bool id3 =
            bytes.length >= 3 &&
            bytes[0] == 0x49 &&
            bytes[1] == 0x44 &&
            bytes[2] == 0x33;
        final bool frameSync =
            bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;
        expect(
          id3 || frameSync,
          isTrue,
          reason: '${source.assetPath} does not look like an mp3',
        );
      }
    }
  });

  test('sound ids are unique across the whole catalog', () {
    final Set<String> seen = <String>{};
    for (final ExitCategory category in kSystemCategories) {
      for (final EscapeSound sound in category.sounds) {
        expect(seen.add(sound.id), isTrue, reason: 'duplicate ${sound.id}');
      }
    }
  });
}
