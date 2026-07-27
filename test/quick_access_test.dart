import 'dart:convert';

import 'package:exitplan/data/system_catalog.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quick access is the one piece of state that references ids across a restart,
/// so its sanitizing and its load *order* are what these tests protect.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  TestWidgetsFlutterBinding.ensureInitialized();

  test('first run fills the four default slots', () async {
    final AppState state = await AppState.bootstrap();
    expect(state.quickAccess, kDefaultQuickAccess);
  });

  test(
    'a short or overlong list is forced back to exactly four slots',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'exitplan.quickAccess': jsonEncode(<String>['alarms-siren']),
      });
      final AppState short = await AppState.bootstrap();
      expect(short.quickAccess.length, 4);
      expect(short.quickAccess.first, 'alarms-siren');
      expect(short.quickAccess[1], kDefaultQuickAccess[1]);

      SharedPreferences.setMockInitialValues(<String, Object>{
        'exitplan.quickAccess': jsonEncode(<String>[
          'alarms-siren',
          'fire-roar',
          'storm-rain',
          'electric-buzz',
          'doorbell-ding',
          'doorbell-knock',
        ]),
      });
      final AppState long = await AppState.bootstrap();
      expect(long.quickAccess.length, 4);
      expect(long.quickAccess.last, 'electric-buzz');
    },
  );

  test('junk entries are dropped and backfilled from the defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'exitplan.quickAccess': jsonEncode(<Object>[42, '', 'fire-roar']),
    });
    final AppState state = await AppState.bootstrap();
    expect(state.quickAccess.length, 4);
    expect(state.quickAccess.first, 'fire-roar');
  });

  test(
    'a slot pointing at a deleted sound falls back to its position default',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'exitplan.quickAccess': jsonEncode(<String>[
          'user-gone-forever',
          'alarms-clock',
          'bad-signal-dropout',
          'fire-crackle',
        ]),
      });
      final AppState state = await AppState.bootstrap();
      expect(state.quickAccess.first, kDefaultQuickAccess.first);
    },
  );

  test('a user sound in a slot survives boot', () async {
    // The regression this guards: validating slot ids before the user library is
    // loaded would discard a freshly saved user sound.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'exitplan.quickAccess': jsonEncode(<String>[
        'user-99',
        'alarms-clock',
        'bad-signal-dropout',
        'fire-crackle',
      ]),
      'exitplan.userLibrary': jsonEncode(<String, dynamic>{
        'categories': <Object>[],
        'sounds': <Object>[
          <String, dynamic>{
            'id': 'user-99',
            'label': 'MINE',
            'categoryId': 'doorbell',
            'icon': 'audio',
            'source': <String, dynamic>{'kind': 'file', 'value': '/a.mp3'},
            'origin': 'user',
          },
        ],
      }),
    });

    final AppState state = await AppState.bootstrap();
    expect(state.quickAccess.first, 'user-99');
    expect(state.quickSlotSound(0).label, 'MINE');
    expect(state.isPinned('user-99'), isTrue);
  });

  test('assigning a slot overwrites only that slot', () async {
    final AppState state = await AppState.bootstrap();
    await state.assignQuickSlot(2, 'storm-thunder');
    expect(state.quickAccess[2], 'storm-thunder');
    expect(state.quickAccess[0], kDefaultQuickAccess[0]);
    expect(state.quickAccess[3], kDefaultQuickAccess[3]);

    // And it persists.
    final AppState reloaded = await AppState.bootstrap();
    expect(reloaded.quickAccess[2], 'storm-thunder');
  });
}
