import 'package:flutter/material.dart';

import 'call_visuals.dart';

/// A fake-call theme: everything needed to draw one incoming call and one
/// answered call, plus the metadata the picker and the paywall read.
///
/// ## Why this is a registry and not an enum
///
/// The three original styles were a `CallPlatform` enum resolved by a `switch`
/// in `incoming_call_screen.dart` *and* another in `fake_call_screen.dart`.
/// Adding a fourth meant editing the enum, both switches, the editor's
/// segmented control and two tests — five places that had to agree, with
/// nothing but discipline keeping them in step.
///
/// Here a theme is one file plus one entry in `kCallThemes`. Nothing else in
/// the app knows how many there are.
///
/// ## The ids are frozen
///
/// [id] is persisted inside every saved [CallPreset], exactly like the sound
/// ids in `system_catalog.dart`. Renaming one silently repoints somebody's
/// saved template at a different theme — or, worse, at none.
///
/// ## Naming rule
///
/// [name] is what the user reads, and it must stay **generic**. No theme in
/// this app is named after a real product, and none ships a real product's
/// logo or wordmark: Play treats that as impersonation, and the risk is the
/// whole developer account rather than the feature. Evoking a look is fine;
/// borrowing a brand is not. `test/branding_test.dart` enforces it.
@immutable
class CallTheme {
  const CallTheme({
    required this.id,
    required this.name,
    required this.premium,
    required this.palette,
    required this.answerGesture,
    required this.declineGesture,
    required this.buildIncoming,
    required this.buildActive,
  });

  /// Frozen. Persisted in `CallPreset.themeId`.
  final String id;

  /// Shown in the picker. Generic by policy — see the class doc.
  final String name;

  /// Whether using this theme requires Premium.
  ///
  /// Consulted **only** where the user picks a theme, never where one is
  /// drawn. A template saved with a premium theme keeps rendering it even if
  /// the entitlement later lapses — the same doctrine `PremiumGate` already
  /// applies to the creation caps, which never hide anything already made.
  final bool premium;

  final CallPalette palette;

  /// How each circle is operated. Declared rather than inferred so a new theme
  /// cannot quietly ship an untested gesture: `call_screen_layout_test` drives
  /// every theme through whichever of the two it claims.
  final CallAnswerGesture answerGesture;
  final CallAnswerGesture declineGesture;

  final Widget Function(CallIncomingContext) buildIncoming;
  final Widget Function(CallActiveContext) buildActive;
}

/// The two real-world gestures a full-screen incoming call uses.
enum CallAnswerGesture {
  /// A flat tap on the circle.
  tap,

  /// The circle is dragged upward past a threshold; a plain tap does nothing.
  dragUp,
}

/// The handful of colours the picker needs without building a whole screen,
/// and that the themes themselves use as their palette.
@immutable
class CallPalette {
  const CallPalette({
    required this.base,
    required this.scrim,
    required this.text,
    required this.subtext,
    required this.accept,
    required this.decline,
  });

  final Color base;
  final Color scrim;
  final Color text;
  final Color subtext;
  final Color accept;
  final Color decline;
}

/// Everything an incoming-call layout is allowed to know.
///
/// Deliberately plain fields rather than the [CallPreset] itself: a theme that
/// took the model would be coupled to a persisted schema it has no business
/// knowing about, and the picker could not build one without inventing a fake
/// preset just to draw a swatch.
@immutable
class CallIncomingContext {
  const CallIncomingContext({
    required this.name,
    required this.number,
    required this.avatarPath,
    required this.onAccept,
    required this.onDecline,
  });

  final String name;
  final String number;
  final String? avatarPath;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
}

/// Everything an answered-call layout is allowed to know. The toggles are
/// cosmetic — there is no real call underneath any of this.
@immutable
class CallActiveContext {
  const CallActiveContext({
    required this.name,
    required this.avatarPath,
    required this.timer,
    required this.muted,
    required this.speaker,
    required this.keypadOpen,
    required this.videoOn,
    required this.onMute,
    required this.onSpeaker,
    required this.onKeypad,
    required this.onVideo,
    required this.onHangUp,
  });

  final String name;
  final String? avatarPath;

  /// Already formatted `mm:ss`.
  final String timer;

  final bool muted;
  final bool speaker;
  final bool keypadOpen;
  final bool videoOn;

  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onKeypad;
  final VoidCallback onVideo;
  final VoidCallback onHangUp;
}

/// What every theme shows once the ring times out unanswered.
///
/// Shared rather than per-theme on purpose: a missed call looks essentially the
/// same everywhere — a name, the words, and nothing to do about it. Six
/// bespoke versions of that would be six chances to disagree about a screen the
/// user sees for two seconds. It takes the theme's palette so it still belongs
/// to whichever call it ended.
class CallMissedView extends StatelessWidget {
  const CallMissedView({
    super.key,
    required this.palette,
    required this.name,
    required this.avatarPath,
  });

  final CallPalette palette;
  final String name;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.base,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CallAvatar(
                avatarPath: avatarPath,
                name: name,
                diameter: 88,
                tint: palette.scrim,
                textColor: palette.text,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.call_missed, size: 17, color: palette.decline),
                  const SizedBox(width: 8),
                  Text(
                    'Missed call',
                    style: TextStyle(
                      color: palette.decline,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
