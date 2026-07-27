import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import 'browse_row.dart';
import 'quick_slot_button.dart';
import 'selectors.dart';

/// Three steps, shown only on the very first run.
///
/// It uses the **real** controls rather than mock-ups, so what the user learns
/// here is exactly what they will touch afterwards. The system back gesture
/// steps back through the intro instead of reaching the screen underneath.
class IntroOverlay extends StatefulWidget {
  const IntroOverlay({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay> {
  int _step = 0;
  int _delayDemo = 10;

  void _next() {
    if (_step >= 2) {
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
                        for (int i = 0; i < 3; i++) ...<Widget>[
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
                        child: Text('SKIP', style: mono(10)),
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
                            'STEP 0${_step + 1} · ${_kickers[_step]}',
                            style: mono(9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _titles[_step],
                        style: sans(
                          30,
                          weight: 600,
                          letterSpacing: -1,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _bodies[_step],
                        style: sans(13, color: ExitColors.mid, height: 1.65),
                      ),
                      const SizedBox(height: 26),
                      _demo(state),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: PrimaryButton.neutral(
                  label: _step == 2 ? 'Start' : 'Next',
                  onTap: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demo(AppState state) {
    switch (_step) {
      case 0:
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
      case 1:
        return DelayFuseSelector(
          seconds: _delayDemo,
          onChanged: (int value) => setState(() => _delayDemo = value),
        );
      default:
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
    }
  }

  static const List<String> _kickers = <String>[
    'THE EXIT',
    'DELAY FUSE',
    'FOUR SLOTS',
  ];

  static const List<String> _titles = <String>[
    'Tap it and\nthe room\nchanges.',
    'Arm it, then\npocket the\nphone.',
    'Four exits,\nalways one\ntap away.',
  ];

  static const List<String> _bodies = <String>[
    'The screen goes completely black and the sound fires in a loop. '
        'It looks like the phone is in your pocket and the noise is real.',
    'Set a fuse of 5, 10 or 30 seconds. Fire it, put the phone away, and let '
        'the noise go off on its own — completely hands free.',
    'The home grid holds four sounds. Change any slot while browsing: tap the '
        'star on a sound and choose which slot it replaces.',
  ];
}
