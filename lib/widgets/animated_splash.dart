import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Short brand animation over the app, mounted as an overlay rather than a
/// route so nothing underneath needs a guard.
///
/// The scene is the door, and this time the camera does not watch it from the
/// room — it goes through it. The panel swings, the warm light behind it is
/// already on, and then the doorway rushes at the viewer until the opening is
/// the whole screen, blows out to warm white, and falls back to black with the
/// wordmark. The product in one shot: you were in the room, now you are not.
///
/// Two rules: it respects the system's reduce-motion setting, and it can never
/// trap the user — a safety timer forces it away even if the animation never
/// reports that it finished.
class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key, required this.onDone});

  static const Duration animation = Duration(milliseconds: 3300);
  static const Duration safetyTimeout = Duration(milliseconds: 4300);

  final VoidCallback onDone;

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AnimatedSplash.animation,
  );

  Timer? _safety;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _safety = Timer(AnimatedSplash.safetyTimeout, _finish);
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      // The last frame of this storyboard is already the static brand screen:
      // black, wordmark, tagline. Nothing to substitute.
      _controller.value = 1;
      _finish();
    } else {
      _controller.forward();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _safety?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _safety?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // How far the doorway has to grow before its opening covers the screen
        // from where it sits. Measured rather than guessed: on a short, wide
        // screen the limit is horizontal, on a tall one it is vertical, and a
        // fixed number would leave black corners on one of them.
        final double cx = constraints.maxWidth / 2;
        final double cy = constraints.maxHeight * (1 + _kDoorY) / 2;
        final double cover = math.max(
          math.max(cx, constraints.maxWidth - cx) / (_Doorway.frameW / 2),
          math.max(cy, constraints.maxHeight - cy) / (_Doorway.frameH / 2),
        );

        return AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) {
            final double t = _controller.value;
            final double push = _seg(t, 0.24, 0.74, _kPushCurve);
            // The stage is pulled out from under the flash while the flash is
            // at full brightness, so what the blowout clears to is the black
            // the app itself starts on — not a screen-filling slab of amber.
            final double stage = 1 - _seg(t, 0.58, 0.76, Curves.easeIn);

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const ColoredBox(color: ExitColors.bg),
                Align(
                  alignment: const Alignment(0, _kDoorY),
                  child: Opacity(
                    opacity: stage,
                    child: Transform.scale(
                      scale: 1 + (cover - 1) * push,
                      child: _Doorway(
                        open: _seg(t, 0.06, 0.34, _kDoorCurve),
                        light: _seg(t, 0.08, 0.24, Curves.easeOut),
                        // The frame is the room's edge, and the room is behind
                        // us by the time it would be scaled into a slab.
                        frame: 1 - _seg(t, 0.34, 0.58, Curves.easeIn),
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: _flash(_seg(t, 0.42, 0.85, Curves.linear)),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, _kDoorY),
                        radius: 0.95,
                        colors: <Color>[
                          Color(0xFFFFE7BC),
                          ExitColors.amber,
                          ExitColors.bg,
                        ],
                        stops: <double>[0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _Wipe(
                        value: _seg(t, 0.70, 0.90, _kDoorCurve),
                        child: Text(
                          'EXITPLAN',
                          style: sans(25, weight: 600, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Rise(
                        value: _seg(t, 0.80, 0.97, Curves.easeOut),
                        child: Text(
                          'THERE IS ALWAYS A WAY OUT',
                          style: mono(9, color: ExitColors.dim, letterSpacing: 2),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 26),
                    child: Opacity(
                      opacity: _seg(t, 0.84, 1, Curves.easeOut),
                      child: Text(
                        // Was "100% OFFLINE · NO ACCOUNTS" until the TikTok
                        // Events SDK made the unqualified claim untrue. What it
                        // now says is the part that is still exactly true, and
                        // is the part users actually care about; Settings
                        // carries the full note.
                        'YOUR SOUNDS · 100% OFFLINE',
                        style: mono(8, color: ExitColors.dim, letterSpacing: 3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Where the doorway sits vertically, as a [Alignment] y — a little above
/// centre, which is both where a door reads as standing and the point the push
/// travels towards.
const double _kDoorY = -0.25;

/// The swing: fast off the mark, settling rather than stopping.
const Cubic _kDoorCurve = Cubic(0.22, 1, 0.36, 1);

/// The camera move: eases in so the first step is a lean rather than a lurch,
/// and eases out so it arrives instead of slamming.
const Cubic _kPushCurve = Cubic(0.65, 0, 0.35, 1);

/// Maps the controller's 0→1 onto one leg of the storyboard.
double _seg(double t, double start, double end, Curve curve) {
  return curve.transform(((t - start) / (end - start)).clamp(0.0, 1.0));
}

/// The blowout: up fast, down slow, peaking at just under half its span.
double _flash(double t) {
  if (t <= 0 || t >= 1) return 0;
  const double peak = 0.38;
  return t < peak
      ? Curves.easeOut.transform(t / peak)
      : Curves.easeInOut.transform(1 - (t - peak) / (1 - peak));
}

/// Fade up from 12px below.
class _Rise extends StatelessWidget {
  const _Rise({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: child,
      ),
    );
  }
}

/// Reveals its child left to right, the way a door sweeps a room.
class _Wipe extends StatelessWidget {
  const _Wipe({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(clipper: _WipeClipper(value), child: child);
  }
}

class _WipeClipper extends CustomClipper<Rect> {
  const _WipeClipper(this.value);

  final double value;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * value, size.height);

  @override
  bool shouldReclip(covariant _WipeClipper oldClipper) =>
      oldClipper.value != value;
}

/// The lit doorway: a frame, the light already burning behind it, and the panel
/// hinged on the left that swings out of the way.
///
/// Drawn at a fixed size so the frame and the panel's hinge stay locked to each
/// other on any screen — the push scales the whole thing as one object, which
/// is what makes it read as distance rather than as a growing rectangle.
class _Doorway extends StatelessWidget {
  const _Doorway({
    required this.open,
    required this.light,
    required this.frame,
  });

  static const double frameW = 108;
  static const double frameH = 150;

  /// 0 shut, 1 fully swung open.
  final double open;

  /// Opacity of the light behind the door.
  final double light;

  /// Opacity of the frame's outline.
  final double frame;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: frameW,
      height: frameH,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Opacity(
                  opacity: light,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFFFFE7BC), ExitColors.amber],
                      ),
                    ),
                  ),
                ),
                // Hinged on the left edge, with just enough perspective that
                // the far edge shortens as it swings towards the viewer.
                Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 1 / 420)
                    ..rotateY(-74 * math.pi / 180 * open),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: ExitColors.bg,
                      border: Border(
                        right: BorderSide(color: ExitColors.line2, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // The frame sits over both, so the opening panel is contained by an
          // outline that never moves.
          IgnorePointer(
            child: Opacity(
              opacity: frame,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                  border: Border(
                    top: BorderSide(color: ExitColors.line2, width: 1.5),
                    left: BorderSide(color: ExitColors.line2, width: 1.5),
                    right: BorderSide(color: ExitColors.line2, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
