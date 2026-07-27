import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'system_catalog.dart';
import 'user_library.dart';

/// Local key-value storage. Nothing leaves the device: there is no backend, no
/// account and no network call anywhere in this app.
///
/// Every read is defensive. A corrupt value returns the default rather than
/// throwing, because a bad byte on disk must never stop the app from starting.
class Persistence {
  Persistence(this._prefs);

  static const String _kOnboarding = 'exitplan.onboarding';
  static const String _kSettings = 'exitplan.settings';
  static const String _kQuickAccess = 'exitplan.quickAccess';
  static const String _kUserLibrary = 'exitplan.userLibrary';
  static const String _kTipIndex = 'exitplan.tips';
  static const String _kNotificationsAsked = 'exitplan.notificationsAsked';

  final SharedPreferences _prefs;

  static Future<Persistence> open() async =>
      Persistence(await SharedPreferences.getInstance());

  Object? _decode(String key) {
    try {
      final String? raw = _prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _encode(String key, Object value) async {
    try {
      await _prefs.setString(key, jsonEncode(value));
    } catch (_) {
      // Losing a write is survivable; crashing on one is not.
    }
  }

  // --- onboarding ----------------------------------------------------------

  bool get onboardingDone => _prefs.getBool(_kOnboarding) ?? false;

  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboarding, true);

  // --- settings ------------------------------------------------------------

  AppSettings loadSettings() => AppSettings.fromJson(_decode(_kSettings));

  Future<void> saveSettings(AppSettings settings) =>
      _encode(_kSettings, settings.toJson());

  // --- quick access --------------------------------------------------------

  /// Shape-only pass: forces exactly four string slots, filling gaps from the
  /// defaults. Whether each id still *exists* is checked later, once the user
  /// library is loaded — see [AppState.bootstrap].
  List<String> loadQuickAccess() {
    final Object? raw = _decode(_kQuickAccess);
    final List<String> slots = <String>[];
    if (raw is List) {
      for (final Object? entry in raw) {
        if (entry is String && entry.isNotEmpty) slots.add(entry);
      }
    }
    return <String>[
      for (int i = 0; i < kDefaultQuickAccess.length; i++)
        i < slots.length ? slots[i] : kDefaultQuickAccess[i],
    ];
  }

  Future<void> saveQuickAccess(List<String> slots) =>
      _encode(_kQuickAccess, slots);

  // --- user library --------------------------------------------------------

  UserLibrary loadUserLibrary() => UserLibrary.fromJson(_decode(_kUserLibrary));

  Future<void> saveUserLibrary(UserLibrary library) =>
      _encode(_kUserLibrary, library.toJson());

  // --- tips ----------------------------------------------------------------

  int loadTipIndex() {
    final int? value = _prefs.getInt(_kTipIndex);
    if (value == null || value < 0) return 0;
    return value;
  }

  Future<void> saveTipIndex(int index) => _prefs.setInt(_kTipIndex, index);

  // --- notification permission --------------------------------------------

  bool get notificationsAsked => _prefs.getBool(_kNotificationsAsked) ?? false;

  Future<void> setNotificationsAsked() =>
      _prefs.setBool(_kNotificationsAsked, true);
}
