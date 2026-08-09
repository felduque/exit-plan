import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'calls/call_launch.dart';
import 'core/theme.dart';
import 'data/entitlement.dart';
import 'l10n/app_localizations.dart';
import 'permissions/permission_center.dart';
import 'screens/home_screen.dart';
import 'services/billing_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/force_update_service.dart';
import 'services/tiktok_analytics.dart';
import 'state/app_state.dart';
import 'state/permissions.dart';
import 'widgets/animated_splash.dart';
import 'widgets/force_update_screen.dart';
import 'widgets/intro_overlay.dart';
import 'widgets/tip_banner.dart';

/// The boot sequence: animated splash → first-run intro → home.
///
/// The splash and the intro are **overlays over the navigator, not routes**, so
/// the home screen needs no guard or redirect and is never seen half-built.
class ExitApp extends StatefulWidget {
  const ExitApp({super.key, required this.state});

  final AppState state;

  @override
  State<ExitApp> createState() => _ExitAppState();
}

class _ExitAppState extends State<ExitApp> {
  bool _splashDone = false;
  late bool _introDone = widget.state.onboardingDone;

  /// True once the user is sitting quietly on the home screen.
  bool get _settled => _splashDone && _introDone;

  /// Read directly off [widget.state], never via `AppScope.of` — at the point
  /// `MaterialApp` is built below, `context` is still above [AppScope], since
  /// `AppScope` wraps `MaterialApp` as its child rather than the reverse.
  Locale get _locale {
    final String? saved = widget.state.languageCode;
    if (saved != null) return Locale(saved);
    final String system = ui.PlatformDispatcher.instance.locale.languageCode;
    return Locale(system == 'es' ? 'es' : 'en');
  }

  /// Kept only so it can be disposed; nothing reads it.
  late final AppLifecycleListener _lifecycle;

  /// A scheduled call has to be able to push a route from outside the widget
  /// tree — the alarm arrives with no BuildContext attached to it.
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  late final CallLaunchRouter _calls = CallLaunchRouter(
    navigatorKey: _navigator,
    state: widget.state,
  );

  @override
  void initState() {
    super.initState();
    // `MaterialApp`'s `locale:` is computed from `widget.state.languageCode`
    // (see `_locale` above) at *this* widget's build time — but this widget
    // never reads `AppState` through `AppScope.of`, since it is the one
    // constructing `AppScope`. Without this listener, `setLanguageCode`
    // calling `notifyListeners()` would rebuild every screen below `AppScope`
    // (they do read through it) while `MaterialApp` itself kept the stale
    // `Locale` it was built with — the language would only actually change
    // on the next cold start.
    widget.state.addListener(_onStateChanged);
    // Starts watching POST_NOTIFICATIONS, including re-checking it every time
    // the app comes back to the foreground — which is how the app notices that
    // the user granted it from the system settings page.
    NotificationPermission.instance.start(
      alreadyAsked: widget.state.notificationsAsked,
    );
    // The other three permissions, on the same resume-and-recheck cycle. For
    // exact alarms and full-screen intents that cycle is the *only* way the
    // answer ever changes: neither has a runtime dialog, so the app learns it
    // was granted by noticing it has come back from a settings page.
    PermissionCenter.instance.start();
    // Picks up a call that arrived while the app was closed, and listens for
    // the ones that arrive while it is open. Not awaited: a scheduled call is
    // never the reason the first frame is late.
    unawaited(_calls.start());
    // The TikTok SDK batches on a timer, so an install recorded moments before
    // the user leaves can otherwise sit in the queue unsent. Leaving is exactly
    // when this app expects to be dismissed mid-use, so the flush matters more
    // here than it would elsewhere. A no-op when tracking is not configured.
    _lifecycle = AppLifecycleListener(onPause: TikTokAnalytics.flush);
    // Opens the Play connection and replays anything already owned — a purchase
    // made on another device, a subscription that renewed, a payment that
    // cleared while the app was closed. The service never writes storage; it
    // hands the resolved entitlement here so AppState stays the only writer.
    BillingService.instance.start(
      onEntitlement: (Entitlement value) =>
          unawaited(widget.state.setEntitlement(value)),
    );
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _lifecycle.dispose();
    _calls.stop();
    BillingService.instance.stop();
    PermissionCenter.instance.stop();
    NotificationPermission.instance.stop();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSplashDone() {
    setState(() => _splashDone = true);
    if (_settled) _askNotificationsOnce();
  }

  Future<void> _onIntroDone() async {
    await widget.state.completeOnboarding();
    if (!mounted) return;
    setState(() => _introDone = true);
    _askNotificationsOnce();
  }

  /// The system dialog is shown here and nowhere else: one appearing in the
  /// middle of a firing would ruin the excuse. It is also shown exactly once —
  /// Android will not display it a second time anyway.
  ///
  /// Denying it is no longer the end of the story: the home status line turns
  /// amber and settings grows a notice with a shortcut into the app's own
  /// permission page, which is the only route left once the dialog is spent.
  Future<void> _askNotificationsOnce() async {
    if (widget.state.notificationsAsked) return;
    await widget.state.markNotificationsAsked();
    await NotificationPermission.instance.request();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'EXITPLAN',
        debugShowCheckedModeBanner: false,
        theme: buildExitTheme(),
        navigatorKey: _navigator,
        navigatorObservers: <NavigatorObserver>[
          if (FirebaseAnalyticsService.observer != null)
            FirebaseAnalyticsService.observer!,
        ],
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const HomeScreen(),
        builder: (BuildContext context, Widget? child) {
          return Stack(
            children: <Widget>[
              child ?? const SizedBox.shrink(),
              TipBanner(suppressed: !_settled),
              if (!_splashDone)
                Material(
                  color: ExitColors.bg,
                  child: AnimatedSplash(onDone: _onSplashDone),
                ),
              if (_splashDone && !_introDone)
                Material(
                  color: ExitColors.bg,
                  child: IntroOverlay(onDone: _onIntroDone),
                ),
              // Topmost, deliberately: a build the Remote Config check has
              // flagged as dangerously outdated must not be reachable through
              // the intro or the splash either, not just through home.
              ValueListenableBuilder<bool>(
                valueListenable: ForceUpdateService.updateRequired,
                builder: (BuildContext context, bool required, _) => required
                    ? const ForceUpdateScreen()
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}
