import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';

/// A row of mutually exclusive cells inside one enclosing track.
///
/// Both firing parameters use it, on the home screen and on a category screen
/// alike, so whatever is fired behaves identically wherever it was set. The
/// selected cell is a raised slab rather than a coloured one: these are settings,
/// not actions, and colour on this screen belongs to the categories.
class SegmentedRow<T> extends StatelessWidget {
  const SegmentedRow({
    super.key,
    required this.caption,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.compact = false,
  });

  final String caption;
  final List<T> options;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  /// Shorter cells, for the pair sitting side by side on a category screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(caption, style: ExitText.caption),
        SizedBox(height: compact ? 6 : 7),
        DecoratedBox(
          decoration: BoxDecoration(
            color: ExitColors.surf,
            borderRadius: BorderRadius.all(Radius.circular(compact ? 10 : 11)),
            border: Border.all(color: ExitColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < options.length; i++) ...<Widget>[
                  if (i > 0) SizedBox(width: compact ? 4 : 5),
                  Expanded(
                    child: _Cell(
                      label: labelOf(options[i]),
                      active: options[i] == selected,
                      compact: compact,
                      onTap: () => onChanged(options[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // "∞" is drawn small by the face, so it needs a point more than the digits
    // to carry the same weight in the row.
    final bool symbol = label.length <= 1;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? ExitColors.raise : null,
            borderRadius: BorderRadius.all(Radius.circular(compact ? 7 : 8)),
          ),
          // A fixed height rather than padding: the oversized "∞" would
          // otherwise make its own cell taller and knock the two selectors on a
          // category screen out of alignment.
          child: SizedBox(
            height: compact ? 26 : 32,
            child: Center(
              child: Text(
                label,
                style: mono(
                  compact ? (symbol ? 11 : 10) : (symbol ? 12 : 11),
                  color: active ? ExitColors.hi : ExitColors.mid,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DelayFuseSelector extends StatelessWidget {
  const DelayFuseSelector({
    super.key,
    required this.seconds,
    required this.onChanged,
    this.compact = false,
  });

  final int seconds;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SegmentedRow<int>(
      caption: AppLocalizations.of(context).selectorFuseCaption,
      options: kDelayFuseOptions,
      selected: seconds,
      compact: compact,
      // Only the first cell carries the unit: "0s 5 10 30" reads as one scale,
      // where four repeated "s" glyphs read as four separate settings.
      labelOf: (int value) =>
          value == kDelayFuseOptions.first ? '${value}s' : '$value',
      onChanged: onChanged,
    );
  }
}

class LoopLengthSelector extends StatelessWidget {
  const LoopLengthSelector({
    super.key,
    required this.loop,
    required this.onChanged,
    this.compact = false,
  });

  final LoopChoice loop;
  final ValueChanged<LoopChoice> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const List<LoopChoice> options = kLoopOptions;

    return SegmentedRow<LoopChoice>(
      caption: AppLocalizations.of(context).selectorLoopCaption,
      // A loop restored from settings can be missing here; showing it as
      // unselected would be a lie, so fall back to the nearest cell.
      selected: options.contains(loop) ? loop : LoopChoice.infinite,
      options: options,
      compact: compact,
      labelOf: (LoopChoice value) => value.label,
      onChanged: onChanged,
    );
  }
}
