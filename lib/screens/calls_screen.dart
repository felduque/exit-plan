import 'package:flutter/material.dart';

import '../calls/call_dispatcher.dart';
import '../calls/call_scheduler.dart';
import '../core/theme.dart';
import '../core/premium_config.dart';
import '../l10n/app_localizations.dart';
import '../models/call_preset.dart';
import '../state/app_state.dart';
import '../widgets/ad_banner.dart';
import '../widgets/call_preset_card.dart';
import '../widgets/premium_gate_sheet.dart';
import '../widgets/schedule_outcome.dart';
import '../widgets/tip_banner.dart';
import 'call_preset_editor_screen.dart';

/// Every saved fake-call template, plus the way to make another.
///
/// Mirrors `BrowseScreen`'s shape (header, list, one add action) but for
/// templates instead of sounds: a template bundles who is "calling" with which
/// screen it imitates, while the ringtone underneath is still just a sound
/// from the same shared library `BrowseScreen` lists.
/// Stands in for the booking centre before boot has wired one up, so the list
/// can subscribe unconditionally instead of branching on null in `build`.
final Listenable _never = ValueNotifier<int>(0);

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppLocalizations loc = AppLocalizations.of(context);
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
                    Expanded(
                      child: Text(loc.callsScreenTitle, style: ExitText.title),
                    ),
                    _AddButton(onTap: () => _newPreset(context)),
                  ],
                ),
              ),
              Expanded(
                child: presets.isEmpty
                    ? _EmptyState(onTap: () => _newPreset(context))
                    // Rebuilt whenever a booking is made, cancelled or comes
                    // due, so a card can never claim a call is still pending
                    // after it has already rung.
                    : AnimatedBuilder(
                        animation: CallDispatcher.bookings ?? _never,
                        builder: (BuildContext context, _) {
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                            itemCount: presets.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 9),
                            itemBuilder: (BuildContext context, int index) {
                              final CallPreset preset = presets[index];
                              return CallPresetCard(
                                preset: preset,
                                bookedAt: CallDispatcher.bookings?.bookedAt(
                                  preset.id,
                                ),
                                onCancelBooking: () =>
                                    CallDispatcher.unschedule(preset.id),
                                // Through the dispatcher, not straight to
                                // `fireCall`: a template whose schedule says
                                // "in five minutes" must book here too, not
                                // ring instantly because this happens to be
                                // the list screen.
                                onCall: () => _call(context, preset),
                                onEdit: () => _editPreset(context, preset),
                              );
                            },
                          );
                        },
                      ),
              ),
              const AdBannerSlot(),
            ],
          ),
        ),
      ),
    );
  }

  /// Rings or books, and **always says which**.
  ///
  /// Booking used to be silent here: the `ScheduleOutcome` was discarded and
  /// nothing on screen changed, so tapping the button on a scheduled template
  /// looked exactly like tapping a dead control. The card's own state covers
  /// the "what is pending" question; this covers the "and what will it
  /// actually do" one, including the two ways Android degrades a booking.
  Future<void> _call(BuildContext context, CallPreset preset) async {
    final ScheduleOutcome? outcome = await CallDispatcher.dispatch(
      context,
      preset,
    );
    if (outcome == null || !context.mounted) return;
    showScheduleOutcome(context, outcome);
  }

  /// The gate lives here, at the point the user's intent starts, rather than
  /// inside `AppState.addCallPreset`. Refusing at save time would mean letting
  /// someone name a caller, pick a photo and choose a ringtone before telling
  /// them it cannot be kept.
  Future<void> _newPreset(BuildContext context) async {
    final AppState state = AppScope.read(context);
    if (!state.canAddCallPreset) {
      await showPremiumGate(
        context,
        kind: PremiumGateKind.callPresets,
        cap: state.callPresetCap,
        freeLimit: FreeLimits.callPresets,
      );
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
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
    final AppLocalizations loc = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: loc.callsAddTemplate,
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
              Text(loc.callsNew, style: mono(10, color: ExitColors.hi)),
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
    final AppLocalizations loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.call_rounded, size: 26, color: ExitColors.dim),
            const SizedBox(height: 14),
            Text(
              loc.callsEmptyTitle,
              style: sans(15, weight: 600, letterSpacing: -0.2),
            ),
            const SizedBox(height: 8),
            Text(
              loc.callsEmptyBody,
              textAlign: TextAlign.center,
              style: ExitText.body,
            ),
            const SizedBox(height: 18),
            PrimaryButton(label: loc.callsAddTemplate, onTap: onTap),
          ],
        ),
      ),
    );
  }
}
