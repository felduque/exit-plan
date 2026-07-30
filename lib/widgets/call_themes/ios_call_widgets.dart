import 'package:flutter/material.dart';

import 'call_visuals.dart';

/// The palette and iconography a real iOS incoming/in-call screen uses. Kept
/// separate from the rest of the app's own theme on purpose.
abstract final class IosCallColors {
  static const Color scrim = Color(0xB3000000);
  static const Color base = Color(0xFF1C1C1E);
  static const Color decline = Color(0xFFFF3B30);
  static const Color accept = Color(0xFF34C759);
  static const Color text = Colors.white;
  static const Color subtext = Color(0xFFD7D7DC);
}

/// iOS's real gesture pair on a full-screen incoming call: tap the red circle
/// to decline, drag the green circle upward to answer.
class IosIncomingActions extends StatelessWidget {
  const IosIncomingActions({
    super.key,
    required this.onDecline,
    required this.onAccept,
  });

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
            background: IosCallColors.decline,
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
              background: IosCallColors.accept,
              iconColor: Colors.white,
              // The drag is the real gesture here — see DragUpToConfirm above
              // — so a plain tap on the circle deliberately does nothing.
              onTap: () {},
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

/// The two rows of secondary actions above the hang-up button on iOS's in-call
/// screen: mute / keypad / speaker, then add call / FaceTime / contacts.
/// Cosmetic — there is nothing real underneath to control.
class IosInCallGrid extends StatelessWidget {
  const IosInCallGrid({
    super.key,
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
              tint: IosCallColors.base,
            ),
            CallGridButton(
              icon: Icons.dialpad_rounded,
              label: 'keypad',
              active: keypadOpen,
              onTap: onKeypad,
              tint: IosCallColors.base,
            ),
            CallGridButton(
              icon: Icons.volume_up_rounded,
              label: 'speaker',
              active: speaker,
              onTap: onSpeaker,
              tint: IosCallColors.base,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _StaticGridIcon(icon: Icons.add_call, label: 'add call'),
            _StaticGridIcon(icon: Icons.videocam_rounded, label: 'FaceTime'),
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
