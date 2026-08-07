import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_settings.dart';
import '../state/app_state.dart';
import '../state/permissions.dart';
import '../widgets/ad_banner.dart';
import '../widgets/permission_notice.dart';
import 'premium_screen.dart';
import '../widgets/tip_banner.dart';

/// Six toggles and the privacy note. No account, no upsell.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppSettings s = state.settings;

    return TipsSuppressor(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                child: Row(
                  children: <Widget>[
                    const BackChevron(),
                    Text('Settings', style: ExitText.title),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                  children: <Widget>[
                    _Toggle(
                      label: 'Loop sound',
                      detail: 'Default loop = repeat until stopped',
                      value: s.loopSound,
                      onChanged: (bool v) =>
                          state.updateSettings(s.copyWith(loopSound: v)),
                    ),
                    _Toggle(
                      label: 'Haptic support',
                      detail: 'Vibrate on fire, per category',
                      value: s.hapticSupport,
                      onChanged: (bool v) =>
                          state.updateSettings(s.copyWith(hapticSupport: v)),
                    ),
                    _Toggle(
                      label: 'Max volume override',
                      detail: 'Force player to 100% on fire',
                      value: s.maxVolumeOverride,
                      onChanged: (bool v) => state.updateSettings(
                        s.copyWith(maxVolumeOverride: v),
                      ),
                    ),
                    _Toggle(
                      label: 'Dark screen hints',
                      detail: 'Very faint status on blackout',
                      value: s.darkScreenHints,
                      onChanged: (bool v) =>
                          state.updateSettings(s.copyWith(darkScreenHints: v)),
                    ),
                    _Toggle(
                      label: 'Lock-screen controls',
                      detail: 'Neutral controls · keeps audio alive',
                      value: s.lockScreenControls,
                      onChanged: (bool v) =>
                          _setLockScreenControls(state, s, v),
                    ),
                    // Sits directly under the toggle it belongs to, so the reason
                    // the setting is not working is next to the setting.
                    NotificationPermissionNotice(
                      relevant: s.lockScreenControls,
                    ),
                    _Toggle(
                      label: 'In-app tips',
                      detail: 'Occasional reminders while open',
                      value: s.inAppTips,
                      onChanged: (bool v) =>
                          state.updateSettings(s.copyWith(inAppTips: v)),
                    ),
                    // After the toggles, not before them. Putting it first
                    // pushed the sixth toggle out of the viewport on a 360dp
                    // phone, and a settings screen whose own settings are
                    // below a sales pitch has its priorities backwards. The
                    // always-visible entry point is the masthead tile on home;
                    // this is the second way in, and it is fine that it needs
                    // a scroll.
                    const _PremiumRow(),
                    const _PrivacyNote(),
                  ],
                ),
              ),
              const FooterNote('YOUR SOUNDS · 100% OFFLINE'),
              const AdBannerSlot(),
            ],
          ),
        ),
      ),
    );
  }

  /// Turning this on is the moment the permission actually starts to matter, so
  /// it is the moment to ask for it — never during a firing, where a system
  /// dialog would wreck the excuse.
  ///
  /// Only asks when the dialog can still appear. Once it cannot, the notice
  /// underneath takes over with the settings shortcut instead of firing off a
  /// request that silently does nothing.
  static Future<void> _setLockScreenControls(
    AppState state,
    AppSettings settings,
    bool value,
  ) async {
    await state.updateSettings(settings.copyWith(lockScreenControls: value));
    final NotificationPermission permission = NotificationPermission.instance;
    if (!value || permission.granted || permission.needsSettings) return;
    await permission.request();
  }
}

/// The way into the paywall from settings, and the receipt once it is paid.
///
/// A [Panel] with a chevron rather than a [_Toggle], for two reasons. Premium
/// is not a preference the user flips — it is a purchase, and dressing it as a
/// switch would imply it can be turned off from here. And `layout_test` asserts
/// this screen holds exactly six [ExitSwitch]es, which is the kind of guard that
/// is easy to break and annoying to debug.
class _PremiumRow extends StatelessWidget {
  const _PremiumRow();

  @override
  Widget build(BuildContext context) {
    final bool premium = AppScope.of(context).isPremium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Semantics(
        button: true,
        label: premium ? 'Premium, active' : 'Get Premium',
        child: Panel(
          radius: ExitRadius.tile,
          color: premium ? ExitColors.greenWash : ExitColors.surf,
          borderColor: premium ? ExitColors.greenLine : ExitColors.line,
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                premium
                    ? Icons.check_circle
                    : Icons.workspace_premium_outlined,
                size: 18,
                color: premium ? ExitColors.green : ExitColors.amber,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      premium ? 'Premium' : 'Get Premium',
                      style: ExitText.row,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      premium
                          ? 'No ads · no limits'
                          : 'Remove ads · unlimited calls and imports',
                      style: ExitText.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: ExitColors.mid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The honest version of the footer line above it.
///
/// The app once claimed "100% OFFLINE · NO ACCOUNTS" outright, and that was
/// true. Two things have since made the unqualified claim false: the TikTok
/// Events SDK, so ad campaigns can tell which installs they paid for, and now
/// AdMob banners. Each time, the claim gets narrowed here rather than quietly
/// left standing.
///
/// The first paragraph is the part that is still exactly true and is what
/// people actually care about. The second says plainly what leaves, in the
/// specific terms Play's Data Safety form uses, and points at the control the
/// user actually has — Android's own advertising ID reset, which works whether
/// or not this app cooperates.
///
/// Shown to every build, including ones compiled without ad ids where nothing
/// is served at all. Over-disclosing costs nothing; the reverse is a lie in the
/// direction that matters.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Privacy', style: ExitText.row),
          const SizedBox(height: 6),
          Text(
            'Your sounds, imported files and call presets never leave this '
            'device. No account, no sync, no recording.',
            style: ExitText.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Ads and install measurement use your device advertising ID. The '
            'app sends no record of which sounds you play or when. You can '
            'reset or delete that ID in Android settings.',
            style: ExitText.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Semantics(
        toggled: value,
        label: label,
        child: Panel(
          onTap: () => onChanged(!value),
          radius: ExitRadius.tile,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: ExitText.row),
                    const SizedBox(height: 3),
                    Text(detail, style: ExitText.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExitSwitch(value: value),
            ],
          ),
        ),
      ),
    );
  }
}
