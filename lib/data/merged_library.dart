import '../models/escape_sound.dart';
import '../models/exit_category.dart';
import 'system_catalog.dart';
import 'user_library.dart';

/// System catalog + user library, assembled into the single view every screen
/// reads from. The static catalog is an input to this class and to nothing else.
class MergedLibrary {
  MergedLibrary._(this.categories, this._soundsById, this._categoriesById);

  /// System categories first, then user categories, each with its user sounds
  /// appended after the bundled ones.
  final List<ExitCategory> categories;

  final Map<String, EscapeSound> _soundsById;
  final Map<String, ExitCategory> _categoriesById;

  factory MergedLibrary.build({
    required List<ExitCategory> system,
    required UserLibrary user,
  }) {
    final List<ExitCategory> assembled = <ExitCategory>[];

    for (final ExitCategory category in <ExitCategory>[
      ...system,
      ...user.categories,
    ]) {
      final List<EscapeSound> userSounds = user.sounds
          .where((EscapeSound s) => s.categoryId == category.id)
          .toList(growable: false);
      assembled.add(
        userSounds.isEmpty
            ? category
            : category.withSounds(<EscapeSound>[
                ...category.sounds,
                ...userSounds,
              ]),
      );
    }

    // User entries are inserted last so that on an id collision the user's own
    // content wins the lookup.
    final Map<String, EscapeSound> soundsById = <String, EscapeSound>{};
    for (final ExitCategory category in assembled) {
      for (final EscapeSound sound in category.sounds) {
        soundsById[sound.id] = sound;
      }
    }
    for (final EscapeSound sound in user.sounds) {
      soundsById[sound.id] = sound;
    }

    final Map<String, ExitCategory> categoriesById = <String, ExitCategory>{
      for (final ExitCategory category in assembled) category.id: category,
    };

    return MergedLibrary._(
      List<ExitCategory>.unmodifiable(assembled),
      soundsById,
      categoriesById,
    );
  }

  EscapeSound? soundById(String id) => _soundsById[id];

  ExitCategory? categoryById(String id) => _categoriesById[id];

  bool hasSound(String id) => _soundsById.containsKey(id);

  int get categoryCount => categories.length;

  int get soundCount => _soundsById.length;

  /// Never null: the black screen must be able to fire *something* rather than
  /// fail on a stale id.
  EscapeSound resolveOrFallback(String id) =>
      _soundsById[id] ??
      _soundsById[kFallbackSoundId] ??
      categories.first.sounds.first;
}
