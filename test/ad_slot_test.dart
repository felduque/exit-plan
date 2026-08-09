import 'package:exitplan/data/entitlement.dart';
import 'package:exitplan/screens/home_screen.dart';
import 'package:exitplan/screens/settings_screen.dart';
import 'package:exitplan/services/ads_service.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:exitplan/state/ui_flags.dart';
import 'package:exitplan/widgets/ad_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_localized.dart';

/// The banner is the one piece of this app that can hurt someone: it sits on a
/// panic button, and a layout that shifts under a thumb, or a banner that
/// creeps up next to a quick exit, is the failure that matters. `layout_test`
/// already proves these screens fit without ads; this proves they still fit
/// *with* them, at the height a real banner will actually occupy.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AdsService.debugSet(ready: false, forcedHeight: null);
    blackoutActive.value = false;
  });

  tearDown(() {
    AdsService.debugSet(ready: false, forcedHeight: null);
    blackoutActive.value = false;
  });

  /// The design doc's phone, and the small cheap Android that actually
  /// overflows first.
  const List<Size> sizes = <Size>[Size(394, 852), Size(360, 640)];

  Future<AppState> pump(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final AppState state = await AppState.bootstrap();
    await pumpLocalized(tester, state, screen);
    await tester.pump();
    return state;
  }

  double slotHeight(WidgetTester tester) =>
      tester.getSize(find.byType(AdBannerSlot)).height;

  group('before the SDK is up', () {
    testWidgets('takes no space at all', (WidgetTester tester) async {
      await pump(tester, const HomeScreen(), sizes.last);

      expect(find.byType(AdBannerSlot), findsOneWidget);
      expect(slotHeight(tester), 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('once a banner is live', () {
    testWidgets('home still fits every screen size', (
      WidgetTester tester,
    ) async {
      // 90 is the tallest anchored adaptive banner Google serves — if the
      // layout survives that, it survives every device.
      AdsService.debugSet(ready: true, forcedHeight: 90);

      for (final Size size in sizes) {
        await pump(tester, const HomeScreen(), size);
        expect(slotHeight(tester), 90, reason: 'reserved before any ad loads');
        expect(
          tester.takeException(),
          isNull,
          reason: 'home overflowed at $size with a banner',
        );
      }
    });

    testWidgets('settings still fits every screen size', (
      WidgetTester tester,
    ) async {
      AdsService.debugSet(ready: true, forcedHeight: 90);

      for (final Size size in sizes) {
        await pump(tester, const SettingsScreen(), size);
        expect(
          tester.takeException(),
          isNull,
          reason: 'settings broke at $size',
        );
      }
    });

    testWidgets('the space is claimed before anything loads', (
      WidgetTester tester,
    ) async {
      AdsService.debugSet(ready: true, forcedHeight: 50);
      await pump(tester, const HomeScreen(), sizes.first);

      // No ad has arrived and none will in a test — the height is already
      // there. This is the property that stops a late-arriving banner from
      // moving the browse row out from under a thumb.
      expect(slotHeight(tester), 50);
    });
  });

  group('kill switches', () {
    testWidgets('premium removes the slot entirely, not just the ad', (
      WidgetTester tester,
    ) async {
      AdsService.debugSet(ready: true, forcedHeight: 90);
      await pump(tester, const HomeScreen(), sizes.last);
      expect(slotHeight(tester), 90);

      // Buying premium must give back the exact layout the app had before ads,
      // reservation included — not a blank band where an ad used to be.
      await tester.runAsync(() async {
        final AppState state = AppScope.read(
          tester.element(find.byType(HomeScreen)),
        );
        await state.setEntitlement(
          const Entitlement(source: PremiumSource.lifetime),
        );
      });
      await tester.pumpAndSettle();

      expect(slotHeight(tester), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an open keyboard makes the banner yield entirely', (
      WidgetTester tester,
    ) async {
      AdsService.debugSet(ready: true, forcedHeight: 90);
      await pump(tester, const HomeScreen(), sizes.last);
      expect(slotHeight(tester), 90);

      // The editor and the call-template editor both put a text field above a
      // Save button. Without this, the keyboard shrinks the viewport and the
      // banner rides up to sit between the two — the exact adjacency the
      // placement contract exists to prevent.
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      await tester.pumpAndSettle();
      expect(slotHeight(tester), 0);
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(slotHeight(tester), 90, reason: 'comes back once typing ends');
    });

    testWidgets('a blackout keeps the reservation and survives the round trip', (
      WidgetTester tester,
    ) async {
      AdsService.debugSet(ready: true, forcedHeight: 90);
      await pump(tester, const HomeScreen(), sizes.last);

      // Home stays mounted underneath the blackout route, so the slot has to
      // cope with the flag flipping under it. The effect that matters — the
      // BannerAd being disposed so no unviewable impression is served and no
      // WebView is held alive during a firing — happens in _sync and cannot be
      // observed here, because the forced-height seam never creates a real ad.
      // What this does prove is that the reservation is *held* rather than
      // collapsed, so returning from a firing does not move the layout.
      blackoutActive.value = true;
      await tester.pumpAndSettle();
      expect(slotHeight(tester), 90);
      expect(tester.takeException(), isNull);

      blackoutActive.value = false;
      await tester.pumpAndSettle();
      expect(slotHeight(tester), 90);
      expect(tester.takeException(), isNull);
    });
  });
}
