import 'package:exitplan/screens/home_screen.dart';
import 'package:exitplan/screens/settings_screen.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:exitplan/state/permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_localized.dart';

/// A denied notification permission breaks lock-screen controls *silently* —
/// the toggle stays on and nothing works. These tests pin the two things that
/// stop it being silent: the home status line changes colour and wording, and
/// settings grows a notice whose button knows whether asking again can still do
/// anything.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // The singleton outlives a test, so every case starts from unknown.
    NotificationPermission.instance.debugSet();
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(394, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final AppState state = await AppState.bootstrap();
    await pumpLocalized(tester, state, screen);
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('settings notice', () {
    testWidgets('stays away while the permission is granted', (
      WidgetTester tester,
    ) async {
      NotificationPermission.instance.debugSet(
        status: PermissionStatus.granted,
      );
      await pump(tester, const SettingsScreen());

      expect(find.text('Notifications are blocked'), findsNothing);
    });

    testWidgets('offers the dialog the first time it is denied', (
      WidgetTester tester,
    ) async {
      NotificationPermission.instance.debugSet(status: PermissionStatus.denied);
      await pump(tester, const SettingsScreen());

      expect(find.text('Notifications are blocked'), findsOneWidget);
      expect(find.text('Allow'), findsOneWidget);
      expect(find.text('Open settings'), findsNothing);
    });

    testWidgets('offers settings once the dialog has been spent', (
      WidgetTester tester,
    ) async {
      // Android shows the prompt once. A second "Allow" would do nothing at
      // all, so past that point the only honest offer is the settings page.
      NotificationPermission.instance.debugSet(
        status: PermissionStatus.denied,
        asked: true,
      );
      await pump(tester, const SettingsScreen());

      expect(find.text('Open settings'), findsOneWidget);
      expect(find.text('Allow'), findsNothing);
    });

    testWidgets('says nothing when the permission is permanently denied but '
        'lock-screen controls are off', (WidgetTester tester) async {
      NotificationPermission.instance.debugSet(
        status: PermissionStatus.permanentlyDenied,
      );
      final AppState state = await AppState.bootstrap();
      await state.updateSettings(
        state.settings.copyWith(lockScreenControls: false),
      );

      tester.view.physicalSize = const Size(394, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpLocalized(tester, state, const SettingsScreen());
      await tester.pump(const Duration(milliseconds: 300));

      // Nothing is being taken from the user, so there is nothing to nag about.
      expect(find.text('Notifications are blocked'), findsNothing);
    });
  });

  group('home status line', () {
    testWidgets('reads standby while everything works', (
      WidgetTester tester,
    ) async {
      NotificationPermission.instance.debugSet(
        status: PermissionStatus.granted,
      );
      await pump(tester, const HomeScreen());

      expect(find.text('STANDBY · 4 EXITS READY'), findsOneWidget);
    });

    testWidgets('turns into a warning when notifications are blocked', (
      WidgetTester tester,
    ) async {
      NotificationPermission.instance.debugSet(status: PermissionStatus.denied);
      await pump(tester, const HomeScreen());

      expect(find.text('NO NOTIFICATIONS · TAP TO FIX'), findsOneWidget);
      expect(find.text('STANDBY · 4 EXITS READY'), findsNothing);
    });

    testWidgets('the warning opens settings', (WidgetTester tester) async {
      NotificationPermission.instance.debugSet(status: PermissionStatus.denied);
      await pump(tester, const HomeScreen());

      await tester.tap(find.text('NO NOTIFICATIONS · TAP TO FIX'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('an unknown status never nags', (WidgetTester tester) async {
      // The first check has not landed yet. A warning that flashes on every
      // cold start would be worse than one that arrives a frame late.
      NotificationPermission.instance.debugSet();
      await pump(tester, const HomeScreen());

      expect(find.text('STANDBY · 4 EXITS READY'), findsOneWidget);
    });
  });
}
