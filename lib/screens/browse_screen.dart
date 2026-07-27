import 'package:flutter/material.dart';

import '../audio/preview_player.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import '../models/enums.dart';
import '../models/escape_sound.dart';
import '../models/exit_category.dart';
import '../state/app_state.dart';
import '../widgets/confirm.dart';
import '../widgets/slot_picker_sheet.dart';
import '../widgets/sound_row.dart';
import 'blackout_screen.dart';
import 'category_detail_screen.dart';
import 'import_flow.dart';

/// Every exit in the app, on one screen.
///
/// This is the flat half of the navigation: instead of a list of categories that
/// opens a list of sounds, the categories are headings inside a single list and
/// the chips at the top narrow it. A category still has its own screen — reached
/// by tapping a heading — but only for what belongs to one category alone: the
/// firing parameters, importing into it, and deleting it.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final PreviewPlayer _preview = PreviewPlayer();

  /// Null means "all". Otherwise the only category shown.
  String? _filter;

  @override
  void dispose() {
    // Leaving the screen always stops the preview.
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<ExitCategory> categories = state.library.categories;
    // A filter can point at a category that was deleted from under it.
    final String? filter = categories.any((ExitCategory c) => c.id == _filter)
        ? _filter
        : null;
    final List<ExitCategory> shown = filter == null
        ? categories
        : categories.where((ExitCategory c) => c.id == filter).toList();

    // Firing from here uses the defaults: no fuse, and the loop the user set in
    // settings. The fuse belongs to the screens that show it.
    final LoopChoice loop = loopDefaultFor(state.settings.loopSound);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
              child: Row(
                children: <Widget>[
                  const BackChevron(),
                  Expanded(child: Text('All exits', style: ExitText.title)),
                  _ImportButton(onTap: () => startImport(context)),
                ],
              ),
            ),
            _FilterBar(
              categories: categories,
              selected: filter,
              onSelected: (String? id) => setState(() => _filter = id),
            ),
            Expanded(
              // The playing state comes straight from the player, so the row's
              // icon can never disagree with what is coming out of the speaker.
              child: ValueListenableBuilder<String?>(
                valueListenable: _preview.playing,
                builder: (BuildContext context, String? playingId, _) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                    children: <Widget>[
                      for (final ExitCategory category in shown) ...<Widget>[
                        _GroupHeading(
                          category: category,
                          onTap: () => _openCategory(category),
                        ),
                        for (final EscapeSound sound
                            in category.sounds) ...<Widget>[
                          SoundRow(
                            sound: sound,
                            pinned: state.isPinned(sound.id),
                            previewing: playingId == sound.id,
                            onFire: () => fireSound(
                              context,
                              soundId: sound.id,
                              delaySeconds: 0,
                              loop: loop,
                            ),
                            onPreview: () => _preview.toggle(sound),
                            onPin: () => showSlotPicker(context, sound),
                            onDelete: sound.isUser
                                ? () => _deleteSound(sound)
                                : null,
                          ),
                          const SizedBox(height: 7),
                        ],
                        if (category.sounds.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: AddYourAudioRow(
                              onTap: () => startImport(
                                context,
                                targetCategoryId: category.id,
                              ),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategory(ExitCategory category) {
    // A preview must not keep playing under the screen that replaced it.
    _preview.stop();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailScreen(categoryId: category.id),
      ),
    );
  }

  Future<void> _deleteSound(EscapeSound sound) async {
    final bool ok = await confirmDestructive(
      context,
      title: 'Delete sound',
      message: '${sound.label} and its audio file will be removed.',
    );
    if (!ok || !mounted) return;
    await _preview.stop();
    if (!mounted) return;
    await AppScope.read(context).deleteUserSound(sound.id);
  }
}

/// The horizontal row of category chips. ALL is first and is what the screen
/// opens on — narrowing is the exception, not the way in.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<ExitCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
        children: <Widget>[
          _Chip(
            label: 'ALL',
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final ExitCategory category in categories) ...<Widget>[
            const SizedBox(width: 7),
            _Chip(
              label: category.label.toUpperCase(),
              active: selected == category.id,
              onTap: () => onSelected(category.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: active ? ExitColors.raise : ExitColors.surf,
              borderRadius: ExitRadius.chip,
              border: Border.all(
                color: active ? Colors.transparent : ExitColors.line,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              label,
              style: mono(10, color: active ? ExitColors.hi : ExitColors.mid),
            ),
          ),
        ),
      ),
    );
  }
}

/// A category's name inside the flat list: a square of its colour, the name in
/// mono, and a chevron that opens the category's own screen.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.category, required this.onTap});

  final ExitCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = category.isUser
        ? ExitColors.green
        : accentForCategory(category.id);

    return Semantics(
      button: true,
      label: 'Open ${category.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
          child: Row(
            children: <Widget>[
              CategoryDot(accent),
              const SizedBox(width: 9),
              Text(
                category.label.toUpperCase(),
                style: mono(9, letterSpacing: 1.5),
              ),
              const SizedBox(width: 8),
              Text(
                '${category.sounds.length}',
                style: mono(9, color: ExitColors.dim),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16, color: ExitColors.dim),
            ],
          ),
        ),
      ),
    );
  }
}

/// Import lives here rather than on the home screen: adding audio is something
/// you do once, while browsing, not something you reach for in a hurry.
class _ImportButton extends StatelessWidget {
  const _ImportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Import audio',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: ExitColors.surf,
            borderRadius: const BorderRadius.all(Radius.circular(9)),
            border: Border.all(color: ExitColors.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.add, size: 13, color: ExitColors.hi),
              const SizedBox(width: 7),
              Text('IMPORT', style: mono(10, color: ExitColors.hi)),
            ],
          ),
        ),
      ),
    );
  }
}
