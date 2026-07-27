import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_settings.dart';
import '../state/app_state.dart';
import '../state/permissions.dart';
import '../widgets/permission_notice.dart';

/// Six toggles, and nothing else. No paid tier, no upsell, no account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppSettings s = state.settings;

    return Scaffold(
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
                    onChanged: (bool v) =>
                        state.updateSettings(s.copyWith(maxVolumeOverride: v)),
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
                    onChanged: (bool v) => _setLockScreenControls(state, s, v),
                  ),
                  // Sits directly under the toggle it belongs to, so the reason
                  // the setting is not working is next to the setting.
                  NotificationPermissionNotice(relevant: s.lockScreenControls),
                  _Toggle(
                    label: 'In-app tips',
                    detail: 'Occasional reminders while open',
                    value: s.inAppTips,
                    onChanged: (bool v) =>
                        state.updateSettings(s.copyWith(inAppTips: v)),
                  ),
                ],
              ),
            ),
            const FooterNote('100% OFFLINE · NO ACCOUNTS'),
          ],
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
