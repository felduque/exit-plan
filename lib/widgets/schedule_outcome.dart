import 'package:flutter/material.dart';

import '../calls/call_scheduler.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Tells the user what the device is actually going to do with a booking.
///
/// A receipt, not a celebration. Both cases say the call arrives as a banner,
/// because since the full-screen intent permission was dropped it always does,
/// and somebody should learn that now rather than while staring at a locked
/// screen waiting for a call to fill it. What still varies is the timing: an
/// inexact alarm is perfectly usable, but only if its owner knows it may run a
/// few minutes behind.
///
/// Shared between the editor's save and the list's call button so the two
/// cannot drift into describing the same outcome differently — which they did,
/// the list saying nothing at all.
void showScheduleOutcome(BuildContext context, ScheduleOutcome outcome) {
  final AppLocalizations loc = AppLocalizations.of(context);
  final String when =
      '${outcome.at.hour.toString().padLeft(2, '0')}:'
      '${outcome.at.minute.toString().padLeft(2, '0')}';

  final String message = outcome.exact
      ? loc.callEditorScheduledExactBanner(when)
      : loc.callEditorScheduledApproxBanner(when);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message, style: ExitText.bodySmall)),
    );
}
