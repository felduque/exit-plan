import '../calls/call_schedule.dart';
import '../themes/call_theme_registry.dart';

/// How long the phone rings before the call gives up and is recorded as missed.
///
/// `0` is "never" — it rings until somebody deals with it, which is what every
/// template did before this option existed and therefore what an upgrade has to
/// keep doing unless the user says otherwise.
const List<int> kRingSecondsOptions = <int>[15, 30, 60, 0];

/// How long an answered call runs before it hangs up on its own. `null` is
/// "never" and is the default: an excuse that ends itself is useful, but an
/// excuse that ends itself while you are still using it is worse than one that
/// does not.
const List<int?> kAutoEndOptions = <int?>[null, 30, 60, 120, 300];

/// A saved fake-call template: who is "calling", which theme draws it, which
/// sound rings, and how the call behaves once it starts.
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
    required this.themeId,
    required this.ringtoneSoundId,
    this.avatarPath,
    this.ringSeconds = 30,
    this.autoEndSeconds,
    this.vibrate = true,
    this.schedule = const ImmediateSchedule(),
  });

  final String id;
  final String name;

  /// The line under the name. Most themes render it as a phone number; the
  /// `business` theme renders it as the organisation. Free text either way.
  final String number;

  /// Path to a copy of a picked gallery image, made by [CallAvatarFiles]. Null
  /// shows the theme's own fallback — an initial, a silhouette or a monogram.
  final String? avatarPath;

  /// Which [CallTheme] draws this call. Resolved through `callThemeFor`, which
  /// falls back rather than throwing, so an id from a rolled-back build still
  /// opens.
  final String themeId;

  /// Id resolved through `state.library.resolveOrFallback`, same as every
  /// other sound reference in the app.
  final String ringtoneSoundId;

  /// Seconds of ringing before the call is treated as missed. 0 rings on.
  final int ringSeconds;

  /// Seconds an answered call lasts before hanging up by itself. Null never
  /// hangs up.
  final int? autoEndSeconds;

  /// Whether the phone buzzes along with the ringtone.
  final bool vibrate;

  /// When the call arrives — the only timing axis there is.
  ///
  /// [ImmediateSchedule] rings here and now with the app open, and is the only
  /// one that needs no permission at all. The other two book a real alarm,
  /// which is what makes a call arrive with the phone locked in a pocket.
  ///
  /// This absorbed the old `delaySeconds` fuse; see [CallSchedule] for why
  /// having both was a mistake.
  final CallSchedule schedule;

  CallPreset copyWith({
    String? name,
    String? number,
    String? avatarPath,
    bool clearAvatar = false,
    String? themeId,
    String? ringtoneSoundId,

    int? ringSeconds,
    int? autoEndSeconds,
    bool clearAutoEnd = false,
    bool? vibrate,
    CallSchedule? schedule,
  }) {
    return CallPreset(
      id: id,
      name: name ?? this.name,
      number: number ?? this.number,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      themeId: themeId ?? this.themeId,
      ringtoneSoundId: ringtoneSoundId ?? this.ringtoneSoundId,

      ringSeconds: ringSeconds ?? this.ringSeconds,
      autoEndSeconds: clearAutoEnd
          ? null
          : (autoEndSeconds ?? this.autoEndSeconds),
      vibrate: vibrate ?? this.vibrate,
      schedule: schedule ?? this.schedule,
    );
  }

  /// Writes the current schema **and** the pre-registry `platform` field.
  ///
  /// That extra string is not dead weight. Rollbacks happen when something has
  /// already gone wrong, and a previous build reading a `themeId`-only entry
  /// would fall every template back to the default look. One redundant field
  /// makes going backwards lossless — see [legacyPlatformFor].
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'number': number,
    'avatarPath': avatarPath,
    'themeId': themeId,
    'platform': legacyPlatformFor(themeId),
    'ringtoneSoundId': ringtoneSoundId,
    // The pre-merge fuse field. Same reasoning as `platform` above: a short
    // delay round-trips through a rollback perfectly, and anything longer
    // degrades to ringing at once rather than to a wrong time.
    'delaySeconds': schedule.legacyDelaySeconds,
    'ringSeconds': ringSeconds,
    'autoEndSeconds': autoEndSeconds,
    'vibrate': vibrate,
    'schedule': schedule.toJson(),
  };

  /// Tolerant parse: a structurally broken entry returns null so the caller
  /// can drop it rather than fail the whole list.
  ///
  /// Only `id`, `name` and `ringtoneSoundId` are load-bearing. Everything else
  /// falls back, including a `themeId` that is missing entirely — which is what
  /// every template saved before the theme registry looks like, and is read
  /// from the old `platform` field instead.
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
    final String? avatarPath = avatarRaw is String && avatarRaw.isNotEmpty
        ? avatarRaw
        : null;

    // The pre-merge fuse. Not a field any more — it is folded into the
    // schedule below, which is the single timing axis now.
    final Object? delayRaw = raw['delaySeconds'];
    final int legacyDelay = delayRaw is int && delayRaw >= 0 ? delayRaw : 0;

    final Object? ringRaw = raw['ringSeconds'];
    final int ringSeconds = ringRaw is int && ringRaw >= 0 ? ringRaw : 30;

    final Object? autoEndRaw = raw['autoEndSeconds'];
    final int? autoEndSeconds = autoEndRaw is int && autoEndRaw > 0
        ? autoEndRaw
        : null;

    final Object? vibrateRaw = raw['vibrate'];
    final bool vibrate = vibrateRaw is bool ? vibrateRaw : true;

    return CallPreset(
      id: id,
      name: name,
      number: number,
      avatarPath: avatarPath,
      themeId: _readThemeId(raw),
      ringtoneSoundId: ringtoneSoundId,
      ringSeconds: ringSeconds,
      autoEndSeconds: autoEndSeconds,
      vibrate: vibrate,
      schedule: CallSchedule.fromJson(
        raw['schedule'],
        legacyDelaySeconds: legacyDelay,
      ),
    );
  }

  /// The one piece of migration in this model.
  ///
  /// Reads the current field, then the pre-registry one, then gives up and
  /// returns the default. It deliberately does **not** validate the id against
  /// the registry: an unknown theme is resolved — and defaulted — at render
  /// time by `callThemeFor`, so storing it verbatim means a template saved on a
  /// newer build survives a downgrade-and-upgrade round trip with its theme
  /// intact instead of being flattened on the way through.
  static String _readThemeId(Map<Object?, Object?> raw) {
    final Object? themeId = raw['themeId'];
    if (themeId is String && themeId.isNotEmpty) return themeId;

    final Object? platform = raw['platform'];
    if (platform is String) {
      final String? mapped = kLegacyPlatformThemeIds[platform];
      if (mapped != null) return mapped;
    }
    return kDefaultCallThemeId;
  }
}
