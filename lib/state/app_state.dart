import 'package:flutter/widgets.dart';

import '../data/app_settings.dart';
import '../data/call_avatar_files.dart';
import '../data/merged_library.dart';
import '../data/persistence.dart';
import '../data/system_catalog.dart';
import '../data/user_files.dart';
import '../data/user_library.dart';
import '../models/call_preset.dart';
import '../models/escape_sound.dart';
import '../models/exit_category.dart';

/// All persisted user state, loaded in the order the pieces depend on each
/// other and kept in one place so the UI never has to know about storage.
class AppState extends ChangeNotifier {
  AppState._(
    this._store,
    this._settings,
    this._userLibrary,
    this._quickAccess,
    this._tipIndex,
    this._onboardingDone,
    this._callPresets,
  ) {
    _rebuildLibrary();
  }

  final Persistence _store;

  AppSettings _settings;
  UserLibrary _userLibrary;
  List<String> _quickAccess;
  int _tipIndex;
  bool _onboardingDone;
  List<CallPreset> _callPresets;
  late MergedLibrary _library;

  AppSettings get settings => _settings;
  UserLibrary get userLibrary => _userLibrary;
  List<String> get quickAccess => List<String>.unmodifiable(_quickAccess);
  int get tipIndex => _tipIndex;
  bool get onboardingDone => _onboardingDone;
  List<CallPreset> get callPresets => List<CallPreset>.unmodifiable(_callPresets);

  /// The one library every screen reads from.
  MergedLibrary get library => _library;

  bool get notificationsAsked => _store.notificationsAsked;

  /// Boot order matters (and the spec calls it out): settings and onboarding
  /// first, then the user library, and only *then* the quick access existence
  /// check — validating ids any earlier would throw away a freshly saved user
  /// sound that had not been loaded yet.
  static Future<AppState> bootstrap() async {
    final Persistence store = await Persistence.open();

    final AppState state = AppState._(
      store,
      store.loadSettings(),
      store.loadUserLibrary(),
      store.loadQuickAccess(),
      store.loadTipIndex(),
      store.onboardingDone,
      store.loadCallPresets(),
    );

    // Second pass, deliberately after the user library is in place.
    await state._pruneQuickAccess(persist: true);
    return state;
  }

  void _rebuildLibrary() {
    _library = MergedLibrary.build(
      system: kSystemCategories,
      user: _userLibrary,
    );
  }

  /// Replaces any slot pointing at an id that no longer resolves with the
  /// default for that position.
  Future<void> _pruneQuickAccess({bool persist = false}) async {
    bool changed = false;
    final List<String> pruned = <String>[];
    for (int i = 0; i < _quickAccess.length; i++) {
      final String id = _quickAccess[i];
      if (_library.hasSound(id)) {
        pruned.add(id);
      } else {
        pruned.add(kDefaultQuickAccess[i]);
        changed = true;
      }
    }
    if (!changed) return;
    _quickAccess = pruned;
    if (persist) await _store.saveQuickAccess(_quickAccess);
    notifyListeners();
  }

  // --- settings ------------------------------------------------------------

  Future<void> updateSettings(AppSettings value) async {
    _settings = value;
    notifyListeners();
    await _store.saveSettings(value);
  }

  // --- onboarding ----------------------------------------------------------

  Future<void> completeOnboarding() async {
    if (_onboardingDone) return;
    _onboardingDone = true;
    notifyListeners();
    await _store.setOnboardingDone();
  }

  Future<void> markNotificationsAsked() => _store.setNotificationsAsked();

  // --- quick access --------------------------------------------------------

  /// Overwrites one specific slot. The slot is always chosen by the user, never
  /// picked for them.
  Future<void> assignQuickSlot(int index, String soundId) async {
    if (index < 0 || index >= _quickAccess.length) return;
    final List<String> next = List<String>.of(_quickAccess);
    next[index] = soundId;
    _quickAccess = next;
    notifyListeners();
    await _store.saveQuickAccess(next);
  }

  bool isPinned(String soundId) => _quickAccess.contains(soundId);

  EscapeSound quickSlotSound(int index) =>
      _library.resolveOrFallback(_quickAccess[index]);

  // --- user library --------------------------------------------------------

  Future<void> addUserCategory(ExitCategory category) async {
    _userLibrary = _userLibrary.copyWith(
      categories: <ExitCategory>[..._userLibrary.categories, category],
    );
    _rebuildLibrary();
    notifyListeners();
    await _store.saveUserLibrary(_userLibrary);
  }

