import 'package:flutter/widgets.dart';

import '../state/permissions.dart';
import 'app_permission.dart';
import 'call_platform_channel.dart';

/// Every permission this app can want, in one place, re-checked whenever the
/// app comes back to the foreground.
///
/// That last part is the whole reason this is a long-lived object rather than a
/// function: two of the four permissions here have **no runtime dialog at
/// all**. `SCHEDULE_EXACT_ALARM` and `USE_FULL_SCREEN_INTENT` can only be
/// granted on a settings page, so the app's only way to learn the answer is to
/// notice it has been resumed and ask again.
///
/// A singleton because a permission is a property of the process, not of a
/// screen, and because several screens watch the same ones.
///
/// ## Notifications are not owned here
///
/// `POST_NOTIFICATIONS` already has an owner in [NotificationPermission], with
/// its own tests pinning the branch that decides between offering the dialog
/// and offering the settings page. This delegates to it rather than keeping a
/// second copy: two objects asking the platform the same question will
/// eventually disagree, and the one the UI happens to be reading will be the
/// stale one.
class PermissionCenter extends ChangeNotifier with WidgetsBindingObserver {
  PermissionCenter._();

  static final PermissionCenter instance = PermissionCenter._();

  /// The three this object genuinely owns. Notifications are read through
  /// [NotificationPermission] on demand.
  final Map<AppPermission, PermissionState> _states =
      <AppPermission, PermissionState>{};

  NotificationPermission get _notifications => NotificationPermission.instance;

  bool _started = false;

  /// Everything known right now.
  ///
  /// Unknown permissions read as [PermissionAvailability.granted] rather than
  /// denied — deliberately optimistic, the same call `NotificationPermission`
  /// already made. A warning that flashes on every cold start before the first
  /// check lands is worse than one that arrives a frame late, and it keeps
  /// widget tests, where none of these channels exist, from lighting up as a
  /// wall of errors.
  Map<AppPermission, PermissionState> get states =>
      <AppPermission, PermissionState>{
        for (final AppPermission p in AppPermission.values) p: stateOf(p),
      };

  PermissionState stateOf(AppPermission permission) {
    if (permission == AppPermission.notifications) {
      return PermissionState(
        permission: permission,
        availability: _notifications.granted
            ? PermissionAvailability.granted
            : (_notifications.needsSettings
                  ? PermissionAvailability.needsSettings
                  : PermissionAvailability.denied),
      );
    }
    return _states[permission] ??
        PermissionState(
          permission: permission,
          availability: PermissionAvailability.granted,
        );
  }

  bool satisfied(AppPermission permission) => stateOf(permission).satisfied;

  /// Called once, from the app root, after [NotificationPermission.start].
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    // A notification grant is a change in this object's answers too, so
    // anything watching only this one still hears about it.
    _notifications.addListener(notifyListeners);
    refresh();
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _notifications.removeListener(notifyListeners);
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from a system settings page is the entire reason this
    // listens. For exact alarms and full-screen intents it is the *only* way
    // the answer can ever change.
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    // Notifications refresh themselves — NotificationPermission is its own
    // lifecycle observer.
    final Map<AppPermission, PermissionAvailability> next =
        <AppPermission, PermissionAvailability>{
          AppPermission.exactAlarm: _fromChannel(
            await CallPlatformChannel.canScheduleExactAlarms(),
          ),
          AppPermission.fullScreenIntent: _fromChannel(
            await CallPlatformChannel.canUseFullScreenIntent(),
          ),
          AppPermission.batteryUnrestricted: _fromChannel(
            await CallPlatformChannel.isIgnoringBatteryOptimizations(),
          ),
        };

    bool changed = false;
    next.forEach((AppPermission p, PermissionAvailability availability) {
      if (_states[p]?.availability == availability) return;
      _states[p] = PermissionState(permission: p, availability: availability);
      changed = true;
    });
    if (changed) notifyListeners();
  }

  /// The one action a "fix this" button needs: ask if asking can still work,
  /// otherwise open the page where the user can flip it by hand.
  ///
  /// For everything except notifications there is no dialog to try, so this is
  /// always the settings page. The result arrives on the way back through
  /// [didChangeAppLifecycleState].
  Future<void> resolve(AppPermission permission) async {
    switch (permission) {
      case AppPermission.notifications:
        await _notifications.resolve();
      case AppPermission.exactAlarm:
        await CallPlatformChannel.openExactAlarmSettings();
      case AppPermission.fullScreenIntent:
        await CallPlatformChannel.openFullScreenIntentSettings();
      case AppPermission.batteryUnrestricted:
        await CallPlatformChannel.openBatterySettings();
    }
  }

  /// The channel answers a plain yes/no. A "no" from it always means the same
  /// thing — the switch lives on a settings page, and there is no dialog to
  /// try first, so it never reports [PermissionAvailability.denied].
  PermissionAvailability _fromChannel(bool granted) => granted
      ? PermissionAvailability.granted
      : PermissionAvailability.needsSettings;

  /// Test seam, the same door [NotificationPermission], [BillingService] and
  /// [AdsService] all have. There is no way to reach a real permission from a
  /// widget test, and the branches this class exists for — degraded scheduling,
  /// a blocked feature, a permission this Android version does not have — are
  /// exactly the ones that would otherwise rot unnoticed.
  ///
  /// Covers only the three permissions this object owns. Notifications belong
  /// to [NotificationPermission] and are set through *its* seam — asserting
  /// rather than quietly forwarding, because a value written here that the
  /// getter then reads from somewhere else would be a test that passes while
  /// proving nothing.
  @visibleForTesting
  void debugSet(Map<AppPermission, PermissionAvailability> values) {
    assert(
      !values.containsKey(AppPermission.notifications),
      'Notifications are owned by NotificationPermission — set them with '
      'NotificationPermission.instance.debugSet.',
    );
    values.forEach((AppPermission p, PermissionAvailability availability) {
      if (p == AppPermission.notifications) return;
      _states[p] = PermissionState(permission: p, availability: availability);
    });
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    _states.clear();
    notifyListeners();
  }
}
