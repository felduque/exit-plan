import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_boot.dart';
import '../audio/call_ring_engine.dart';
import '../models/call_preset.dart';
import '../themes/call_theme.dart';
import '../themes/call_theme_registry.dart';
import '../widgets/tip_banner.dart';

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
  bool _muted = false;
  bool _speaker = false;
  bool _keypadOpen = false;
  bool _videoOn = false;
  bool _hungUp = false;
  StreamSubscription<void>? _engineSub;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _engineSub = callRingEngine.changes.listen(_onEngine);
  }

  void _onEngine(void _) {
    if (!mounted) return;
    setState(() {});
    // The auto-end timer hung the call up from underneath us. The engine is
    // already quiet; this screen just has to stop pretending there is a call.
    if (!_hungUp && callRingEngine.phase == CallEnginePhase.idle) {
      _hungUp = true;
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }
  }

  Future<void> _hangUp() async {
    if (_hungUp) return;
    _hungUp = true;
    await callRingEngine.cancel();
    if (!mounted) return;
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  void dispose() {
    _engineSub?.cancel();
    _engineSub = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!_hungUp) callRingEngine.cancel();
    super.dispose();
  }

  String get _timer {
    final Duration d = callRingEngine.elapsed;
    final String m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return TipsSuppressor(
      child: PopScope(
        canPop: false,
        child: callThemeFor(widget.preset.themeId).buildActive(
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
    );
  }
}
