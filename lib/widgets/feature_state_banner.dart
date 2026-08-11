import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../permissions/app_permission.dart';
import '../permissions/permission_center.dart';

/// Says out loud what a permission costs, and offers the one tap that fixes it.
///
/// Generalises the shape `NotificationPermissionNotice` established, with one
/// addition that is the whole point of it: **"needs a permission" and "cannot
/// do this at all" look different, and both look different from "will work,
/// less well".** An app that renders those three the same way teaches its users
/// that amber means nothing.
///
/// Amber rather than red throughout: a setting that is not doing its job is not
/// an emergency. Red on any ExitPlan screen belongs to fire, and to nothing
/// else.
class PermissionNotice extends StatelessWidget {
  const PermissionNotice({
    super.key,
    required this.permission,
    required this.title,
    required this.explanation,
    this.blocking = false,
  });

  final AppPermission permission;

  final String title;

  /// What is lost without it, in the user's terms. Never "grant this
  /// permission" — always what stops working if they do not.
  final String explanation;

  /// True when the feature does not work at all without this, false when it
  /// merely works worse. Changes the wording, not the colour.
  final bool blocking;

  @override
  Widget build(BuildContext context) {
    final PermissionCenter center = PermissionCenter.instance;

    return AnimatedBuilder(
      animation: center,
      builder: (BuildContext context, _) {
        final PermissionState state = center.stateOf(permission);
        // Nothing to say when it is granted — and nothing to *offer* when this
        // Android version has no such permission, which is the case the old
        // one-permission notice never had to think about. A button that opens a
        // settings page with no such switch on it is worse than silence.
        if (!state.actionable) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Panel(
            radius: ExitRadius.tile,
            borderColor: ExitColors.amber.withValues(alpha: 0.35),
            color: ExitColors.amber.withValues(alpha: 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      blocking
                          ? Icons.error_outline
                          : Icons.info_outline_rounded,
                      size: 16,
                      color: ExitColors.amber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: sans(13, weight: 600, color: ExitColors.amber),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(explanation, style: ExitText.bodySmall),
                const SizedBox(height: 12),
                _FixButton(
                  permission: permission,
                  availability: state.availability,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FixButton extends StatelessWidget {
  const _FixButton({required this.permission, required this.availability});

  final AppPermission permission;
  final PermissionAvailability availability;

  /// Only `POST_NOTIFICATIONS` has a runtime dialog, and only until it has been
  /// shown once. Everything else here lives on a settings page and always has,
  /// so offering "Allow" would be a button that visibly does nothing.
  bool get _canPrompt =>
      permission == AppPermission.notifications &&
      availability == PermissionAvailability.denied;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final String label = _canPrompt
        ? loc.permissionNoticeAllow
        : loc.permissionNoticeOpenSettings;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => PermissionCenter.instance.resolve(permission),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ExitColors.amber,
            borderRadius: ExitRadius.field,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Center(
              child: Text(
                label,
                style: sans(13, weight: 600, color: const Color(0xFF1A1206)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stack of notices a scheduled call needs, in order of consequence.
///
/// Ordered deliberately: telling somebody their call may be a couple of minutes
/// late is noise while the real problem is that no call will arrive at all.
/// Each renders nothing when its permission is fine, so a device with
/// everything granted shows an empty column and the editor looks untouched.
class ScheduleReadinessNotice extends StatelessWidget {
  const ScheduleReadinessNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PermissionNotice(
          permission: AppPermission.notifications,
          title: loc.scheduleNoticeNotificationsTitle,
          explanation: loc.scheduleNoticeNotificationsBody,
          blocking: true,
        ),
        PermissionNotice(
          permission: AppPermission.exactAlarm,
          title: loc.scheduleNoticeExactAlarmTitle,
          explanation: loc.scheduleNoticeExactAlarmBody,
        ),
      ],
    );
  }
}
