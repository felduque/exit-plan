import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/call_preset.dart';
import '../state/app_state.dart';
import '../widgets/call_preset_card.dart';
import '../widgets/tip_banner.dart';
import 'call_preset_editor_screen.dart';
import 'incoming_call_screen.dart';

/// Every saved fake-call template, plus the way to make another.
///
/// Mirrors `BrowseScreen`'s shape (header, list, one add action) but for
/// templates instead of sounds: a template bundles who is "calling" with which
/// screen it imitates, while the ringtone underneath is still just a sound
/// from the same shared library `BrowseScreen` lists.
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<CallPreset> presets = state.callPresets;

    return TipsSuppressor(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                child: Row(
                  children: <Widget>[
                    const BackChevron(),
                    Expanded(child: Text('Fake calls', style: ExitText.title)),
                    _AddButton(onTap: () => _newPreset(context)),
                  ],
                ),
              ),
              Expanded(
                child: presets.isEmpty
                    ? _EmptyState(onTap: () => _newPreset(context))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                        itemCount: presets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (BuildContext context, int index) {
                          final CallPreset preset = presets[index];
                          return CallPresetCard(
                            preset: preset,
                            onCall: () => fireCall(context, preset),
                            onEdit: () => _editPreset(context, preset),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _newPreset(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const CallPresetEditorScreen()),
    );
  }

  void _editPreset(BuildContext context, CallPreset preset) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CallPresetEditorScreen(preset: preset),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add template',
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
              Text('NEW', style: mono(10, color: ExitColors.hi)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.call_rounded, size: 26, color: ExitColors.dim),
            const SizedBox(height: 14),
            Text(
              'No call templates yet',
              style: sans(15, weight: 600, letterSpacing: -0.2),
            ),
            const SizedBox(height: 8),
            Text(
              'Save a name, a photo and a screen style, and ring it '
              'whenever you need a way out.',
              textAlign: TextAlign.center,
              style: ExitText.body,
            ),
            const SizedBox(height: 18),
            PrimaryButton(label: 'Add template', onTap: onTap),
          ],
        ),
      ),
    );
  }
}
