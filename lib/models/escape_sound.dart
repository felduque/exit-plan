import 'enums.dart';

/// Where the audio bytes live.
sealed class SoundSource {
  const SoundSource();

  Map<String, dynamic> toJson();

  /// Returns null for anything unexpected: a corrupt entry is dropped, never
  /// allowed to throw during boot.
  static SoundSource? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final value = raw['value'];
    if (value is! String || value.isEmpty) return null;
    return switch (raw['kind']) {
      'asset' => BundledSource(value),
      'file' => UserFileSource(value),
      _ => null,
    };
  }
}

/// An audio asset shipped inside the binary. Only system sounds use this.
final class BundledSource extends SoundSource {
  const BundledSource(this.assetPath);

  final String assetPath;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': 'asset',
    'value': assetPath,
  };
}

/// A file the user imported, copied into the app's own storage.
final class UserFileSource extends SoundSource {
  const UserFileSource(this.path);

  final String path;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': 'file',
    'value': path,
  };
}

/// A virtual trim: only this window of the file is played. The file itself is
/// never cut or re-encoded.
class TrimWindow {
  const TrimWindow({required this.startMs, required this.endMs});

  final int startMs;
  final int endMs;

  Duration get start => Duration(milliseconds: startMs);
  Duration get end => Duration(milliseconds: endMs);
  Duration get length => Duration(milliseconds: endMs - startMs);

  bool get isValid => startMs >= 0 && endMs > startMs;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'startMs': startMs,
    'endMs': endMs,
  };

  static TrimWindow? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final start = raw['startMs'];
    final end = raw['endMs'];
    if (start is! int || end is! int) return null;
    final window = TrimWindow(startMs: start, endMs: end);
    return window.isValid ? window : null;
  }
}

/// A playable escape sound plus its metadata.
class EscapeSound {
  const EscapeSound({
    required this.id,
    required this.label,
    required this.categoryId,
    required this.icon,
    required this.source,
    this.excuse,
    this.vibration = const <int>[],
    this.origin = SoundOrigin.system,
    this.trim,
  });

  /// Globally unique. System ids are `category-slug` and are **frozen**: they
  /// are persisted in the user's quick access slots, so renaming one would
  /// silently break a slot.
  final String id;

  final String label;

  /// Optional one-liner. When null the UI shows no excuse line at all — it does
  /// not leave a gap.
  final String? excuse;

  final String categoryId;
  final String icon;
  final SoundSource source;

  /// Android-style pattern in milliseconds: [wait, on, off, on, ...].
  /// Empty means no vibration.
  final List<int> vibration;

  final SoundOrigin origin;
  final TrimWindow? trim;

  bool get isUser => origin == SoundOrigin.user;

  EscapeSound copyWith({
    String? label,
    String? excuse,
    String? categoryId,
    String? icon,
    List<int>? vibration,
    TrimWindow? trim,
  }) {
    return EscapeSound(
      id: id,
      label: label ?? this.label,
      excuse: excuse ?? this.excuse,
      categoryId: categoryId ?? this.categoryId,
      icon: icon ?? this.icon,
      source: source,
      vibration: vibration ?? this.vibration,
      origin: origin,
      trim: trim ?? this.trim,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'excuse': excuse,
    'categoryId': categoryId,
    'icon': icon,
    'source': source.toJson(),
    'vibration': vibration,
    'origin': origin.name,
    'trim': trim?.toJson(),
  };

  /// Tolerant parse: missing optionals fall back to defaults, and anything
  /// structurally broken returns null so the caller can drop the entry.
  static EscapeSound? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final label = raw['label'];
    final categoryId = raw['categoryId'];
    if (id is! String || id.isEmpty) return null;
    if (label is! String || label.isEmpty) return null;
    if (categoryId is! String || categoryId.isEmpty) return null;

    final source = SoundSource.tryFromJson(raw['source']);
    if (source == null) return null;

    final excuseRaw = raw['excuse'];
    final excuse = excuseRaw is String && excuseRaw.trim().isNotEmpty
        ? excuseRaw.trim()
        : null;

    final iconRaw = raw['icon'];
    final icon = iconRaw is String && iconRaw.isNotEmpty ? iconRaw : 'audio';

    final vibrationRaw = raw['vibration'];
    final vibration = <int>[];
    if (vibrationRaw is List) {
      for (final v in vibrationRaw) {
        if (v is int && v >= 0) vibration.add(v);
      }
    }

    return EscapeSound(
      id: id,
      label: label,
      excuse: excuse,
      categoryId: categoryId,
      icon: icon,
      source: source,
      vibration: vibration,
      origin: raw['origin'] == 'system' ? SoundOrigin.system : SoundOrigin.user,
      trim: TrimWindow.tryFromJson(raw['trim']),
    );
  }
}
