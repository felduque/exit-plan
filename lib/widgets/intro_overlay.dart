import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/system_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/call_preset.dart';
import '../state/app_state.dart';
import '../themes/call_theme_registry.dart';
import 'browse_row.dart';
import 'call_preset_card.dart';
import 'quick_slot_button.dart';
import 'selectors.dart';

/// Five steps, shown only on the very first run: language, then one per
/// section of the app — the quick-exit grid, the delay fuse, browsing the
/// full library, and building a fake call.
///
/// Language comes first and gets its own step, not a small toggle tucked in
/// the header — it is the one choice that changes how every step after it
/// reads, so it has to be impossible to miss and easy to change your mind
/// about before going further.
///
/// The other four use the **real** controls rather than mock-ups, so what the
/// user learns here is exactly what they will touch afterwards. The system
/// back gesture steps back through the intro instead of reaching the screen
/// underneath.
class IntroOverlay extends StatefulWidget {
  const IntroOverlay({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay> {
  int _step = 0;
  int _delayDemo = 10;

  /// The step count is a fixed property of the tour itself, independent of
  /// the (now build-time, localized) copy arrays below. Step 0 is language;
  /// 1-4 are the four content steps.
  static const int _lastStep = 4;

  void _next() {
    if (_step >= _lastStep) {
      widget.onDone();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppLocalizations loc = AppLocalizations.of(context);

    final List<String> kickers = <String>[
      loc.introKicker0,
      loc.introKicker1,
      loc.introKicker2,
      loc.introKicker3,
    ];
    final List<String> titles = <String>[
      loc.introTitle0,
      loc.introTitle1,
      loc.introTitle2,
      loc.introTitle3,
    ];
    final List<String> bodies = <String>[
      loc.introBody0,
      loc.introBody1,
      loc.introBody2,
      loc.introBody3,
    ];

    final String kicker = _step == 0
        ? loc.introLanguageKicker
        : kickers[_step - 1];
    final String title = _step == 0
        ? loc.introLanguageTitle
        : titles[_step - 1];
    final String body = _step == 0 ? loc.introLanguageBody : bodies[_step - 1];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) => _back(),
      child: ColoredBox(
        color: ExitColors.bg,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        for (int i = 0; i <= _lastStep; i++) ...<Widget>[
                          if (i > 0) const SizedBox(width: 6),
                          Container(
                            width: 24,
                            height: 3,
                            decoration: BoxDecoration(
                              color: i == _step
                                  ? ExitColors.hi
                                  : ExitColors.raise,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onDone,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(loc.introSkip, style: mono(10)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: ExitRadius.chip,
                          border: Border.all(color: ExitColors.line2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          child: Text(
                            loc.introStepLabel(_step + 1, kicker),
                            style: mono(9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        title,
                        style: sans(
                          30,
                          weight: 600,
                          letterSpacing: -1,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        body,
                        style: sans(13, color: ExitColors.mid, height: 1.65),
                      ),
                      const SizedBox(height: 26),
                      _demo(state, loc),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: PrimaryButton.neutral(
                  label: _step == _lastStep ? loc.introStart : loc.introNext,
                  onTap: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demo(AppState state, AppLocalizations loc) {
    switch (_step) {
      case 0:
        return _LanguageStep(state: state);
      case 1:
        return SizedBox(
          height: 150,
          width: 186,
          child: QuickSlotButton(
            slot: 0,
            sound: state.quickSlotSound(0),
            // In the intro this only advances the tour; nothing fires.
            onFire: _next,
          ),
        );
      case 2:
        return DelayFuseSelector(
          seconds: _delayDemo,
          onChanged: (int value) => setState(() => _delayDemo = value),
        );
      case 3:
        return Column(
          children: <Widget>[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              mainAxisExtent: 150,
              children: <Widget>[
                for (int i = 0; i < 4; i++)
                  QuickSlotButton(
                    slot: i,
                    sound: state.quickSlotSound(i),
                    onFire: _next,
                  ),
              ],
            ),
            const SizedBox(height: 11),
            BrowseRow(
              categoryCount: state.library.categoryCount,
              soundCount: state.library.soundCount,
              onTap: _next,
            ),
          ],
        );
      default:
        // A throwaway preset, never saved — the intro only borrows the real
        // card so the tour matches what `CallsScreen` actually shows.
        return CallPresetCard(
          preset: CallPreset(
            id: 'intro-demo',
            name: loc.introDemoCallerName,
            number: '+1 555 0100',
            themeId: kDefaultCallThemeId,
            ringtoneSoundId: kFallbackSoundId,
          ),
          onCall: _next,
          onEdit: _next,
        );
    }
  }
}

/// Two full-width cards, not a pill tucked in a corner — this is the one
/// choice in the intro that changes how every other step reads, so it gets
/// the same visual weight as the real controls the other steps demo.
///
/// A language is already picked by the time this shows (the system locale,
/// resolved in `app.dart`), so this is confirm-or-change, not a blocking
/// choice — `Next` always works.
class _LanguageStep extends StatelessWidget {
  const _LanguageStep({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final String current =
        state.languageCode ?? Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _option(code: 'en', label: 'English', current: current),
        const SizedBox(height: 10),
        _option(code: 'es', label: 'Español', current: current),
      ],
    );
  }

  Widget _option({
    required String code,
    required String label,
    required String current,
  }) {
    final bool selected = current == code;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Panel(
        onTap: () => state.setLanguageCode(code),
        radius: ExitRadius.tile,
        color: selected ? ExitColors.raise : ExitColors.surf,
        borderColor: selected ? ExitColors.line2 : ExitColors.line,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: sans(16, weight: 600, letterSpacing: -0.2),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 20, color: ExitColors.hi),
          ],
        ),
      ),
    );
  }
}
