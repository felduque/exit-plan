import 'package:exitplan/core/theme.dart';
import 'package:exitplan/models/escape_sound.dart';
import 'package:exitplan/screens/call_preset_editor_screen.dart';
import 'package:exitplan/screens/home_screen.dart';
import 'package:exitplan/screens/settings_screen.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:exitplan/widgets/browse_row.dart';
import 'package:exitplan/widgets/call_theme_picker.dart';
import 'package:exitplan/widgets/intro_overlay.dart';
import 'package:exitplan/widgets/quick_slot_button.dart';
import 'package:exitplan/widgets/sound_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_localized.dart';

/// The layout is dense — fixed tile heights, two selectors side by side, a
/// 2x2 grid above the fold — and every one of those is a way to overflow on a
/// screen shorter than the design doc's. These tests pump the screens that own
/// no audio player and fail on the first overflow.
///
/// The screens that do own one (browse, category, editor) are not here: their
/// `PreviewPlayer` reaches for a platform channel that does not exist under the
/// test binding. What they draw is the widgets below, exercised directly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// The design doc's phone, and a small cheap Android, which is the one that
  /// actually overflows.
  const List<Size> sizes = <Size>[Size(394, 852), Size(360, 640)];

  Future<void> pump(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final AppState state = await AppState.bootstrap();
    await pumpLocalized(tester, state, screen);
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final Size size in sizes) {
    testWidgets('home fits ${size.width.toInt()}x${size.height.toInt()}', (
      WidgetTester tester,
    ) async {
      await pump(tester, const HomeScreen(), size);
      expect(tester.takeException(), isNull);
      expect(find.text('EXITPLAN'), findsOneWidget);
      expect(find.byType(QuickSlotButton), findsNWidgets(4));
      expect(find.byType(BrowseRow), findsOneWidget);
    });

    testWidgets('settings fits ${size.width.toInt()}x${size.height.toInt()}', (
      WidgetTester tester,
    ) async {
      await pump(tester, const SettingsScreen(), size);
      expect(tester.takeException(), isNull);
      expect(find.byType(ExitSwitch), findsNWidgets(6));
    });

    testWidgets('the call template editor fits '
        '${size.width.toInt()}x${size.height.toInt()}', (
      WidgetTester tester,
    ) async {
      // This screen owns no player, so unlike the audio editor it can be
      // pumped whole — and it is the one that grew most when themes,
      // the ring window, auto-end and vibrate arrived. Its theme strip also
      // builds real call screens, which is the most expensive thing any
      // editor in this app draws.
      await pump(tester, const CallPresetEditorScreen(), size);
      expect(tester.takeException(), isNull);
      expect(find.byType(CallThemePicker), findsOneWidget);
      expect(find.text('Save template'), findsOneWidget);
    });

    testWidgets(
      'every intro step fits ${size.width.toInt()}x${size.height.toInt()}',
      (WidgetTester tester) async {
        await pump(tester, IntroOverlay(onDone: () {}), size);
        expect(tester.takeException(), isNull);

        // Four steps now that the intro also covers fake calls: three "Next"
        // taps to reach the last one.
        for (int step = 0; step < 3; step++) {
          await tester.tap(find.text('Next'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Start'), findsOneWidget);
      },
    );
  }

  testWidgets('a sound row survives a long name and a long excuse', (
    WidgetTester tester,
  ) async {
    const EscapeSound wordy = EscapeSound(
      id: 'user-1',
      label: 'An imported file with a genuinely unreasonable name',
      excuse:
          'Sorry, something is burning and I really do have to run right now.',
      categoryId: 'fire',
      icon: 'fire',
      source: UserFileSource('/tmp/x.mp3'),
    );

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpLocalizedApp(
      tester,
      Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(22),
          children: <Widget>[
            SoundRow(
              sound: wordy,
              pinned: true,
              previewing: false,
              onFire: () {},
              onPreview: () {},
              onPin: () {},
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              width: 160,
              child: QuickSlotButton(slot: 0, sound: wordy, onFire: () {}),
            ),
            const SizedBox(height: 8),
            AddYourAudioRow(onTap: () {}),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
