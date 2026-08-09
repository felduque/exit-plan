import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../call_theme.dart';
import '../call_visuals.dart';

/// "Chat verde" — the messaging-app look: a deep teal ground under a tiled
/// doodle wallpaper, the name at the top rather than the middle, a silhouette
/// avatar, and one dark pill holding every in-call control instead of a grid
/// above a big red circle.
///
/// ## The name, deliberately
///
/// This theme used to be called after the messaging product it evokes, and its
/// palette class and background carried that product's name too. That is the
/// one thing in this app that could cost the developer account rather than the
/// feature: Play treats a third-party mark in a UI as impersonation, and a
/// wordmark is not something a disclaimer fixes.
///
/// So the look stays and the name goes. Nothing here reproduces anyone's
/// artwork — the wallpaper below is a generated scatter of ordinary Material
/// outline glyphs, not a traced pattern — and the palette is a colour, which
/// nobody owns. `test/branding_test.dart` keeps it that way.
///
/// Free tier: this is the theme existing users already have saved, and taking
/// it away from them to sell it back would be indefensible.
const CallTheme chatGreenTheme = CallTheme(
  id: 'chat-green',
  name: 'Green chat',
  premium: false,
  palette: _palette,
  answerGesture: CallAnswerGesture.tap,
  declineGesture: CallAnswerGesture.tap,
  buildIncoming: _buildIncoming,
  buildActive: _buildActive,
);

// One constant per colour — see the note in `classic_light.dart` for why these
// are not read back off [_palette].
const Color _base = Color(0xFF0B141A);
const Color _scrim = Color(0xCC0B141A);
const Color _text = Colors.white;
const Color _subtext = Color(0xFF8696A0);
const Color _accept = Color(0xFF25D366);
const Color _decline = Color(0xFFEA0038);

const CallPalette _palette = CallPalette(
  base: _base,
  scrim: _scrim,
  text: _text,
  subtext: _subtext,
  accept: _accept,
  decline: _decline,
);

const Color _pill = Color(0x40000000);
const Color _avatarTint = Color(0xFFCFD7DB);
const Color _avatarGlyph = Color(0xFF8696A0);

Widget _buildIncoming(CallIncomingContext ctx) {
  return Builder(
    builder: (BuildContext context) {
      final AppLocalizations loc = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: _base,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const DoodleBackground(),
            const SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: CallStatusBar(color: _text),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 34),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 40),
                    Text(
                      ctx.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.callChatGreenVoiceCall,
                      style: TextStyle(color: _subtext, fontSize: 14.5),
                    ),
                    const Spacer(),
                    CallAvatar(
                      avatarPath: ctx.avatarPath,
                      name: ctx.name,
                      diameter: 128,
                      tint: _avatarTint,
                      textColor: _avatarGlyph,
                      fallbackIcon: kSilhouetteAvatar,
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
    },
  );
}

