import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'call_visuals.dart';

/// WhatsApp's own call-screen palette.
abstract final class WhatsAppCallColors {
  static const Color base = Color(0xFF0B141A);
  static const Color scrim = Color(0xCC0B141A);
  static const Color accent = Color(0xFF25D366);
  static const Color decline = Color(0xFFEA0038);
  static const Color text = Colors.white;
  static const Color subtext = Color(0xFF8696A0);
  static const Color pill = Color(0x40000000);
}

/// WhatsApp's own default avatar when a contact has no photo: a plain grey
/// silhouette, not an initial.
const IconData kWhatsAppAvatarFallback = Icons.person;

/// The classic dark, doodle-tiled wallpaper behind every WhatsApp call
/// screen. Drawn rather than shipped as an image: a generic scatter of
/// everyday outline icons evokes the pattern without reproducing WhatsApp's
/// own artwork — the same restraint the rest of the app already applies to
/// system sound labels, which stay generic rather than naming a real brand.
class WhatsAppDoodleBackground extends StatelessWidget {
  const WhatsAppDoodleBackground({super.key});

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
    return DecoratedBox(
      decoration: const BoxDecoration(color: WhatsAppCallColors.base),
      child: CustomPaint(size: Size.infinite, painter: const _DoodlePainter()),
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
      // Brick offset per row, matching the tiled look of the real wallpaper.
      final double rowOffset = row.isOdd ? _spacing / 2 : 0;
      for (int col = 0; col < cols; col++) {
        final IconData icon =
            WhatsAppDoodleBackground._doodles[(row * cols + col) %
                WhatsAppDoodleBackground._doodles.length];
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

/// WhatsApp's real gesture is the plainest of the three: a flat tap on either
/// circle, no drag.
class WhatsAppIncomingActions extends StatelessWidget {
  const WhatsAppIncomingActions({
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
        children: <Widget>[
          CallActionButton(
            icon: Icons.call_end_rounded,
            background: WhatsAppCallColors.decline,
            iconColor: Colors.white,
            onTap: onDecline,
            label: 'Decline',
            semanticLabel: 'Decline call',
          ),
          CallActionButton(
            icon: Icons.call_rounded,
            background: WhatsAppCallColors.accent,
            iconColor: Colors.white,
            onTap: onAccept,
            pulse: true,
            label: 'Accept',
            semanticLabel: 'Accept call',
          ),
        ],
      ),
    );
  }
}

/// WhatsApp's in-call controls: one dark rounded pill holding every button —
/// more options, video, speaker, mute and, at the end, hang up — rather than
/// a separate row of labelled icons above a big red circle the way iOS and
/// Android lay it out.
class WhatsAppInCallBar extends StatelessWidget {
  const WhatsAppInCallBar({
    super.key,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: WhatsAppCallColors.pill,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _PillButton(
            icon: Icons.more_horiz,
            active: false,
            onTap: () {},
            semanticLabel: 'More options',
          ),
          _PillButton(
            icon: Icons.videocam_rounded,
            active: videoOn,
            onTap: onVideo,
            semanticLabel: 'Toggle video',
          ),
          _PillButton(
            icon: Icons.volume_up_rounded,
            active: speaker,
            onTap: onSpeaker,
            semanticLabel: 'Toggle speaker',
          ),
          _PillButton(
            icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            active: muted,
            onTap: onMute,
            semanticLabel: 'Toggle mute',
          ),
          _PillButton(
            icon: Icons.call_end_rounded,
            active: false,
            background: WhatsAppCallColors.decline,
            onTap: onHangUp,
            semanticLabel: 'End call',
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
        : (active ? WhatsAppCallColors.base : Colors.white);

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
