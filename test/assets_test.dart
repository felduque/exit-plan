import 'dart:io';
import 'dart:typed_data';

import 'package:exitplan/data/system_catalog.dart';
import 'package:exitplan/models/escape_sound.dart';
import 'package:exitplan/models/exit_category.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps the catalog and the generated WAVs in sync, and checks each file is
/// actually audio rather than an empty placeholder.
void main() {
  test('every bundled sound has a real WAV behind it', () {
    for (final ExitCategory category in kSystemCategories) {
      for (final EscapeSound sound in category.sounds) {
        final BundledSource source = sound.source as BundledSource;
        final File file = File(source.assetPath);
        expect(file.existsSync(), isTrue, reason: source.assetPath);

        final Uint8List bytes = file.readAsBytesSync();
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');

        // 22.05 kHz, 16-bit mono: at least two seconds of audio.
        expect(
          bytes.length,
          greaterThan(22050 * 2 * 2),
          reason: source.assetPath,
        );

        final ByteData view = ByteData.sublistView(bytes);
        expect(view.getUint16(22, Endian.little), 1, reason: 'mono');
        expect(view.getUint32(24, Endian.little), 22050);
        expect(view.getUint16(34, Endian.little), 16, reason: '16-bit');
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
