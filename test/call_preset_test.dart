import 'package:exitplan/models/call_preset.dart';
import 'package:flutter_test/flutter_test.dart';

/// Same tolerant-parse contract every other persisted model in this app
/// follows: a corrupt or missing field must never crash the boot, only drop
/// the entry or fall back to a sane default.
void main() {
  test('round-trips every field through JSON', () {
    const CallPreset preset = CallPreset(
      id: 'call-1',
      name: 'Mom',
      number: '+1 555 0100',
      avatarPath: '/tmp/photo.jpg',
      platform: CallPlatform.whatsapp,
      ringtoneSoundId: 'alarms-clock',
      delaySeconds: 10,
    );

    final CallPreset? parsed = CallPreset.tryFromJson(preset.toJson());

    expect(parsed, isNotNull);
    expect(parsed!.id, preset.id);
    expect(parsed.name, preset.name);
    expect(parsed.number, preset.number);
    expect(parsed.avatarPath, preset.avatarPath);
    expect(parsed.platform, preset.platform);
    expect(parsed.ringtoneSoundId, preset.ringtoneSoundId);
    expect(parsed.delaySeconds, preset.delaySeconds);
  });

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
      CallPreset.tryFromJson(<String, dynamic>{'id': 'call-1', 'name': 'Mom'}),
      isNull,
    );
    expect(CallPreset.tryFromJson('not a map'), isNull);
    expect(CallPreset.tryFromJson(null), isNull);
  });

  test('an unknown platform name falls back to iOS rather than throwing', () {
    final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
      'id': 'call-1',
      'name': 'Mom',
      'ringtoneSoundId': 'alarms-clock',
      'platform': 'palm-pilot',
    });

    expect(parsed, isNotNull);
    expect(parsed!.platform, CallPlatform.ios);
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
    expect(parsed.delaySeconds, 0);
  });

  test('a negative delay is dropped rather than trusted', () {
    final CallPreset? parsed = CallPreset.tryFromJson(<String, dynamic>{
      'id': 'call-1',
      'name': 'Mom',
      'ringtoneSoundId': 'alarms-clock',
      'delaySeconds': -5,
    });

    expect(parsed!.delaySeconds, 0);
  });

  test('copyWith(clearAvatar: true) removes the photo even if a new '
      'avatarPath is not given', () {
    const CallPreset preset = CallPreset(
      id: 'call-1',
      name: 'Mom',
      number: '',
      avatarPath: '/tmp/photo.jpg',
      platform: CallPlatform.ios,
      ringtoneSoundId: 'alarms-clock',
    );

    final CallPreset cleared = preset.copyWith(clearAvatar: true);
    expect(cleared.avatarPath, isNull);
  });

  test('copyWith leaves untouched fields alone', () {
    const CallPreset preset = CallPreset(
      id: 'call-1',
      name: 'Mom',
      number: '555',
      platform: CallPlatform.android,
      ringtoneSoundId: 'alarms-clock',
      delaySeconds: 5,
    );

    final CallPreset next = preset.copyWith(name: 'Dad');
    expect(next.id, 'call-1');
    expect(next.name, 'Dad');
    expect(next.number, '555');
    expect(next.platform, CallPlatform.android);
    expect(next.ringtoneSoundId, 'alarms-clock');
    expect(next.delaySeconds, 5);
  });
}
