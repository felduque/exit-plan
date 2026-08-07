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

  /// Null while hidden. Driving visibility off a separate flag rather than off
  /// this being null lets the banner keep its last text mounted through the
  /// whole hide animation, instead of swapping to an empty box the instant it
  /// starts fading — which would skip the fade entirely.
  String? _text;
  String _lastText = '';

  /// Live drag offset while a swipe-to-dismiss gesture is in progress. Reset
  /// to 0 once the finger lifts, whether or not the drag dismissed anything.
  double _dragY = 0;

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

    // A Premium nudge is not an extra banner — it is this one, showing
    // something else. Every gate above already applied, the app's total
    // interruption budget does not rise, and the `inAppTips` switch the user
    // already knows about silences it too. See lib/core/premium_cadence.dart.
    final String? promo = state.premiumNudge(DateTime.now());
    final String next = promo ?? kTips[state.tipIndex % kTips.length];

    setState(() {
      _lastText = next;
      _text = next;
      _dragY = 0;
    });

    if (promo != null) {
      await state.markPremiumNudge(DateTime.now());
    } else {
      // Remembering the index means reopening the app does not always show the
      // same first tip. Deliberately not advanced on a promo tick: a nudge must
      // not cost the user a tip they would otherwise have seen.
      await state.advanceTip(kTips.length);
    }

    _hideTimer?.cancel();
    _hideTimer = Timer(TipBanner.visible, _hide);
  }

  /// Ends the banner early — a tap, a swipe, or navigation landing on a
  /// screen that does not want it. The auto-hide timer no longer matters once
  /// this fires, so it is cancelled rather than left to fire on nothing.
  void _hide() {
    if (!mounted) return;
    _hideTimer?.cancel();
    _hideTimer = null;
    setState(() => _text = null);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _dragY = (_dragY + details.delta.dy).clamp(-80.0, 0.0));
  }

  void _onDragEnd(DragEndDetails details) {
    // Swiping it back up, the direction it dropped in from, is what dismisses
    // it — the same "undo the entrance" gesture the call screens use for
    // slide-to-answer.
    final bool dismiss = _dragY <= -28;
    setState(() => _dragY = 0);
    if (dismiss) _hide();
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
        return _banner(!hide && _text != null);
      },
    );
  }

  Widget _banner(bool visible) {
    return IgnorePointer(
      ignoring: !visible,
      // Drops down from behind the status bar and fades in; reverses on the
      // way out. Both properties animate the same mounted content — the text
      // itself only ever changes when a fresh tip is about to show, in
      // [_show] — so the exit is a real fade, not an instant swap.
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          // The banner is stacked in MaterialApp.builder, above the navigator
          // and outside any Scaffold, so it has no Material ancestor —
          // without one, Flutter paints the debug double underline over
          // every letter.
          child: _lastText.isEmpty
              ? const SizedBox.shrink()
              : Material(
                  type: MaterialType.transparency,
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Transform.translate(
                          offset: Offset(0, _dragY),
                          child: GestureDetector(
                            onTap: _hide,
                            onVerticalDragUpdate: _onDragUpdate,
                            onVerticalDragEnd: _onDragEnd,
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
                                    child: Text(
                                      _lastText,
                                      style: sans(12, height: 1.4),
                                    ),
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
        ),
      ),
    );
  }
}
