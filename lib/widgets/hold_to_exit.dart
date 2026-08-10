import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A deliberate press-and-hold as the only way off a screen, with a ring that
/// closes while held.
///
/// Extracted from `BlackoutScreen`, which is still one of its two callers. The
/// other is `CallMaskScreen`: both are screens whose whole job is to look like
/// nothing is happening, and on both a stray tap or an edge swipe must not end
/// the excuse. The awkward parts below — the grace period and the wall-clock
/// check — were paid for once on the black screen and should not be discovered
/// a second time on the mask.
class HoldToExit extends StatefulWidget {
  const HoldToExit({
    super.key,
    required this.child,
    required this.onExit,
    required this.label,
    required this.showHints,
    this.hold = kHoldToExit,
    this.track = ExitColors.black,
  });

  /// How long the finger has to stay down. Long enough that nothing casual
  /// reaches it, short enough that somebody who wants out is not fighting it.
  static const Duration kHoldToExit = Duration(milliseconds: 750);

  /// How long after opening a pointer is treated as the leftover of the tap
  /// that got here. The finger that hit the exit is usually still on the glass
  /// when the screen appears, and that pointer arrives with no matching
  /// release — counting it as the exit gesture would throw the user straight
  /// back out.
  static const Duration graceAfterOpen = Duration(milliseconds: 500);

  final Widget child;
  final VoidCallback onExit;

  /// Shown under the ring, and only when [showHints] is on.
  final String label;

  /// The user's "dark screen hints" setting. The arc is painted either way —
  /// it is the only confirmation that a hold is registering, and without it
  /// the gesture feels broken rather than discreet. The empty track and the
  /// label are what hints off is actually meant to remove.
  final bool showHints;

  final Duration hold;

  /// What the empty ring is drawn against when hints are off — i.e. the
  /// screen's own background, so it disappears into it.
  final Color track;

  @override
  State<HoldToExit> createState() => _HoldToExitState();
}

class _HoldToExitState extends State<HoldToExit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.hold,
  );

  bool _leaving = false;

  /// Stamped in [initState], not lazily on first touch: as a `late final` it
  /// was initialised by the very first pointer down, so the grace period
  /// measured zero and swallowed that press whenever it happened — including a
  /// deliberate one minutes later. The window is meant to run from when the
  /// screen appeared.
  late final DateTime _shownAt;

  /// Wall-clock start of the current hold, or null when nothing is held.
  DateTime? _holdStart;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _hold.addStatusListener(_onHoldStatus);
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _onHoldDown() {
    if (DateTime.now().difference(_shownAt) < HoldToExit.graceAfterOpen) return;
    _holdStart = DateTime.now();
    _hold.forward(from: 0);
  }

  void _onHoldRelease() {
    _holdStart = null;
    _hold.reverse();
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    final DateTime? start = _holdStart;
    final bool heldLongEnough =
        start != null && DateTime.now().difference(start) >= widget.hold;
    if (heldLongEnough) {
      if (_leaving) return;
      _leaving = true;
      widget.onExit();
      return;
    }

    // Firing can stall the frames for a moment (starting the media service is
    // not instant), and the first tick afterwards carries the whole gap, which
    // completes the ring in one jump. Only wall-clock time may end the excuse,
    // so an early completion just restarts it.
    scheduleMicrotask(() {
      if (!mounted || _leaving) return;
      if (_holdStart == null) {
        _hold.value = 0;
      } else {
        _hold.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A raw Listener rather than a gesture recognizer: no arena, no slop
    // threshold, so a slow finger still counts as a hold.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _onHoldDown(),
      onPointerUp: (_) => _onHoldRelease(),
      onPointerCancel: (_) => _onHoldRelease(),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          _HoldRing(
            progress: _hold,
            label: widget.label,
            visible: widget.showHints,
            track: widget.track,
          ),
        ],
      ),
    );
  }
}

Color _grey(double opacity) => ExitColors.mid.withValues(alpha: opacity);

/// The exit gesture's only feedback: a ring that closes while held.
class _HoldRing extends StatelessWidget {
  const _HoldRing({
    required this.progress,
    required this.label,
    required this.visible,
    required this.track,
  });

  static const double _size = 60;

  final Animation<double> progress;
  final String label;
  final bool visible;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 52),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: _size,
              height: _size,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: progress,
                    builder: (_, _) => CustomPaint(
                      size: const Size.square(_size),
                      painter: _RingPainter(
                        progress: progress.value,
                        track: visible ? _grey(0.12) : track,
                        arc: _grey(0.35),
                      ),
                    ),
                  ),
                  if (visible)
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: _grey(0.28),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (visible) ...<Widget>[
              const SizedBox(height: 16),
              Text(label, style: mono(8, color: _grey(0.25), letterSpacing: 3)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.arc,
  });

  final double progress;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    final Rect circle = box.deflate(0.75);

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = track;
    canvas.drawArc(circle, 0, math.pi * 2, false, stroke);

    if (progress <= 0) return;
    canvas.drawArc(
      circle,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      stroke
        ..color = arc
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.arc != arc;
}
