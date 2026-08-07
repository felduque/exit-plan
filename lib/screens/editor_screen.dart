import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/preview_player.dart';
import '../core/icons.dart';
import '../core/premium_config.dart';
import '../core/theme.dart';
import '../data/system_catalog.dart';
import '../data/user_files.dart';
import '../models/enums.dart';
import '../models/escape_sound.dart';
import '../models/exit_category.dart';
import '../state/app_state.dart';
import '../state/ui_flags.dart';
import '../widgets/ad_banner.dart';
import '../widgets/premium_gate_sheet.dart';
import '../widgets/tip_banner.dart';
import '../widgets/trim_timeline.dart';
import 'category_detail_screen.dart';

/// Turns an imported file into a user sound.
///
/// The trim is **virtual**: the file is never cut or re-encoded, only the window
/// is stored, and playback clips to it. If the user leaves without saving, the
/// copied file is deleted so nothing is left behind.
///
/// Green runs through this whole screen — the trim window, the cursor, the
/// chosen icon, the save slab. It is the app's colour for the user's own work,
/// and this is the only screen where the user makes any.
class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.filePath,
    required this.suggestedLabel,
    this.targetCategoryId,
  });

  /// Default window when the file is longer than this.
  static const Duration defaultWindow = Duration(seconds: 30);

  final String filePath;
  final String suggestedLabel;
  final String? targetCategoryId;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final PreviewPlayer _preview = PreviewPlayer();
  late final TextEditingController _label = TextEditingController(
    text: widget.suggestedLabel,
  );
  final TextEditingController _newCategory = TextEditingController();

  StreamSubscription<Duration>? _positionSub;

  Duration _duration = Duration.zero;
  Duration _start = Duration.zero;
  Duration _end = Duration.zero;
  Duration _position = Duration.zero;

  String _icon = 'audio';
  String? _categoryId;
  bool _creatingCategory = false;
  String _newCategoryIcon = 'folder';
  bool _saved = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.targetCategoryId;
    _load();
  }

  Future<void> _load() async {
    try {
      final Duration? duration = await _preview.loadFile(widget.filePath);
      if (!mounted) return;
      final Duration total = duration ?? Duration.zero;
      setState(() {
        _duration = total;
        _start = Duration.zero;
        // First 30 seconds, or the whole file when it is shorter.
        _end = total <= EditorScreen.defaultWindow
            ? total
            : EditorScreen.defaultWindow;
      });
      _positionSub = _preview.positionStream.listen((Duration position) {
        if (mounted) setState(() => _position = position);
      });
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _preview.dispose();
    _label.dispose();
    _newCategory.dispose();
    // Orphan cleanup: nothing was saved, so the copy is rubbish.
    if (!_saved) UserFiles.delete(widget.filePath);
    super.dispose();
  }

  bool get _canSave =>
      !_loadFailed &&
      _label.text.trim().isNotEmpty &&
      _categoryId != null &&
      _end > _start;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);

    return TipsSuppressor(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                child: Row(
                  children: <Widget>[
                    BackChevron(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Text('New exit', style: ExitText.title),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                  children: <Widget>[
                    if (_loadFailed)
                      Panel(
                        borderColor: ExitColors.red,
                        child: Text(
                          'This file could not be read.',
                          style: ExitText.row.copyWith(color: ExitColors.red),
                        ),
                      )
                    else ...<Widget>[
                      TrimTimeline(
                        duration: _duration,
                        start: _start,
                        end: _end,
                        position: _position,
                        onChanged: (Duration start, Duration end) {
                          setState(() {
                            _start = start;
                            _end = end;
                          });
                          // Keeps a preview that is already running on the bounds
                          // being dragged, instead of looping the old cut.
                          _preview.retargetWindow(start, end);
                        },
                        onEdgeReleased: _auditionEdge,
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<String?>(
                        valueListenable: _preview.playing,
                        builder: (BuildContext context, String? playing, _) =>
                            _PreviewButton(
                              playing: playing != null,
                              onTap: _toggleWindow,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const _FieldCaption('LABEL'),
                    Panel(
                      radius: ExitRadius.field,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _label,
                        textCapitalization: TextCapitalization.sentences,
                        style: sans(14, weight: 500),
                        cursorColor: ExitColors.green,
                        cursorWidth: 2,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Name it',
                          hintStyle: sans(14, color: ExitColors.dim),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _FieldCaption('ICON'),
                    _IconPicker(
                      selected: _icon,
                      onSelected: (String value) =>
                          setState(() => _icon = value),
                    ),
                    const SizedBox(height: 20),
                    const _FieldCaption('TARGET CATEGORY'),
                    _CategoryField(
                      category: _categoryId == null
                          ? null
                          : state.library.categoryById(_categoryId!),
                      onTap: () => _pickCategory(state),
                    ),
                    if (_creatingCategory) ...<Widget>[
                      const SizedBox(height: 8),
                      _NewCategoryForm(
                        controller: _newCategory,
                        icon: _newCategoryIcon,
                        onIcon: (String value) =>
                            setState(() => _newCategoryIcon = value),
                        onCancel: () =>
                            setState(() => _creatingCategory = false),
                        onCreate: () => _createCategory(state),
                      ),
                    ],
                  ],
                ),
              ),
              // This screen ends in a primary filled action rather than a
              // footer or a list, which is the one shape the banner's placement
              // contract warns about: an ad directly under a Save button is the
              // accidental-click layout AdMob treats as invalid traffic.
              //
              // It carries one anyway, with the risk bought down two ways:
              //
              // * The bottom padding is 28 rather than the usual 14, so there
              //   is double the dead space between the button and the ad's
              //   hairline. Nothing else in the app uses 28 here; it is not a
              //   style choice and should not be "tidied" back to 14.
              // * AdBannerSlot yields entirely while the keyboard is open (see
              //   rule 5 there), which matters because the label field on this
              //   screen would otherwise push the ad up against the button.
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                child: PrimaryButton(
                  label: 'Save exit',
                  enabled: _canSave,
                  onTap: _canSave ? () => _save(state) : null,
                ),
              ),
              const AdBannerSlot(),
            ],
          ),
        ),
      ),
    );
  }

  /// Starts or stops the window preview.
  ///
  /// "Stop" covers an edge audition too: whatever is audible, this button is the
  /// one that silences it, so it must never be showing "play" while something
  /// is coming out of the speaker.
  Future<void> _toggleWindow() async {
    if (_preview.isPlaying) {
      await _preview.pause();
      return;
    }
    await _preview.playWindow(_start, _end);
  }

  /// Puts the playhead where the handle landed, so the next thing heard is the
  /// cut that was just made. Only does anything while a preview is running —
  /// dragging never starts or stops the audio, the play button does.
  ///
  /// The end handle lands slightly *before* its edge: the interesting part of a
  /// closing cut is the moment leading into it, not the silence after.
  Future<void> _auditionEdge(bool startEdge) async {
    final Duration at = startEdge
        ? _start
        : Duration(
            milliseconds: math.max(
              _start.inMilliseconds,
              _end.inMilliseconds - 700,
            ),
          );
    await _preview.seekToEdge(at);
  }

  /// The destination is one line with a sheet behind it rather than a list of
  /// every category inline: the trim and the name are what this screen is about,
  /// and a six-row radio list pushed the save button off the fold.
  Future<void> _pickCategory(AppState state) async {
    final String? picked = await showCategorySheet(
      context,
      categories: state.library.categories,
      selected: _categoryId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked == kNewCategorySentinel) {
        _creatingCategory = true;
      } else {
        _categoryId = picked;
        _creatingCategory = false;
      }
    });
  }

  Future<void> _createCategory(AppState state) async {
    final String name = _newCategory.text.trim();
    if (name.isEmpty) return;

    // The one gate that cannot sit at the start of the flow: making a category
    // is a step *inside* saving a sound, not a journey of its own. So it is
    // checked at the moment of creation — and it costs the user nothing,
    // because the sound they are editing is unaffected and every existing
    // category is still there to file it under.
    if (!state.canAddUserCategory) {
      await showPremiumGate(
        context,
        kind: PremiumGateKind.userCategories,
        cap: state.userCategoryCap,
        freeLimit: FreeLimits.userCategories,
      );
      return;
    }
    if (!mounted) return;
    final ExitCategory category = ExitCategory(
      id: 'usercat-${DateTime.now().microsecondsSinceEpoch}',
      label: name,
      description: 'Your own category.',
      icon: _newCategoryIcon,
      origin: SoundOrigin.user,
    );
    await state.addUserCategory(category);
    if (!mounted) return;
    setState(() {
      _categoryId = category.id;
      _creatingCategory = false;
      _newCategory.clear();
    });
  }

  Future<void> _save(AppState state) async {
    final String? categoryId = _categoryId;
    if (categoryId == null) return;

    await _preview.stop();

    final EscapeSound sound = EscapeSound(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      // Kept exactly as typed. Names are sentence case everywhere now, and
      // shouting the user's own label back at them is not the app's business.
      label: _label.text.trim(),
      categoryId: categoryId,
      icon: _icon,
      source: UserFileSource(widget.filePath),
      vibration: _inheritedVibration(state, categoryId),
      origin: SoundOrigin.user,
      trim: TrimWindow(
        startMs: _start.inMilliseconds,
        endMs: _end.inMilliseconds,
      ),
    );

    _saved = true;
    await state.addUserSound(sound);
    if (!mounted) return;

    // Land on the category the sound went into.
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailScreen(categoryId: categoryId),
      ),
    );
  }

  /// Inherits the pattern of the destination category: its first system sound if
  /// there is one, otherwise no vibration at all.
  List<int> _inheritedVibration(AppState state, String categoryId) {
    final ExitCategory? category = state.library.categoryById(categoryId);
    if (category != null) {
      for (final EscapeSound sound in category.sounds) {
        if (!sound.isUser) return sound.vibration;
      }
    }
    return vibrationForCategory(categoryId);
  }
}

