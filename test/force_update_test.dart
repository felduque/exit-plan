import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exitplan/services/force_update_service.dart';
import 'package:exitplan/widgets/force_update_screen.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'support/pump_localized.dart';

/// Records what it was asked to launch instead of touching a platform
/// channel, and always says a URL can be handled — this test only cares
/// about *what* the screen asks the platform to open, not whether Android
/// itself could.
class _FakeUrlLauncher extends UrlLauncherPlatform {
  final List<String> launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeUrlLauncher fakeLauncher;

  setUp(() {
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
    ForceUpdateService.debugSet(required: false);
  });

  tearDown(() => ForceUpdateService.debugSet(required: false));

  test('debugSet drives the notifier a widget test can gate on', () {
    expect(ForceUpdateService.updateRequired.value, isFalse);
    ForceUpdateService.debugSet(required: true);
    expect(ForceUpdateService.updateRequired.value, isTrue);
  });

  testWidgets('cannot be dismissed — no back gesture, no close button', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(tester, const ForceUpdateScreen());

    final PopScope popScope = tester.widget(find.byType(PopScope));
    expect(popScope.canPop, isFalse);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('shows the required copy and a single action', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(tester, const ForceUpdateScreen());

    expect(find.text('UPDATE REQUIRED'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
  });

  testWidgets('the button opens the Play Store listing for this package', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(tester, const ForceUpdateScreen());

    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.launched, isNotEmpty);
    expect(
      fakeLauncher.launched.single,
      contains('com.dg.developer.exitplan'),
    );
  });
}
