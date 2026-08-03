import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/system_catalog.dart';
import '../models/call_preset.dart';
import '../state/app_state.dart';
import 'browse_row.dart';
import 'call_preset_card.dart';
import 'quick_slot_button.dart';
import 'selectors.dart';

/// Four steps, shown only on the very first run — one per section of the app:
/// the quick-exit grid, the delay fuse, browsing the full library, and
/// building a fake call.
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

  static int get _lastStep => _kickers.length - 1;

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
                        for (int i = 0; i < _kickers.length; i++) ...<Widget>[
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
                  label: _step == _lastStep ? 'Start' : 'Next',
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
      case 2:
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
            name: 'Mom',
            number: '+1 555 0100',
            platform: CallPlatform.ios,
            ringtoneSoundId: kFallbackSoundId,
          ),
          onCall: _next,
          onEdit: _next,
        );
    }
  }

  static const List<String> _kickers = <String>[
    'THE EXIT',
    'DELAY FUSE',
    'FOUR SLOTS',
    'FAKE CALLS',
  ];

  static const List<String> _titles = <String>[
    'Tap it and\nthe room\nchanges.',
    'Arm it, then\npocket the\nphone.',
    'Four exits,\nalways one\ntap away.',
    'A call\nthat looks\nreal.',
  ];

  static const List<String> _bodies = <String>[
    'The screen goes completely black and the sound fires in a loop. '
        'It looks like the phone is in your pocket and the noise is real.',
    'Set a fuse of 5, 10 or 30 seconds. Fire it, put the phone away, and let '
        'the noise go off on its own — completely hands free.',
    'The home grid holds four sounds. Change any slot while browsing: tap the '
        'star on a sound and choose which slot it replaces.',
    'Build a caller under Fake calls: a name, a photo from your gallery, and '
        'whether it should look like iOS, Android or WhatsApp. Ring it, '
        'answer for real, hang up when you are ready to go. No new '
        'permission — the photo never leaves your phone.',
  ];
}