/// Returned by [showCategorySheet] when the user wants a category that does not
/// exist yet.
const String kNewCategorySentinel = '@new';

/// The destination picker: every category, plus one way to make another.
Future<String?> showCategorySheet(
  BuildContext context, {
  required List<ExitCategory> categories,
  required String? selected,
}) {
  return withModal(
    () => showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x9E000000),
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: ExitColors.surf2,
            borderRadius: ExitRadius.sheet,
            border: Border(top: BorderSide(color: ExitColors.line2)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
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
                    'Save it where?',
                    style: sans(17, weight: 600, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        for (final ExitCategory category in categories)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: _CategoryOption(
                              category: category,
                              selected: category.id == selected,
                              onTap: () =>
                                  Navigator.of(sheetContext).pop(category.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Panel(
                    onTap: () =>
                        Navigator.of(sheetContext).pop(kNewCategorySentinel),
                    radius: ExitRadius.field,
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.add, size: 16, color: ExitColors.mid),
                        const SizedBox(width: 11),
                        Text(
                          'New category',
                          style: sans(13, weight: 500, color: ExitColors.mid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// The small mono caption that labels each field.
class _FieldCaption extends StatelessWidget {
  const _FieldCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: ExitText.caption),
    );
  }
}

/// Auditions the trimmed window on loop, which is exactly what firing will do.
class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Stop preview' : 'Preview window',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ExitColors.surf,
            borderRadius: ExitRadius.field,
            border: Border.all(
              color: playing ? ExitColors.greenLine : ExitColors.line,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  size: 14,
                  color: ExitColors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  playing ? 'Stop preview' : 'Preview window',
                  style: sans(11, weight: 500, color: ExitColors.green),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String name in kPickableIcons)
          GestureDetector(
            onTap: () => onSelected(name),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: name == selected ? ExitColors.raise : ExitColors.surf,
                borderRadius: ExitRadius.field,
                border: Border.all(
                  color: name == selected ? ExitColors.line2 : ExitColors.line,
                ),
              ),
              child: Icon(
                iconFor(name),
                size: 18,
                color: name == selected ? ExitColors.green : ExitColors.dim,
              ),
            ),
          ),
      ],
    );
  }
}

