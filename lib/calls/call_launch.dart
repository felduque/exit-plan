import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/call_preset.dart';
import '../permissions/call_platform_channel.dart';
import '../screens/incoming_call_screen.dart';
import '../state/app_state.dart';
import 'call_scheduler.dart';

/// Turns "a scheduled call just arrived" into "the incoming-call screen is on
/// top", however the app got here.
///
/// Two ways in, and both have to work:
///
/// * **Cold start.** The alarm fired while the app was not running. Android
///   launched it, and the payload is waiting in the launch details.
/// * **Already running.** The alarm fired with the app in the background, or in
///   front of the user. The payload arrives on the plugin's stream.
///
/// The full-screen intent is what makes the first case take over a locked
/// screen rather than sitting in the shade — but the *routing* is identical
/// either way, which is why this is one class and not two paths that will drift.
class CallLaunchRouter {
  CallLaunchRouter({
    required this.navigatorKey,
    required this.state,
    CallScheduler? scheduler,
  }) : _scheduler = scheduler ?? CallScheduler.instance;

  final GlobalKey<NavigatorState> navigatorKey;
  final AppState state;
  final CallScheduler _scheduler;

  StreamSubscription<String>? _taps;

  /// Guards against ringing the same booking twice — the cold-start payload is
  /// still readable after the stream has already delivered it.
  String? _lastHandled;

  Future<void> start() async {
    await _scheduler.init();
    _taps = _scheduler.taps.listen(_open);

    final String? launch = await _scheduler.launchPayload();
    if (launch != null) await _open(launch);
  }

  void stop() {
    _taps?.cancel();
    _taps = null;
  }

  Future<void> _open(String presetId) async {
    if (presetId == _lastHandled) return;
    _lastHandled = presetId;

    final CallPreset? preset = state.callPresets
        .cast<CallPreset?>()
        .firstWhere((CallPreset? p) => p?.id == presetId, orElse: () => null);

    // The template was deleted between booking and arrival. Cancelling rather
    // than shrugging matters: without it the alarm survives to fire again after
    // the next reboot, and a call from a contact the user has already forgotten
    // creating is worse than no call at all.
    if (preset == null) {
      await _scheduler.cancel(presetId);
      return;
    }

    // Let the window sit over the keyguard and wake the display. Held only for
    // the life of the call screen — `fireCall` completes when the route is
    // popped, which is exactly when it has to be given back.
    await CallPlatformChannel.setLockScreenMode(enabled: true);

    // Resolved *after* that await, not before: the navigator is the thing most
    // likely to have gone away across it, and a stale NavigatorState would
    // push a route into a tree that no longer exists.
    final NavigatorState? navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      await CallPlatformChannel.setLockScreenMode(enabled: false);
      return;
    }

    try {
      await fireCall(navigator.context, preset);
    } finally {
      await CallPlatformChannel.setLockScreenMode(enabled: false);
    }
  }
}
