import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import '../data/call_avatar_files.dart';
import '../data/call_presets.dart';
import '../data/system_catalog.dart';
import '../models/call_preset.dart';
import '../models/escape_sound.dart';
import '../models/exit_category.dart';
import '../state/app_state.dart';
import '../state/ui_flags.dart';
import '../widgets/call_themes/call_visuals.dart';
import '../widgets/confirm.dart';
import '../widgets/selectors.dart';
import '../widgets/tip_banner.dart';

/// Creates or edits a call template: who is "calling", the photo, which
/// screen it imitates, the ringtone and how long it waits before ringing.
///
/// The ringtone field opens the same merged sound library every other screen
/// reads from — a template does not own its own tone, it just points at one.
class CallPresetEditorScreen extends StatefulWidget {
  const CallPresetEditorScreen({super.key, this.preset});

  /// Null when creating a new template.
  final CallPreset? preset;

  @override
  State<CallPresetEditorScreen> createState() => _CallPresetEditorScreenState();
}

class _CallPresetEditorScreenState extends State<CallPresetEditorScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.preset?.name ?? '',
  );
  late final TextEditingController _number = TextEditingController(
    text: widget.preset?.number ?? '',
  );

  String? _avatarPath;

  /// Only the photo picked *during this session*, so it can be cleaned up if
  /// the screen is left without saving — the original preset's photo, if any,
  /// is untouched until a save actually replaces it.
  String? _pendingNewAvatarPath;

  late CallPlatform _platform = widget.preset?.platform ?? CallPlatform.ios;
  late String _ringtoneSoundId =
      widget.preset?.ringtoneSoundId ?? kFallbackSoundId;
  late int _delay = widget.preset?.delaySeconds ?? 0;

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _avatarPath = widget.preset?.avatarPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    // Orphan cleanup: a picked-but-unsaved photo is rubbish once this screen
    // closes, same rule `EditorScreen` applies to an imported audio file.
    if (!_saved && _pendingNewAvatarPath != null) {
      CallAvatarFiles.delete(_pendingNewAvatarPath!);
    }
    super.dispose();
  }

  bool get _isEditing => widget.preset != null;
  bool get _canSave => _name.text.trim().isNotEmpty;

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
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit template' : 'New template',
                        style: ExitText.title,
                      ),
                    ),
                    if (_isEditing)
                      IconTile(
                        icon: Icons.delete_outline,
                        semanticLabel: 'Delete template',
                        color: ExitColors.red,
                        borderColor: ExitColors.line,
                        onTap: () => _delete(state),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                  children: <Widget>[
                    Center(
                      child: _AvatarPicker(
                        path: _avatarPath,
                        name: _name.text,
                        onPick: _pickAvatar,
                        onClear: _avatarPath == null ? null : _clearAvatar,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _FieldCaption('NAME'),
                    _TextField(
                      controller: _name,
                      hint: 'Caller name',
                      textCapitalization: TextCapitalization.words,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    const _FieldCaption('NUMBER'),
                    _TextField(
                      controller: _number,
                      hint: '+1 555 0100',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    SegmentedRow<CallPlatform>(
                      caption: 'SCREEN STYLE',
                      options: CallPlatform.values,
                      selected: _platform,
                      labelOf: (CallPlatform p) => p.label,
                      onChanged: (CallPlatform p) =>
                          setState(() => _platform = p),
                    ),
                    const SizedBox(height: 20),
                    const _FieldCaption('RINGTONE'),
                    _RingtoneField(
                      sound: state.library.resolveOrFallback(_ringtoneSoundId),
                      onTap: () => _pickRingtone(state),
                    ),
                    const SizedBox(height: 20),
                    DelayFuseSelector(
                      seconds: _delay,
                      onChanged: (int value) => setState(() => _delay = value),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                child: PrimaryButton(
                  label: 'Save template',
                  enabled: _canSave,
                  onTap: _canSave ? () => _save(state) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    final String? sourcePath = result?.files.firstOrNull?.path;
    if (sourcePath == null) return;

    String newPath;
    try {
      newPath = await CallAvatarFiles.importCopy(sourcePath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read that photo.')),
        );
      }
      return;
    }

    final String? previousPending = _pendingNewAvatarPath;
    if (!mounted) {
      await CallAvatarFiles.delete(newPath);
      return;
    }
    setState(() {
      _avatarPath = newPath;
      _pendingNewAvatarPath = newPath;
    });
    // A second pick during the same visit replaces the first — the first
    // one never got saved anywhere, so it is safe to drop now.
    if (previousPending != null) await CallAvatarFiles.delete(previousPending);
  }

  Future<void> _clearAvatar() async {
    final String? pending = _pendingNewAvatarPath;
    setState(() {
      _avatarPath = null;
      _pendingNewAvatarPath = null;
    });
    if (pending != null) await CallAvatarFiles.delete(pending);
  }

  Future<void> _pickRingtone(AppState state) async {
    final String? picked = await showRingtonePicker(
      context,
      categories: state.library.categories,
      selected: _ringtoneSoundId,
    );
    if (picked == null || !mounted) return;
    setState(() => _ringtoneSoundId = picked);
  }

  Future<void> _save(AppState state) async {
    final String name = _name.text.trim();
    final String number = _number.text.trim();

    final CallPreset? existing = widget.preset;
    final CallPreset preset = existing == null
        ? CallPreset(
            id: newCallPresetId(),
            name: name,
            number: number,
            avatarPath: _avatarPath,
            platform: _platform,
            ringtoneSoundId: _ringtoneSoundId,
            delaySeconds: _delay,
          )
        : existing.copyWith(
            name: name,
            number: number,
            avatarPath: _avatarPath,
            clearAvatar: _avatarPath == null,
            platform: _platform,
            ringtoneSoundId: _ringtoneSoundId,
            delaySeconds: _delay,
          );

    _saved = true;
    if (existing == null) {
      await state.addCallPreset(preset);
    } else {
      await state.updateCallPreset(preset);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(AppState state) async {
    final CallPreset? preset = widget.preset;
    if (preset == null) return;

    final bool ok = await confirmDestructive(
      context,
      title: 'Delete template',
      message: '${preset.name} will be removed, along with its photo.',
    );
    if (!ok || !mounted) return;

    _saved = true;
    await state.deleteCallPreset(preset.id);
    if (mounted) Navigator.of(context).pop();
  }
}

extension on List<PlatformFile> {
  PlatformFile? get firstOrNull => isEmpty ? null : first;
}

/// The circular photo field: tap to pick, tap the small badge to clear.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.path,
    required this.name,
    required this.onPick,
    required this.onClear,
  });

  final String? path;
  final String name;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pick a photo',
      child: GestureDetector(
        onTap: onPick,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: ExitColors.line2),
                ),
              ),
              child: CallAvatar(
                avatarPath: path,
                name: name,
                diameter: 84,
                tint: ExitColors.raise,
                textColor: ExitColors.dim,
              ),
            ),
            if (onClear != null)
              Positioned(
                right: -2,
                bottom: -2,
                child: Semantics(
                  button: true,
                  label: 'Remove photo',
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: ExitColors.surf2,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: ExitColors.line2),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 13,
                        color: ExitColors.red,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Panel(
      radius: ExitRadius.field,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        style: sans(14, weight: 500),
        cursorColor: ExitColors.green,
        cursorWidth: 2,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: sans(14, color: ExitColors.dim),
        ),
        onChanged: onChanged == null ? null : (_) => onChanged!(),
      ),
    );
  }
}

