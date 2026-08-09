import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../call_theme.dart';
import '../call_visuals.dart';

/// "Material" — the flat dark surface, the circular avatar above the name, and
/// the two circles that are both dragged upward rather than tapped.
///
/// Free tier. This was `CallPlatform.android` before the registry existed, and
/// its id is frozen at the value the migration maps that onto.
const CallTheme materialTheme = CallTheme(
  id: 'material',
  name: 'Material',
  premium: false,
  palette: _palette,
  answerGesture: CallAnswerGesture.dragUp,
  declineGesture: CallAnswerGesture.dragUp,
  buildIncoming: _buildIncoming,
  buildActive: _buildActive,
);

// One constant per colour — see the note in `classic_light.dart` for why these
// are not read back off [_palette].
const Color _base = Color(0xFF202124);
const Color _scrim = Color(0xCC000000);
const Color _text = Colors.white;
const Color _subtext = Color(0xFFBDC1C6);
const Color _accept = Color(0xFF1EA562);
const Color _decline = Color(0xFFE8483A);

const CallPalette _palette = CallPalette(
  base: _base,
  scrim: _scrim,
  text: _text,
  subtext: _subtext,
  accept: _accept,
  decline: _decline,
);

const Color _avatarTint = Color(0xFF3C4043);

Widget _buildIncoming(CallIncomingContext ctx) {
  return Builder(
    builder: (BuildContext context) {
      final AppLocalizations loc = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: _base,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CallBackdrop(
              avatarPath: ctx.avatarPath,
              name: ctx.name,
              baseColor: _base,
              scrim: _scrim,
            ),
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
                    const SizedBox(height: 26),
                    Text(
                      loc.callMaterialIncomingCall,
                      style: TextStyle(
                        color: _subtext,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    CallAvatar(
                      avatarPath: ctx.avatarPath,
                      name: ctx.name,
                      diameter: 118,
                      tint: _avatarTint,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      ctx.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (ctx.number.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        ctx.number,
                        style: TextStyle(color: _subtext, fontSize: 15),
                      ),
                    ],
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
  return Builder(
    builder: (BuildContext context) {
      final AppLocalizations loc = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: _base,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            child: Column(
              children: <Widget>[
                const Spacer(),
                CallAvatar(
                  avatarPath: ctx.avatarPath,
                  name: ctx.name,
                  diameter: 96,
                  tint: _avatarTint,
                ),
                const SizedBox(height: 18),
                Text(
                  ctx.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ctx.timer,
                  style: TextStyle(
                    color: _subtext,
                    fontSize: 15,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                _InCallGrid(
                  muted: ctx.muted,
                  onMute: ctx.onMute,
                  speaker: ctx.speaker,
                  onSpeaker: ctx.onSpeaker,
                  keypadOpen: ctx.keypadOpen,
                  onKeypad: ctx.onKeypad,
                ),
                const SizedBox(height: 30),
                CallActionButton(
                  icon: Icons.call_end_rounded,
                  background: _decline,
                  iconColor: Colors.white,
                  onTap: ctx.onHangUp,
                  semanticLabel: loc.callActionEndCall,
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Both circles are dragged upward past a threshold — there is no plain tap
/// target, dragging is the whole interaction.
class _IncomingActions extends StatelessWidget {
  const _IncomingActions({required this.onDecline, required this.onAccept});

  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          DragUpToConfirm(
            onConfirm: onDecline,
            hint: loc.callMaterialSwipeUpDecline,
            child: CallActionButton(
              icon: Icons.call_end_rounded,
              background: _decline,
              iconColor: Colors.white,
              onTap: callNoop,
              semanticLabel: loc.callActionDeclineCall,
            ),
          ),
          DragUpToConfirm(
            onConfirm: onAccept,
            hint: loc.callMaterialSwipeUpAnswer,
            child: CallActionButton(
              icon: Icons.call_rounded,
              background: _accept,
              iconColor: Colors.white,
              onTap: callNoop,
              pulse: true,
              semanticLabel: loc.callActionAcceptCall,
            ),
          ),
        ],
      ),
    );
  }
}

/// The in-call button row above hang-up: mute, keypad, speaker. Cosmetic.
class _InCallGrid extends StatelessWidget {
  const _InCallGrid({
    required this.muted,
    required this.onMute,
    required this.speaker,
    required this.onSpeaker,
    required this.keypadOpen,
    required this.onKeypad,
  });

  final bool muted;
  final VoidCallback onMute;
  final bool speaker;
  final VoidCallback onSpeaker;
  final bool keypadOpen;
  final VoidCallback onKeypad;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        CallGridButton(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: loc.callGridMute,
          active: muted,
          onTap: onMute,
          tint: _base,
        ),
        CallGridButton(
          icon: Icons.dialpad_rounded,
          label: loc.callGridKeypad,
          active: keypadOpen,
          onTap: onKeypad,
          tint: _base,
        ),
        CallGridButton(
          icon: Icons.volume_up_rounded,
          label: loc.callGridSpeaker,
          active: speaker,
          onTap: onSpeaker,
          tint: _base,
        ),
      ],
    );
  }
}
