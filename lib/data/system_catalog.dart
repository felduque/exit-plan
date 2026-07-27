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
    source: BundledSource('assets/audio/$categoryId/$slug.wav'),
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
        excuse: "Someone's at the door.",
      ),
      _sound(
        categoryId: 'doorbell',
        slug: 'dingdong',
        label: 'Ding dong',
        icon: 'bell',
        excuse: "That's the delivery, hang on.",
      ),
      _sound(
        categoryId: 'doorbell',
        slug: 'buzzer',
        label: 'Buzzer',
        icon: 'intercom',
        excuse: "Someone's buzzing me in.",
      ),
      _sound(
        categoryId: 'doorbell',
        slug: 'chime',
        label: 'Chime',
        icon: 'chime',
      ),
      _sound(
        categoryId: 'doorbell',
        slug: 'intercom',
        label: 'Intercom',
        icon: 'intercom',
        excuse: 'The door station. I have to get it.',
      ),
      _sound(
        categoryId: 'doorbell',
        slug: 'knock',
        label: 'Knocking',
        icon: 'knock',
        excuse: "Someone's knocking. Give me a second.",
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
        slug: 'siren',
        label: 'Siren',
        icon: 'siren',
        excuse: 'There are sirens right outside.',
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'clock',
        label: 'Alarm clock',
        icon: 'alarm',
        excuse: "That's my alarm. I have to go.",
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'twotone',
        label: 'Two-tone',
        icon: 'emergency',
        excuse: 'Emergency vehicle at the door.',
      ),
      _sound(categoryId: 'alarms', slug: 'wail', label: 'Wail', icon: 'siren'),
      _sound(
        categoryId: 'alarms',
        slug: 'smoke',
        label: 'Smoke alarm',
        icon: 'smoke',
        excuse: 'The smoke detector went off.',
      ),
      _sound(
        categoryId: 'alarms',
        slug: 'evacuation',
        label: 'Evacuation',
        icon: 'exit',
        excuse: "That's the building alarm. I have to leave.",
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
        slug: 'static',
        label: 'Static',
        icon: 'static',
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'glitch',
        label: 'Glitch',
        icon: 'waveform',
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'dropout',
        label: 'Dropout',
        icon: 'wifi-off',
        excuse: "You're breaking up, I can't hear you.",
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'crackle',
        label: 'Crackle',
        icon: 'static',
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'interference',
        label: 'Interference',
        icon: 'tower',
        excuse: "The line's terrible, I'll call you back.",
      ),
      _sound(
        categoryId: 'bad-signal',
        slug: 'dead-line',
        label: 'Dead line',
        icon: 'call-end',
        excuse: 'The call dropped.',
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
        slug: 'crackle',
        label: 'Crackle',
        icon: 'fireplace',
        excuse: "Something's burning. I have to check.",
      ),
      _sound(
        categoryId: 'fire',
        slug: 'roar',
        label: 'Roar',
        icon: 'fire',
        excuse: 'I have to go. Now.',
      ),
      _sound(
        categoryId: 'fire',
        slug: 'embers',
        label: 'Embers',
        icon: 'fireplace',
      ),
      _sound(
        categoryId: 'fire',
        slug: 'blaze',
        label: 'Blaze',
        icon: 'hot',
        excuse: "There's a fire, I'm calling it in.",
      ),
      _sound(
        categoryId: 'fire',
        slug: 'hiss',
        label: 'Hiss',
        icon: 'sensors',
        excuse: "Something's leaking in the kitchen.",
      ),
      _sound(
        categoryId: 'fire',
        slug: 'pop',
        label: 'Popping',
        icon: 'hot',
        excuse: 'I left something on the stove.',
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
        slug: 'thunder',
        label: 'Thunder',
        icon: 'storm',
        excuse: "The storm's right on top of us.",
      ),
      _sound(
        categoryId: 'storm',
        slug: 'rain',
        label: 'Rain',
        icon: 'rain',
        excuse: "It's pouring, I have to move the car.",
      ),
      _sound(categoryId: 'storm', slug: 'wind', label: 'Wind', icon: 'wind'),
      _sound(
        categoryId: 'storm',
        slug: 'downpour',
        label: 'Downpour',
        icon: 'rain',
        excuse: 'I need to close everything up.',
      ),
      _sound(
        categoryId: 'storm',
        slug: 'distant-thunder',
        label: 'Distant thunder',
        icon: 'cloud',
      ),
      _sound(
        categoryId: 'storm',
        slug: 'gale',
        label: 'Gale',
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
        slug: 'buzz',
        label: 'Buzz',
        icon: 'bolt',
        excuse: "Something's wrong with the wiring.",
      ),
      _sound(
        categoryId: 'electric',
        slug: 'arc',
        label: 'Arcing',
        icon: 'plug',
        excuse: 'I have to cut the power.',
      ),
      _sound(
        categoryId: 'electric',
        slug: 'short',
        label: 'Short circuit',
        icon: 'plug',
        excuse: 'Something just shorted out.',
      ),
      _sound(
        categoryId: 'electric',
        slug: 'hum',
        label: 'Hum',
        icon: 'sensors',
      ),
      _sound(
        categoryId: 'electric',
        slug: 'zap',
        label: 'Zap',
        icon: 'bolt',
        excuse: 'The breaker just went.',
      ),
      _sound(
        categoryId: 'electric',
        slug: 'transformer',
        label: 'Transformer',
        icon: 'power',
        excuse: 'I think the transformer blew.',
      ),
    ],
  ),
];

/// Filled into the four quick access slots on first run, and used as the
/// replacement for any slot whose id no longer resolves.
const List<String> kDefaultQuickAccess = <String>[
  'doorbell-dingdong',
  'alarms-clock',
  'bad-signal-dropout',
  'fire-crackle',
];

/// Last-resort sound for the black screen when an id cannot be resolved at all.
const String kFallbackSoundId = 'doorbell-dingdong';

/// The vibration a user sound inherits when saved into [categoryId].
List<int> vibrationForCategory(String categoryId) =>
    kCategoryVibration[categoryId] ?? const <int>[];

bool isSystemCategoryId(String id) =>
    kSystemCategories.any((ExitCategory c) => c.id == id);
