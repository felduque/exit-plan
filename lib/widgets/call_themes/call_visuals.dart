import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared pieces every fake-call screen — whichever OS it imitates — is built
/// from: the status bar, the caller photo, and the round action buttons. Kept
/// out of `core/theme.dart` on purpose: nothing here may leak into the rest of
/// the app, the same way `BlackoutScreen` never borrows the app's own look.

/// The system status bar every real call screen sits under: time on the left,
/// signal/wifi/battery glyphs on the right. Drawn rather than left to the OS
/// because these screens render full-bleed with no real system chrome behind
/// them.
class CallStatusBar extends StatefulWidget {
  const CallStatusBar({super.key, required this.color});

  final Color color;

  @override
  State<CallStatusBar> createState() => _CallStatusBarState();
}

class _CallStatusBarState extends State<CallStatusBar> {
  late String _time = _now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _time = _now());
    });
  }

  String _now() {
    final DateTime t = DateTime.now();
    final int hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final String minute = t.minute.toString().padLeft(2, '0');
    final String period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      color: widget.color,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 18, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(_time, style: style),
          Row(
            children: <Widget>[
              Icon(Icons.signal_cellular_alt, size: 15, color: widget.color),
              const SizedBox(width: 5),
              Icon(Icons.wifi, size: 15, color: widget.color),
              const SizedBox(width: 5),
              Icon(Icons.battery_full, size: 16, color: widget.color),
            ],
          ),
        ],
      ),
    );
  }
}

/// The caller's photo, as a plain circle for the incoming-call header, the
/// in-call header and cards. Falls back to a soft initial when there is no
/// photo — or, when [fallbackIcon] is given (WhatsApp's own default avatar is
/// a generic silhouette rather than an initial), that icon instead.
class CallAvatar extends StatelessWidget {
  const CallAvatar({
    super.key,
    required this.avatarPath,
    required this.name,
    required this.diameter,
    this.tint = const Color(0xFF3A3D46),
    this.textColor = Colors.white,
    this.fallbackIcon,
  });

  final String? avatarPath;
  final String name;
  final double diameter;
  final Color tint;
  final Color textColor;
  final IconData? fallbackIcon;

  String get _initial {
    final String trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String? path = avatarPath;
    return ClipOval(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: path != null && File(path).existsSync()
            ? Image.file(File(path), fit: BoxFit.cover)
            : ColoredBox(
                color: tint,
                child: Center(
                  child: fallbackIcon != null
                      ? Icon(
                          fallbackIcon,
                          size: diameter * 0.56,
                          color: textColor,
                        )
                      : Text(
                          _initial,
                          style: TextStyle(
                            color: textColor,
                            fontSize: diameter * 0.38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
      ),
    );
  }
}

/// The blurred, darkened full-screen backdrop behind an incoming-call layout:
/// the photo itself, softened and dimmed so white text stays legible over any
/// picture.
class CallBackdrop extends StatelessWidget {
  const CallBackdrop({
    super.key,
    required this.avatarPath,
    required this.name,
    required this.baseColor,
    required this.scrim,
  });

  final String? avatarPath;
  final String name;
  final Color baseColor;
  final Color scrim;

  @override
  Widget build(BuildContext context) {
    final String? path = avatarPath;
    final bool hasPhoto = path != null && File(path).existsSync();

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (hasPhoto)
          Image.file(File(path), fit: BoxFit.cover)
        else
          ColoredBox(color: baseColor),
        if (hasPhoto)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
            child: const SizedBox.expand(),
          ),
        DecoratedBox(decoration: BoxDecoration(color: scrim)),
      ],
    );
  }
}

