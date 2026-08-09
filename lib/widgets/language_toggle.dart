import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';

/// A compact `EN | ES` text toggle, sized to sit next to controls like the
/// intro's SKIP button.
///
/// Not [SegmentedRow]: that widget always renders a caption label above its
/// pills, which is too heavy for a header slot next to a plain text button.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final String current =
        state.languageCode ?? Localizations.localeOf(context).languageCode;

    Widget option(String code, String label) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => state.setLanguageCode(code),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          label,
          style: mono(
            10,
            color: current == code ? ExitColors.hi : ExitColors.mid,
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        option('en', 'EN'),
        Text('/', style: mono(10, color: ExitColors.line2)),
        option('es', 'ES'),
      ],
    );
  }
}