/// The one-line ringtone field: current sound, and the way to change it.
class _RingtoneField extends StatelessWidget {
  const _RingtoneField({required this.sound, required this.onTap});

  final EscapeSound sound;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      radius: ExitRadius.field,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: ExitColors.raise,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Icon(
              iconFor(sound.icon),
              size: 14,
              color: sound.isUser ? ExitColors.green : ExitColors.mid,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              sound.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sans(14, weight: 500),
            ),
          ),
          Text('CHANGE ▾', style: mono(11)),
        ],
      ),
    );
  }
}

/// The ringtone picker: the same merged library `BrowseScreen` lists, grouped
/// by category, one tap to select.
Future<String?> showRingtonePicker(
  BuildContext context, {
  required List<ExitCategory> categories,
  required String? selected,
}) {
  return withModal(
    () => showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x9E000000),
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Container(
            decoration: const BoxDecoration(
              color: ExitColors.surf2,
              borderRadius: ExitRadius.sheet,
              border: Border(top: BorderSide(color: ExitColors.line2)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: const BoxDecoration(
                        color: ExitColors.line2,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                    Text(
                      'Pick a ringtone',
                      style: sans(17, weight: 600, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          for (final ExitCategory category in categories) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: <Widget>[
                                  CategoryDot(
                                    category.isUser
                                        ? ExitColors.green
                                        : accentForCategory(category.id),
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    category.label.toUpperCase(),
                                    style: mono(9, letterSpacing: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            for (final EscapeSound sound in category.sounds)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: _SoundOption(
                                  sound: sound,
                                  selected: sound.id == selected,
                                  onTap: () =>
                                      Navigator.of(sheetContext).pop(sound.id),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _SoundOption extends StatelessWidget {
  const _SoundOption({
    required this.sound,
    required this.selected,
    required this.onTap,
  });

  final EscapeSound sound;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      radius: ExitRadius.field,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: selected ? ExitColors.raise : ExitColors.surf,
      borderColor: selected ? ExitColors.line2 : ExitColors.line,
      child: Row(
        children: <Widget>[
          Icon(
            iconFor(sound.icon),
            size: 16,
            color: sound.isUser ? ExitColors.green : ExitColors.mid,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    sound.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ExitText.row,
                  ),
                ),
                if (sound.isUser) ...<Widget>[
                  const SizedBox(width: 7),
                  const UserBadge(),
                ],
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check, size: 16, color: ExitColors.green),
        ],
      ),
    );
  }
}
