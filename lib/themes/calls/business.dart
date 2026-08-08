import 'package:flutter/material.dart';

import '../call_theme.dart';
import '../call_visuals.dart';

/// "Trabajo" — the call that gets somebody out of a personal situation rather
/// than a professional one: a slate-blue conference surface, a monogram tile
/// instead of a photo, and a `WORK` badge above the name.
///
/// The `number` field is repurposed here as the organisation line, which is why
/// this theme labels it rather than showing it bare — "Regional office" under
/// "Sandra Ruiz" reads as a real work call in a way a phone number does not.
/// Nothing about the model changes; only what this theme does with the field it
/// is handed.
///
/// Premium.
const CallTheme businessTheme = CallTheme(
  id: 'business',
  name: 'Work',
  premium: true,
  palette: _palette,
  answerGesture: CallAnswerGesture.tap,
  declineGesture: CallAnswerGesture.tap,
  buildIncoming: _buildIncoming,
  buildActive: _buildActive,
);

// One constant per colour — see the note in `classic_light.dart` for why these
// are not read back off [_palette].
const Color _base = Color(0xFF161B22);
const Color _scrim = Color(0xD1161B22);
const Color _text = Color(0xFFF0F3F7);
const Color _subtext = Color(0xFF8B95A5);
const Color _accept = Color(0xFF2D8A6B);
const Color _decline = Color(0xFFC4453C);

const CallPalette _palette = CallPalette(
  base: _base,
  scrim: _scrim,
  text: _text,
  subtext: _subtext,
  accept: _accept,
  decline: _decline,
);

const Color _tile = Color(0xFF232B36);
const Color _badge = Color(0xFF3D6FA8);

/// The squared monogram this theme shows in place of a round photo. Falls back
/// to the caller's initial the same way [CallAvatar] does, but keeps the
/// corporate-directory shape.
class _Monogram extends StatelessWidget {
  const _Monogram({
    required this.avatarPath,
    required this.name,
    required this.size,
  });

  final String? avatarPath;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.16),
      child: CallAvatar(
        avatarPath: avatarPath,
        name: name,
        diameter: size,
        tint: _tile,
        textColor: _text,
      ),
    );
  }
}

class _WorkBadge extends StatelessWidget {
  const _WorkBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _badge.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _badge.withValues(alpha: 0.45)),
      ),
      child: const Text(
        'WORK',
        style: TextStyle(
          color: Color(0xFF9CC0EA),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

Widget _buildIncoming(CallIncomingContext ctx) {
  return Scaffold(
    backgroundColor: _base,
    body: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF1D2530), Color(0xFF12161C)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        const SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: CallStatusBar(color: _subtext),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 34),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 34),
                const _WorkBadge(),
                const Spacer(),
                _Monogram(
                  avatarPath: ctx.avatarPath,
                  name: ctx.name,
                  size: 112,
                ),
                const SizedBox(height: 22),
                Text(
                  ctx.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  ctx.number.isEmpty ? 'Incoming call' : ctx.number,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _subtext, fontSize: 14.5),
                ),
                const Spacer(flex: 2),
                _IncomingActions(
                  onDecline: ctx.onDecline,
                  onAccept: ctx.onAccept,
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

Widget _buildActive(CallActiveContext ctx) {
  return Scaffold(
    backgroundColor: _base,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
        child: Column(
          children: <Widget>[
            const Spacer(),
            _Monogram(avatarPath: ctx.avatarPath, name: ctx.name, size: 88),
            const SizedBox(height: 18),
            Text(
              ctx.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ctx.timer,
              style: TextStyle(
                color: _subtext,
                fontSize: 14.5,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CallGridButton(
                  icon: ctx.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: 'Mute',
                  active: ctx.muted,
                  onTap: ctx.onMute,
                  tint: _base,
                  inactiveBackground: _tile,
                ),
                CallGridButton(
                  icon: Icons.dialpad_rounded,
                  label: 'Keypad',
                  active: ctx.keypadOpen,
                  onTap: ctx.onKeypad,
                  tint: _base,
                  inactiveBackground: _tile,
                ),
                CallGridButton(
                  icon: Icons.volume_up_rounded,
                  label: 'Speaker',
                  active: ctx.speaker,
                  onTap: ctx.onSpeaker,
                  tint: _base,
                  inactiveBackground: _tile,
                ),
              ],
            ),
            const SizedBox(height: 28),
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

class _IncomingActions extends StatelessWidget {
  const _IncomingActions({required this.onDecline, required this.onAccept});

  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          CallActionButton(
            icon: Icons.call_end_rounded,
            background: _decline,
            iconColor: Colors.white,
            onTap: onDecline,
            label: 'Decline',
            labelColor: _subtext,
            semanticLabel: 'Decline call',
          ),
          CallActionButton(
            icon: Icons.call_rounded,
            background: _accept,
            iconColor: Colors.white,
            onTap: onAccept,
            pulse: true,
            label: 'Answer',
            labelColor: _subtext,
            semanticLabel: 'Accept call',
          ),
        ],
      ),
    );
  }
}