/// One round action button: decline, accept, or one of the in-call grid
/// controls. [pulse] draws a slow breathing ring around it, used for the
/// accept button while the phone is still ringing.
class CallActionButton extends StatefulWidget {
  const CallActionButton({
    super.key,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.size = 66,
    this.iconSize = 28,
    this.label,
    this.labelColor = Colors.white70,
    this.pulse = false,
    this.semanticLabel,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final String? label;
  final Color labelColor;
  final bool pulse;
  final String? semanticLabel;

  @override
  State<CallActionButton> createState() => _CallActionButtonState();
}

class _CallActionButtonState extends State<CallActionButton>
    with SingleTickerProviderStateMixin {
  // Built eagerly in initState rather than as a lazy `late` field: a button
  // whose `pulse` is always false never reads `_c` during build, and a lazy
  // initializer touched for the first time from dispose() tries to create a
  // ticker against an element that is already being torn down.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          button: true,
          label: widget.semanticLabel ?? widget.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.size * 1.6,
              height: widget.size * 1.6,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (widget.pulse)
                    AnimatedBuilder(
                      animation: _c,
                      builder: (BuildContext context, _) {
                        final double t = _c.value;
                        return Opacity(
                          opacity: (1 - t) * 0.35,
                          child: Container(
                            width: widget.size + t * 26,
                            height: widget.size + t * 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.background,
                            ),
                          ),
                        );
                      },
                    ),
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.background,
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: widget.iconSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.label != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            widget.label!,
            style: TextStyle(
              color: widget.labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Wraps a [CallActionButton] with the real "drag up to confirm" gesture used
/// by iOS's and stock Android's own incoming-call screens: the button follows
/// the finger upward, [onConfirm] fires once it clears [threshold], and it
/// springs back to rest on an early release.
class DragUpToConfirm extends StatefulWidget {
  const DragUpToConfirm({
    super.key,
    required this.child,
    required this.onConfirm,
    this.threshold = 64,
    this.hint,
    this.hintColor = Colors.white70,
  });

  final Widget child;
  final VoidCallback onConfirm;
  final double threshold;
  final String? hint;
  final Color hintColor;

  @override
  State<DragUpToConfirm> createState() => _DragUpToConfirmState();
}

class _DragUpToConfirmState extends State<DragUpToConfirm>
    with SingleTickerProviderStateMixin {
  // Built eagerly — see the same fix on `_CallActionButtonState._c`: most
  // drags end in a confirm and never touch the spring-back controller, so a
  // lazy `late` initializer would only ever run for the first time inside
  // dispose(), against an element that is already being torn down.
  late final AnimationController _spring;

  double _dragY = 0;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails details) {
    if (_confirmed) return;
    setState(() {
      _dragY = (_dragY + details.delta.dy).clamp(-widget.threshold * 1.6, 0.0);
    });
  }

  void _onEnd(DragEndDetails details) {
    if (_confirmed) return;
    if (-_dragY >= widget.threshold) {
      _confirmed = true;
      widget.onConfirm();
      return;
    }
    _springBack();
  }

  void _springBack() {
    final double start = _dragY;
    _spring
      ..value = 0
      ..addListener(_applySpring(start))
      ..forward(from: 0);
  }

  VoidCallback _applySpring(double start) {
    return () {
      if (!mounted) return;
      setState(() => _dragY = start * (1 - _spring.value));
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.hint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Opacity(
              opacity: (1 - (-_dragY / widget.threshold)).clamp(0.25, 1.0),
              child: Icon(
                Icons.keyboard_double_arrow_up_rounded,
                size: 16,
                color: widget.hintColor,
              ),
            ),
          ),
        GestureDetector(
          onVerticalDragUpdate: _onUpdate,
          onVerticalDragEnd: _onEnd,
          child: Transform.translate(
            offset: Offset(0, _dragY),
            child: widget.child,
          ),
        ),
        if (widget.hint != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            widget.hint!,
            style: TextStyle(
              color: widget.hintColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// A small square control used in the in-call button grid (mute, keypad,
/// speaker…). Cosmetic — it toggles its own look and nothing real, since there
/// is no real call underneath.
class CallGridButton extends StatelessWidget {
  const CallGridButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.tint,
    this.activeColor = Colors.white,
    this.inactiveBackground = const Color(0x26FFFFFF),
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color tint;
  final Color activeColor;
  final Color inactiveBackground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? activeColor : inactiveBackground,
              ),
              child: Icon(icon, size: 24, color: active ? tint : Colors.white),
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
        ),
      ),
    );
  }
}
