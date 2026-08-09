import 'package:exitplan/themes/call_theme.dart';
import 'package:exitplan/themes/call_theme_registry.dart';
import 'package:exitplan/themes/call_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_localized.dart';

/// Every theme in the registry, drawn at both ends of the device range.
///
/// This iterates [kCallThemes] rather than naming three screens, which is the
/// whole point of the registry: a seventh theme is covered the moment it is
/// registered, and cannot ship with a layout that overflows or a gesture
/// nobody wired up.
///
/// The full screens still cannot be pumped — they reach into live
/// audio/haptics/wakelock engines that need a real device — so what is
/// exercised here is the theme's own `buildIncoming`/`buildActive`, which is
/// all the theme actually owns.
void main() {
  /// The design doc's phone, and the smallest one the app supports.
  const List<Size> sizes = <Size>[Size(394, 852), Size(360, 640)];

  CallIncomingContext incoming({
    VoidCallback? onAccept,
    VoidCallback? onDecline,
    String number = '+1 555 0100',
  }) {
    return CallIncomingContext(
      name: 'Priya',
      number: number,
      avatarPath: null,
      onAccept: onAccept ?? callNoop,
      onDecline: onDecline ?? callNoop,
    );
  }

  CallActiveContext active({VoidCallback? onHangUp}) {
    return CallActiveContext(
      name: 'Priya',
      avatarPath: null,
      timer: '00:12',
      muted: false,
      speaker: false,
      keypadOpen: false,
      videoOn: false,
      onMute: callNoop,
      onSpeaker: callNoop,
      onKeypad: callNoop,
      onVideo: callNoop,
      onHangUp: onHangUp ?? callNoop,
    );
  }

  Future<void> pumpAt(WidgetTester tester, Size size, Widget child) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpLocalizedApp(tester, child);
    // Not pumpAndSettle: the accept circle pulses forever, so settling would
    // never return.
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpBare(WidgetTester tester, Widget child) =>
      pumpLocalizedApp(tester, Scaffold(body: Center(child: child)));

  group('the registry itself', () {
    test('every id is unique — ids are persisted, so a collision would '
        'silently repoint saved templates', () {
      final Set<String> ids = kCallThemes.map((CallTheme t) => t.id).toSet();
      expect(ids.length, kCallThemes.length);
    });

    test('every name is unique, or the picker shows two identical labels', () {
      final Set<String> names = kCallThemes
          .map((CallTheme t) => t.name)
          .toSet();
      expect(names.length, kCallThemes.length);
    });

    test('an unknown id resolves to the default rather than throwing', () {
      expect(callThemeFor('nope').id, kDefaultCallThemeId);
      expect(callThemeFor(null).id, kDefaultCallThemeId);
      expect(callThemeFor('').id, kDefaultCallThemeId);
    });

    test('the fallback is never a premium theme — an unresolvable id must not '
        'hand a paying feature to a free user, nor lock a screen they were '
        'already using', () {
      expect(callThemeFor('nope').premium, isFalse);
    });

    test(
      'at least one free theme exists, so the picker is never all padlocks',
      () {
        expect(kCallThemes.any((CallTheme t) => !t.premium), isTrue);
      },
    );

    test('the free themes come first in the picker', () {
      final int firstPremium = kCallThemes.indexWhere(
        (CallTheme t) => t.premium,
      );
      final int lastFree = kCallThemes.lastIndexWhere(
        (CallTheme t) => !t.premium,
      );
      expect(lastFree, lessThan(firstPremium));
    });

    test('the three pre-registry looks are all still free — they are what '
        'existing users already have saved', () {
      for (final String id in kLegacyPlatformThemeIds.values) {
        expect(callThemeFor(id).premium, isFalse, reason: '$id became premium');
      }
    });
  });

  for (final CallTheme theme in kCallThemes) {
    group(theme.name, () {
      for (final Size size in sizes) {
        final String at = '${size.width.toInt()}x${size.height.toInt()}';

        testWidgets('incoming fits at $at', (WidgetTester tester) async {
          await pumpAt(tester, size, theme.buildIncoming(incoming()));
          expect(tester.takeException(), isNull);
        });

        testWidgets('incoming fits at $at with no number', (
          WidgetTester tester,
        ) async {
          // The number line is conditional in most themes, so its absence is a
          // different layout rather than the same one with a gap.
          await pumpAt(tester, size, theme.buildIncoming(incoming(number: '')));
          expect(tester.takeException(), isNull);
        });

        testWidgets('in-call fits at $at', (WidgetTester tester) async {
          await pumpAt(tester, size, theme.buildActive(active()));
          expect(tester.takeException(), isNull);
        });

        testWidgets('the missed notice fits at $at', (
          WidgetTester tester,
        ) async {
          await pumpAt(
            tester,
            size,
            CallMissedView(
              palette: theme.palette,
              name: 'Priya',
              avatarPath: null,
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('hang-up ends the call', (WidgetTester tester) async {
        int hangUps = 0;
        await pumpAt(
          tester,
          sizes.first,
          theme.buildActive(active(onHangUp: () => hangUps++)),
        );
        await tester.tap(find.byIcon(Icons.call_end_rounded).last);
        expect(hangUps, 1);
      });

      testWidgets('answering honours the gesture it declares', (
        WidgetTester tester,
      ) async {
        int accepts = 0;
        await pumpAt(
          tester,
          sizes.first,
          theme.buildIncoming(incoming(onAccept: () => accepts++)),
        );
        final Finder circle = find.byIcon(Icons.call_rounded);

        switch (theme.answerGesture) {
          case CallAnswerGesture.tap:
            await tester.tap(circle);
            expect(accepts, 1);
          case CallAnswerGesture.dragUp:
            // A tap alone must do nothing, or a phone jostled in a pocket
            // answers a call by itself.
            await tester.tap(circle);
            expect(accepts, 0);
            // Well short of the threshold: must spring back, not answer.
            await tester.drag(circle, const Offset(0, -20));
            await tester.pump(const Duration(milliseconds: 250));
            expect(accepts, 0);
            await tester.drag(circle, const Offset(0, -90));
            expect(accepts, 1);
        }
      });

      testWidgets('declining honours the gesture it declares', (
        WidgetTester tester,
      ) async {
        int declines = 0;
        await pumpAt(
          tester,
          sizes.first,
          theme.buildIncoming(incoming(onDecline: () => declines++)),
        );
        // Minimal uses a cross rather than a handset for decline.
        final Finder circle =
            find.byIcon(Icons.call_end_rounded).evaluate().isEmpty
            ? find.byIcon(Icons.close_rounded)
            : find.byIcon(Icons.call_end_rounded);

        switch (theme.declineGesture) {
          case CallAnswerGesture.tap:
            await tester.tap(circle);
            expect(declines, 1);
          case CallAnswerGesture.dragUp:
            await tester.tap(circle);
            expect(declines, 0);
            await tester.drag(circle, const Offset(0, -90));
            expect(declines, 1);
        }
      });
    });
  }

  group('CallAvatar', () {
    testWidgets('falls back to the caller\'s initial without a photo', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        const CallAvatar(avatarPath: null, name: 'Priya', diameter: 80),
      );
      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('shows "?" for a blank name rather than nothing', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        const CallAvatar(avatarPath: null, name: '  ', diameter: 80),
      );
      expect(find.text('?'), findsOneWidget);
    });
  });

  group('CallActionButton', () {
    testWidgets('a plain tap fires immediately', (WidgetTester tester) async {
      int taps = 0;
      await pumpBare(
        tester,
        CallActionButton(
          icon: Icons.call_rounded,
          background: Colors.green,
          iconColor: Colors.white,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.byIcon(Icons.call_rounded));
      expect(taps, 1);
    });
  });

  group('CallPreviewScope', () {
    testWidgets('a pulsing button inside a preview holds still, so a picker '
        'of six themes is not six animations behind a sheet', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        const CallPreviewScope(
          child: CallActionButton(
            icon: Icons.call_rounded,
            background: Colors.green,
            iconColor: Colors.white,
            onTap: callNoop,
            pulse: true,
          ),
        ),
      );

      // A live pulse never settles; a still one does, and that is exactly the
      // difference being asserted.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the status bar clock does not tick inside a preview', (
      WidgetTester tester,
    ) async {
      await pumpBare(
        tester,
        const CallPreviewScope(child: CallStatusBar(color: Colors.white)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
