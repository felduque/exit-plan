import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tips.dart';
import '../state/app_state.dart';
import '../state/ui_flags.dart';

/// A faint banner that reminds the user what the app can do.
///
/// Never a push notification (that would need network and a permission, and it
/// could give the app away), never over the black screen, and never during the
/// splash or intro.
class TipBanner extends StatefulWidget {
  const TipBanner({super.key, required this.suppressed});

  static const Duration firstDelay = Duration(seconds: 20);
  static const Duration interval = Duration(seconds: 75);
  static const Duration visible = Duration(seconds: 6);

  /// True while the splash or intro is up.
  final bool suppressed;

  @override
  State<TipBanner> createState() => _TipBannerState();
}

/// Wraps a screen that is not home or "all exits" so [TipBanner] never shows
/// over it — see [tipSuppressDepth]. Every other screen in the app should
/// wrap its returned widget in one of these.
class TipsSuppressor extends StatefulWidget {
  const TipsSuppressor({super.key, required this.child});

  final Widget child;

  @override
  State<TipsSuppressor> createState() => _TipsSuppressorState();
}

class _TipsSuppressorState extends State<TipsSuppressor> {
  @override
  void initState() {
    super.initState();
    tipSuppressDepth.value++;
  }

  @override
  void dispose() {
    tipSuppressDepth.value--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TipBannerState extends State<TipBanner> {
  Timer? _showTimer;
  Timer? _hideTimer;
  String? _text;

  @override
  void initState() {
    super.initState();
    _showTimer = Timer(TipBanner.firstDelay, _show);
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _show() async {
    _showTimer = Timer(TipBanner.interval, _show);
    if (!mounted) return;

    final AppState state = AppScope.read(context);
    if (!state.settings.inAppTips) return;
    if (widget.suppressed ||
        blackoutActive.value ||
        modalActive.value ||
        tipsSuppressedByScreen) {
      return;
    }

    setState(() => _text = kTips[state.tipIndex % kTips.length]);
    // Remembering the index means reopening the app does not always show the
    // same first tip.
    await state.advanceTip(kTips.length);

    _hideTimer?.cancel();
    _hideTimer = Timer(TipBanner.visible, _hide);
  }

  void _hide() {
    if (!mounted) return;
    setState(() => _text = null);
  }

  @override
  Widget build(BuildContext context) {
    // A tip already up when a sheet opens, or when navigation lands on a
    // screen that does not want it, has to get out of the way too — not just
    // be skipped next time round.
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[modalActive, tipSuppressDepth]),
      builder: (BuildContext context, _) {
        final bool hide = modalActive.value || tipsSuppressedByScreen;
        return _banner(hide ? null : _text);
      },
    );
  }

  Widget _banner(String? text) {
    return IgnorePointer(
      ignoring: text == null,
      child: AnimatedOpacity(
        opacity: text == null ? 0 : 1,
        duration: const Duration(milliseconds: 220),
        // The banner is stacked in MaterialApp.builder, above the navigator and
        // outside any Scaffold, so it has no Material ancestor — without one,
        // Flutter paints the debug double underline over every letter.
        child: text == null
            ? const SizedBox.shrink()
            : Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: GestureDetector(
                        onTap: _hide,
                        child: Panel(
                          color: ExitColors.surf2,
                          borderColor: ExitColors.line2,
                          radius: ExitRadius.tile,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 13,
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.info_outline,
                                size: 15,
                                color: ExitColors.mid,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(text, style: sans(12, height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
