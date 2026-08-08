import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../screens/premium_screen.dart';
import '../state/ui_flags.dart';

/// Which limit the user just met.
enum PremiumGateKind {
  callPresets('fake call templates', 'template'),
  userSounds('imported sounds', 'sound'),
  userCategories('categories of your own', 'category');

  const PremiumGateKind(this.plural, this.singular);

  final String plural;
  final String singular;
}

/// The sheet shown when a free user asks for one more than they can have.
///
/// This is the only upsell in the app that interrupts anything, and it is the
/// one that has earned the right to: the user has just tapped "new". They asked
/// a question and this is the answer, so it is not counted against the nudge
/// budget in `PremiumCadence` — that budget exists for the ones nobody asked
/// for.
///
/// Two things the copy must always do, because both are true and both are the
/// difference between an honest limit and a hostage situation:
///
/// * say that nothing they already made is affected, and
/// * when their allowance is above the free tier — because they were using the
///   app before limits existed — say so, rather than quoting a number that
///   would look arbitrary and wrong to them.
Future<void> showPremiumGate(
  BuildContext context, {
  required PremiumGateKind kind,
  required int cap,
  required int freeLimit,
}) {
  /// True when this device kept an allowance larger than the free tier because
  /// it held that much before the limits shipped.
  final bool grandfathered = cap > freeLimit;

  return showPremiumSheet(
    context,
    title: 'That is $cap ${cap == 1 ? kind.singular : kind.plural}',
    body: grandfathered
        ? 'You had $cap before this version added limits, so you kept them '
              'all. Premium removes the ceiling entirely.'
        : 'The free version covers $freeLimit. Premium removes the limit on '
              '${kind.plural}, and the ads with it.',
  );
}

/// The same sheet, for a premium *theme* rather than a premium *quantity*.
///
/// A theme is not a cap, so it gets its own copy: there is no number to quote
/// and nothing the user is at risk of losing. What it must say instead is that
/// the free themes remain, because "this one costs money" and "you now have
/// fewer than you did" are very different messages and only the first is true.
Future<void> showPremiumThemeGate(BuildContext context, String themeName) {
  return showPremiumSheet(
    context,
    title: '$themeName is a Premium theme',
    body: 'Premium unlocks every call screen, and removes the ads. The free '
        'themes stay exactly where they are.',
    footnote: 'Templates you already saved keep the theme they were saved with.',
  );
}

/// The shared chrome. Wrapped in [withModal] like every other blocking flow, so
/// a tip banner cannot land on the buttons.
Future<void> showPremiumSheet(
  BuildContext context, {
  required String title,
  required String body,
  String footnote = 'Nothing you already made is affected.',
}) {
  return withModal(
    () => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x9E000000),
      builder: (BuildContext sheetContext) =>
          _GateSheet(title: title, body: body, footnote: footnote),
    ),
  );
}

class _GateSheet extends StatelessWidget {
  const _GateSheet({
    required this.title,
    required this.body,
    required this.footnote,
  });

  final String title;
  final String body;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ExitColors.surf2,
        borderRadius: ExitRadius.sheet,
        border: Border(top: BorderSide(color: ExitColors.line2)),
      ),
      child: SafeArea(
        top: false,
        // Scrollable, unlike the slot picker it borrows its shape from. That
        // sheet shows four fixed cells; this one shows a paragraph whose length
        // depends on which gate opened it — the longest version overflows a
        // 360dp phone, and a large system font scale would make it worse on any
        // device.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: const BoxDecoration(
                  color: ExitColors.line2,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              Text(
                title,
                style: sans(17, weight: 600, letterSpacing: -0.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(body, style: ExitText.body, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                footnote,
                style: ExitText.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'See Premium',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const PremiumScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: ExitRadius.field,
                    border: Border.all(color: ExitColors.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Text(
                      'Not now',
                      textAlign: TextAlign.center,
                      style: sans(13, weight: 500, color: ExitColors.mid),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
