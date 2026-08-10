import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_boot.dart';
import '../audio/call_ring_engine.dart';
import '../models/call_preset.dart';
import '../themes/call_theme.dart';
import '../themes/call_theme_registry.dart';
import '../widgets/tip_banner.dart';
import 'call_mask_screen.dart';

/// The screen shown once a fake call has been answered: a live duration
/// timer, that theme's in-call controls (cosmetic — there is nothing real
/// underneath) and a hang-up that actually ends everything.
///
/// It also leaves on its own when the preset carries an auto-end: the engine
/// drops back to `idle` on its own clock, and this screen follows it out.
class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key, required this.preset});

  final CallPreset preset;

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  /// How long the "call ended" card stays up before the mask takes over. The
  /// same beat a real phone gives you between the last word and the home
  /// screen — except here what follows is black rather than the app.
  static const Duration _endedLinger = Duration(milliseconds: 1400);

  bool _muted = false;
  bool _speaker = false;
  bool _keypadOpen = false;
  bool _videoOn = false;
  bool _hungUp = false;

  /// The duration to show on the closing card.
  ///
  /// Cached on every tick rather than read at the end: `cancel()` resets the
  /// engine's `elapsed` to zero, so by the time the phase reaches `idle` the
  /// number this screen has been showing for the last minute is gone.
  String _lastTimer = '00:00';

  StreamSubscription<void>? _engineSub;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _engineSub = callRingEngine.changes.listen(_onEngine);
  }

  void _onEngine(void _) {
    if (!mounted) return;
    if (callRingEngine.phase == CallEnginePhase.active) {
      _lastTimer = _formatted(callRingEngine.elapsed);
    }
    setState(() {});
    // The auto-end timer hung the call up from underneath us. The engine is
    // already quiet; this screen just has to stop pretending there is a call.
    if (!_hungUp && callRingEngine.phase == CallEnginePhase.idle) {
      unawaited(_finish());
    }
  }

  Future<void> _hangUp() async {
    if (_hungUp) return;
    await callRingEngine.cancel();
    if (!mounted) return;
    await _finish();
  }

  /// The one way this screen ends, however the call got here: hold the closing
  /// card for a beat, cover everything with the mask, and only pop once the
  /// user has deliberately left it.
  ///
  /// A single `pop()` and not the old `popUntil(isFirst)`: all three endings
  /// now return the user to the screen the call was fired from, and with the
  /// mask in the stack there is nothing left worth unwinding blindly.
  Future<void> _finish() async {
    if (_hungUp) return;
    setState(() => _hungUp = true);
    await Future<void>.delayed(_endedLinger);
    if (!mounted) return;
    await showCallMask(context);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _engineSub?.cancel();
    _engineSub = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!_hungUp) callRingEngine.cancel();
    super.dispose();
  }

  static String _formatted(Duration d) {
    final String m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _timer => _formatted(callRingEngine.elapsed);

  @override
  Widget build(BuildContext context) {
    final CallTheme theme = callThemeFor(widget.preset.themeId);

    return TipsSuppressor(
      child: PopScope(
        canPop: false,
        // Same crossfade as the incoming screen, so hanging up and timing out
        // end the same way to the eye.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _hungUp
              ? CallEndView(
                  key: const ValueKey<String>('call-end'),
                  palette: theme.palette,
                  name: widget.preset.name,
                  avatarPath: widget.preset.avatarPath,
                  outcome: CallEndOutcome.ended,
                  duration: _lastTimer,
                )
              : KeyedSubtree(
                  key: const ValueKey<String>('call-active'),
                  child: theme.buildActive(
                    CallActiveContext(
                      name: widget.preset.name,
                      avatarPath: widget.preset.avatarPath,
                      timer: _timer,
                      muted: _muted,
                      speaker: _speaker,
                      keypadOpen: _keypadOpen,
                      videoOn: _videoOn,
                      onMute: () => setState(() => _muted = !_muted),
                      onSpeaker: () => setState(() => _speaker = !_speaker),
                      onKeypad: () => setState(() => _keypadOpen = !_keypadOpen),
                      onVideo: () => setState(() => _videoOn = !_videoOn),
                      onHangUp: _hangUp,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
