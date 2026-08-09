import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../call_theme.dart';
import '../call_visuals.dart';

/// "Chat azul" — the other messaging look: a cool indigo gradient instead of a
/// wallpaper, a rounded-square avatar rather than a circle, and the caller's
/// handle under the name the way a chat app shows an account rather than a
/// phone number.
///
/// Premium. Like every theme here the name is generic and nothing in it
/// reproduces a real product's mark — see the note in `chat_green.dart`.
const CallTheme chatBlueTheme = CallTheme(
  id: 'chat-blue',
  name: 'Blue chat',
  premium: true,
  palette: _palette,
  answerGesture: CallAnswerGesture.tap,
  declineGesture: CallAnswerGesture.tap,
  buildIncoming: _buildIncoming,
  buildActive: _buildActive,
);

// One constant per colour — see the note in `classic_light.dart` for why these
// are not read back off [_palette].
const Color _base = Color(0xFF15181F);
const Color _scrim = Color(0xD11B2340);
const Color _text = Colors.white;
const Color _subtext = Color(0xFF9AA6C4);
const Color _accept = Color(0xFF2F9BEA);
const Color _decline = Color(0xFFE8455F);

const CallPalette _palette = CallPalette(
  base: _base,
  scrim: _scrim,
  text: _text,
  subtext: _subtext,
  accept: _accept,
  decline: _decline,
);

const Color _avatarTint = Color(0xFF2B3350);

/// The soft indigo wash this theme sits on when there is no caller photo.
class _Gradient extends StatelessWidget {
  const _Gradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF232C4D), Color(0xFF15181F)],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

/// The rounded square this theme uses in place of a circular avatar.
class _SquareAvatar extends StatelessWidget {
  const _SquareAvatar({
    required this.avatarPath,
    required this.name,
    required this.diameter,
  });

  final String? avatarPath;
  final String name;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(diameter * 0.28),
      child: CallAvatar(
        avatarPath: avatarPath,
        name: name,
        diameter: diameter,
        tint: _avatarTint,
        textColor: Colors.white,
      ),
    );
  }
}

Widget _buildIncoming(CallIncomingContext ctx) {
  return Builder(
    builder: (BuildContext context) {
      final AppLocalizations loc = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: _base,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const _Gradient(),
            if (ctx.avatarPath != null)
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
                    const SizedBox(height: 34),
                    Text(
                      loc.callChatBlueIncomingVoiceCall,
                      style: TextStyle(
                        color: _subtext,
                        fontSize: 13.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    _SquareAvatar(
                      avatarPath: ctx.avatarPath,
                      name: ctx.name,
                      diameter: 124,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      ctx.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (ctx.number.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        ctx.number,
                        style: TextStyle(color: _subtext, fontSize: 14.5),
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
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const _Gradient(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 26,
                ),
                child: Column(
                  children: <Widget>[
                    const Spacer(),
                    _SquareAvatar(
                      avatarPath: ctx.avatarPath,
                      name: ctx.name,
                      diameter: 96,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      ctx.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ctx.timer,
                      style: TextStyle(
                        color: _subtext,
                        fontSize: 14,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        CallGridButton(
                          icon: ctx.muted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          label: loc.callGridMute,
                          active: ctx.muted,
                          onTap: ctx.onMute,
                          tint: _base,
                        ),
                        CallGridButton(
                          icon: Icons.videocam_rounded,
                          label: loc.callChatBlueVideo,
                          active: ctx.videoOn,
                          onTap: ctx.onVideo,
                          tint: _base,
                        ),
                        CallGridButton(
                          icon: Icons.volume_up_rounded,
                          label: loc.callGridSpeaker,
                          active: ctx.speaker,
                          onTap: ctx.onSpeaker,
                          tint: _base,
                        ),
                      ],
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
          ],
        ),
      );
    },
  );
}

class _IncomingActions extends StatelessWidget {
  const _IncomingActions({required this.onDecline, required this.onAccept});

  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          CallActionButton(
            icon: Icons.call_end_rounded,
            background: _decline,
            iconColor: Colors.white,
            onTap: onDecline,
            label: loc.callActionDecline,
            labelColor: _subtext,
            semanticLabel: loc.callActionDeclineCall,
          ),
          CallActionButton(
            icon: Icons.call_rounded,
            background: _accept,
            iconColor: Colors.white,
            onTap: onAccept,
            pulse: true,
            label: loc.callActionAccept,
            labelColor: _subtext,
            semanticLabel: loc.callActionAcceptCall,
          ),
        ],
      ),
    );
  }
}
