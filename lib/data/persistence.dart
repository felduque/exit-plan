import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/call_preset.dart';
import 'app_settings.dart';
import 'entitlement.dart';
import 'gate_baseline.dart';
import 'system_catalog.dart';
import 'user_library.dart';

/// Local key-value storage. Nothing here leaves the device: there is no
/// backend, no account and no sync anywhere in this app.
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
  static const String _kCallPresets = 'exitplan.callPresets';
  static const String _kEntitlement = 'exitplan.premium';
  static const String _kGateBaseline = 'exitplan.gateBaseline';
  static const String _kNudgedAt = 'exitplan.premium.nudgedAt';
  static const String _kNudgeCount = 'exitplan.premium.nudgeCount';
  static const String _kLanguage = 'exitplan.language';

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

  // --- language --------------------------------------------------------------

  /// `null` means "not chosen yet" — the app follows the system locale until
  /// the user picks one explicitly, from the intro header or from Settings.
  String? get languageCode => _prefs.getString(_kLanguage);

  Future<void> setLanguageCode(String code) =>
      _prefs.setString(_kLanguage, code);

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

  // --- call presets ----------------------------------------------------------

  /// Drops any entry that does not parse, same tolerant rule as every other
  /// list here: a corrupt template must not cost the user the rest of them.
  List<CallPreset> loadCallPresets() {
    final Object? raw = _decode(_kCallPresets);
    final List<CallPreset> presets = <CallPreset>[];
    if (raw is List) {
      for (final Object? entry in raw) {
        final CallPreset? parsed = CallPreset.tryFromJson(entry);
        if (parsed == null) continue;
        if (presets.any((CallPreset p) => p.id == parsed.id)) continue;
        presets.add(parsed);
      }
    }
    return presets;
  }

  Future<void> saveCallPresets(List<CallPreset> presets) => _encode(
    _kCallPresets,
    presets.map((CallPreset p) => p.toJson()).toList(),
  );

  // --- premium ---------------------------------------------------------------

  /// Kept out of [_kSettings] on purpose: purchases arrive asynchronously and
  /// would race the read-modify-write of the settings blob. See [Entitlement].
  Entitlement loadEntitlement() => Entitlement.fromJson(_decode(_kEntitlement));

  Future<void> saveEntitlement(Entitlement value) =>
      _encode(_kEntitlement, value.toJson());

  /// `null` means "never captured on this device", which is the signal for
  /// [AppState] to take the snapshot. It is not the same as a baseline of zero,
  /// which is a real answer meaning "this install started with nothing".
  GateBaseline? loadGateBaseline() =>
      GateBaseline.tryFromJson(_decode(_kGateBaseline));

  Future<void> saveGateBaseline(GateBaseline value) =>
      _encode(_kGateBaseline, value.toJson());

  /// Plain ints rather than JSON, same as the tip cursor: two counters that are
  /// read on every banner tick and must never be the reason one is slow.
  ///
  /// Zero means "never nudged", which is also what an absent or corrupt value
  /// reads as — erring toward showing the user one more nudge than they were
  /// owed, never toward showing them a seventh.
  int loadNudgedAtMs() {
    final int? value = _prefs.getInt(_kNudgedAt);
    return value == null || value < 0 ? 0 : value;
  }

  int loadNudgeCount() {
    final int? value = _prefs.getInt(_kNudgeCount);
    return value == null || value < 0 ? 0 : value;
  }

  Future<void> saveNudge({required int atMs, required int count}) async {
    await _prefs.setInt(_kNudgedAt, atMs);
    await _prefs.setInt(_kNudgeCount, count);
  }
}
