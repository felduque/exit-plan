import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

/// The one runtime permission this app asks for, and whether it is *actually*
/// granted right now.
///
/// `POST_NOTIFICATIONS` is what the lock-screen controls setting rests on, and
/// denying it breaks that setting silently: the audio still fires, but there is
/// no way to pause it without reopening the app — and on Android the media
/// notification is also what keeps the system from killing background playback
/// after a few minutes. A toggle that is on while the permission is missing is a
/// lie, so the app has to be able to notice and say so.
///
/// A singleton because the permission is a property of the process, not of a
/// screen, and because two screens watch it at once.
class NotificationPermission extends ChangeNotifier
    with WidgetsBindingObserver {
  NotificationPermission._();

  static final NotificationPermission instance = NotificationPermission._();

  PermissionStatus? _status;

  /// Whether the system dialog has already been spent on this user, across
  /// restarts. Seeded from persisted state at boot — see [seedAsked].
  bool _asked = false;

  PermissionStatus? get status => _status;

  /// Deliberately optimistic while unknown. A warning that flashes on every cold
  /// start before the first check lands would be worse than one that arrives a
  /// frame late, and it keeps widget tests — where the plugin channel does not
  /// exist — from lighting up a permission error.
  bool get granted => _status?.isGranted ?? true;

  /// True once asking again would do nothing. Android shows the dialog once;
  /// after that a request returns denied without any UI, so the only honest
  /// action left is to send the user to the app's settings page.
  bool get needsSettings {
    final PermissionStatus? s = _status;
    if (s == null || s.isGranted) return false;
    return _asked || s.isPermanentlyDenied;
  }

  /// Starts watching. Called once, from the app root.
  void start({bool alreadyAsked = false}) {
    _asked = _asked || alreadyAsked;
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  void stop() => WidgetsBinding.instance.removeObserver(this);

  /// Carries over what the app persisted about having asked before, so a user
  /// who denied it three launches ago is offered settings rather than a dialog
  /// that will never appear.
  void seedAsked(bool value) => _asked = _asked || value;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system settings page is the whole reason this
    // listens: the permission may have been granted while the app was away, and
    // nothing else would tell us.
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    final PermissionStatus? next = await _read();
    if (next == null || next == _status) return;
    _status = next;
    notifyListeners();
  }

  /// The one action a "fix this" button needs: ask if asking can still work,
  /// otherwise open the page where the user can flip it by hand.
  Future<void> resolve() async {
    if (needsSettings) {
      // The result arrives through didChangeAppLifecycleState on the way back.
      await openAppSettings();
      return;
    }
    await request();
  }

  /// Shows the system dialog, once. Safe to call when already granted.
  Future<void> request() async {
    _asked = true;
    try {
      _status = await Permission.notification.request();
    } catch (_) {
      // No plugin channel (tests, desktop). Leave the status alone.
    }
    notifyListeners();
  }

  Future<PermissionStatus?> _read() async {
    try {
      return await Permission.notification.status;
    } catch (_) {
      return null;
    }
  }

  /// Test seam. There is no way to reach the real permission from a widget test
  /// — the plugin channel does not exist — and the branch this class exists for
  /// (ask again, or give up and open settings) is precisely the one that would
  /// rot unnoticed, so it gets a door.
  @visibleForTesting
  void debugSet({PermissionStatus? status, bool asked = false}) {
    _status = status;
    _asked = asked;
    notifyListeners();
  }
}
