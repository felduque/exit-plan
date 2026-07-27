/// Where a sound or category came from. Controls the USER badge and whether
/// destructive actions are offered: system content can never be deleted.
enum SoundOrigin { system, user }

/// The phases of the firing engine. The black screen renders a different faint
/// line per phase, but it never lights up on a phase change.
enum FirePhase { idle, armed, live, paused, done }

/// How long the sound repeats once it fires.
enum LoopChoice {
  infinite('∞', null),
  once('1×', null),
  seconds30('30s', Duration(seconds: 30)),
  minute1('1m', Duration(minutes: 1)),
  minutes5('5m', Duration(minutes: 5));

  const LoopChoice(this.label, this.limit);

  final String label;

  /// After this long the audio stops on its own. Null means no timer: either it
  /// repeats forever ([infinite]) or it plays exactly once ([once]).
  final Duration? limit;

  bool get repeats => this != LoopChoice.once;
}

/// Initial value of the loop length selector, taken from the LOOP SOUND
/// setting: ON means repeat until stopped, OFF means play once.
LoopChoice loopDefaultFor(bool loopSound) =>
    loopSound ? LoopChoice.infinite : LoopChoice.once;

/// Seconds the delay fuse waits before firing. 0 fires immediately.
const List<int> kDelayFuseOptions = <int>[0, 5, 10, 30];

/// Loop lengths, shortest first so ∞ — the default — sits at the end where the
/// thumb rests. The same three cells everywhere: the loop control now sits
/// beside the fuse on every screen that offers it, so there is no room for more,
/// and one list means a loop set here reads the same there.
///
/// The design doc draws two cells, `1×` and `∞`. The timed cell is kept because
/// dropping it would take away the only way to have the audio stop by itself
/// while the screen stays black. [LoopChoice.minute1] and [LoopChoice.minutes5]
/// survive in the enum for anything already holding one, but nothing offers them.
const List<LoopChoice> kLoopOptions = <LoopChoice>[
  LoopChoice.once,
  LoopChoice.seconds30,
  LoopChoice.infinite,
];
