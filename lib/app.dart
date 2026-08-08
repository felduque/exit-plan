import 'dart:async';

import 'package:flutter/material.dart';

import 'calls/call_launch.dart';
import 'core/theme.dart';
import 'data/entitlement.dart';
import 'permissions/permission_center.dart';
import 'screens/home_screen.dart';
import 'services/billing_service.dart';
import 'services/tiktok_analytics.dart';
import 'state/app_state.dart';
import 'state/permissions.dart';
import 'widgets/animated_splash.dart';
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
    _lifecycle.dispose();
    _calls.stop();
    BillingService.instance.stop();
    PermissionCenter.instance.stop();
    NotificationPermission.instance.stop();
    super.dispose();
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
            ],
          );
        },
      ),
    );
  }
}
