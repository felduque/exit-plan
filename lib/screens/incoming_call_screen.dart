import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_boot.dart';
import '../audio/call_ring_engine.dart';
import '../calls/call_dispatcher.dart';
import '../models/call_preset.dart';
import '../models/escape_sound.dart';
import '../state/app_state.dart';
import '../themes/call_theme.dart';
import '../themes/call_theme_registry.dart';
import '../widgets/tip_banner.dart';
import 'call_mask_screen.dart';
import 'fake_call_screen.dart';

/// Arms [preset] and pushes the full-screen incoming-call UI. Every fake call
/// in the app starts here — no screen rings the phone itself.
///
/// When [fromNotification] is true, the system notification is already ringing
/// the device's own ringtone, so the app's own tone and vibration stay off.
Future<void> fireCall(
  BuildContext context,
  CallPreset preset, {
  bool fromNotification = false,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => IncomingCallScreen(
        preset: preset,
        fromNotification: fromNotification,
      ),
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
  const IncomingCallScreen({
    super.key,
    required this.preset,
    this.fromNotification = false,
  });

  final CallPreset preset;

  /// True when the call arrived through the system notification. The app must
  /// not add its own ringtone on top of the one the system is already playing.
  final bool fromNotification;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

/// What this screen is doing, independently of what the engine is doing.
///
/// The engine knows about sound; this knows about the story being told. They
/// used to be the same variable, which is why the missed notice and the exit
/// were tangled together in the engine listener.
enum _Stage {
  /// The phone is ringing — first time round, or the one retry.
  ringing,

  /// The call is over and the closing card is up. Nothing is ringing.
  ended,

  /// The mask is on its way up; this route is only waiting to pop.
  leaving,
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  /// How long the missed-call notice stays up. Long enough to read, short
  /// enough that a phone left on a table does not sit there advertising a call
  /// that never happened — and it no longer has to cover the exit as well,
  /// since the mask does that now.
  static const Duration _missedLinger = Duration(seconds: 2);

  /// Shorter than [_missedLinger]: declining is the user's own doing, so there
  /// is nothing to tell them. The card is only there so the screen does not
  /// cut to black on the same frame as the tap.
  static const Duration _declinedLinger = Duration(milliseconds: 1200);

  /// The pause between giving up and ringing again, when the preset asks for a
  /// retry. Someone redialling does not do it instantly.
  static const Duration _retryGap = Duration(seconds: 3);

  _Stage _stage = _Stage.ringing;
  CallEndOutcome _outcome = CallEndOutcome.missed;

  /// True once the one permitted retry has been spent. A fake call that rang
  /// forever would stop being an excuse and start being a problem.
  bool _retried = false;

  /// Set only when the call is answered: from there on the engine belongs to
  /// [FakeCallScreen] and this route must not stop it on the way out.
  bool _answered = false;

  StreamSubscription<void>? _engineSub;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _engineSub = callRingEngine.changes.listen(_onEngine);
    WidgetsBinding.instance.addPostFrameCallback((_) => _arm());
  }

  /// [retry] is the second ring of a preset that asks to be called back.
  ///
  /// It matters here because the notification's own ringtone is a first-arrival
  /// thing: by the time this rings again there is no system sound to double up
  /// with, so the retry always uses the preset's tone even when the first ring
  /// deliberately did not.
  Future<void> _arm({bool retry = false}) async {
    // The two engines must never sound at once.
    await fireEngine.cancel();
    if (!mounted) return;

    final bool coveredByNotification = widget.fromNotification && !retry;

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
      // If the system notification brought the user here, that notification is
      // already ringing the device's own ringtone. Adding the preset tone on
      // top is the double-ring bug.
      vibrate: widget.preset.vibrate && !coveredByNotification,
      playSound: !coveredByNotification,
    );
  }

  void _onEngine(void _) {
    if (!mounted) return;
    setState(() {});
    // Nobody answered. The engine has already silenced everything; all that is
    // left is to decide whether this call insists once more or gives up.
    if (_stage == _Stage.ringing &&
        callRingEngine.phase == CallEnginePhase.missed) {
      unawaited(_onMissed());
    }
  }

  /// The ring timed out. Show it happened, then either ring again or hand over
  /// to the mask.
  Future<void> _onMissed() async {
    setState(() {
      _stage = _Stage.ended;
      _outcome = CallEndOutcome.missed;
    });
    await Future<void>.delayed(_missedLinger);
    // Anything the user did in the meantime — declining is impossible here,
    // but a pop from outside is not — wins over the rest of this.
    if (!mounted || _stage != _Stage.ended) return;

    if (widget.preset.retryOnMissed && !_retried) {
      _retried = true;
      await Future<void>.delayed(_retryGap);
      if (!mounted || _stage != _Stage.ended) return;
      setState(() => _stage = _Stage.ringing);
      await _arm(retry: true);
      return;
    }

    await _leave();
  }

  Future<void> _decline() async {
    if (_stage != _Stage.ringing) return;
    setState(() {
      _stage = _Stage.ended;
      _outcome = CallEndOutcome.declined;
    });
    await callRingEngine.cancel();
    await _clearNotificationIfNeeded();
    await Future<void>.delayed(_declinedLinger);
    if (!mounted) return;
    await _leave();
  }

  /// The single way out of a call that was not answered.
  ///
  /// The mask goes **on top** of this route rather than replacing it, and this
  /// route pops only once the user has held their way out of the mask — which
  /// is what keeps `CallLaunchRouter`'s lock-screen window alive for the whole
  /// sequence. See [showCallMask].
  Future<void> _leave() async {
    if (_stage == _Stage.leaving) return;
    _stage = _Stage.leaving;
    await showCallMask(context);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _accept() async {
    if (_stage != _Stage.ringing) return;
    _stage = _Stage.leaving;
    _answered = true;
    await callRingEngine.answer();
    await _clearNotificationIfNeeded();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => FakeCallScreen(preset: widget.preset),
      ),
    );
  }

  /// When the call arrived through the system notification, the notification is
  /// what is ringing the device. Cancelling it here guarantees the ring stops
  /// the instant the user acts, rather than lingering for a few seconds.
  Future<void> _clearNotificationIfNeeded() async {
    if (!widget.fromNotification) return;
    await CallDispatcher.unschedule(widget.preset.id);
  }

  @override
  void dispose() {
    _engineSub?.cancel();
    _engineSub = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Belt and braces, mirroring BlackoutScreen: leaving this route must never
    // leave the ring running. An answered call is the one exception — the
    // engine is running the timer FakeCallScreen displays.
    if (!_answered) callRingEngine.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CallTheme theme = callThemeFor(widget.preset.themeId);
    final bool over = _stage != _Stage.ringing;

    // A tip banner popping up mid-call would give the whole thing away — this
    // screen exists to be believed.
    return TipsSuppressor(
      child: PopScope(
        // A stray back gesture must not silently kill the excuse.
        canPop: false,
        // Ringing and over are two different moments, not two frames of the
        // same one: crossfading them is what makes the timeout read as a call
        // giving up rather than as a screen being swapped.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: over
              ? CallEndView(
                  key: const ValueKey<String>('call-end'),
                  palette: theme.palette,
                  name: widget.preset.name,
                  avatarPath: widget.preset.avatarPath,
                  outcome: _outcome,
                )
              : KeyedSubtree(
                  key: const ValueKey<String>('call-ringing'),
                  child: theme.buildIncoming(
                    CallIncomingContext(
                      name: widget.preset.name,
                      number: widget.preset.number,
                      avatarPath: widget.preset.avatarPath,
                      onAccept: _accept,
                      onDecline: _decline,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
