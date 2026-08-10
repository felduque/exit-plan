import 'dart:async';

import 'package:exitplan/screens/call_mask_screen.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_localized.dart';

/// The mask is the last thing between a finished fake call and the app being
/// seen, so what it must never do is more important than what it looks like:
/// no ExitPlan underneath it, and no accidental way off it.
///
/// The hold gesture is measured against the wall clock on purpose (see
/// `HoldToExit`), so the exit test spends real milliseconds rather than pumped
/// ones — `tester.pump` moves the animation clock, not `DateTime.now()`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// A screen standing in for the app, with the mask pushed over it exactly the
  /// way a call ends: pushed, not replacing, and popped only after the mask is.
  Future<void> pumpMaskedApp(WidgetTester tester) async {
    final AppState state = await AppState.bootstrap();
    late BuildContext ctx;

    await pumpLocalized(
      tester,
      state,
      Builder(
        builder: (BuildContext context) {
          ctx = context;
          return const Scaffold(body: Center(child: Text('EXITPLAN')));
        },
      ),
    );

    // Dropped rather than awaited: in the app this future is what the call
    // screen waits on before popping itself, and here the test is the thing
    // driving the mask.
    unawaited(showCallMask(ctx));
    await tester.pumpAndSettle();
  }

  testWidgets('covers the app completely', (WidgetTester tester) async {
    await pumpMaskedApp(tester);

    expect(find.byType(CallMaskScreen), findsOneWidget);
    expect(find.text('EXITPLAN'), findsNothing);
  });

  testWidgets('a stray tap does not uncover the app', (
    WidgetTester tester,
  ) async {
    await pumpMaskedApp(tester);

    await tester.tap(find.byType(CallMaskScreen));
    await tester.pumpAndSettle();

    expect(find.byType(CallMaskScreen), findsOneWidget);
    expect(find.text('EXITPLAN'), findsNothing);
  });

  testWidgets('the system back gesture does not uncover the app', (
    WidgetTester tester,
  ) async {
    await pumpMaskedApp(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(CallMaskScreen), findsOneWidget);
    expect(find.text('EXITPLAN'), findsNothing);
  });

  testWidgets('a deliberate hold gives the app back', (
    WidgetTester tester,
  ) async {
    await pumpMaskedApp(tester);

    // Past the grace period that ignores the finger still on the glass from
    // whatever opened this screen.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );

    final TestGesture hold = await tester.startGesture(
      tester.getCenter(find.byType(CallMaskScreen)),
    );
    await tester.pump();
    // Real time for the wall-clock check, then pumped time to drive the ring's
    // controller to completion. Both have to pass.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 900)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    await hold.up();
    await tester.pumpAndSettle();

    expect(find.byType(CallMaskScreen), findsNothing);
    expect(find.text('EXITPLAN'), findsOneWidget);
  });
}
