import 'dart:convert';

import 'package:exitplan/core/premium_config.dart';
import 'package:exitplan/core/theme.dart';
import 'package:exitplan/data/gate_baseline.dart';
import 'package:exitplan/screens/calls_screen.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:exitplan/state/premium_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Free-tier limits are being introduced into an app that shipped without any.
/// The whole risk of that is retroactively taking something away from someone
/// who already has it, so most of what follows is about proving that cannot
/// happen — a user with nine call presets keeps all nine.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, Object> prefsWithPresets(int count) => <String, Object>{
    'exitplan.callPresets': jsonEncode(<Map<String, Object?>>[
      for (int i = 0; i < count; i++)
        <String, Object?>{
          'id': 'call-$i',
          'name': 'Contact $i',
          'number': '',
          'platform': 'ios',
          'ringtoneSoundId': 'doorbell-ding',
          'delaySeconds': 0,
        },
    ]),
  };

  group('cap arithmetic', () {
    test('premium has no ceiling', () {
      expect(
        PremiumGate.effectiveCap(freeLimit: 2, baseline: 0, premium: true),
        kUnlimited,
      );
      expect(PremiumGate.canAdd(current: 9999, cap: kUnlimited), isTrue);
    });

    test('a fresh install gets exactly the published free limit', () {
      const GateBaseline fresh = GateBaseline.empty;

      expect(
        PremiumGate.callPresetCap(fresh, premium: false),
        FreeLimits.callPresets,
      );
      expect(
        PremiumGate.userSoundCap(fresh, premium: false),
        FreeLimits.userSounds,
      );
      expect(
        PremiumGate.userCategoryCap(fresh, premium: false),
        FreeLimits.userCategories,
      );
    });

    test('a user over the limit keeps every one they had', () {
      const GateBaseline heavy = GateBaseline(
        callPresets: 9,
        userSounds: 20,
        userCategories: 4,
        capturedAtMs: 1,
      );

      expect(PremiumGate.callPresetCap(heavy, premium: false), 9);
      expect(PremiumGate.userSoundCap(heavy, premium: false), 20);
      expect(PremiumGate.userCategoryCap(heavy, premium: false), 4);

      // Nothing is hidden — they are simply not offered a tenth.
      expect(PremiumGate.canAdd(current: 9, cap: 9), isFalse);
      expect(PremiumGate.canAdd(current: 8, cap: 9), isTrue);
    });

    test('a user under the limit still gets the full free allowance', () {
      const GateBaseline light = GateBaseline(
        callPresets: 1,
        userSounds: 0,
        userCategories: 0,
        capturedAtMs: 1,
      );

      expect(
        PremiumGate.callPresetCap(light, premium: false),
        FreeLimits.callPresets,
      );
      expect(
        PremiumGate.canAdd(current: 1, cap: FreeLimits.callPresets),
        isTrue,
        reason: 'a baseline below the free limit must never shrink it',
      );
    });

    test('deleting does not cost the grandfathered allowance', () {
      // The baseline is a snapshot, not a live count: someone who had nine may
      // tidy down to three and still add back up to nine.
      const GateBaseline heavy = GateBaseline(
        callPresets: 9,
        userSounds: 0,
        userCategories: 0,
        capturedAtMs: 1,
      );
      final int cap = PremiumGate.callPresetCap(heavy, premium: false);
      expect(PremiumGate.canAdd(current: 3, cap: cap), isTrue);
    });
  });

  group('baseline capture', () {
    test('records what an existing user already had', () async {
      SharedPreferences.setMockInitialValues(prefsWithPresets(9));

      final AppState state = await AppState.bootstrap();

      expect(state.gateBaseline.callPresets, 9);
      expect(state.callPresets.length, 9);
      expect(PremiumGate.callPresetCap(state.gateBaseline, premium: false), 9);
    });

    test('a fresh install baselines at zero', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final AppState state = await AppState.bootstrap();

      expect(state.gateBaseline.callPresets, 0);
      expect(state.gateBaseline.userSounds, 0);
      expect(state.gateBaseline.userCategories, 0);
      expect(state.isPremium, isFalse);
    });

    test('is captured once and never ratchets upward', () async {
      SharedPreferences.setMockInitialValues(prefsWithPresets(1));

      final AppState first = await AppState.bootstrap();
      expect(first.gateBaseline.callPresets, 1);

      // Simulate the user adding presets, then relaunching. If the snapshot
      // were recomputed at boot it would grow to 5 here, the cap would follow
      // it forever, and no free user would ever meet a limit.
      final int capturedAt = first.gateBaseline.capturedAtMs;
      SharedPreferences.setMockInitialValues(<String, Object>{
        ...prefsWithPresets(5),
        'exitplan.gateBaseline': jsonEncode(first.gateBaseline.toJson()),
      });

      final AppState second = await AppState.bootstrap();

      expect(second.callPresets.length, 5);
      expect(second.gateBaseline.callPresets, 1);
      expect(second.gateBaseline.capturedAtMs, capturedAt);
      expect(
        PremiumGate.callPresetCap(second.gateBaseline, premium: false),
        FreeLimits.callPresets,
      );
    });

    test('a fresh install baselines at zero and blocks the third preset',
        () async {
      SharedPreferences.setMockInitialValues(prefsWithPresets(2));

      final AppState state = await AppState.bootstrap();

      expect(state.gateBaseline.callPresets, 2);
      expect(
        state.canAddCallPreset,
        isFalse,
        reason: 'two presets is the free ceiling',
      );
      expect(state.callPresetCap, FreeLimits.callPresets);
    });

    test('survives a corrupt stored baseline without granting a free pass',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'exitplan.gateBaseline': 'not json at all',
      });

      final AppState state = await AppState.bootstrap();

      // Unreadable means "never captured", so it is captured now — against an
      // empty library, which lands on the plain free tier.
      expect(state.gateBaseline.callPresets, 0);
      expect(state.gateBaseline.capturedAtMs, greaterThan(0));
    });
  });

  group('the gate sheet', () {
    Future<void> pumpCalls(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final AppState state = await AppState.bootstrap();
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            theme: buildExitTheme(),
            home: const CallsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('NEW'));
      await tester.pumpAndSettle();
    }

    testWidgets('appears at the free ceiling and promises nothing is lost', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(prefsWithPresets(2));
      await pumpCalls(tester);

      expect(find.textContaining('The free version covers 2'), findsOneWidget);
      // The sentence that makes this an honest limit rather than a hostage
      // situation. If it ever disappears, the gate is a different feature.
      expect(
        find.text('Nothing you already made is affected.'),
        findsOneWidget,
      );
      expect(find.text('Not now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tells a grandfathered user their real number, not the free one',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(prefsWithPresets(9));
      await pumpCalls(tester);

      // Quoting "the free version covers 2" to somebody holding nine would
      // read as if six were about to be taken away.
      expect(find.textContaining('You had 9 before'), findsOneWidget);
      expect(find.textContaining('The free version covers'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
