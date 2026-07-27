import 'package:exitplan/data/app_settings.dart';
import 'package:exitplan/data/user_library.dart';
import 'package:exitplan/models/escape_sound.dart';
import 'package:flutter_test/flutter_test.dart';

/// The spec is explicit that a bad byte on disk must never stop the app. These
/// cover the parses that read persisted state.
void main() {
  group('AppSettings.fromJson', () {
    test('falls back to defaults for junk', () {
      expect(AppSettings.fromJson(null).loopSound, isTrue);
      expect(AppSettings.fromJson('not a map').hapticSupport, isTrue);
      expect(AppSettings.fromJson(<String, Object>{}).inAppTips, isTrue);
    });

    test('keeps valid booleans and ignores wrong types', () {
      final AppSettings settings = AppSettings.fromJson(<String, Object>{
        'loopSound': false,
        'hapticSupport': 'yes',
        'darkScreenHints': false,
      });
      expect(settings.loopSound, isFalse);
      expect(settings.hapticSupport, isTrue, reason: 'wrong type -> default');
      expect(settings.darkScreenHints, isFalse);
    });

    test('survives a round trip', () {
      const AppSettings original = AppSettings(
        loopSound: false,
        lockScreenControls: false,
      );
      final AppSettings restored = AppSettings.fromJson(original.toJson());
      expect(restored.loopSound, isFalse);
      expect(restored.lockScreenControls, isFalse);
      expect(restored.maxVolumeOverride, isTrue);
    });
  });

  group('EscapeSound.tryFromJson', () {
    Map<String, dynamic> valid() => <String, dynamic>{
      'id': 'user-1',
      'label': 'MY AUDIO',
      'categoryId': 'doorbell',
      'icon': 'audio',
      'source': <String, dynamic>{'kind': 'file', 'value': '/tmp/a.mp3'},
      'vibration': <int>[0, 200],
      'origin': 'user',
      'trim': <String, dynamic>{'startMs': 0, 'endMs': 30000},
    };

    test('parses a complete entry', () {
      final EscapeSound? sound = EscapeSound.tryFromJson(valid());
      expect(sound, isNotNull);
      expect(sound!.trim!.endMs, 30000);
      expect(sound.isUser, isTrue);
      expect(sound.source, isA<UserFileSource>());
    });

    test('rejects entries missing required fields', () {
      for (final String key in <String>[
        'id',
        'label',
        'categoryId',
        'source',
      ]) {
        final Map<String, dynamic> broken = valid()..remove(key);
        expect(EscapeSound.tryFromJson(broken), isNull, reason: 'missing $key');
      }
      expect(EscapeSound.tryFromJson(<String, dynamic>{}), isNull);
      expect(EscapeSound.tryFromJson('nope'), isNull);
    });

    test('drops an invalid trim instead of failing', () {
      final Map<String, dynamic> raw = valid()
        ..['trim'] = <String, dynamic>{'startMs': 500, 'endMs': 100};
      expect(EscapeSound.tryFromJson(raw)!.trim, isNull);
    });

    test('normalises an empty excuse to null so the UI leaves no gap', () {
      final Map<String, dynamic> raw = valid()..['excuse'] = '   ';
      expect(EscapeSound.tryFromJson(raw)!.excuse, isNull);
    });

    test('discards non-integer vibration values', () {
      final Map<String, dynamic> raw = valid()
        ..['vibration'] = <Object>[0, 'x', 200, -5];
      expect(EscapeSound.tryFromJson(raw)!.vibration, <int>[0, 200]);
    });
  });

  group('UserLibrary.fromJson', () {
    test('keeps the good entries and drops the broken ones', () {
      final UserLibrary library = UserLibrary.fromJson(<String, dynamic>{
        'categories': <Object>[
          <String, dynamic>{'id': 'usercat-1', 'label': 'MINE'},
          <String, dynamic>{'label': 'NO ID'},
          'garbage',
        ],
        'sounds': <Object>[
          <String, dynamic>{
            'id': 'user-1',
            'label': 'ONE',
            'categoryId': 'usercat-1',
            'source': <String, dynamic>{'kind': 'file', 'value': '/a.mp3'},
          },
          <String, dynamic>{'id': 'user-2', 'label': 'BROKEN'},
        ],
      });

      expect(library.categories.length, 1);
      expect(library.sounds.length, 1);
      expect(library.sounds.single.id, 'user-1');
    });

    test('rejects a persisted sound claiming to be a bundled asset', () {
      final UserLibrary library = UserLibrary.fromJson(<String, dynamic>{
        'sounds': <Object>[
          <String, dynamic>{
            'id': 'user-3',
            'label': 'FAKE',
            'categoryId': 'fire',
            'source': <String, dynamic>{'kind': 'asset', 'value': 'a/b.wav'},
          },
        ],
      });
      expect(library.sounds, isEmpty);
    });

    test('empty for junk', () {
      expect(UserLibrary.fromJson(null).isEmpty, isTrue);
      expect(UserLibrary.fromJson(42).isEmpty, isTrue);
    });
  });
}
