/// Every permission this app can want, and what it is for.
///
/// One enum rather than a class per permission — which is what
/// `state/permissions.dart` grew into when there was only one. That shape does
/// not survive three: each would bring its own singleton, its own lifecycle
/// observer and its own hand-written notice widget, and the three would drift.
///
/// `USE_FULL_SCREEN_INTENT` used to be the fourth, and is gone rather than
/// merely denied. Play rejected it under the full-screen intent policy, which
/// admits only apps whose core purpose is real calls or alarms, so the app no
/// longer declares it on any Android version. Modelling it as a permission
/// stuck at "not granted" would have been worse than dropping it: the notice
/// widget would offer a settings page that has no switch for an app that does
/// not ask for the permission, and the scheduled call would report itself
/// permanently degraded for a capability it can never regain. See
/// android/app/src/main/AndroidManifest.xml.
enum AppPermission {
  /// `POST_NOTIFICATIONS`. Lock-screen media controls rest on it, and so does
  /// every scheduled call — a call that arrives while the app is closed arrives
  /// *as* a notification.
  notifications,

  /// `SCHEDULE_EXACT_ALARM`. Without it a scheduled call still arrives, but
  /// Android is free to batch it with whatever else it was going to wake up
  /// for, which in practice means minutes late.
  ///
  /// Deliberately not `USE_EXACT_ALARM`, which is granted automatically but is
  /// restricted by Play policy to alarm-clock and calendar apps. Shipping it
  /// here would be claiming to be something this app is not.
  exactAlarm,

  /// Exemption from battery optimisation. Never required, never asked for
  /// unprompted, and offered only from the permission centre — a request for
  /// this out of nowhere is a Play review problem and, fairly, reads as an app
  /// overreaching.
  batteryUnrestricted,
}

/// What the system currently says about a permission.
enum PermissionAvailability {
  granted,

  /// Refused, but the dialog would still appear if asked again.
  denied,

  /// Refused and the dialog is spent. Android shows a runtime prompt once; from
  /// then on a request returns denied with no UI at all, so the only honest
  /// action left is to open the settings page.
  ///
  /// Some permissions are born in this state: `SCHEDULE_EXACT_ALARM` has no
  /// runtime dialog and is only ever granted from a settings screen.
  needsSettings,

  /// This version of Android has no such concept, so it is neither granted nor
  /// missing — the feature simply behaves as though it were granted.
  ///
  /// Kept distinct from [granted] because the UI must say different things: a
  /// green tick against a permission that does not exist invites the user to go
  /// looking for a switch they will never find.
  unsupported,
}

/// A permission and where it currently stands.
class PermissionState {
  const PermissionState({
    required this.permission,
    required this.availability,
  });

  final AppPermission permission;
  final PermissionAvailability availability;

  /// Whether the app may behave as though it has this.
  ///
  /// [PermissionAvailability.unsupported] counts, and that is the point: on
  /// Android 11 there is no exact-alarm permission to hold, so the alarm is
  /// exact regardless and the feature is not degraded.
  bool get satisfied =>
      availability == PermissionAvailability.granted ||
      availability == PermissionAvailability.unsupported;

  /// Whether there is anything the user could usefully do about it. False for
  /// [PermissionAvailability.unsupported] — offering a button that opens a
  /// settings page with no such setting on it is worse than saying nothing.
  bool get actionable =>
      availability == PermissionAvailability.denied ||
      availability == PermissionAvailability.needsSettings;

  PermissionState copyWith({PermissionAvailability? availability}) =>
      PermissionState(
        permission: permission,
        availability: availability ?? this.availability,
      );
}
