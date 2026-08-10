import 'package:exitplan/calls/call_schedule.dart';
import 'package:exitplan/models/call_preset.dart';
import 'package:exitplan/themes/call_theme_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Same tolerant-parse contract every other persisted model in this app
/// follows: a corrupt or missing field must never crash the boot, only drop
/// the entry or fall back to a sane default.
///
/// The migration group is the load-bearing one. Every template saved before
/// the theme registry stores `platform: ios | android | whatsapp` and no
/// `themeId` at all, and those rows are still on disk on every device that has
/// not yet opened this version.
void main() {
  group('round trip', () {
    test('carries every field through JSON', () {
      const CallPreset preset = CallPreset(
        id: 'call-1',
        name: 'Mom',
        number: '+1 555 0100',
        avatarPath: '/tmp/photo.jpg',
        themeId: 'chat-green',
        ringtoneSoundId: 'alarms-clock',
        schedule: AfterDelaySchedule(600),
        ringSeconds: 60,
        autoEndSeconds: 120,
        vibrate: false,
        retryOnMissed: true,
      );

      final CallPreset? parsed = CallPreset.tryFromJson(preset.toJson());

      expect(parsed, isNotNull);
      expect(parsed!.id, preset.id);
      expect(parsed.name, preset.name);
      expect(parsed.number, preset.number);
      expect(parsed.avatarPath, preset.avatarPath);
      expect(parsed.themeId, preset.themeId);
      expect(parsed.ringtoneSoundId, preset.ringtoneSoundId);
      expect((parsed.schedule as AfterDelaySchedule).seconds, 600);
      expect(parsed.ringSeconds, preset.ringSeconds);
      expect(parsed.autoEndSeconds, preset.autoEndSeconds);
      expect(parsed.vibrate, preset.vibrate);
      expect(parsed.retryOnMissed, preset.retryOnMissed);
    });

    test('a template saved before the retry option existed does not start '
        'ringing twice', () {
      final Map<String, dynamic> saved = const CallPreset(
        id: 'call-1',
        name: 'Mom',
        number: '',
        themeId: 'chat-green',
        ringtoneSoundId: 'alarms-clock',
      ).toJson()..remove('retryOnMissed');

      expect(CallPreset.tryFromJson(saved)!.retryOnMissed, isFalse);
    });

    test('still writes the pre-registry platform field, so rolling back to '
        'the previous version does not reset everyone to the default look', () {
      const CallPreset preset = CallPreset(
        id: 'call-1',
        name: 'Mom',
        number: '',
        themeId: 'chat-green',
        ringtoneSoundId: 'alarms-clock',
      );

      expect(preset.toJson()['platform'], 'whatsapp');
      expect(
        const CallPreset(
          id: 'c',
          name: 'n',
          number: '',
          themeId: 'material',
          ringtoneSoundId: 's',
        ).toJson()['platform'],
        'android',
      );
    });

    test('a theme with no legacy equivalent still writes a usable platform', () {
      for (final String id in <String>['chat-blue', 'minimal-dark', 'business']) {
        final Object? platform = CallPreset(
          id: 'c',
          name: 'n',
          number: '',
          themeId: id,
          ringtoneSoundId: 's',
        ).toJson()['platform'];
        expect(kLegacyPlatformThemeIds.containsKey(platform), isTrue,
            reason: '$id wrote "$platform", which an old build cannot read');
      }
    });
  });

  group('migration from the pre-registry schema', () {
    /// A template exactly as version 1.3.0 wrote it: no themeId, no ring
    /// window, no auto-end, no vibrate flag.
    Map<String, dynamic> legacy(String platform) => <String, dynamic>{
      'id': 'call-1',
      'name': 'Mom',
      'number': '+1 555 0100',
      'avatarPath': null,
      'platform': platform,
      'ringtoneSoundId': 'alarms-clock',
      'delaySeconds': 5,
    };

    test('each old platform lands on the theme that looks the same', () {
      expect(CallPreset.tryFromJson(legacy('ios'))!.themeId, 'classic-light');
      expect(CallPreset.tryFromJson(legacy('android'))!.themeId, 'material');
      expect(CallPreset.tryFromJson(legacy('whatsapp'))!.themeId, 'chat-green');
    });

    test('every legacy value maps onto a theme that actually exists', () {
      for (final String themeId in kLegacyPlatformThemeIds.values) {
        expect(callThemeFor(themeId).id, themeId);
      }
    });

    test('the rest of an old entry survives the migration untouched', () {
      final CallPreset parsed = CallPreset.tryFromJson(legacy('whatsapp'))!;
      expect(parsed.name, 'Mom');
      expect(parsed.number, '+1 555 0100');
    });

    test('the old fuse becomes a schedule of the same length — a template '
        'that used to ring five seconds after firing still does', () {
      final CallPreset parsed = CallPreset.tryFromJson(legacy('ios'))!;
      expect(parsed.schedule, isA<AfterDelaySchedule>());
      expect((parsed.schedule as AfterDelaySchedule).seconds, 5);
    });

    test('a pre-merge minute schedule becomes the same number of seconds', () {
      final CallPreset parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'schedule': <String, dynamic>{'kind': 'in', 'minutes': 5},
      })!;
      expect((parsed.schedule as AfterDelaySchedule).seconds, 300);
    });

    test('a fuse and a schedule together resolve to the schedule — the two '
        'were never meant to combine, and the outer wait is the one the user '
        'was actually looking at', () {
      final CallPreset parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'delaySeconds': 5,
        'schedule': <String, dynamic>{'kind': 'in', 'minutes': 1},
      })!;
      expect((parsed.schedule as AfterDelaySchedule).seconds, 60);
    });

    test('a short delay still round-trips through a rollback, because the '
        'old fuse field keeps being written', () {
      const CallPreset p = CallPreset(
        id: 'call-1',
        name: 'Mom',
        number: '',
        themeId: 'material',
        ringtoneSoundId: 'alarms-clock',
        schedule: AfterDelaySchedule(10),
      );
      expect(p.toJson()['delaySeconds'], 10);
    });

    test('a delay the old fuse could not express writes 0 rather than a wrong '
        'time — ringing at once is a visible surprise, ringing an hour early '
        'is not', () {
      const CallPreset p = CallPreset(
        id: 'call-1',
        name: 'Mom',
        number: '',
        themeId: 'material',
        ringtoneSoundId: 'alarms-clock',
        schedule: AfterDelaySchedule(3600),
      );
      expect(p.toJson()['delaySeconds'], 0);
    });

    test('fields the old schema never had take their defaults, and the '
        'defaults are what the old behaviour was', () {
      final CallPreset parsed = CallPreset.tryFromJson(legacy('ios'))!;
      expect(parsed.ringSeconds, 30);
      // Never hanging up on its own is what every template did before this
      // option existed.
      expect(parsed.autoEndSeconds, isNull);
      expect(parsed.vibrate, isTrue);
    });

    test('themeId wins when both fields are present', () {
      final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'themeId': 'minimal-dark',
        'platform': 'ios',
      });
      expect(parsed!.themeId, 'minimal-dark');
    });

    test('an unknown themeId is stored verbatim rather than flattened, so a '
        'downgrade-and-upgrade round trip keeps the theme', () {
      final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'themeId': 'theme-from-a-future-build',
      });
      expect(parsed!.themeId, 'theme-from-a-future-build');
      // …and rendering it is what falls back, not storing it.
      expect(callThemeFor(parsed.themeId).id, kDefaultCallThemeId);
    });

    test('an unknown platform with no themeId falls back to the default', () {
      final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'platform': 'palm-pilot',
      });
      expect(parsed!.themeId, kDefaultCallThemeId);
    });

    test('neither field at all falls back to the default', () {
      final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
      });
      expect(parsed!.themeId, kDefaultCallThemeId);
    });
  });

  group('tolerant parse', () {
    test('missing id, name or ringtone drops the entry', () {
      expect(
        CallPreset.tryFromJson(<String, dynamic>{
          'name': 'Mom',
          'ringtoneSoundId': 'alarms-clock',
        }),
        isNull,
      );
      expect(
        CallPreset.tryFromJson(<String, dynamic>{
          'id': 'call-1',
          'ringtoneSoundId': 'alarms-clock',
        }),
        isNull,
      );
      expect(
        CallPreset.tryFromJson(<String, dynamic>{
          'id': 'call-1',
          'name': 'Mom',
        }),
        isNull,
      );
      expect(CallPreset.tryFromJson('not a map'), isNull);
      expect(CallPreset.tryFromJson(null), isNull);
    });

    test('missing optionals default to no photo, no delay, empty number', () {
      final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
      });

      expect(parsed, isNotNull);
      expect(parsed!.avatarPath, isNull);
      expect(parsed.number, isEmpty);
      expect(parsed.schedule, isA<ImmediateSchedule>());
    });

    test('a negative delay is dropped rather than trusted', () {
      final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'delaySeconds': -5,
      });

      expect(parsed!.schedule, isA<ImmediateSchedule>());
    });

    test('a negative ring window falls back rather than never ringing', () {
      final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'ringSeconds': -1,
      });
      expect(parsed!.ringSeconds, 30);
    });

    test('ringSeconds of 0 is a real answer — "ring until dealt with" — and '
        'is kept rather than treated as missing', () {
      final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'ringSeconds': 0,
      });
      expect(parsed!.ringSeconds, 0);
    });

    test('a zero or negative auto-end becomes null, not a call that ends '
        'the instant it is answered', () {
      for (final int value in <int>[0, -30]) {
        final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
          'id': 'call-1',
          'name': 'Mom',
          'ringtoneSoundId': 'alarms-clock',
          'autoEndSeconds': value,
        });
        expect(parsed!.autoEndSeconds, isNull);
      }
    });

    test('a non-boolean vibrate falls back to on', () {
      final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'Mom',
        'ringtoneSoundId': 'alarms-clock',
        'vibrate': 'yes please',
      });
      expect(parsed!.vibrate, isTrue);
    });
  });

  group('copyWith', () {
    const CallPreset preset = CallPreset(
      id: 'call-1',
      name: 'Mom',
      number: '555',
      avatarPath: '/tmp/photo.jpg',
      themeId: 'material',
      ringtoneSoundId: 'alarms-clock',
      schedule: AfterDelaySchedule(300),
      autoEndSeconds: 60,
    );

    test('clearAvatar removes the photo even without a new avatarPath', () {
      expect(preset.copyWith(clearAvatar: true).avatarPath, isNull);
    });

    test('clearAutoEnd removes it, which a null argument cannot express', () {
      // `autoEndSeconds: null` is indistinguishable from "not passed", so
      // turning the feature off needs its own flag — the same shape
      // `clearAvatar` already has.
      expect(preset.copyWith(autoEndSeconds: null).autoEndSeconds, 60);
      expect(preset.copyWith(clearAutoEnd: true).autoEndSeconds, isNull);
    });

    test('leaves untouched fields alone', () {
      final CallPreset next = preset.copyWith(name: 'Dad');
      expect(next.id, 'call-1');
      expect(next.name, 'Dad');
      expect(next.number, '555');
      expect(next.themeId, 'material');
      expect(next.ringtoneSoundId, 'alarms-clock');
      expect((next.schedule as AfterDelaySchedule).seconds, 300);
      expect(next.autoEndSeconds, 60);
    });
  });
}
