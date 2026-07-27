import '../models/enums.dart';
import '../models/escape_sound.dart';
import '../models/exit_category.dart';

/// Everything the user imported. Categories are stored without their sounds:
/// all user sounds live in one flat list keyed by `categoryId`, so a user sound
/// can sit inside a *system* category without duplicating anything.
class UserLibrary {
  const UserLibrary({
    this.categories = const <ExitCategory>[],
    this.sounds = const <EscapeSound>[],
  });

  static const UserLibrary empty = UserLibrary();

  final List<ExitCategory> categories;
  final List<EscapeSound> sounds;

  bool get isEmpty => categories.isEmpty && sounds.isEmpty;

  UserLibrary copyWith({
    List<ExitCategory>? categories,
    List<EscapeSound>? sounds,
  }) {
    return UserLibrary(
      categories: categories ?? this.categories,
      sounds: sounds ?? this.sounds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'categories': categories.map((ExitCategory c) => c.toJson()).toList(),
    'sounds': sounds.map((EscapeSound s) => s.toJson()).toList(),
  };

  /// Drops any entry that does not parse. A single corrupt sound must not cost
  /// the user their whole library, and must never fail the boot.
  static UserLibrary fromJson(Object? raw) {
    if (raw is! Map) return empty;

    final List<ExitCategory> categories = <ExitCategory>[];
    final Object? rawCategories = raw['categories'];
    if (rawCategories is List) {
      for (final Object? entry in rawCategories) {
        final ExitCategory? parsed = ExitCategory.tryFromJson(entry);
        if (parsed == null) continue;
        if (parsed.origin != SoundOrigin.user) continue;
        if (categories.any((ExitCategory c) => c.id == parsed.id)) continue;
        categories.add(parsed);
      }
    }

    final List<EscapeSound> sounds = <EscapeSound>[];
    final Object? rawSounds = raw['sounds'];
    if (rawSounds is List) {
      for (final Object? entry in rawSounds) {
        final EscapeSound? parsed = EscapeSound.tryFromJson(entry);
        if (parsed == null) continue;
        if (parsed.source is! UserFileSource) continue;
        if (sounds.any((EscapeSound s) => s.id == parsed.id)) continue;
        sounds.add(parsed);
      }
    }

    return UserLibrary(categories: categories, sounds: sounds);
  }
}
