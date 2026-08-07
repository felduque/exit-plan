import 'package:flutter/material.dart';

import '../audio/preview_player.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import '../models/enums.dart';
import '../models/escape_sound.dart';
import '../models/exit_category.dart';
import '../state/app_state.dart';
import '../widgets/ad_banner.dart';
import '../widgets/confirm.dart';
import '../widgets/selectors.dart';
import '../widgets/slot_picker_sheet.dart';
import '../widgets/sound_row.dart';
import '../widgets/tip_banner.dart';
import 'blackout_screen.dart';
import 'import_flow.dart';

/// One category, with the two firing parameters so whatever is fired from here
/// behaves exactly as it would from the home screen.
///
/// The category's colour appears once, as a wash behind the heading. It is the
/// only place in the app where a hue covers any real area, and it is what tells
/// you which category you are in before you read the name.
class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final PreviewPlayer _preview = PreviewPlayer();

  int _delay = 0;
  LoopChoice? _loop;

  @override
  void dispose() {
    // Leaving the screen always stops the preview.
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final ExitCategory? category = state.library.categoryById(
      widget.categoryId,
    );

    if (category == null) {
      // The category was deleted while this screen was open.
      return TipsSuppressor(
        child: Scaffold(
          body: Center(child: Text('Category not found', style: ExitText.body)),
        ),
      );
    }

    final LoopChoice loop = _loop ?? loopDefaultFor(state.settings.loopSound);
    final List<EscapeSound> sounds = category.sounds;
    final Color accent = category.isUser
        ? ExitColors.green
        : accentForCategory(category.id);

    return TipsSuppressor(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      accent.withValues(alpha: 0.12),
                      ExitColors.bg.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                    child: Row(
                      children: <Widget>[
                        const BackChevron(color: ExitColors.hi),
                        const Spacer(),
                        if (category.isUser)
                          IconTile(
                            icon: Icons.delete_outline,
                            semanticLabel: 'Delete category',
                            color: ExitColors.red,
                            size: 34,
                            iconSize: 17,
                            onTap: () => _deleteCategory(category),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: ExitColors.surf,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(14),
                            ),
                            border: Border.all(color: ExitColors.line2),
                          ),
                          child: Icon(
                            iconFor(category.icon),
                            size: 24,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      category.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: ExitText.display,
                                    ),
                                  ),
                                  if (category.isUser) ...<Widget>[
                                    const SizedBox(width: 9),
                                    const UserBadge(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _strapline(category),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: mono(10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: DelayFuseSelector(
                            compact: true,
                            seconds: _delay,
                            onChanged: (int value) =>
                                setState(() => _delay = value),
                          ),
                        ),
                        const SizedBox(width: 9),
                        SizedBox(
                          width: 104,
                          child: LoopLengthSelector(
                            compact: true,
                            loop: loop,
                            onChanged: (LoopChoice value) =>
                                setState(() => _loop = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    // Driven by the player itself — see [PreviewPlayer.playing].
                    child: ValueListenableBuilder<String?>(
                      valueListenable: _preview.playing,
                      builder: (BuildContext context, String? playingId, _) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                          children: <Widget>[
                            for (final EscapeSound sound in sounds) ...<Widget>[
                              SoundRow(
                                sound: sound,
                                pinned: state.isPinned(sound.id),
                                previewing: playingId == sound.id,
                                onFire: () => fireSound(
                                  context,
                                  soundId: sound.id,
                                  delaySeconds: _delay,
                                  loop: loop,
                                ),
                                onPreview: () => _preview.toggle(sound),
                                onPin: () => showSlotPicker(context, sound),
                                onDelete: sound.isUser
                                    ? () => _deleteSound(sound)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                            ],
                            AddYourAudioRow(
                              onTap: () => startImport(
                                context,
                                targetCategoryId: category.id,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const AdBannerSlot(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The mono line under the name. The description is written as sentences, so
  /// only its first clause survives being set in uppercase.
  static String _strapline(ExitCategory category) {
    final String lead = category.description.split('.').first.trim();
    final String count = '${category.sounds.length} SOUNDS';
    return lead.isEmpty ? count : '${lead.toUpperCase()} · $count';
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

  Future<void> _deleteCategory(ExitCategory category) async {
    final bool ok = await confirmDestructive(
      context,
      title: 'Delete category',
      message:
          '${category.label} and every sound in it will be removed, files included.',
    );
    if (!ok || !mounted) return;
    await _preview.stop();
    if (!mounted) return;
    await AppScope.read(context).deleteUserCategory(category.id);
    if (mounted) Navigator.of(context).pop();
  }
}