/// The one-line destination field: colour, name, and the way to change it.
class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.category, required this.onTap});

  final ExitCategory? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ExitCategory? c = category;
    final Color accent = c == null
        ? ExitColors.dim
        : (c.isUser ? ExitColors.green : accentForCategory(c.id));

    return Semantics(
      button: true,
      label: 'Target category',
      child: Panel(
        onTap: onTap,
        radius: ExitRadius.field,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: <Widget>[
            CategoryDot(accent, size: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                c?.label ?? 'Pick one',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: c == null
                    ? sans(14, weight: 500, color: ExitColors.dim)
                    : sans(14, weight: 500),
              ),
            ),
            Text('CHANGE ▾', style: mono(11)),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ExitCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = category.isUser
        ? ExitColors.green
        : accentForCategory(category.id);

    return Panel(
      onTap: onTap,
      radius: ExitRadius.field,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      color: selected ? ExitColors.raise : ExitColors.surf,
      borderColor: selected ? ExitColors.line2 : ExitColors.line,
      child: Row(
        children: <Widget>[
          Icon(iconFor(category.icon), size: 18, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ExitText.row,
            ),
          ),
          if (category.isUser) const UserBadge(),
        ],
      ),
    );
  }
}

class _NewCategoryForm extends StatelessWidget {
  const _NewCategoryForm({
    required this.controller,
    required this.icon,
    required this.onIcon,
    required this.onCancel,
    required this.onCreate,
  });

  final TextEditingController controller;
  final String icon;
  final ValueChanged<String> onIcon;
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Panel(
      radius: ExitRadius.field,
      borderColor: ExitColors.greenLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('NEW CATEGORY', style: ExitText.caption),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            style: sans(14, weight: 500),
            cursorColor: ExitColors.green,
            cursorWidth: 2,
            decoration: InputDecoration(
              isDense: true,
              border: const UnderlineInputBorder(),
              hintText: 'Name',
              hintStyle: sans(14, color: ExitColors.dim),
            ),
          ),
          const SizedBox(height: 14),
          _IconPicker(selected: icon, onSelected: onIcon),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCancel,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    'Cancel',
                    style: sans(13, weight: 500, color: ExitColors.mid),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCreate,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    'Create',
                    style: sans(13, weight: 600, color: ExitColors.green),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
