import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../state/permissions.dart';

/// Says out loud that notifications are denied, what that costs, and offers the
/// one tap that fixes it.
///
/// Amber rather than red: this is a setting that is not doing its job, not an
/// emergency. Red on this screen belongs to fire and to nothing else.
///
/// Renders nothing when the permission is granted, or when [relevant] is false —
/// with lock-screen controls turned off the app does not want a notification
/// anyway, and nagging for a permission it will not use is exactly the sort of
/// thing this app refuses to do.
class NotificationPermissionNotice extends StatelessWidget {
  const NotificationPermissionNotice({super.key, required this.relevant});

  final bool relevant;

  @override
  Widget build(BuildContext context) {
    final NotificationPermission permission = NotificationPermission.instance;

    return AnimatedBuilder(
      animation: permission,
      builder: (BuildContext context, _) {
        if (!relevant || permission.granted) return const SizedBox.shrink();

        final AppLocalizations loc = AppLocalizations.of(context);
        final bool settings = permission.needsSettings;

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
                    const Icon(
                      Icons.notifications_off_outlined,
                      size: 16,
                      color: ExitColors.amber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.permissionNoticeBlockedTitle,
                        style: sans(13, weight: 600, color: ExitColors.amber),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(loc.permissionNoticeBody, style: ExitText.bodySmall),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: settings
                      ? loc.permissionNoticeOpenAppSettings
                      : loc.permissionNoticeAllowNotifications,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: permission.resolve,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ExitColors.amber,
                        borderRadius: ExitRadius.field,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Center(
                          child: Text(
                            // Android only ever shows the dialog once. Offering
                            // "Allow" a second time would do nothing at all and
                            // look broken, so past that point this says where
                            // the switch actually lives.
                            settings
                                ? loc.permissionNoticeOpenSettings
                                : loc.permissionNoticeAllow,
                            style: sans(
                              13,
                              weight: 600,
                              color: const Color(0xFF1A1206),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
