import 'package:exitplan/data/merged_library.dart';
import 'package:exitplan/data/system_catalog.dart';
import 'package:exitplan/data/user_library.dart';
import 'package:exitplan/models/enums.dart';
import 'package:exitplan/models/escape_sound.dart';
import 'package:exitplan/models/exit_category.dart';
import 'package:flutter_test/flutter_test.dart';

EscapeSound _userSound(String id, String categoryId) => EscapeSound(
  id: id,
  label: id.toUpperCase(),
  categoryId: categoryId,
  icon: 'audio',
  source: UserFileSource('/audio/$id.mp3'),
  origin: SoundOrigin.user,
);

void main() {
  test('system catalog ships six categories with bundled sounds', () {
    expect(kSystemCategories.length, 6);
    for (final ExitCategory category in kSystemCategories) {
      expect(category.sounds, isNotEmpty, reason: category.id);
      for (final EscapeSound sound in category.sounds) {
        expect(sound.id, startsWith('${category.id}-'));
        expect(sound.source, isA<BundledSource>());
        expect(sound.vibration, kCategoryVibration[category.id]);
      }
    }
    // Losing signal must not shake the phone.
    expect(kCategoryVibration['bad-signal'], isEmpty);
  });

  test('default quick access ids all resolve', () {
    final MergedLibrary library = MergedLibrary.build(
      system: kSystemCategories,
      user: UserLibrary.empty,
    );
    for (final String id in kDefaultQuickAccess) {
      expect(library.hasSound(id), isTrue, reason: id);
    }
    expect(library.hasSound(kFallbackSoundId), isTrue);
  });

  test('a user sound lands inside a system category', () {
    final MergedLibrary library = MergedLibrary.build(
      system: kSystemCategories,
      user: UserLibrary(
        sounds: <EscapeSound>[_userSound('user-1', 'doorbell')],
      ),
    );

    final ExitCategory doorbell = library.categoryById('doorbell')!;
    expect(doorbell.sounds.last.id, 'user-1');
    expect(
      doorbell.sounds.first.isUser,
      isFalse,
      reason: 'bundled sounds stay first',
    );
    expect(library.soundById('user-1'), isNotNull);
    expect(library.categoryCount, 6);
  });

  test('user categories are appended after the system ones', () {
    final MergedLibrary library = MergedLibrary.build(
      system: kSystemCategories,
      user: UserLibrary(
        categories: <ExitCategory>[
          const ExitCategory(
            id: 'usercat-1',
            label: 'MINE',
            description: '',
            icon: 'folder',
            origin: SoundOrigin.user,
          ),
        ],
        sounds: <EscapeSound>[_userSound('user-2', 'usercat-1')],
      ),
    );

    expect(library.categoryCount, 7);
    expect(library.categories.last.id, 'usercat-1');
    expect(library.categories.last.sounds.single.id, 'user-2');
  });

  test('a user sound wins an id collision with a system one', () {
    final MergedLibrary library = MergedLibrary.build(
      system: kSystemCategories,
      user: UserLibrary(
        sounds: <EscapeSound>[_userSound('doorbell-ding', 'doorbell')],
      ),
    );
    expect(library.soundById('doorbell-ding')!.isUser, isTrue);
  });

  test('resolveOrFallback degrades instead of throwing on a stale id', () {
    final MergedLibrary library = MergedLibrary.build(
      system: kSystemCategories,
      user: UserLibrary.empty,
    );
    expect(library.resolveOrFallback('deleted-sound').id, kFallbackSoundId);
  });
}
