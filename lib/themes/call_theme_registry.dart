import 'call_theme.dart';
import 'calls/business.dart';
import 'calls/chat_blue.dart';
import 'calls/chat_green.dart';
import 'calls/classic_light.dart';
import 'calls/material.dart';
import 'calls/minimal_dark.dart';

/// Every call theme the app knows about.
///
/// **Adding one is a file plus a line here.** Nothing else in the app counts
/// them, switches on them or needs to be told: the editor lists this, the two
/// call screens resolve through [callThemeFor], and `call_screen_layout_test`
/// drives whatever it finds.
///
/// Order is display order in the picker, and it puts the free tier first. That
/// is not a sales decision — it means a free user's first three taps all land
/// on something they can actually use, instead of on a padlock.
const List<CallTheme> kCallThemes = <CallTheme>[
  classicLightTheme,
  materialTheme,
  chatGreenTheme,
  chatBlueTheme,
  minimalDarkTheme,
  businessTheme,
];

/// What a preset gets when it has never been told otherwise, and the last
/// resort of [callThemeFor].
const String kDefaultCallThemeId = 'classic-light';

/// Resolves a persisted id.
///
/// **Never throws and never returns a premium theme as a fallback.** A saved id
/// can go missing for reasons that are nobody's fault — a build rolled back
/// past a theme that used to exist, a corrupted preferences blob, a hand-edited
/// backup — and the honest answer to "I do not know what this is" is the plain
/// default, not a crash on a screen the user is about to rely on.
CallTheme callThemeFor(String? id) {
  for (final CallTheme theme in kCallThemes) {
    if (theme.id == id) return theme;
  }
  return _default;
}

/// The theme [callThemeFor] falls back to. Resolved by id rather than by index
/// so reordering [kCallThemes] cannot silently change what an unknown id means.
final CallTheme _default = kCallThemes.firstWhere(
  (CallTheme t) => t.id == kDefaultCallThemeId && !t.premium,
);

/// What the three pre-registry styles map onto.
///
/// Before themes were a registry, a template stored `platform: ios | android |
/// whatsapp`. Those values are still on disk for every user who saved a
/// template before this version, so this table is load-bearing rather than
/// historical, and it must not be deleted once "enough time has passed" — a
/// device that sat un-upgraded for a year still opens with the old JSON.
///
/// `whatsapp` maps to `chat-green`, which is the same screen under a name that
/// does not borrow somebody's trademark. Nobody's saved template changes
/// appearance.
const Map<String, String> kLegacyPlatformThemeIds = <String, String>{
  'ios': 'classic-light',
  'android': 'material',
  'whatsapp': 'chat-green',
};

/// The reverse map, used when writing.
///
/// `toJson` keeps emitting the old `platform` field alongside the new
/// `themeId`. It costs one string per template and it makes a rollback to the
/// previous version **lossless** instead of resetting everybody's theme to the
/// default — which matters because the way a rollback happens is that something
/// has already gone wrong.
///
/// A theme with no legacy equivalent writes the nearest one that has.
String legacyPlatformFor(String themeId) => switch (themeId) {
  'classic-light' => 'ios',
  'material' => 'android',
  'chat-green' => 'whatsapp',
  // The three added with the registry. An old build meeting one of these picks
  // the closest surviving look rather than dropping to iOS for all of them.
  'chat-blue' => 'ios',
  'minimal-dark' => 'android',
  'business' => 'android',
  _ => 'ios',
};
