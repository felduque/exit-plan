/// In-app reminders of things the app can actually do.
///
/// In-app only, never a push notification: that would need network and a
/// permission, and a notification reading "your excuse is ready" is exactly the
/// thing that gives the app away. Each line below must map to a real feature.
const List<String> kTips = <String>[
  'Hold anywhere for 0.75s to leave the dark screen.',
  'Star a sound to put it in a quick exit slot.',
  'The fuse lets you pocket the phone before it fires.',
  'A loop of 30s stops the sound on its own.',
  'Browse all shows every category on one screen.',
  'Preview a sound before you trust it.',
  'Max volume override fires at full level.',
  'Import your own audio and trim it to 30 seconds.',
  'Lock-screen controls let you pause without reopening.',
  'Bad signal cuts a call without any vibration.',
];
