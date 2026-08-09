import 'package:exitplan/core/premium_config.dart';
import 'package:exitplan/core/theme.dart';
import 'package:exitplan/data/entitlement.dart';
import 'package:exitplan/screens/home_screen.dart';
import 'package:exitplan/screens/premium_screen.dart';
import 'package:exitplan/screens/settings_screen.dart';
import 'package:exitplan/services/billing_service.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_localized.dart';

/// The paywall has to survive states nobody thinks to design for: a device with
/// no Play Billing, a purchase stuck mid-flight, a product Play has not finished
/// publishing. Each of those is a real screen a real user can land on, and an
/// overflow or a blank page there is a support ticket about money.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    BillingService.instance.debugSet();
  });

  const List<Size> sizes = <Size>[Size(394, 852), Size(360, 640)];

  ProductDetails product(String id, String price) => ProductDetails(
    id: id,
    title: id,
    description: '',
    price: price,
    rawPrice: 0,
    currencyCode: 'USD',
  );

  Future<AppState> pump(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final AppState state = await AppState.bootstrap();
    // Keyed by size: tests that loop over sizes in the same `tester`
    // (scrolling at one size, then re-pumping at another) would otherwise
    // have Flutter reuse the previous size's Scrollable — and its leftover
    // scroll offset — for the new tree, under-building the list at the
    // smaller size before the test gets a chance to scroll it itself. A
    // fresh key forces a clean Scrollable per size instead.
    await pumpLocalized(
      tester,
      state,
      KeyedSubtree(key: ValueKey(size), child: screen),
    );
    await tester.pump();
    return state;
  }

  group('premium screen fits', () {
    testWidgets('with all three plans listed', (WidgetTester tester) async {
      BillingService.instance.debugSet(
        products: <ProductDetails>[
          product(PremiumProducts.monthly, r'$2.99'),
          product(PremiumProducts.yearly, r'$11.99'),
          product(PremiumProducts.lifetime, r'$24.99'),
        ],
      );

      for (final Size size in sizes) {
        await pump(tester, const PremiumScreen(), size);
        expect(find.text(r'$2.99'), findsOneWidget);

        // A ListView only builds what fits, so on a short phone the one-off
        // plan starts below the fold. Scrolling to it is also the check that
        // matters: this is the tier the screen recommends, and it has to be
        // reachable on the smallest device the app supports.
        await tester.scrollUntilVisible(find.text(r'$24.99'), 120);
        expect(find.text(r'$24.99'), findsOneWidget);
        expect(find.text('BEST VALUE'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'broke at $size');
      }
    });

    testWidgets('when Play Billing is missing from the device', (
      WidgetTester tester,
    ) async {
      BillingService.instance.debugSet(phase: BillingPhase.unavailable);

      for (final Size size in sizes) {
        await pump(tester, const PremiumScreen(), size);
        // It must say so rather than showing an empty list, which reads as a
        // broken app rather than an unsupported device.
        expect(find.textContaining('not available'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('when the store errors, and offers a way back', (
      WidgetTester tester,
    ) async {
      BillingService.instance.debugSet(
        phase: BillingPhase.error,
        error: 'Network unreachable',
      );

      await pump(tester, const PremiumScreen(), sizes.last);
      expect(find.text('Network unreachable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a receipt instead of an offer once paid', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'exitplan.premium': '{"source":"lifetime"}',
      });
      BillingService.instance.debugSet(
        products: <ProductDetails>[
          product(PremiumProducts.lifetime, r'$24.99'),
        ],
      );

      await pump(tester, const PremiumScreen(), sizes.last);

      expect(find.text('Premium — one payment'), findsOneWidget);
      // Nobody should be able to buy the same thing twice.
      expect(find.text(r'$24.99'), findsNothing);
      expect(find.text('Restore a previous purchase'), findsNothing);
    });
  });

  group('the upsell disappears once it is pointless', () {
    testWidgets('home shows the premium tile only while free', (
      WidgetTester tester,
    ) async {
      await pump(tester, const HomeScreen(), sizes.last);
      expect(find.bySemanticsLabel('Premium'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.runAsync(() async {
        final AppState state = AppScope.read(
          tester.element(find.byType(HomeScreen)),
        );
        await state.setEntitlement(
          const Entitlement(source: PremiumSource.yearly),
        );
      });
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Premium'), findsNothing);
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('settings keeps exactly six switches with the row added', (
      WidgetTester tester,
    ) async {
      for (final Size size in sizes) {
        await pump(tester, const SettingsScreen(), size);

        // The guard layout_test relies on: premium is a purchase, not a
        // preference, so it must never become a seventh toggle. It also must
        // not displace one — the row lives after the toggles precisely so all
        // six still render on the smallest supported phone.
        expect(find.byType(ExitSwitch), findsNWidgets(6));

        await tester.scrollUntilVisible(find.text('Get Premium'), 120);
        expect(find.text('Get Premium'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'broke at $size');
      }
    });
  });
}
