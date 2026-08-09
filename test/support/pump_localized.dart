import 'package:exitplan/core/theme.dart';
import 'package:exitplan/l10n/app_localizations.dart';
import 'package:exitplan/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [screen] wrapped exactly like the real app (`AppScope` > `MaterialApp`),
/// with English localization delegates wired in, so a migrated widget's
/// `AppLocalizations.of(context)` calls resolve to the same English text this
/// test suite already asserts on today.
Future<void> pumpLocalized(
  WidgetTester tester,
  AppState state,
  Widget screen,
) async {
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(
        theme: buildExitTheme(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: screen,
      ),
    ),
  );
}

/// The same English-delegate wrapping as [pumpLocalized], for widget tests
/// that build a screen directly under `MaterialApp` without an `AppState`
/// (e.g. a single widget pumped in isolation).
Future<void> pumpLocalizedApp(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildExitTheme(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
  );
}
