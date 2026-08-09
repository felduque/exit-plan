import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_boot.dart';
import '../audio/call_ring_engine.dart';
import '../models/call_preset.dart';
import '../models/escape_sound.dart';
import '../state/app_state.dart';
import '../themes/call_theme.dart';
import '../themes/call_theme_registry.dart';
import '../widgets/tip_banner.dart';
import 'fake_call_screen.dart';

/// Arms [preset] and pushes the full-screen incoming-call UI. Every fake call
/// in the app starts here — no screen rings the phone itself.
Future<void> fireCall(BuildContext context, CallPreset preset) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => IncomingCallScreen(preset: preset),
      transitionDuration: const Duration(milliseconds: 160),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      transitionsBuilder: (_, Animation<double> animation, _, Widget child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// The screen that imitates a real incoming call. Deliberately outside the
/// app's own visual language, the same way `BlackoutScreen` is — this has to
/// look like somebody else's phone, not like ExitPlan.
///
/// Which look is not decided here: the preset names a theme, the registry
/// resolves it, and this screen only owns the engine, the phases and the two
/// outcomes.
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key, required this.preset});

  final CallPreset preset;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  /// How long the missed-call notice stays up before the screen leaves by
  /// itself. Long enough to read, short enough that a phone left on a table
  /// does not sit there advertising a call that never happened.
  static const Duration _missedLinger = Duration(seconds: 3);

  bool _handedOff = false;
  StreamSubscription<void>? _engineSub;
  Timer? _missedExit;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _engineSub = callRingEngine.changes.listen(_onEngine);
    WidgetsBinding.instance.addPostFrameCallback((_) => _arm());
  }

  Future<void> _arm() async {
    // The two engines must never sound at once.
    await fireEngine.cancel();
    if (!mounted) return;

    final AppState state = AppScope.read(context);
    final EscapeSound sound = state.library.resolveOrFallback(
      widget.preset.ringtoneSoundId,
    );
    await callRingEngine.arm(
      sound,
      // Always zero now. By the time this screen exists the wait is already
      // over — either the user asked for a call *now*, or a booking came due.
      // The engine keeps the parameter because the armed phase is still real
      // machinery worth its tests, but nothing in the app sets it any more:
      // the old fuse it served is folded into `CallSchedule`.
      delaySeconds: 0,
      ringSeconds: widget.preset.ringSeconds,
      autoEndSeconds: widget.preset.autoEndSeconds,
      vibrate: widget.preset.vibrate,
    );
  }

  void _onEngine(void _) {
    if (!mounted) return;
    setState(() {});
    // Nobody answered. The engine has already silenced everything; all that is
    // left is to show it happened and then get off the screen.
    if (callRingEngine.phase == CallEnginePhase.missed) {
      _missedExit ??= Timer(_missedLinger, _leaveAfterMissed);
    }
  }

  void _leaveAfterMissed() {
    if (!mounted || _handedOff) return;
    _handedOff = true;
    Navigator.of(context).pop();
  }

  Future<void> _decline() async {
    if (_handedOff) return;
    _handedOff = true;
    await callRingEngine.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _accept() async {
    if (_handedOff) return;
    _handedOff = true;
    await callRingEngine.answer();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => FakeCallScreen(preset: widget.preset),
      ),
    );
  }

  @override
  void dispose() {
    _engineSub?.cancel();
    _engineSub = null;
    _missedExit?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Belt and braces, mirroring BlackoutScreen: leaving this route must never
    // leave the ring running.
    if (!_handedOff) callRingEngine.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CallTheme theme = callThemeFor(widget.preset.themeId);

    // A tip banner popping up mid-call would give the whole thing away — this
    // screen exists to be believed.
    return TipsSuppressor(
      child: PopScope(
        // A stray back gesture must not silently kill the excuse.
        canPop: false,
        child: callRingEngine.phase == CallEnginePhase.missed
            ? CallMissedView(
                palette: theme.palette,
                name: widget.preset.name,
                avatarPath: widget.preset.avatarPath,
              )
            : theme.buildIncoming(
                CallIncomingContext(
                  name: widget.preset.name,
                  number: widget.preset.number,
                  avatarPath: widget.preset.avatarPath,
                  onAccept: _accept,
                  onDecline: _decline,
                ),
              ),
      ),
    );
  }
}
