import 'package:flutter/material.dart';

import 'call_visuals.dart';

/// The palette stock Android's own dialer/incoming-call surface uses.
abstract final class AndroidCallColors {
  static const Color scrim = Color(0xCC000000);
  static const Color base = Color(0xFF202124);
  static const Color decline = Color(0xFFE8483A);
  static const Color accept = Color(0xFF1EA562);
  static const Color text = Colors.white;
  static const Color subtext = Color(0xFFBDC1C6);
}

/// Stock Android's real gesture: both the decline and accept circles are
/// dragged upward past a threshold — there is no plain tap target, dragging
/// is the whole interaction.
class AndroidIncomingActions extends StatelessWidget {
  const AndroidIncomingActions({
    super.key,
    required this.onDecline,
    required this.onAccept,
  });

  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          DragUpToConfirm(
            onConfirm: onDecline,
            hint: 'Swipe up to decline',
            child: CallActionButton(
              icon: Icons.call_end_rounded,
              background: AndroidCallColors.decline,
              iconColor: Colors.white,
              // Stock Android's gesture is drag-only — a plain tap here does
              // nothing, the drag reaching the threshold is what fires.
              onTap: () {},
              semanticLabel: 'Decline call',
            ),
          ),
          DragUpToConfirm(
            onConfirm: onAccept,
            hint: 'Swipe up to answer',
            child: CallActionButton(
              icon: Icons.call_rounded,
              background: AndroidCallColors.accept,
              iconColor: Colors.white,
              onTap: () {},
              pulse: true,
              semanticLabel: 'Accept call',
            ),
          ),
        ],
      ),
    );
  }
}

/// The in-call button row Android's own Phone app shows above hang-up: mute,
/// keypad, speaker. Cosmetic, same as the iOS grid.
class AndroidInCallGrid extends StatelessWidget {
  const AndroidInCallGrid({
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        CallGridButton(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: 'Mute',
          active: muted,
          onTap: onMute,
          tint: AndroidCallColors.base,
        ),
        CallGridButton(
          icon: Icons.dialpad_rounded,
          label: 'Keypad',
          active: keypadOpen,
          onTap: onKeypad,
          tint: AndroidCallColors.base,
        ),
        CallGridButton(
          icon: Icons.volume_up_rounded,
          label: 'Speaker',
          active: speaker,
          onTap: onSpeaker,
          tint: AndroidCallColors.base,
        ),
      ],
    );
  }
}
