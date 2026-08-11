import 'app_permission.dart';

/// The things a user can ask this app to do, for the purpose of saying whether
/// it can currently do them.
enum AppFeature {
  /// Fire a sound and go to the black screen. Works with no permission at all;
  /// notifications only add the lock-screen controls.
  blackoutSound,

  /// Ring a fake call right now, with the app open. Needs nothing — it is a
  /// route push and an audio player.
  fakeCallNow,

  /// Ring a fake call later, with the app closed and the phone locked. This is
  /// the one with a permission story.
  fakeCallScheduled,
}

/// How well a feature can currently work.
enum FeatureStatus {
  /// Everything it wants, it has.
  ready,

  /// It will work, but not as well, and the user is owed that sentence *before*
  /// they rely on it rather than after it disappoints them.
  ///
  /// This is a first-class outcome rather than a soft failure. Most of what
  /// Android withholds here degrades gracefully — a call arrives as a banner
  /// instead of taking the screen, or arrives two minutes late — and an app
  /// that treated those as errors would refuse to do things it is perfectly
  /// capable of.
  degraded,

  /// It cannot work at all until something is granted.
  blocked,
}

/// Which permissions each feature needs, and what it makes of what it has.
///
/// Pure functions over a snapshot, with no Flutter import and no I/O, so the
/// whole matrix can be checked without a device — which matters because the
/// interesting cases are the ones that only occur on an Android version or a
/// settings state the developer's own phone is not in.
abstract final class FeatureRequirement {
  /// Without every one of these, the feature does not run.
  static List<AppPermission> required(AppFeature feature) => switch (feature) {
    AppFeature.blackoutSound => const <AppPermission>[],
    AppFeature.fakeCallNow => const <AppPermission>[],
    // The scheduled call *is* a notification: the alarm posts one, and the
    // full-screen intent rides on it. With notifications denied there is
    // nothing to post and nothing arrives.
    AppFeature.fakeCallScheduled => const <AppPermission>[
      AppPermission.notifications,
    ],
  };

  /// Without these it still works, less well.
  static List<AppPermission> recommended(AppFeature feature) =>
      switch (feature) {
        // The media notification is what lets the user pause a firing without
        // reopening the app, and what stops Android killing the audio after a
        // few minutes.
        AppFeature.blackoutSound => const <AppPermission>[
          AppPermission.notifications,
        ],
        AppFeature.fakeCallNow => const <AppPermission>[],
        AppFeature.fakeCallScheduled => const <AppPermission>[
          AppPermission.exactAlarm,
          AppPermission.batteryUnrestricted,
        ],
      };

  /// The verdict, given what the device currently reports.
  static FeatureStatus statusOf(
    AppFeature feature,
    Map<AppPermission, PermissionState> states,
  ) {
    bool satisfied(AppPermission p) => states[p]?.satisfied ?? false;

    for (final AppPermission p in required(feature)) {
      if (!satisfied(p)) return FeatureStatus.blocked;
    }
    for (final AppPermission p in recommended(feature)) {
      if (!satisfied(p)) return FeatureStatus.degraded;
    }
    return FeatureStatus.ready;
  }

  /// The permissions standing between this feature and [FeatureStatus.ready],
  /// most consequential first.
  ///
  /// Ordered rather than a set because the UI shows the first one as the
  /// headline: telling somebody their call may be a couple of minutes late is
  /// noise when the real problem is that no call will arrive at all.
  static List<AppPermission> missing(
    AppFeature feature,
    Map<AppPermission, PermissionState> states,
  ) {
    bool satisfied(AppPermission p) => states[p]?.satisfied ?? false;
    return <AppPermission>[
      ...required(feature).where((AppPermission p) => !satisfied(p)),
      ...recommended(feature).where((AppPermission p) => !satisfied(p)),
    ];
  }
}
