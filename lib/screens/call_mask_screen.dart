import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/hold_to_exit.dart';
import '../widgets/tip_banner.dart';

/// Pushes the black mask over whatever call screen is ending, and completes
/// when the user has held their way out of it.
///
/// **Pushed, never `pushReplacement`.** The call route stays alive underneath,
/// fully covered, and pops itself once this future completes. That is what
/// keeps `CallLaunchRouter._show` honest: it awaits `fireCall` and only then
/// turns `setLockScreenMode` back off, so replacing the call route here would
/// drop the window off the keyguard while the mask is still on screen.
Future<void> showCallMask(BuildContext context) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const CallMaskScreen(),
      // Slower than the call screens' own 160ms: this is the moment the excuse
      // is over, and a hard cut to black reads as a screen doing something.
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (_, Animation<double> animation, _, Widget child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Where every fake call ends: absolute black, and nothing else.
///
/// The call is over but the room is not. Landing back on `CallsScreen` or
/// `HomeScreen` the instant the ringing stops puts ExitPlan in front of
/// whoever is sitting across the table, at the exact moment they are still
/// looking at the phone. So the call hands off to this instead — the same
/// black `BlackoutScreen` uses, exited the same deliberate way, so a user who
/// has met one already knows this one.
class CallMaskScreen extends StatefulWidget {
  const CallMaskScreen({super.key});

  @override
  State<CallMaskScreen> createState() => _CallMaskScreenState();
}

class _CallMaskScreenState extends State<CallMaskScreen> {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _exit() {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool hints = AppScope.of(context).settings.darkScreenHints;

    // A tip banner on top of the mask gives away the app that the mask exists
    // to hide, exactly as it would mid-call.
    return TipsSuppressor(
      child: PopScope(
        // Back must not skip past the mask into the app.
        canPop: false,
        child: Scaffold(
          backgroundColor: ExitColors.black,
          body: HoldToExit(
            onExit: _exit,
            label: AppLocalizations.of(context).blackoutHoldToExit,
            showHints: hints,
            child: const ColoredBox(color: ExitColors.black),
          ),
        ),
      ),
    );
  }
}
