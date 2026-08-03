import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_boot.dart';
import '../models/call_preset.dart';
import '../widgets/call_themes/android_call_widgets.dart';
import '../widgets/call_themes/call_visuals.dart';
import '../widgets/call_themes/ios_call_widgets.dart';
import '../widgets/call_themes/whatsapp_call_widgets.dart';
import '../widgets/tip_banner.dart';

/// The screen shown once a fake call has been answered: a live duration
/// timer, that platform's in-call controls (cosmetic — there is nothing real
/// underneath) and a hang-up that actually ends everything.
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
    if (mounted) setState(() {});
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
        child: switch (widget.preset.platform) {
          CallPlatform.ios => _IosInCall(
            preset: widget.preset,
            timer: _timer,
            muted: _muted,
            speaker: _speaker,
            keypadOpen: _keypadOpen,
            onMute: () => setState(() => _muted = !_muted),
            onSpeaker: () => setState(() => _speaker = !_speaker),
            onKeypad: () => setState(() => _keypadOpen = !_keypadOpen),
            onHangUp: _hangUp,
          ),
          CallPlatform.android => _AndroidInCall(
            preset: widget.preset,
            timer: _timer,
            muted: _muted,
            speaker: _speaker,
            keypadOpen: _keypadOpen,
            onMute: () => setState(() => _muted = !_muted),
            onSpeaker: () => setState(() => _speaker = !_speaker),
            onKeypad: () => setState(() => _keypadOpen = !_keypadOpen),
            onHangUp: _hangUp,
          ),
          CallPlatform.whatsapp => _WhatsAppInCall(
            preset: widget.preset,
            timer: _timer,
            muted: _muted,
            speaker: _speaker,
            videoOn: _videoOn,
            onMute: () => setState(() => _muted = !_muted),
            onSpeaker: () => setState(() => _speaker = !_speaker),
            onVideo: () => setState(() => _videoOn = !_videoOn),
            onHangUp: _hangUp,
          ),
        },
      ),
    );
  }
}

class _IosInCall extends StatelessWidget {
  const _IosInCall({
    required this.preset,
    required this.timer,
    required this.muted,
    required this.speaker,
    required this.keypadOpen,
    required this.onMute,
    required this.onSpeaker,
    required this.onKeypad,
    required this.onHangUp,
  });

  final CallPreset preset;
  final String timer;
  final bool muted;
  final bool speaker;
  final bool keypadOpen;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onKeypad;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IosCallColors.base,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          child: Column(
            children: <Widget>[
              const Spacer(),
              CallAvatar(
                avatarPath: preset.avatarPath,
                name: preset.name,
                diameter: 92,
                tint: const Color(0xFF3A3D46),
              ),
              const SizedBox(height: 18),
              Text(
                preset.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: IosCallColors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timer,
                style: const TextStyle(
                  color: IosCallColors.subtext,
                  fontSize: 15,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(flex: 2),
              IosInCallGrid(
                muted: muted,
                onMute: onMute,
                speaker: speaker,
                onSpeaker: onSpeaker,
                keypadOpen: keypadOpen,
                onKeypad: onKeypad,
              ),
              const SizedBox(height: 34),
              CallActionButton(
                icon: Icons.call_end_rounded,
                background: IosCallColors.decline,
                iconColor: Colors.white,
                onTap: onHangUp,
                semanticLabel: 'End call',
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _AndroidInCall extends StatelessWidget {
  const _AndroidInCall({
    required this.preset,
    required this.timer,
    required this.muted,
    required this.speaker,
    required this.keypadOpen,
    required this.onMute,
    required this.onSpeaker,
    required this.onKeypad,
    required this.onHangUp,
  });

  final CallPreset preset;
  final String timer;
  final bool muted;
  final bool speaker;
  final bool keypadOpen;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onKeypad;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndroidCallColors.base,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          child: Column(
            children: <Widget>[
              const Spacer(),
              CallAvatar(
                avatarPath: preset.avatarPath,
                name: preset.name,
                diameter: 96,
                tint: const Color(0xFF3C4043),
              ),
              const SizedBox(height: 18),
              Text(
                preset.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AndroidCallColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timer,
                style: TextStyle(
                  color: AndroidCallColors.subtext,
                  fontSize: 15,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              AndroidInCallGrid(
                muted: muted,
                onMute: onMute,
                speaker: speaker,
                onSpeaker: onSpeaker,
                keypadOpen: keypadOpen,
                onKeypad: onKeypad,
              ),
              const SizedBox(height: 30),
              CallActionButton(
                icon: Icons.call_end_rounded,
                background: AndroidCallColors.decline,
                iconColor: Colors.white,
                onTap: onHangUp,
                semanticLabel: 'End call',
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppInCall extends StatelessWidget {
  const _WhatsAppInCall({
    required this.preset,
    required this.timer,
    required this.muted,
    required this.speaker,
    required this.videoOn,
    required this.onMute,
    required this.onSpeaker,
    required this.onVideo,
    required this.onHangUp,
  });

  final CallPreset preset;
  final String timer;
  final bool muted;
  final bool speaker;
  final bool videoOn;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onVideo;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WhatsAppCallColors.base,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const WhatsAppDoodleBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                children: <Widget>[
                  Text(
                    preset.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WhatsAppCallColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timer,
                    style: TextStyle(
                      color: WhatsAppCallColors.subtext,
                      fontSize: 13,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const Spacer(),
                  CallAvatar(
                    avatarPath: preset.avatarPath,
                    name: preset.name,
                    diameter: 128,
                    tint: const Color(0xFFCFD7DB),
                    textColor: const Color(0xFF8696A0),
                    fallbackIcon: kWhatsAppAvatarFallback,
                  ),
                  const Spacer(flex: 2),
                  WhatsAppInCallBar(
                    speaker: speaker,
                    onSpeaker: onSpeaker,
                    videoOn: videoOn,
                    onVideo: onVideo,
                    muted: muted,
                    onMute: onMute,
                    onHangUp: onHangUp,
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
