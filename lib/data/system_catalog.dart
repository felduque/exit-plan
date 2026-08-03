import '../models/escape_sound.dart';
import '../models/exit_category.dart';

/// The factory content. **Nothing outside `merged_library.dart` should read this
/// directly** — every screen goes through the merged library so that imported
/// sounds are always included.
///
/// Curation rule: a sound only ships if it buys a *credible* excuse. No memes,
/// no voices, no laughter. And never a real brand's tone: audio owned by a third
/// party, or a label naming one, is a store-policy problem, so labels here stay
/// generic on purpose.
///
/// Real audio, not synthesized: the "Efectos de Sonido — Edwin Arenas" pack and
/// Pixabay, both confirmed free of copyright and commercial-use restrictions —
/// see `assets/audio/README.md` for the full origin and licence note. A
/// `socials/` set (WhatsApp, Discord, Telegram…) exists in the same source pack
/// but is deliberately **not** bundled here: those tones are proprietary to
/// Meta/Microsoft/ByteDance, and shipping them under a brand's name is an IP/
/// impersonation problem for store review, not a licensing one.
///
/// The ids below are **frozen**. They are persisted inside the user's quick
/// access slots, so renaming or reordering one silently breaks a slot.

/// Per-category default vibration, inherited by every sound in it.
/// Android-style pattern in ms: [wait, on, off, on, ...].
const Map<String, List<int>> kCategoryVibration = <String, List<int>>{
  'doorbell': <int>[0, 380, 220, 380, 900],
  'alarms': <int>[0, 850, 350, 850, 350],
  // Losing signal does not shake a phone. Leaving this empty is the point.
  'bad-signal': <int>[],
  'fire': <int>[0, 110, 70, 140, 60, 90, 380],
  'storm': <int>[0, 1300, 700, 900, 1100],
  'electric': <int>[0, 55, 45, 55, 45, 55, 320],
};

EscapeSound _sound({
  required String categoryId,
  required String slug,
  required String label,
  required String icon,
  String? excuse,
}) {
  return EscapeSound(
    id: '$categoryId-$slug',
    label: label,
    excuse: excuse,
    categoryId: categoryId,
    icon: icon,
    source: BundledSource('assets/audio/$categoryId/$slug.mp3'),
    vibration: kCategoryVibration[categoryId] ?? const <int>[],
  );
}

