import 'dart:io';

import 'package:exitplan/themes/call_theme.dart';
import 'package:exitplan/themes/call_theme_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one test here that protects the developer account rather than a feature.
///
/// A call theme that evokes a well-known messaging app is fine — a colour and a
/// layout belong to nobody. Naming that app, or shipping its wordmark or its
/// logo, is impersonation under Play's policy, and the penalty is not a rejected
/// update but a suspended account. This app used to carry exactly that: a theme
/// whose visible label, palette class and background widget were all named after
/// a real product.
///
/// It is a grep rather than a code review because that is the failure mode
/// being defended against. Nobody sets out to add a trademark; somebody adds a
/// tooltip that says "looks like WhatsApp" eighteen months from now, and a
/// reviewer who was not part of this conversation waves it through.
void main() {
  /// Third-party marks that must not appear anywhere the build can carry them.
  ///
  /// Matched on word boundaries rather than as bare substrings, so
  /// `ScaffoldMessenger` — Flutter's own API — is not mistaken for Meta's
  /// product. TikTok is deliberately **not** on this list: that SDK is a real
  /// integration this app declares in its manifest and its privacy note, and
  /// naming a dependency you actually ship is not impersonation.
  final List<RegExp> forbidden = <String>[
    'whatsapp',
    'messenger',
    'telegram',
    'instagram',
    'facebook',
    'snapchat',
    'imessage',
    'facetime',
    'viber',
    'wechat',
  ].map((String brand) => RegExp('\\b$brand\\b', caseSensitive: false)).toList();

  /// Files allowed to say a brand, each for a stated reason.
  ///
  /// Both are comments and persisted-data plumbing — never a string the user
  /// can see:
  ///
  /// * `system_catalog.dart` documents which sound packs were deliberately
  ///   *not* bundled, and has to name them for the note to be worth reading.
  /// * `call_theme_registry.dart` maps the pre-registry `platform: whatsapp`
  ///   value onto `chat-green`. That literal is on disk on every device that
  ///   has not upgraded yet, so it cannot be renamed — deleting it to "finish"
  ///   the rename would reset those users to a different look.
  const List<String> exempt = <String>[
    'system_catalog.dart',
    'call_theme_registry.dart',
  ];

  bool isExempt(String path) =>
      exempt.any((String name) => path.endsWith(name));

  test('no third-party brand appears in lib/', () {
    final List<String> offences = <String>[];

    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (isExempt(entity.path)) continue;

      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        for (final RegExp brand in forbidden) {
          if (brand.hasMatch(lines[i])) {
            offences.add('${entity.path}:${i + 1}  ${lines[i].trim()}');
          }
        }
      }
    }

    expect(
      offences,
      isEmpty,
      reason:
          'A third-party brand name reached the source. Evoking a look is '
          'fine; naming or reproducing the mark is an impersonation report '
          'against the whole developer account. Rename it, or add a reasoned '
          'exemption to this test.\n${offences.join('\n')}',
    );
  });

  test('no theme is named after a real product', () {
    for (final CallTheme theme in kCallThemes) {
      for (final RegExp brand in forbidden) {
        expect(
          brand.hasMatch(theme.name),
          isFalse,
          reason: 'theme name: ${theme.name}',
        );
        expect(
          brand.hasMatch(theme.id),
          isFalse,
          reason: 'theme id: ${theme.id}',
        );
      }
    }
  });

  test('the pre-registry migration keeps mapping the old brand value, because '
      'it is still on disk on every device that has not upgraded', () {
    // The *value* survives — it has to, it is persisted data — while the theme
    // it now resolves to carries a generic name. Deleting this mapping to
    // "finish" the rename would silently reset those users to another look.
    expect(kLegacyPlatformThemeIds['whatsapp'], 'chat-green');
    expect(callThemeFor('chat-green').name.toLowerCase(), isNot(contains('whatsapp')));
  });
}
