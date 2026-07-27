import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Short brand animation over the app, mounted as an overlay rather than a
/// route so nothing underneath needs a guard.
///
/// Two rules: it respects the system's reduce-motion setting, and it can never
/// trap the user — a safety timer forces it away even if the animation never
/// reports that it finished.
class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key, required this.onDone});

  static const Duration animation = Duration(milliseconds: 1600);
  static const Duration safetyTimeout = Duration(milliseconds: 2500);

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
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: ExitColors.bg),
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              final double t = Curves.easeOut.transform(_controller.value);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // The mark fades in before the word arrives.
                  Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: const BrandMark(size: 58),
                  ),
                  const SizedBox(height: 20),
                  Opacity(
                    opacity: (t * 1.4 - 0.4).clamp(0.0, 1.0),
                    child: Text(
                      'EXITPLAN',
                      style: sans(25, weight: 600, letterSpacing: 1),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Text(
              '100% OFFLINE · NO ACCOUNTS',
              style: mono(8, color: ExitColors.dim, letterSpacing: 3),
            ),
          ),
        ),
      ],
    );
  }
}
