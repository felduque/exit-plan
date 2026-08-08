import 'package:exitplan/permissions/app_permission.dart';
import 'package:exitplan/permissions/feature_requirement.dart';
import 'package:exitplan/permissions/permission_center.dart';
import 'package:exitplan/state/permissions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

/// The permission matrix, checked without a device.
///
/// Every interesting case here is one the developer's own phone is not in: an
/// Android 14 that withheld the full-screen-intent permission, an exact-alarm
/// switch the user turned off, a version of Android too old to have either. On
/// hardware these are reachable only by owning four phones; here they are a
/// map literal.
void main() {
  /// Everything granted. Individual tests knock out the one they care about,
  /// so a test never accidentally passes because a *different* permission was
  /// also missing.
  Map<AppPermission, PermissionState> allGranted() =>
      <AppPermission, PermissionState>{
        for (final AppPermission p in AppPermission.values)
          p: PermissionState(
            permission: p,
            availability: PermissionAvailability.granted,
          ),
      };

  Map<AppPermission, PermissionState> without(
    AppPermission missing, {
    PermissionAvailability as = PermissionAvailability.needsSettings,
  }) => allGranted()
    ..[missing] = PermissionState(permission: missing, availability: as);

  group('PermissionState', () {
    test('unsupported counts as satisfied — on an Android with no such '
        'permission the feature is not degraded, it simply works', () {
      const PermissionState state = PermissionState(
        permission: AppPermission.fullScreenIntent,
        availability: PermissionAvailability.unsupported,
      );
      expect(state.satisfied, isTrue);
      // …but there is nothing to offer the user, so no button is drawn.
      expect(state.actionable, isFalse);
    });

    test('granted is satisfied and offers nothing to do', () {
      const PermissionState state = PermissionState(
        permission: AppPermission.exactAlarm,
        availability: PermissionAvailability.granted,
      );
      expect(state.satisfied, isTrue);
      expect(state.actionable, isFalse);
    });

    test('denied and needsSettings are both unsatisfied and both actionable', () {
      for (final PermissionAvailability a in <PermissionAvailability>[
        PermissionAvailability.denied,
        PermissionAvailability.needsSettings,
      ]) {
        final PermissionState state = PermissionState(
          permission: AppPermission.notifications,
          availability: a,
        );
        expect(state.satisfied, isFalse);
        expect(state.actionable, isTrue);
      }
    });
  });

  group('what each feature needs', () {
    test('firing a sound needs nothing at all — the panic button never '
        'depends on a permission', () {
      expect(FeatureRequirement.required(AppFeature.blackoutSound), isEmpty);
      expect(
        FeatureRequirement.statusOf(AppFeature.blackoutSound, <AppPermission,
            PermissionState>{}),
        FeatureStatus.degraded,
      );
      // Degraded, never blocked: without notifications the sound still fires,
      // it just loses the lock-screen controls.
      expect(
        FeatureRequirement.statusOf(
          AppFeature.blackoutSound,
          without(AppPermission.notifications),
        ),
        FeatureStatus.degraded,
      );
    });

    test('ringing a call from inside the app needs nothing, whatever else is '
        'denied', () {
      Map<AppPermission, PermissionState> nothing = allGranted();
      for (final AppPermission p in AppPermission.values) {
        nothing = <AppPermission, PermissionState>{
          ...nothing,
          p: PermissionState(
            permission: p,
            availability: PermissionAvailability.needsSettings,
          ),
        };
      }
      expect(
        FeatureRequirement.statusOf(AppFeature.fakeCallNow, nothing),
        FeatureStatus.ready,
      );
    });

    test('a scheduled call is ready only when everything is in place', () {
      expect(
        FeatureRequirement.statusOf(
          AppFeature.fakeCallScheduled,
          allGranted(),
        ),
        FeatureStatus.ready,
      );
    });

    test('no notifications blocks a scheduled call outright — the call *is* a '
        'notification, so there is nothing to post', () {
      expect(
        FeatureRequirement.statusOf(
          AppFeature.fakeCallScheduled,
          without(AppPermission.notifications),
        ),
        FeatureStatus.blocked,
      );
    });

    test('no exact alarm degrades rather than blocks — a call two minutes '
        'late still gets you out of the meeting', () {
      expect(
        FeatureRequirement.statusOf(
          AppFeature.fakeCallScheduled,
          without(AppPermission.exactAlarm),
        ),
        FeatureStatus.degraded,
      );
    });

    test('no full-screen intent degrades rather than blocks — the call arrives '
        'as a banner, which still rings', () {
      expect(
        FeatureRequirement.statusOf(
          AppFeature.fakeCallScheduled,
          without(AppPermission.fullScreenIntent),
        ),
        FeatureStatus.degraded,
      );
    });

    test('battery optimisation only ever degrades, and is never required — '
        'requesting it outright is a Play review problem', () {
      expect(
        FeatureRequirement.required(AppFeature.fakeCallScheduled),
        isNot(contains(AppPermission.batteryUnrestricted)),
      );
      expect(
        FeatureRequirement.statusOf(
          AppFeature.fakeCallScheduled,
          without(AppPermission.batteryUnrestricted),
        ),
        FeatureStatus.degraded,
      );
    });

    test('an Android too old to have the permission is ready, not degraded', () {
      expect(
        FeatureRequirement.statusOf(
          AppFeature.fakeCallScheduled,
          without(
            AppPermission.fullScreenIntent,
            as: PermissionAvailability.unsupported,
          ),
        ),
        FeatureStatus.ready,
      );
    });

    test('a blocking permission outranks every degrading one, so the headline '
        'is the thing that actually stops the call', () {
      final Map<AppPermission, PermissionState> nothing = allGranted()
        ..[AppPermission.notifications] = const PermissionState(
          permission: AppPermission.notifications,
          availability: PermissionAvailability.needsSettings,
        )
        ..[AppPermission.exactAlarm] = const PermissionState(
          permission: AppPermission.exactAlarm,
          availability: PermissionAvailability.needsSettings,
        );

      final List<AppPermission> missing = FeatureRequirement.missing(
        AppFeature.fakeCallScheduled,
        nothing,
      );
      expect(missing.first, AppPermission.notifications);
      expect(missing, contains(AppPermission.exactAlarm));
    });

    test('nothing missing when everything is granted', () {
      expect(
        FeatureRequirement.missing(
          AppFeature.fakeCallScheduled,
          allGranted(),
        ),
        isEmpty,
      );
    });
  });

  group('PermissionCenter', () {
    setUp(() {
      PermissionCenter.instance.debugReset();
      NotificationPermission.instance.debugSet(status: null);
    });

    test('an unknown permission reads as granted rather than denied — a cold '
        'start must not flash a wall of warnings before the first check '
        'lands', () {
      expect(
        PermissionCenter.instance.stateOf(AppPermission.exactAlarm).satisfied,
        isTrue,
      );
    });

    test('debugSet moves the three it owns', () {
      PermissionCenter.instance.debugSet(<AppPermission, PermissionAvailability>{
        AppPermission.exactAlarm: PermissionAvailability.needsSettings,
      });
      expect(
        PermissionCenter.instance.stateOf(AppPermission.exactAlarm).satisfied,
        isFalse,
      );
      // …and leaves the others alone.
      expect(
        PermissionCenter.instance
            .stateOf(AppPermission.fullScreenIntent)
            .satisfied,
        isTrue,
      );
    });

    test('notifications are read through their owner, not shadowed here', () {
      NotificationPermission.instance.debugSet(
        status: PermissionStatus.denied,
        asked: true,
      );
      final PermissionState state = PermissionCenter.instance.stateOf(
        AppPermission.notifications,
      );
      expect(state.satisfied, isFalse);
      // "asked" means the runtime dialog is spent, so the only honest offer
      // left is the settings page.
      expect(state.availability, PermissionAvailability.needsSettings);
    });

    test('a notification denial that has not been asked yet still offers the '
        'dialog', () {
      NotificationPermission.instance.debugSet(
        status: PermissionStatus.denied,
      );
      expect(
        PermissionCenter.instance
            .stateOf(AppPermission.notifications)
            .availability,
        PermissionAvailability.denied,
      );
    });

    test('setting notifications through this object is a programming error, '
        'because the value would be written where nothing reads it', () {
      expect(
        () => PermissionCenter.instance
            .debugSet(<AppPermission, PermissionAvailability>{
              AppPermission.notifications: PermissionAvailability.denied,
            }),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
