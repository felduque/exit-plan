import 'enums.dart';
import 'escape_sound.dart';

/// A group of escape sounds.
class ExitCategory {
  const ExitCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.sounds = const <EscapeSound>[],
    this.origin = SoundOrigin.system,
  });

  /// Frozen for system categories (`doorbell`, `alarms`, ...): user sounds are
  /// persisted with this id as their destination.
  final String id;

  final String label;
  final String description;
  final String icon;

  /// Assembled at runtime by the merged library. Persisted user categories are
  /// stored empty — their sounds live in the user sound list.
  final List<EscapeSound> sounds;

  final SoundOrigin origin;

  bool get isUser => origin == SoundOrigin.user;

  ExitCategory withSounds(List<EscapeSound> value) => ExitCategory(
    id: id,
    label: label,
    description: description,
    icon: icon,
    sounds: value,
    origin: origin,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'description': description,
    'icon': icon,
    'origin': origin.name,
  };

  static ExitCategory? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final label = raw['label'];
    if (id is! String || id.isEmpty) return null;
    if (label is! String || label.isEmpty) return null;

    final descriptionRaw = raw['description'];
    final iconRaw = raw['icon'];

    return ExitCategory(
      id: id,
      label: label,
      description: descriptionRaw is String ? descriptionRaw : '',
      icon: iconRaw is String && iconRaw.isNotEmpty ? iconRaw : 'audio',
      origin: raw['origin'] == 'system' ? SoundOrigin.system : SoundOrigin.user,
    );
  }
}
