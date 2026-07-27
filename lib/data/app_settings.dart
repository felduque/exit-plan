/// The six toggles from the settings screen. All default to ON.
class AppSettings {
  const AppSettings({
    this.loopSound = true,
    this.hapticSupport = true,
    this.maxVolumeOverride = true,
    this.darkScreenHints = true,
    this.lockScreenControls = true,
    this.inAppTips = true,
  });

  static const AppSettings defaults = AppSettings();

  /// Default for the loop length selector: ON means repeat until stopped.
  final bool loopSound;

  /// Vibrate along with the sound when firing.
  final bool hapticSupport;

  /// Force the player to full volume when firing.
  final bool maxVolumeOverride;

  /// Show a very faint status line on the black screen.
  final bool darkScreenHints;

  /// Publish media controls. On Android this also keeps the OS from killing
  /// background audio after ~3 minutes, so it is not merely cosmetic.
  final bool lockScreenControls;

  final bool inAppTips;

  double get playbackVolume => maxVolumeOverride ? 1.0 : 0.8;

  AppSettings copyWith({
    bool? loopSound,
    bool? hapticSupport,
    bool? maxVolumeOverride,
    bool? darkScreenHints,
    bool? lockScreenControls,
    bool? inAppTips,
  }) {
    return AppSettings(
      loopSound: loopSound ?? this.loopSound,
      hapticSupport: hapticSupport ?? this.hapticSupport,
      maxVolumeOverride: maxVolumeOverride ?? this.maxVolumeOverride,
      darkScreenHints: darkScreenHints ?? this.darkScreenHints,
      lockScreenControls: lockScreenControls ?? this.lockScreenControls,
      inAppTips: inAppTips ?? this.inAppTips,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'loopSound': loopSound,
    'hapticSupport': hapticSupport,
    'maxVolumeOverride': maxVolumeOverride,
    'darkScreenHints': darkScreenHints,
    'lockScreenControls': lockScreenControls,
    'inAppTips': inAppTips,
  };

  /// Any missing or non-boolean field falls back to its default.
  static AppSettings fromJson(Object? raw) {
    if (raw is! Map) return defaults;
    bool read(String key, bool fallback) {
      final Object? value = raw[key];
      return value is bool ? value : fallback;
    }

    return AppSettings(
      loopSound: read('loopSound', true),
      hapticSupport: read('hapticSupport', true),
      maxVolumeOverride: read('maxVolumeOverride', true),
      darkScreenHints: read('darkScreenHints', true),
      lockScreenControls: read('lockScreenControls', true),
      inAppTips: read('inAppTips', true),
    );
  }
}
