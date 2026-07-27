import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/enums.dart';
import '../state/app_state.dart';
import '../state/permissions.dart';
import '../widgets/browse_row.dart';
import '../widgets/quick_slot_button.dart';
import '../widgets/selectors.dart';
import 'blackout_screen.dart';
import 'browse_screen.dart';
import 'settings_screen.dart';

/// The heart of the app, and the only screen that has to work in a hurry:
/// header, the 2x2 grid of exits, the two firing parameters, and one line into
/// the rest of the library.
///
/// Navigation is flat by design. There is no tab bar and no category grid — four
/// exits are a tap away and everything else is one screen deeper.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _delay = 0;
  LoopChoice? _loop;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final LoopChoice loop = _loop ?? loopDefaultFor(state.settings.loopSound);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Masthead(
                      exits: state.quickAccess.length,
                      wantsNotifications: state.settings.lockScreenControls,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'QUICK EXITS',
                      style: mono(9, color: ExitColors.dim, letterSpacing: 2),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 11,
                      crossAxisSpacing: 11,
                      // Tall enough for the icon, the name, a two-line excuse
                      // and the fire marker without any of them clipping.
                      mainAxisExtent: 150,
                      children: <Widget>[
                        for (int i = 0; i < state.quickAccess.length; i++)
                          QuickSlotButton(
                            slot: i,
                            sound: state.quickSlotSound(i),
                            onFire: () => _fire(state.quickAccess[i], loop),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: DelayFuseSelector(
                            seconds: _delay,
                            onChanged: (int value) =>
                                setState(() => _delay = value),
                          ),
                        ),
                        const SizedBox(width: 9),
                        SizedBox(
                          width: 112,
                          child: LoopLengthSelector(
                            loop: loop,
                            onChanged: (LoopChoice value) =>
                                setState(() => _loop = value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Kept out of the scroll view: browsing is where the thumb goes when
            // nothing in the grid fits, and it should always be in the same
            // place at the bottom of the screen.
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: BrowseRow(
                categoryCount: state.library.categoryCount,
                soundCount: state.library.soundCount,
                onTap: () => _open(const BrowseScreen()),
              ),
            ),
            const FooterNote('TAP AN EXIT · SCREEN GOES DARK · SOUND FIRES'),
          ],
        ),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _fire(String soundId, LoopChoice loop) {
    fireSound(context, soundId: soundId, delaySeconds: _delay, loop: loop);
  }
}

/// Name, state and the way out to settings.
///
/// The status line is the only always-on colour on the screen, and it is a real
/// status line: green means the four slots resolved and the app is ready to
/// fire. It turns amber when something the user asked for is not actually
/// working — right now that is only the notification permission, which
/// lock-screen controls depend on. Tapping it goes where the fix is.
///
/// This is the app's one unprompted reminder. It has to stay this quiet: a
/// dialog or a red banner on the home screen is exactly what somebody glancing
/// over a shoulder would notice.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.exits, required this.wantsNotifications});

  final int exits;

  /// Whether the missing permission would actually cost the user anything.
  final bool wantsNotifications;

  @override
  Widget build(BuildContext context) {
    void openSettings() => Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('EXITPLAN', style: ExitText.brand),
              const SizedBox(height: 5),
              AnimatedBuilder(
                animation: NotificationPermission.instance,
                builder: (BuildContext context, _) {
                  final bool blocked =
                      wantsNotifications &&
                      !NotificationPermission.instance.granted;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: blocked ? openSettings : null,
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: blocked
                                ? ExitColors.amber
                                : ExitColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        // Flexible because the warning is the longest line this
                        // slot ever holds, and it shares the row with the
                        // settings button. On a narrow phone, or at a large
                        // system font scale, it has to shorten rather than
                        // overflow — the status line is the last thing that
                        // should be throwing up a debug stripe.
                        Flexible(
                          child: Text(
                            blocked
                                ? 'NO NOTIFICATIONS · TAP TO FIX'
                                : 'STANDBY · $exits EXITS READY',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: mono(
                              10,
                              color: blocked
                                  ? ExitColors.amber
                                  : ExitColors.mid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        IconTile(
          icon: Icons.settings_outlined,
          semanticLabel: 'Settings',
          onTap: openSettings,
        ),
      ],
    );
  }
}
