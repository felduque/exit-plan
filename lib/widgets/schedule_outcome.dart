import 'package:flutter/material.dart';

import '../calls/call_scheduler.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Tells the user what the device is actually going to do with a booking.
///
/// A receipt, not a celebration. Two of the four cases are the ones worth the
/// line: an inexact alarm and a call that will arrive as a banner are both
/// perfectly usable, and both are things somebody should learn now rather than
/// while waiting for a call that is running four minutes behind.
///
/// Shared between the editor's save and the list's call button so the two
/// cannot drift into describing the same outcome differently — which they did,
/// the list saying nothing at all.
void showScheduleOutcome(BuildContext context, ScheduleOutcome outcome) {
  final AppLocalizations loc = AppLocalizations.of(context);
  final String when =
      '${outcome.at.hour.toString().padLeft(2, '0')}:'
      '${outcome.at.minute.toString().padLeft(2, '0')}';

  final String message = switch ((outcome.exact, outcome.fullScreen)) {
    (true, true) => loc.callEditorScheduledExact(when),
    (false, true) => loc.callEditorScheduledApprox(when),
    (true, false) => loc.callEditorScheduledExactBanner(when),
    (false, false) => loc.callEditorScheduledApproxBanner(when),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message, style: ExitText.bodySmall)),
    );
}
