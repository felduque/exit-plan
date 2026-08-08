import 'package:flutter/material.dart';

import '../call_theme.dart';
import '../call_visuals.dart';

/// "Minimal" — near-black, no photo backdrop, no avatar, no chrome. Just the
/// name in a large light weight, a hairline, and two circles.
///
/// The point of this one is discretion rather than mimicry: it is the theme for
/// someone who wants a call screen that reveals nothing about which phone or
/// which app is drawing it, and it is the only theme here that would not look
/// out of place if somebody glanced at it side-on.
///
/// Premium.
const CallTheme minimalDarkTheme = CallTheme(
  id: 'minimal-dark',
  name: 'Minimal',
  premium: true,
  palette: _palette,
  answerGesture: CallAnswerGesture.dragUp,
  declineGesture: CallAnswerGesture.tap,
  buildIncoming: _buildIncoming,
  buildActive: _buildActive,
);

// One constant per colour — see the note in `classic_light.dart` for why these
// are not read back off [_palette].
const Color _base = Color(0xFF0A0A0B);
const Color _scrim = Color(0xE6000000);
const Color _text = Color(0xFFF2F2F4);
const Color _subtext = Color(0xFF6E7179);
const Color _accept = Color(0xFF3FA46F);
const Color _decline = Color(0xFF9E3B34);

const CallPalette _palette = CallPalette(
  base: _base,
  scrim: _scrim,
  text: _text,
  subtext: _subtext,
  accept: _accept,
  decline: _decline,
);

/// The hairline this theme uses instead of a card edge or a scrim.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 1,
      color: _subtext.withValues(alpha: 0.4),
    );
  }
}

Widget _buildIncoming(CallIncomingContext ctx) {
  return Scaffold(
    backgroundColor: _base,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          children: <Widget>[
            const CallStatusBar(color: _subtext),
            const Spacer(),
            Text(
              'Incoming',
              style: TextStyle(
                color: _subtext,
                fontSize: 12,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              ctx.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 36,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.5,
              ),
            ),
            if (ctx.number.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              const _Rule(),
              const SizedBox(height: 14),
              Text(
                ctx.number,
                style: TextStyle(
                  color: _subtext,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                CallActionButton(
                  icon: Icons.close_rounded,
                  background: _decline,
                  iconColor: Colors.white,
                  onTap: ctx.onDecline,
                  size: 58,
                  iconSize: 24,
                  semanticLabel: 'Decline call',
                ),
                DragUpToConfirm(
                  onConfirm: ctx.onAccept,
                  hint: 'Slide up',
                  hintColor: _subtext,
                  // This theme's circles are smaller than the default, so the
                  // hint has to be told the narrower footprint to stay bounded
                  // by the thing it labels.
                  width: 58 * 1.6,
                  child: CallActionButton(
                    icon: Icons.call_rounded,
                    background: _accept,
                    iconColor: Colors.white,
                    onTap: callNoop,
                    size: 58,
                    iconSize: 24,
                    pulse: true,
                    semanticLabel: 'Accept call',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

Widget _buildActive(CallActiveContext ctx) {
  return Scaffold(
    backgroundColor: _base,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          children: <Widget>[
            const Spacer(),
            Text(
              ctx.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            const _Rule(),
            const SizedBox(height: 14),
            Text(
              ctx.timer,
              style: TextStyle(
                color: _subtext,
                fontSize: 15,
                letterSpacing: 2,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CallGridButton(
                  icon: ctx.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: 'mute',
                  active: ctx.muted,
                  onTap: ctx.onMute,
                  tint: _base,
                  inactiveBackground: const Color(0x14FFFFFF),
                ),
                CallGridButton(
                  icon: Icons.dialpad_rounded,
                  label: 'keypad',
                  active: ctx.keypadOpen,
                  onTap: ctx.onKeypad,
                  tint: _base,
                  inactiveBackground: const Color(0x14FFFFFF),
                ),
                CallGridButton(
                  icon: Icons.volume_up_rounded,
                  label: 'speaker',
                  active: ctx.speaker,
                  onTap: ctx.onSpeaker,
                  tint: _base,
                  inactiveBackground: const Color(0x14FFFFFF),
                ),
              ],
            ),
            const SizedBox(height: 30),
            CallActionButton(
              icon: Icons.call_end_rounded,
              background: _decline,
              iconColor: Colors.white,
              onTap: ctx.onHangUp,
              size: 58,
              iconSize: 24,
              semanticLabel: 'End call',
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ),
  );
}
