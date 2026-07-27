import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A timeline with two draggable handles.
///
/// Not a waveform: drawing a real one would mean decoding the file through a
/// recording API, and this app deliberately asks for no microphone permission —
/// requesting one it never uses is a red flag in store review. A tick grid,
/// handles and a time ruler do the same job honestly.
class TrimTimeline extends StatefulWidget {
  const TrimTimeline({
    super.key,
    required this.duration,
    required this.start,
    required this.end,
    required this.position,
    required this.onChanged,
    required this.onEdgeReleased,
  });

  /// Smallest window the user can end up with, so start stays below end.
  static const Duration minWindow = Duration(seconds: 1);

  final Duration duration;
  final Duration start;
  final Duration end;
  final Duration position;
  final void Function(Duration start, Duration end) onChanged;

  /// Called on release with true for the start handle, false for the end one.
  final void Function(bool startEdge) onEdgeReleased;

  @override
  State<TrimTimeline> createState() => _TrimTimelineState();
}

class _TrimTimelineState extends State<TrimTimeline> {
  static const double _trackHeight = 74;

  bool? _draggingStart;

  @override
  Widget build(BuildContext context) {
    final int total = widget.duration.inMilliseconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('TRIM WINDOW', style: ExitText.caption),
            Text(
              '${_clock(widget.start)} → ${_clock(widget.end)}',
              style: mono(9, color: ExitColors.hi),
            ),
          ],
        ),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            double xOf(Duration value) => total <= 0
                ? 0
                : (value.inMilliseconds / total).clamp(0.0, 1.0) * width;

            Duration atX(double x) => Duration(
              milliseconds: ((x / width).clamp(0.0, 1.0) * total).round(),
            );

            final double startX = xOf(widget.start);
            final double endX = xOf(widget.end);
            final double playX = xOf(widget.position);

            return GestureDetector(
              onHorizontalDragStart: (DragStartDetails details) {
                final double x = details.localPosition.dx;
                setState(() {
                  _draggingStart = (x - startX).abs() <= (x - endX).abs();
                });
                _apply(atX(x), total);
              },
              onHorizontalDragUpdate: (DragUpdateDetails details) =>
                  _apply(atX(details.localPosition.dx), total),
              onHorizontalDragEnd: (DragEndDetails details) {
                final bool? startEdge = _draggingStart;
                _draggingStart = null;
                if (startEdge != null) widget.onEdgeReleased(startEdge);
              },
              child: SizedBox(
                height: _trackHeight,
                width: width,
                child: ClipRRect(
                  borderRadius: ExitRadius.field,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ExitColors.surf,
                      borderRadius: ExitRadius.field,
                      border: Border.all(color: ExitColors.line),
                    ),
                    child: Stack(
                      children: <Widget>[
                        const Positioned.fill(
                          child: CustomPaint(painter: _TickGridPainter()),
                        ),
                        Positioned(
                          left: startX,
                          width: (endX - startX).clamp(1.0, width),
                          top: 0,
                          bottom: 0,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: ExitColors.greenWash,
                              border: Border.symmetric(
                                vertical: BorderSide(
                                  color: ExitColors.green,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: (playX - 1).clamp(0.0, width - 2),
                          width: 2,
                          top: 0,
                          bottom: 0,
                          child: ColoredBox(
                            color: ExitColors.hi.withValues(alpha: 0.5),
                          ),
                        ),
                        _handle(startX, width),
                        _handle(endX, width),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (final Duration mark in _ruler(widget.duration))
              Text(_clock(mark), style: ExitText.badge),
          ],
        ),
      ],
    );
  }

  Widget _handle(double x, double width) {
    return Positioned(
      left: (x - 6.5).clamp(0.0, width - 13),
      width: 13,
      top: 0,
      bottom: 0,
      child: const Center(
        child: SizedBox(
          width: 13,
          height: 36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ExitColors.green,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
        ),
      ),
    );
  }

  void _apply(Duration value, int total) {
    final bool? startEdge = _draggingStart;
    if (startEdge == null || total <= 0) return;

    final int min = TrimTimeline.minWindow.inMilliseconds;
    if (startEdge) {
      final int start = value.inMilliseconds.clamp(
        0,
        widget.end.inMilliseconds - min,
      );
      widget.onChanged(Duration(milliseconds: start), widget.end);
    } else {
      final int end = value.inMilliseconds.clamp(
        widget.start.inMilliseconds + min,
        total,
      );
      widget.onChanged(widget.start, Duration(milliseconds: end));
    }
  }

  /// Four evenly spaced labels, the last one being the true end of the file.
  static List<Duration> _ruler(Duration total) {
    if (total <= Duration.zero) return const <Duration>[Duration.zero];
    return <Duration>[
      Duration.zero,
      Duration(milliseconds: total.inMilliseconds ~/ 3),
      Duration(milliseconds: total.inMilliseconds * 2 ~/ 3),
      total,
    ];
  }

  static String _clock(Duration d) {
    final int seconds = d.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

/// Evenly spaced hairlines behind the window. Purely a sense of scale — they do
/// not line up with seconds, and pretending otherwise would be a lie.
class _TickGridPainter extends CustomPainter {
  const _TickGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = ExitColors.line
      ..strokeWidth = 1;
    for (double x = 28; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_TickGridPainter oldDelegate) => false;
}