final List<ExitCategory> kSystemCategories = <ExitCategory>[
  ExitCategory(
    id: 'doorbell',
    label: 'Doorbell',
    description: 'Someone at the door. The oldest exit there is.',
    icon: 'doorbell',
    sounds: <EscapeSound>[
      _sound(
        categoryId: 'doorbell',
        slug: 'ding',
        label: 'Ding',
        icon: 'doorbell',
        excuse: "That's the door.",
      ),
      _sound(
        categoryId: 'doorbell',
        slug: 'bell',
        label: 'Bell',
        icon: 'bell',
        excuse: "Someone's at the door.",
      ),
      _sound(
        categoryId: 'doorbell',
        slug: 'bells',
        label: 'Bells',
        icon: 'chime',
      ),
      _sound(
        categoryId: 'doorbell',
        slug: 'ting',
        label: 'Ting',
        icon: 'bell',
      ),
      _sound(
        categoryId: 'doorbell',
        slug: '1',
        label: 'Doorbell 1',
        icon: 'doorbell',
        excuse: "Someone's at the door. Give me a second.",
      ),
      _sound(
        categoryId: 'doorbell',
        slug: '2',
        label: 'Doorbell 2',
        icon: 'doorbell',
      ),
      _sound(
        categoryId: 'doorbell',
        slug: '3',
        label: 'Doorbell 3',
        icon: 'doorbell',
      ),
      _sound(
        categoryId: 'doorbell',
        slug: '4',
        label: 'Doorbell 4',
        icon: 'doorbell',
        excuse: "The door again. I'll be right back.",
      ),
    ],
  ),
  ExitCategory(
    id: 'alarms',
    label: 'Alarms',
    description: 'Sirens and wake-ups. An emergency you walk out for.',
    icon: 'siren',
    sounds: <EscapeSound>[
      _sound(
        categoryId: 'alarms',
        slug: 'clock',
        label: 'Alarm clock',
        icon: 'alarm',
        excuse: "That's my alarm. I have to go.",
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'siren',
        label: 'Siren',
        icon: 'siren',
        excuse: 'There are sirens right outside.',
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'siren-1',
        label: 'Siren 1',
        icon: 'siren',
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'siren-2',
        label: 'Siren 2',
        icon: 'emergency',
        excuse: 'Emergency vehicle right outside.',
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'siren-3',
        label: 'Siren 3',
        icon: 'siren',
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'siren-4',
        label: 'Siren 4',
        icon: 'exit',
        excuse: "That's the building alarm. I have to leave.",
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'alert',
        label: 'Alert tones',
        icon: 'emergency',
        excuse: 'My phone just sent an alert. I need to check it.',
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'countdown',
        label: 'Countdown',
        icon: 'alarm',
        excuse: "Timer's up, I have to check on something.",
      ),
    ],
  ),
  ExitCategory(
    id: 'bad-signal',
    label: 'Bad signal',
    description: 'Static and dropouts. Cut the call mid-sentence.',
    icon: 'signal-off',
    sounds: <EscapeSound>[
      _sound(
        categoryId: 'bad-signal',
        slug: 'glitch-1',
        label: 'Glitch 1',
        icon: 'waveform',
        excuse: "You're breaking up, I can't hear you.",
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'glitch-2',
        label: 'Glitch 2',
        icon: 'static',
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'glitch-3',
        label: 'Glitch 3',
        icon: 'signal-off',
        excuse: "The line's terrible, I'll call you back.",
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'glitch-4',
        label: 'Glitch 4',
        icon: 'waveform',
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'drop-1',
        label: 'Signal drop 1',
        icon: 'wifi-off',
        excuse: "I'm losing signal.",
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'drop-2',
        label: 'Signal drop 2',
        icon: 'tower',
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'drop-3',
        label: 'Signal drop 3',
        icon: 'signal-off',
        excuse: 'The call dropped.',
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'drop-4',
        label: 'Signal drop 4',
        icon: 'call-end',
      ),
    ],
  ),
  ExitCategory(
    id: 'fire',
    label: 'Fire',
    description: 'Crackling flames. Sells a real emergency.',
    icon: 'fire',
    sounds: <EscapeSound>[
      _sound(
        categoryId: 'fire',
        slug: 'classic',
        label: 'Fire',
        icon: 'fire',
        excuse: "Something's burning. I have to check.",
      ),
      _sound(
        categoryId: 'fire',
        slug: '1',
        label: 'Fire 1',
        icon: 'fireplace',
      ),
      _sound(
        categoryId: 'fire',
        slug: '2',
        label: 'Fire 2',
        icon: 'hot',
        excuse: "There's a fire, I'm calling it in.",
      ),
      _sound(
        categoryId: 'fire',
        slug: '3',
        label: 'Fire 3',
        icon: 'fireplace',
      ),
      _sound(
        categoryId: 'fire',
        slug: 'crackling-1',
        label: 'Crackling 1',
        icon: 'fireplace',
        excuse: "Something's crackling in the kitchen.",
      ),
      _sound(
        categoryId: 'fire',
        slug: 'crackling-2',
        label: 'Crackling 2',
        icon: 'hot',
      ),
      _sound(
        categoryId: 'fire',
        slug: 'crackling-3',
        label: 'Crackling 3',
        icon: 'fireplace',
        excuse: 'I left something on the stove.',
      ),
      _sound(
        categoryId: 'fire',
        slug: 'crackling-4',
        label: 'Crackling 4',
        icon: 'fire',
      ),
    ],
  ),
  ExitCategory(
    id: 'storm',
    label: 'Storm',
    description: 'Thunder, rain and wind. Weather you have to deal with.',
    icon: 'storm',
    sounds: <EscapeSound>[
      _sound(
        categoryId: 'storm',
        slug: 'rain',
        label: 'Rain',
        icon: 'rain',
        excuse: "It's pouring, I have to move the car.",
      ),
      _sound(
        categoryId: 'storm',
        slug: '1',
        label: 'Storm 1',
        icon: 'storm',
      ),
      _sound(
        categoryId: 'storm',
        slug: '2',
        label: 'Storm 2',
        icon: 'cloud',
        excuse: "The storm's right on top of us.",
      ),
      _sound(
        categoryId: 'storm',
        slug: '3',
        label: 'Storm 3',
        icon: 'wind',
      ),
      _sound(
        categoryId: 'storm',
        slug: '4',
        label: 'Storm 4',
        icon: 'storm',
        excuse: 'I need to close everything up.',
      ),
      _sound(
        categoryId: 'storm',
        slug: 'thunder',
        label: 'Thunder',
        icon: 'storm',
        excuse: 'That thunder was close.',
      ),
      _sound(
        categoryId: 'storm',
        slug: 'thunderstorm',
        label: 'Thunder storm',
        icon: 'cloud',
      ),
      _sound(
        categoryId: 'storm',
        slug: 'wind',
        label: 'Wind',
        icon: 'wind',
        excuse: "The wind's taking the door out.",
      ),
    ],
  ),
  ExitCategory(
    id: 'electric',
    label: 'Electric',
    description: "Buzz and short circuits. Something's wrong with the wiring.",
    icon: 'bolt',
    sounds: <EscapeSound>[
      _sound(
        categoryId: 'electric',
        slug: '1',
        label: 'Electric 1',
        icon: 'bolt',
        excuse: "Something's wrong with the wiring.",
      ),
      _sound(
        categoryId: 'electric',
        slug: '2',
        label: 'Electric 2',
        icon: 'plug',
      ),
      _sound(
        categoryId: 'electric',
        slug: '3',
        label: 'Electric 3',
        icon: 'sensors',
      ),
      _sound(
        categoryId: 'electric',
        slug: 'buzz-1',
        label: 'Buzz 1',
        icon: 'bolt',
        excuse: "There's a buzz coming from the outlet.",
      ),
      _sound(
        categoryId: 'electric',
        slug: 'buzz-2',
        label: 'Buzz 2',
        icon: 'plug',
      ),
      _sound(
        categoryId: 'electric',
        slug: 'buzz-3',
        label: 'Buzz 3',
        icon: 'power',
        excuse: "I think the breaker's about to go.",
      ),
      _sound(
        categoryId: 'electric',
        slug: 'buzz-4',
        label: 'Buzz 4',
        icon: 'sensors',
      ),
    ],
  ),
];

/// Filled into the four quick access slots on first run, and used as the
/// replacement for any slot whose id no longer resolves.
const List<String> kDefaultQuickAccess = <String>[
  'doorbell-ding',
  'alarms-clock',
  'bad-signal-drop-3',
  'fire-classic',
];

/// Last-resort sound for the black screen when an id cannot be resolved at all.
const String kFallbackSoundId = 'doorbell-ding';

/// The vibration a user sound inherits when saved into [categoryId].
List<int> vibrationForCategory(String categoryId) =>
    kCategoryVibration[categoryId] ?? const <int>[];

bool isSystemCategoryId(String id) =>
    kSystemCategories.any((ExitCategory c) => c.id == id);
