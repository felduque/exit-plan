/// Which real call screen a template imitates.
enum CallPlatform {
  ios('iOS'),
  android('Android'),
  whatsapp('WhatsApp');

  const CallPlatform(this.label);

  final String label;

  static CallPlatform fromName(String? name) => CallPlatform.values
      .cast<CallPlatform?>()
      .firstWhere((CallPlatform? p) => p?.name == name, orElse: () => null) ??
      CallPlatform.ios;
}

/// A saved fake-call template: who is "calling", which screen it imitates and
/// which sound rings.
///
/// The ringtone is deliberately just a [ringtoneSoundId] pointing into the same
/// merged sound library every other screen reads from — there is no separate
/// ringtone catalogue, so a tone picked here and a tone picked for a quick exit
/// are the same asset.
class CallPreset {
  const CallPreset({
    required this.id,
    required this.name,
    required this.number,
    required this.platform,
    required this.ringtoneSoundId,
    this.avatarPath,
    this.delaySeconds = 0,
  });

  final String id;
  final String name;
  final String number;

  /// Path to a copy of a picked gallery image, made by [CallAvatarFiles]. Null
  /// shows the initials fallback instead of a photo.
  final String? avatarPath;

  final CallPlatform platform;

  /// Id resolved through `state.library.resolveOrFallback`, same as every
  /// other sound reference in the app.
  final String ringtoneSoundId;

  /// Seconds the call waits, armed, before it starts ringing. Same scale as
  /// [kDelayFuseOptions].
  final int delaySeconds;

  CallPreset copyWith({
    String? name,
    String? number,
    String? avatarPath,
    bool clearAvatar = false,
    CallPlatform? platform,
    String? ringtoneSoundId,
    int? delaySeconds,
  }) {
    return CallPreset(
      id: id,
      name: name ?? this.name,
      number: number ?? this.number,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      platform: platform ?? this.platform,
      ringtoneSoundId: ringtoneSoundId ?? this.ringtoneSoundId,
      delaySeconds: delaySeconds ?? this.delaySeconds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'number': number,
    'avatarPath': avatarPath,
    'platform': platform.name,
    'ringtoneSoundId': ringtoneSoundId,
    'delaySeconds': delaySeconds,
  };

  /// Tolerant parse: a structurally broken entry returns null so the caller
  /// can drop it rather than fail the whole list.
  static CallPreset? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? id = raw['id'];
    final Object? name = raw['name'];
    final Object? ringtoneSoundId = raw['ringtoneSoundId'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    if (ringtoneSoundId is! String || ringtoneSoundId.isEmpty) return null;

    final Object? numberRaw = raw['number'];
    final String number = numberRaw is String ? numberRaw : '';

    final Object? avatarRaw = raw['avatarPath'];
    final String? avatarPath =
        avatarRaw is String && avatarRaw.isNotEmpty ? avatarRaw : null;

    final Object? delayRaw = raw['delaySeconds'];
    final int delaySeconds = delayRaw is int && delayRaw >= 0 ? delayRaw : 0;

    return CallPreset(
      id: id,
      name: name,
      number: number,
      avatarPath: avatarPath,
      platform: CallPlatform.fromName(raw['platform'] as String?),
      ringtoneSoundId: ringtoneSoundId,
      delaySeconds: delaySeconds,
    );
  }
}
