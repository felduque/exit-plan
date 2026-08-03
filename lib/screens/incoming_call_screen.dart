import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_boot.dart';
import '../models/call_preset.dart';
import '../models/escape_sound.dart';
import '../state/app_state.dart';
import '../widgets/call_themes/android_call_widgets.dart';
import '../widgets/call_themes/call_visuals.dart';
import '../widgets/call_themes/ios_call_widgets.dart';
import '../widgets/call_themes/whatsapp_call_widgets.dart';
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
/// look like iOS, Android or WhatsApp, not like ExitPlan.
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key, required this.preset});

  final CallPreset preset;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _handedOff = false;
  StreamSubscription<void>? _engineSub;

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
    await callRingEngine.arm(sound, delaySeconds: widget.preset.delaySeconds);
  }

  void _onEngine(void _) {
    if (mounted) setState(() {});
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Belt and braces, mirroring BlackoutScreen: leaving this route must never
    // leave the ring running.
    if (!_handedOff) callRingEngine.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A tip banner popping up mid-call would give the whole thing away — this
    // screen exists to be believed.
    return TipsSuppressor(
      child: PopScope(
        // A stray back gesture must not silently kill the excuse.
        canPop: false,
        child: switch (widget.preset.platform) {
          CallPlatform.ios => _IosIncoming(
            preset: widget.preset,
            onDecline: _decline,
            onAccept: _accept,
          ),
          CallPlatform.android => _AndroidIncoming(
            preset: widget.preset,
            onDecline: _decline,
            onAccept: _accept,
          ),
          CallPlatform.whatsapp => _WhatsAppIncoming(
            preset: widget.preset,
            onDecline: _decline,
            onAccept: _accept,
          ),
        },
      ),
    );
  }
}

class _IosIncoming extends StatelessWidget {
  const _IosIncoming({
    required this.preset,
    required this.onDecline,
    required this.onAccept,
  });

  final CallPreset preset;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IosCallColors.base,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CallBackdrop(
            avatarPath: preset.avatarPath,
            name: preset.name,
            baseColor: IosCallColors.base,
            scrim: IosCallColors.scrim,
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: CallStatusBar(color: IosCallColors.text),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  Text(
                    'incoming call',
                    style: TextStyle(
                      color: IosCallColors.subtext,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    preset.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: IosCallColors.text,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (preset.number.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      preset.number,
                      style: TextStyle(
                        color: IosCallColors.subtext,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const Spacer(flex: 2),
                  IosIncomingActions(onDecline: onDecline, onAccept: onAccept),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AndroidIncoming extends StatelessWidget {
  const _AndroidIncoming({
    required this.preset,
    required this.onDecline,
    required this.onAccept,
  });

  final CallPreset preset;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndroidCallColors.base,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CallBackdrop(
            avatarPath: preset.avatarPath,
            name: preset.name,
            baseColor: AndroidCallColors.base,
            scrim: AndroidCallColors.scrim,
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: CallStatusBar(color: AndroidCallColors.text),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 34),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 26),
                  Text(
                    'Incoming call',
                    style: TextStyle(
                      color: AndroidCallColors.subtext,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  CallAvatar(
                    avatarPath: preset.avatarPath,
                    name: preset.name,
                    diameter: 118,
                    tint: const Color(0xFF3C4043),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    preset.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AndroidCallColors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (preset.number.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      preset.number,
                      style: TextStyle(
                        color: AndroidCallColors.subtext,
                        fontSize: 15,
                      ),
                    ),
                  ],
                  const Spacer(flex: 2),
                  AndroidIncomingActions(
                    onDecline: onDecline,
                    onAccept: onAccept,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppIncoming extends StatelessWidget {
  const _WhatsAppIncoming({
    required this.preset,
    required this.onDecline,
    required this.onAccept,
  });

  final CallPreset preset;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WhatsAppCallColors.base,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const WhatsAppDoodleBackground(),
          const SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: CallStatusBar(color: WhatsAppCallColors.text),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 34),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 40),
                  Text(
                    preset.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WhatsAppCallColors.text,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'WhatsApp voice call…',
                    style: TextStyle(
                      color: WhatsAppCallColors.subtext,
                      fontSize: 14.5,
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
                  WhatsAppIncomingActions(
                    onDecline: onDecline,
                    onAccept: onAccept,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
