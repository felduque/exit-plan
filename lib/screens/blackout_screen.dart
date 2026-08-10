import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_boot.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/escape_sound.dart';
import '../state/app_state.dart';
import '../state/ui_flags.dart';
import '../widgets/hold_to_exit.dart';

/// Fires [soundId] by opening the black screen. Every trigger in the app goes
/// through here: no ordinary screen plays the alarm itself.
Future<void> fireSound(
  BuildContext context, {
  required String soundId,
  required int delaySeconds,
  required LoopChoice loop,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => BlackoutScreen(
        soundId: soundId,
        delaySeconds: delaySeconds,
        loop: loop,
      ),
      transitionDuration: const Duration(milliseconds: 160),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      transitionsBuilder: (_, Animation<double> animation, _, Widget child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Absolute black while the audio runs.
/// The screen never lights up on its own — not when the audio pauses from the
/// notification, not when a finite loop expires, not on an error. The only way
/// out is a deliberate long press; system back and edge swipes are disabled so a
/// stray gesture cannot end the excuse.
///
/// This screen shares nothing with the rest of the app's design language. There
/// are no surfaces, no borders and no accents here: everything drawn is a few
/// percent of one colour on black, legible if you are the one holding the phone
/// and looking for it, and invisible to somebody across the table.
class BlackoutScreen extends StatefulWidget {
  const BlackoutScreen({
    super.key,
    required this.soundId,
    required this.delaySeconds,
    required this.loop,
  });

  /// Kept as the screen's own name for the gesture; the timing itself now
  /// lives with the widget that implements it.
  static const Duration holdToExit = HoldToExit.kHoldToExit;

  final String soundId;
  final int delaySeconds;
  final LoopChoice loop;

  @override
  State<BlackoutScreen> createState() => _BlackoutScreenState();
}

class _BlackoutScreenState extends State<BlackoutScreen> {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    blackoutActive.value = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    fireEngine.addListener(_onEngine);
    WidgetsBinding.instance.addPostFrameCallback((_) => _arm());
  }

  Future<void> _arm() async {
    final AppState state = AppScope.read(context);
    // A stale id degrades to a default sound instead of failing.
    final EscapeSound sound = state.library.resolveOrFallback(widget.soundId);
    await fireEngine.arm(
      sound,
      delaySeconds: widget.delaySeconds,
      loop: widget.loop,
      settings: state.settings,
    );
  }

  void _onEngine() {
    if (mounted) setState(() {});
  }

  Future<void> _exit() async {
    if (_leaving) return;
    _leaving = true;
    await fireEngine.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    fireEngine.removeListener(_onEngine);
    blackoutActive.value = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Belt and braces: leaving this route must never leave audio running.
    if (!_leaving) fireEngine.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hints = AppScope.of(context).settings.darkScreenHints;
    final AppLocalizations loc = AppLocalizations.of(context);
    final FirePhase phase = fireEngine.phase;
    final bool armed = phase == FirePhase.armed;

    return PopScope(
      // The system back gesture must not end the excuse.
      canPop: false,
      child: Scaffold(
        backgroundColor: ExitColors.black,
        body: HoldToExit(
          onExit: _exit,
          // A held finger during the fuse aborts before anything sounds,
          // which is a different promise from ending a live excuse.
          label: armed ? loc.blackoutHoldToAbort : loc.blackoutHoldToExit,
          showHints: hints,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const ColoredBox(color: ExitColors.black),
              if (hints) ...<Widget>[
                if (armed)
                  _ArmedBody(countdown: fireEngine.countdown, loc: loc)
                else ...<Widget>[
                  _PhaseMarker(phase: phase, loc: loc),
                  _GetOutLine(excuse: fireEngine.sound?.excuse, loc: loc),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ink on the black screen. Everything here is one of these two colours at a
/// single-digit percentage — nothing else may be drawn on this screen.
Color _grey(double opacity) => ExitColors.mid.withValues(alpha: opacity);
Color _red(double opacity) => ExitColors.red.withValues(alpha: opacity);

/// The fuse: a big countdown, dim red, and nothing else.
class _ArmedBody extends StatelessWidget {
  const _ArmedBody({required this.countdown, required this.loc});

  final int countdown;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            loc.blackoutArmed,
            style: mono(9, color: _red(0.5), letterSpacing: 5),
          ),
          const SizedBox(height: 14),
          Text(
            '$countdown',
            style: sans(92, weight: 600, color: _red(0.8), height: 1),
          ),
          const SizedBox(height: 14),
          Text(
            loc.blackoutFiringIn,
            style: mono(8, color: _grey(0.3), letterSpacing: 3),
          ),
        ],
      ),
    );
  }
}

/// The one-word state, top of the screen. Red once it is live, so a glance is
/// enough to tell "it is running" from "it stopped".
class _PhaseMarker extends StatelessWidget {
  const _PhaseMarker({required this.phase, required this.loc});

  final FirePhase phase;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final bool live = phase == FirePhase.live;
    final String text = switch (phase) {
      FirePhase.idle => loc.blackoutStandby,
      FirePhase.armed => loc.blackoutArmed,
      FirePhase.live => loc.blackoutLive,
      FirePhase.paused => loc.blackoutPaused,
      FirePhase.done => loc.blackoutDone,
    };

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (live) ...<Widget>[
              PulseDot(color: _red(0.6), size: 5),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: mono(
                9,
                color: live ? _red(0.45) : _grey(0.25),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The excuse, faint, in the middle of the dark.
///
/// This is the point of the whole screen: the noise buys you a few seconds, and
/// what you say in them decides whether it works. Having the line already in
/// front of you turns a sound into a complete exit.
class _GetOutLine extends StatelessWidget {
  const _GetOutLine({required this.excuse, required this.loc});

  final String? excuse;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final String? line = excuse;
    // Not every sound carries an excuse, and an empty heading would be worse
    // than nothing at all.
    if (line == null || line.trim().isEmpty) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              loc.blackoutGetOutLine,
              style: mono(8, color: _grey(0.18), letterSpacing: 4),
            ),
            const SizedBox(height: 16),
            Text(
              '"$line"',
              textAlign: TextAlign.center,
              style: sans(
                17,
                color: ExitColors.hi.withValues(alpha: 0.14),
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