  Future<void> addUserSound(EscapeSound sound) async {
    _userLibrary = _userLibrary.copyWith(
      sounds: <EscapeSound>[..._userLibrary.sounds, sound],
    );
    _rebuildLibrary();
    notifyListeners();
    await _store.saveUserLibrary(_userLibrary);
  }

  /// Removes a user sound and deletes its file from storage.
  Future<void> deleteUserSound(String soundId) async {
    final EscapeSound? sound = _userLibrary.sounds
        .cast<EscapeSound?>()
        .firstWhere((EscapeSound? s) => s?.id == soundId, orElse: () => null);
    if (sound == null) return;

    _userLibrary = _userLibrary.copyWith(
      sounds: _userLibrary.sounds
          .where((EscapeSound s) => s.id != soundId)
          .toList(growable: false),
    );
    _rebuildLibrary();
    notifyListeners();

    await _store.saveUserLibrary(_userLibrary);
    await _deleteFileOf(sound);
    await _pruneQuickAccess(persist: true);
  }

  /// Removes a user category together with every sound in it, files included.
  Future<void> deleteUserCategory(String categoryId) async {
    final List<EscapeSound> doomed = _userLibrary.sounds
        .where((EscapeSound s) => s.categoryId == categoryId)
        .toList(growable: false);

    _userLibrary = UserLibrary(
      categories: _userLibrary.categories
          .where((ExitCategory c) => c.id != categoryId)
          .toList(growable: false),
      sounds: _userLibrary.sounds
          .where((EscapeSound s) => s.categoryId != categoryId)
          .toList(growable: false),
    );
    _rebuildLibrary();
    notifyListeners();

    await _store.saveUserLibrary(_userLibrary);
    for (final EscapeSound sound in doomed) {
      await _deleteFileOf(sound);
    }
    await _pruneQuickAccess(persist: true);
  }

  Future<void> _deleteFileOf(EscapeSound sound) async {
    final SoundSource source = sound.source;
    if (source is UserFileSource) {
      await UserFiles.delete(source.path);
    }
  }

  // --- call presets ----------------------------------------------------------

  Future<void> addCallPreset(CallPreset preset) async {
    _callPresets = <CallPreset>[..._callPresets, preset];
    notifyListeners();
    await _store.saveCallPresets(_callPresets);
  }

  Future<void> updateCallPreset(CallPreset preset) async {
    final int index = _callPresets.indexWhere(
      (CallPreset p) => p.id == preset.id,
    );
    if (index < 0) return;

    final CallPreset previous = _callPresets[index];
    final List<CallPreset> next = List<CallPreset>.of(_callPresets);
    next[index] = preset;
    _callPresets = next;
    notifyListeners();
    await _store.saveCallPresets(_callPresets);

    // The old photo is only orphaned once the new one is safely saved.
    if (previous.avatarPath != null &&
        previous.avatarPath != preset.avatarPath) {
      await CallAvatarFiles.delete(previous.avatarPath!);
    }
  }

  /// Removes a call template and deletes its photo from storage.
  Future<void> deleteCallPreset(String presetId) async {
    final CallPreset? preset = _callPresets
        .cast<CallPreset?>()
        .firstWhere((CallPreset? p) => p?.id == presetId, orElse: () => null);
    if (preset == null) return;

    _callPresets = _callPresets
        .where((CallPreset p) => p.id != presetId)
        .toList(growable: false);
    notifyListeners();

    await _store.saveCallPresets(_callPresets);
    final String? avatarPath = preset.avatarPath;
    if (avatarPath != null) await CallAvatarFiles.delete(avatarPath);
  }

  // --- tips ----------------------------------------------------------------

  Future<void> advanceTip(int tipCount) async {
    if (tipCount <= 0) return;
    _tipIndex = (_tipIndex + 1) % tipCount;
    await _store.saveTipIndex(_tipIndex);
  }
}

/// Exposes [AppState] down the tree and rebuilds dependents when it changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  /// Subscribes the caller to changes.
  static AppState of(BuildContext context) {
    final AppScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.notifier!;
  }

  /// One-off access for callbacks, without subscribing.
  static AppState read(BuildContext context) {
    final AppScope? scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.notifier!;
  }
}