Widget _buildActive(CallActiveContext ctx) {
  return Scaffold(
    backgroundColor: _base,
    body: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const DoodleBackground(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              children: <Widget>[
                Text(
                  ctx.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ctx.timer,
                  style: TextStyle(
                    color: _subtext,
                    fontSize: 13,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const Spacer(),
                CallAvatar(
                  avatarPath: ctx.avatarPath,
                  name: ctx.name,
                  diameter: 128,
                  tint: _avatarTint,
                  textColor: _avatarGlyph,
                  fallbackIcon: kSilhouetteAvatar,
                ),
                const Spacer(flex: 2),
                _InCallBar(
                  speaker: ctx.speaker,
                  onSpeaker: ctx.onSpeaker,
                  videoOn: ctx.videoOn,
                  onVideo: ctx.onVideo,
                  muted: ctx.muted,
                  onMute: ctx.onMute,
                  onHangUp: ctx.onHangUp,
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

/// The dark, doodle-tiled wallpaper this theme sits on. Drawn rather than
/// shipped as an image: a generic scatter of everyday outline icons evokes the
/// pattern without reproducing anyone's own artwork — the same restraint the
/// sound catalogue already applies by keeping its labels generic rather than
/// naming a real brand.
class DoodleBackground extends StatelessWidget {
  const DoodleBackground({super.key});

  static const List<IconData> _doodles = <IconData>[
    Icons.star_border,
    Icons.favorite_border,
    Icons.local_florist_outlined,
    Icons.music_note_outlined,
    Icons.cake_outlined,
    Icons.pets_outlined,
    Icons.wb_sunny_outlined,
    Icons.umbrella_outlined,
    Icons.emoji_emotions_outlined,
    Icons.local_pizza_outlined,
    Icons.beach_access_outlined,
    Icons.flight_outlined,
    Icons.camera_alt_outlined,
    Icons.headphones_outlined,
    Icons.icecream_outlined,
    Icons.directions_bike_outlined,
    Icons.local_florist,
    Icons.wb_cloudy_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: _base),
      child: CustomPaint(size: Size.infinite, painter: _DoodlePainter()),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  const _DoodlePainter();

  static const double _spacing = 58;

  @override
  void paint(Canvas canvas, Size size) {
    // A fixed seed: the tile has to look the same on every rebuild, not
    // reshuffle itself while the call is on screen.
    final math.Random rnd = math.Random(7);
    final int rows = (size.height / _spacing).ceil() + 1;
    final int cols = (size.width / _spacing).ceil() + 2;

    for (int row = 0; row < rows; row++) {
      // Brick offset per row, matching the tiled look it evokes.
      final double rowOffset = row.isOdd ? _spacing / 2 : 0;
      for (int col = 0; col < cols; col++) {
        final IconData icon = DoodleBackground
            ._doodles[(row * cols + col) % DoodleBackground._doodles.length];
        final double dx = col * _spacing + rowOffset - _spacing;
        final double dy = row * _spacing;
        final double angle = (rnd.nextDouble() - 0.5) * 0.35;
        final double glyphSize = 15 + rnd.nextDouble() * 5;

        final TextPainter tp = TextPainter(textDirection: TextDirection.ltr)
          ..text = TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: glyphSize,
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          )
          ..layout();

        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(angle);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter oldDelegate) => false;
}

/// The plainest gesture of the six: a flat tap on either circle, no drag.
class _IncomingActions extends StatelessWidget {
  const _IncomingActions({required this.onDecline, required this.onAccept});

  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 46),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          CallActionButton(
            icon: Icons.call_end_rounded,
            background: _decline,
            iconColor: Colors.white,
            onTap: onDecline,
            label: loc.callActionDecline,
            semanticLabel: loc.callActionDeclineCall,
          ),
          CallActionButton(
            icon: Icons.call_rounded,
            background: _accept,
            iconColor: Colors.white,
            onTap: onAccept,
            pulse: true,
            label: loc.callActionAccept,
            semanticLabel: loc.callActionAcceptCall,
          ),
        ],
      ),
    );
  }
}

/// One dark rounded pill holding every button — more options, video, speaker,
/// mute and, at the end, hang up — rather than a separate row of labelled
/// icons above a big red circle.
class _InCallBar extends StatelessWidget {
  const _InCallBar({
    required this.speaker,
    required this.onSpeaker,
    required this.videoOn,
    required this.onVideo,
    required this.muted,
    required this.onMute,
    required this.onHangUp,
  });

  final bool speaker;
  final VoidCallback onSpeaker;
  final bool videoOn;
  final VoidCallback onVideo;
  final bool muted;
  final VoidCallback onMute;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _pill,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _PillButton(
            icon: Icons.more_horiz,
            active: false,
            onTap: callNoop,
            semanticLabel: loc.callChatGreenMoreOptions,
          ),
          _PillButton(
            icon: Icons.videocam_rounded,
            active: videoOn,
            onTap: onVideo,
            semanticLabel: loc.callChatGreenToggleVideo,
          ),
          _PillButton(
            icon: Icons.volume_up_rounded,
            active: speaker,
            onTap: onSpeaker,
            semanticLabel: loc.callChatGreenToggleSpeaker,
          ),
          _PillButton(
            icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            active: muted,
            onTap: onMute,
            semanticLabel: loc.callChatGreenToggleMute,
          ),
          _PillButton(
            icon: Icons.call_end_rounded,
            active: false,
            background: _decline,
            onTap: onHangUp,
            semanticLabel: loc.callActionEndCall,
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.semanticLabel,
    this.background,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final Color fill =
        background ??
        (active ? Colors.white : Colors.white.withValues(alpha: 0.12));
    final Color iconColor = background != null
        ? Colors.white
        : (active ? _base : Colors.white);

    return Semantics(
      button: true,
      selected: active,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
