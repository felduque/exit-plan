import 'package:flutter/material.dart';

import '../call_theme.dart';
import '../call_visuals.dart';

/// "Clásico" — the full-bleed photo backdrop, the tall centred name and the
/// slide-to-answer circle that the most familiar phone in the world uses.
///
/// Free tier. This was `CallPlatform.ios` before the registry existed, and its
/// id is frozen at the value the migration maps that onto.
const CallTheme classicLightTheme = CallTheme(
  id: 'classic-light',
  name: 'Classic',
  premium: false,
  palette: _palette,
  answerGesture: CallAnswerGesture.dragUp,
  declineGesture: CallAnswerGesture.tap,
  buildIncoming: _buildIncoming,
  buildActive: _buildActive,
);

// Declared one per colour rather than read back off [_palette] as
// `_palette.text`. Dart will not evaluate a field access inside a `const`
// expression, and almost every label on these screens is a const TextStyle —
// so the choice is six named constants or losing const on the whole tree.
const Color _base = Color(0xFF1C1C1E);
const Color _scrim = Color(0xB3000000);
const Color _text = Colors.white;
const Color _subtext = Color(0xFFD7D7DC);
const Color _accept = Color(0xFF34C759);
const Color _decline = Color(0xFFFF3B30);

const CallPalette _palette = CallPalette(
  base: _base,
  scrim: _scrim,
  text: _text,
  subtext: _subtext,
  accept: _accept,
  decline: _decline,
);

Widget _buildIncoming(CallIncomingContext ctx) {
  return Scaffold(
    backgroundColor: _base,
    body: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CallBackdrop(
          avatarPath: ctx.avatarPath,
          name: ctx.name,
          baseColor: _base,
          scrim: _scrim,
        ),
        const SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: CallStatusBar(color: _text),
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
                    color: _subtext,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ctx.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (ctx.number.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    ctx.number,
                    style: TextStyle(color: _subtext, fontSize: 16),
                  ),
                ],
                const Spacer(flex: 2),
                _IncomingActions(
                  onDecline: ctx.onDecline,
                  onAccept: ctx.onAccept,
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildActive(CallActiveContext ctx) {
  return Scaffold(
    backgroundColor: _base,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        child: Column(
          children: <Widget>[
            const Spacer(),
            CallAvatar(
              avatarPath: ctx.avatarPath,
              name: ctx.name,
              diameter: 92,
              tint: const Color(0xFF3A3D46),
            ),
            const SizedBox(height: 18),
            Text(
              ctx.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ctx.timer,
              style: TextStyle(
                color: _subtext,
                fontSize: 15,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(flex: 2),
            _InCallGrid(
              muted: ctx.muted,
              onMute: ctx.onMute,
              speaker: ctx.speaker,
              onSpeaker: ctx.onSpeaker,
              keypadOpen: ctx.keypadOpen,
              onKeypad: ctx.onKeypad,
            ),
            const SizedBox(height: 34),
            CallActionButton(
              icon: Icons.call_end_rounded,
              background: _decline,
              iconColor: Colors.white,
              onTap: ctx.onHangUp,
              semanticLabel: 'End call',
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ),
  );
}

/// The real gesture pair: tap the red circle to decline, drag the green circle
/// upward to answer.
class _IncomingActions extends StatelessWidget {
  const _IncomingActions({required this.onDecline, required this.onAccept});

  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 46),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          CallActionButton(
            icon: Icons.call_end_rounded,
            background: _decline,
            iconColor: Colors.white,
            onTap: onDecline,
            label: 'Decline',
            semanticLabel: 'Decline call',
          ),
          DragUpToConfirm(
            onConfirm: onAccept,
            hint: 'Slide up to answer',
            child: CallActionButton(
              icon: Icons.call_rounded,
              background: _accept,
              iconColor: Colors.white,
              // The drag is the real gesture here — see DragUpToConfirm — so a
              // plain tap on the circle deliberately does nothing.
              onTap: callNoop,
              pulse: true,
              label: null,
              semanticLabel: 'Accept call',
            ),
          ),
        ],
      ),
    );
  }
}

/// The two rows of secondary actions above the hang-up button. Cosmetic —
/// there is nothing real underneath to control.
class _InCallGrid extends StatelessWidget {
  const _InCallGrid({
    required this.muted,
    required this.onMute,
    required this.speaker,
    required this.onSpeaker,
    required this.keypadOpen,
    required this.onKeypad,
  });

  final bool muted;
  final VoidCallback onMute;
  final bool speaker;
  final VoidCallback onSpeaker;
  final bool keypadOpen;
  final VoidCallback onKeypad;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CallGridButton(
              icon: muted ? Icons.mic_off_rounded : Icons.mic_off_outlined,
              label: 'mute',
              active: muted,
              onTap: onMute,
              tint: _base,
            ),
            CallGridButton(
              icon: Icons.dialpad_rounded,
              label: 'keypad',
              active: keypadOpen,
              onTap: onKeypad,
              tint: _base,
            ),
            CallGridButton(
              icon: Icons.volume_up_rounded,
              label: 'speaker',
              active: speaker,
              onTap: onSpeaker,
              tint: _base,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _StaticGridIcon(icon: Icons.add_call, label: 'add call'),
            _StaticGridIcon(icon: Icons.videocam_rounded, label: 'video'),
            _StaticGridIcon(icon: Icons.person_rounded, label: 'contacts'),
          ],
        ),
      ],
    );
  }
}

class _StaticGridIcon extends StatelessWidget {
  const _StaticGridIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x26FFFFFF),
          ),
          child: Icon(icon, size: 24, color: Colors.white70),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
