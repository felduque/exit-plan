import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../themes/call_theme.dart';
import '../themes/call_theme_registry.dart';
import '../themes/call_visuals.dart';

/// The horizontal strip of call themes in the template editor.
///
/// ## The previews are the real screens
///
/// Each tile renders the theme's own `buildIncoming` at phone size and scales
/// it down, rather than showing a shipped PNG or a colour swatch. That costs a
/// little more to build and buys two things worth more than the saving:
///
/// * **A preview can never go stale.** A screenshot checked into `assets/`
///   drifts the first time somebody nudges a padding, and nothing fails when it
///   does — the user just gets sold a screen that no longer exists.
/// * **Nothing new has to ship.** Six PNGs at three densities is most of a
///   megabyte in an APK that is already large, for pictures of code that is
///   already in the binary.
///
/// [CallPreviewScope] is what makes it affordable: inside a tile the pulsing
/// accept ring sits still and the status-bar clock does not tick, so six live
/// call screens in a row are six static trees rather than twelve running
/// animations.
class CallThemePicker extends StatelessWidget {
  const CallThemePicker({
    super.key,
    required this.selectedId,
    required this.premium,
    required this.name,
    required this.avatarPath,
    required this.onSelect,
    required this.onLocked,
  });

  final String selectedId;

  /// Whether the user may pick a premium theme.
  final bool premium;

  /// Drawn into the previews, so the strip shows *their* caller rather than a
  /// stranger. Empty is fine — every theme falls back on its own.
  final String name;
  final String? avatarPath;

  final ValueChanged<CallTheme> onSelect;

  /// Called instead of [onSelect] when a locked theme is tapped.
  final ValueChanged<CallTheme> onLocked;

  /// The tile, and the phone it pretends to be. The device size is fixed rather
  /// than taken from the real screen so every tile scales identically and the
  /// strip does not reflow between a tall phone and a short one.
  static const Size _device = Size(360, 720);
  static const double _tileWidth = 92;
  static const double _tileHeight = 164;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('CALL SCREEN', style: ExitText.caption),
        const SizedBox(height: 8),
        SizedBox(
          height: _tileHeight + 26,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: kCallThemes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final CallTheme theme = kCallThemes[index];
              final bool locked = theme.premium && !premium;
              return _ThemeTile(
                theme: theme,
                selected: theme.id == selectedId,
                locked: locked,
                name: name,
                avatarPath: avatarPath,
                onTap: () => locked ? onLocked(theme) : onSelect(theme),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.selected,
    required this.locked,
    required this.name,
    required this.avatarPath,
    required this.onTap,
  });

  final CallTheme theme;
  final bool selected;
  final bool locked;
  final String name;
  final String? avatarPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '${theme.name}, Premium' : theme.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: CallThemePicker._tileWidth,
              height: CallThemePicker._tileHeight,
              decoration: BoxDecoration(
                borderRadius: ExitRadius.card,
                border: Border.all(
                  color: selected ? ExitColors.green : ExitColors.line2,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: ExitRadius.card,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _Preview(
                      theme: theme,
                      name: name,
                      avatarPath: avatarPath,
                    ),
                    if (locked)
                      const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xA6000000)),
                        child: Center(
                          child: Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: ExitColors.amber,
                          ),
                        ),
                      ),
                    if (selected)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: _SelectedDot(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: CallThemePicker._tileWidth,
              child: Text(
                theme.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sans(
                  11,
                  weight: selected ? 600 : 500,
                  color: selected ? ExitColors.hi : ExitColors.mid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The theme's own incoming-call layout, at phone size, scaled into the tile.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.theme,
    required this.name,
    required this.avatarPath,
  });

  final CallTheme theme;
  final String name;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox.fromSize(
        size: CallThemePicker._device,
        // A clean MediaQuery: the real one carries this phone's notch and
        // navigation insets, and a SafeArea inside a 720px-tall box that is
        // then scaled to 164px would push the layout around by an amount that
        // depends on the *host* device rather than on the theme.
        child: MediaQuery(
          data: const MediaQueryData(size: CallThemePicker._device),
          child: CallPreviewScope(
            // The tile owns the tap. Letting a preview's own Accept button
            // receive one would answer a call that is not happening.
            child: IgnorePointer(
              child: theme.buildIncoming(
                CallIncomingContext(
                  name: name.trim().isEmpty ? 'Caller' : name,
                  number: '',
                  avatarPath: avatarPath,
                  onAccept: callNoop,
                  onDecline: callNoop,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedDot extends StatelessWidget {
  const _SelectedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: ExitColors.green,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 12, color: ExitColors.onGreen),
    );
  }
}
