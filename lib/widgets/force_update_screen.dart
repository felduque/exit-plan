import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import 'tip_banner.dart';

/// The one screen this app can put between the user and everything else.
///
/// Shown only when [ForceUpdateService.updateRequired] flips true — a
/// Firebase Remote Config value naming a minimum build this install falls
/// below. It sits as the topmost layer of the overlay stack in `app.dart`,
/// above the intro and the splash, and stays there: no close button, no back
/// gesture, one action.
///
/// Styled like `PremiumScreen`, deliberately — plain, no urgency language, no
/// countdown. The one exception to that screen's doctrine is that this one
/// truly cannot be dismissed, which is why the copy says so plainly instead
/// of pretending otherwise.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  /// Matches `applicationId` in `android/app/build.gradle.kts` — immutable,
  /// same id as the Play listing.
  static const String _packageId = 'com.dg.developer.exitplan';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return TipsSuppressor(
      child: PopScope(
        canPop: false,
        child: Material(
          color: ExitColors.bg,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.system_update_alt_rounded,
                    size: 28,
                    color: ExitColors.hi,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    loc.forceUpdateCaption,
                    style: mono(9, color: ExitColors.dim, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.forceUpdateTitle,
                    style: sans(
                      26,
                      weight: 600,
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    loc.forceUpdateBody,
                    style: sans(13, color: ExitColors.mid, height: 1.6),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton.neutral(
                    label: loc.forceUpdateButton,
                    onTap: _openStore,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tries the Play Store app first — a direct listing rather than a browser
  /// tab — and falls back to the web listing if nothing can handle it (no
  /// Play Store installed, e.g. some emulators).
  Future<void> _openStore() async {
    final Uri marketUri = Uri.parse('market://details?id=$_packageId');
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      return;
    }
    final Uri webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_packageId',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
