# EXITPLAN

Excuse sounds that get you out of a room or off a call. You fire a sound, the
screen goes completely black, and the audio loops — it looks like the phone is
away in a pocket and the noise is real.

**100% offline by design.** No backend, no accounts, no analytics, no network.
Everything is on the device. Free, with nothing locked: no PRO tier, no in-app
purchases, no ads. The release APK ships with **no network permission at all**
(`INTERNET` and `ACCESS_NETWORK_STATE` are stripped from the audio libraries in
`android/app/src/main/AndroidManifest.xml`), and the app never asks for the
microphone.

## Running it

```sh
flutter pub get
flutter run                 # debug
flutter build apk --release
```

Flutter 3.44 / Dart 3.12, Android `minSdk` 23.

## Layout

```
lib/
  main.dart, app.dart          boot: splash overlay -> first-run intro -> home
  core/theme.dart              the whole visual language: palette, type, Panel,
                               PrimaryButton, ExitSwitch, BrandMark, PulseDot
  core/icons.dart              closed icon catalog + per-category accent colour
  models/                      EscapeSound, ExitCategory, phases, loop choices
  data/                        system catalog, user library, merged library,
                               settings, persistence, imported-file storage
  state/                       AppState (all persisted state) + AppScope
  audio/                       media session handler, firing engine, preview player
  screens/                     home, browse, category, editor, settings, blackout
  widgets/                     selectors, sound row, browse row, slot picker,
                               trim timeline, tip banner, splash, intro
tool/gen_audio.dart            synthesizes the bundled sounds
```

### Look

Refined dark — not tactical — from the `Exitplan.dc.html` design doc (UI v3).
Everything lives in `core/theme.dart`; no screen defines its own colour, radius
or type size.

Flat surfaces on a near-black ground: `#0A0B0D` under cards at `#121317`, sheets
at `#171920`, and a `#1C1E26` step used for the selected cell of a control and
the icon well inside a row. Surfaces are separated by a white hairline at 7%
rather than by glow or gradient. Names are **sentence case** in Space Grotesk
with tight tracking; JetBrains Mono is kept for the small uppercase labels the
app owns — `FUSE`, `SLOT 01`, `100% OFFLINE`. Nothing the user typed is ever
shouted back at them.

Colour is an accent and never a field. Each category owns a muted hue
(`accentForCategory`: doorbell blue, alarms amber, bad signal violet, fire red,
storm teal, electric yellow) which appears as a 2px edge along the top of a tile,
an icon, or a 7px square in front of a heading. **Green** `#48B585` has one job —
the user's own work: the trim window, the save slab, the toggles, and the marker
on imported audio. **Red** `#CF4A3C` is fire, and the live emergency on the black
screen. There is at most one filled slab per screen.

The blackout screen shares none of this: it is `#000000` and a few percent of one
grey, nothing else — no surfaces, no borders, no accents.

Two faces are bundled, both SIL OFL 1.1, because the app never touches a network.
Space Grotesk ships only as a variable font, so weights are selected with
`FontVariation('wght', …)` in `sans()` rather than by registering one asset per
weight — that is also why the theme's `TextTheme` sets the axis explicitly on
every inherited style, or unstyled text renders at the font's light default.

Two rules the code is built around:

- **Every screen reads `AppState.library`** (system catalog + user imports
  merged). Nothing but `merged_library.dart` touches `system_catalog.dart`.
- **No ordinary screen plays the alarm.** Firing navigates to the black screen,
  which owns the whole playback cycle. Previews use a separate throwaway player.
- **Only `audio/haptics.dart` touches the vibrator, and a stop always reaches
  it.** Patterns repeat for ever by design, so nothing may skip a cancel on the
  strength of a flag, and a stop must beat a start that is still in flight.
- **Audio only starts and stops when the user says so.** Nothing self-pauses on
  a timer. Dragging a trim handle retargets and re-seeks a preview that is
  already running, and does nothing at all when none is — audio that stops by
  itself is indistinguishable from a bug.
- **No screen keeps its own "is it playing" flag.** `PreviewPlayer.playing` is
  driven by the real `playerStateStream` and every play/pause affordance reads
  it. Screens used to set an optimistic flag on tap, and it was always wrong:
  starting a sound stops the previous one first, so `playing == false` arrived
  *after* the screen had already marked the new sound as playing — the icon
  reset itself and never came back, while audio kept coming out of the speaker.

### Permissions

The app asks for exactly one thing, `POST_NOTIFICATIONS`, and only because
**lock-screen controls** rest on it: without the media notification there is no
way to pause a firing except reopening the app, and Android will eventually kill
background playback that has no foreground service notification.

The system dialog is shown once, from `app.dart`, after the splash and intro have
cleared — never during a firing, where a system dialog would wreck the excuse.
Android will not show it a second time anyway, so denial is handled instead of
re-asked: `state/permissions.dart` re-checks the status on every resume (which is
how the app notices a grant made from the system settings page), the home status
line turns amber and reads `NO NOTIFICATIONS · TAP TO FIX`, and settings grows a
notice under the toggle explaining the cost with a button that asks while asking
can still work and opens the app's own settings page once it cannot.

Both only appear while lock-screen controls are **on**. With the setting off the
app does not want a notification, and nagging for a permission it will not use is
exactly what this app refuses to do.

### The sounds

`assets/audio/**` is generated, not downloaded — `tool/gen_audio.dart` synthesizes
36 WAVs (22.05 kHz mono, 4–8 s, ~10 MB) from plain arithmetic, so nothing in the
app belongs to a third party. Regenerate or tweak with:

```sh
dart tool/gen_audio.dart
```

`assets/fonts/` holds Space Grotesk (`SpaceGrotesk-OFL.txt`) and JetBrains Mono
(`OFL.txt`), both SIL OFL 1.1. They are bundled rather than fetched: the app has
no network permission, and the layout assumes these faces at these sizes. Space
Grotesk is the variable file because Google Fonts publishes no static instances
of it; JetBrains Mono is four static weights, 400 to 700.

The ids in `lib/data/system_catalog.dart` are **frozen**: they are persisted in
the user's quick access slots, so renaming one silently breaks a slot. Never add
a category of real brand tones — that audio is owned by someone else and naming
the brand is a store-policy problem.

## Tests

```sh
flutter analyze     # clean
flutter test        # 47 tests
```

They cover the fragile parts: sanitizing corrupt persisted JSON, quick access
always holding exactly four valid slots (validated *after* the user library
loads), the merged library, and that every catalog id has a real WAV behind it.

`layout_test.dart` is the one the redesign needed: the screens are dense — fixed
150px tiles, a 2×2 grid above the fold, two selectors side by side — so it pumps
every screen that owns no audio player at both the design doc's 394×852 and a
360×640 phone, and fails on the first overflow. The screens that do own a player
(browse, category, editor) are excluded because `PreviewPlayer` reaches for a
platform channel the test binding has not got; what they draw is covered by
exercising the widgets directly.

`permission_notice_test.dart` pins the denied-permission behaviour, which is
otherwise invisible: whether the notice appears at all, whether its button offers
the dialog or the settings page, and that the home status line switches wording
and colour. `NotificationPermission.debugSet` exists only for it — there is no
way to reach a real permission from a widget test, and this is exactly the branch
that would rot unnoticed.

`haptics_test.dart` covers the one piece of hardware the app can leave in a bad
state. Patterns run with `repeat: 0` — for ever, until cancelled — so a missed
cancel is a phone that keeps buzzing in the room the user was walking out of.
`Haptics` takes a `VibrationBackend` positionally so the tests can hold a call
open mid-flight and prove that a stop arriving during a start still silences the
motor. That exact race is what used to leave the phone shaking after the sound
had finished.

**What the tests cannot reach:** anything that needs the audio plugin. The
preview state, the trim window looping, and retargeting the window mid-drag are
all verified against a real `just_audio` player or not at all — see the checklist
below.

## Verify by hand (needs sound, so it is on you)

On a real device, with the volume up:

- [ ] Fire from the 2×2 grid → screen goes black, sound loops, phone vibrates,
      and the sound's excuse is faintly readable in the middle of the dark —
      but only to you, holding the phone.
- [ ] Fuse 5 → `ARMED`, a big 5…1 counting down, then it fires.
- [ ] Loop `30s` → audio stops on its own, **the vibration stops with it**, and
      the screen stays black.
- [ ] Loop `1×` → when the sound ends, the buzzing ends in the same moment. Fire
      again and long-press out immediately: nothing is still shaking afterwards.
- [ ] Lock the phone → audio keeps going. Pause from the notification → the
      vibration stops too, and the screen still does not light up.
- [ ] The notification says only `Audio` — nothing that reveals the app.
- [ ] LOCK-SCREEN CONTROLS off → no notification appears.
- [ ] Only a long press (~0.75 s) leaves the black screen — the ring at the
      bottom closes as you hold; back and edge swipes do nothing.
- [ ] Import an mp3 → trim → save into Doorbell → fire: only the window plays,
      on repeat. Delete it and the file leaves `user_audio/`.
- [ ] Browse all → the chips narrow the list, and tapping a category heading
      opens that category with its own fuse and loop.
- [ ] Preview a sound → its button turns to a pause icon in the category's
      colour **and stays there** until the sound ends or is tapped again. Start a
      second sound → the first row goes back to play in the same frame.
- [ ] In the editor: press *Preview window*, then drag a handle around for a
      while. It **never stops on its own** — the loop follows the handle, jumps
      to the edge just moved, and keeps going until the button is pressed again.
- [ ] In the editor with nothing playing: drag a handle. Nothing makes a sound.
- [ ] Deny notifications → the home status line goes amber, tapping it lands on
      settings, and the notice there offers *Open settings*. Grant it from the
      system page and come back → both are gone without restarting the app.
- [ ] Restart: slots, settings and library persist, and the intro stays away.
- [ ] Each generated sound loops without an audible click at the seam.

## Design doc deltas

The doc's flat navigation is built: **Browse all** is one screen holding every
sound, with the categories as headings and a chip row that narrows the list,
which is what replaced the old categories → detail nesting. A category still has
its own screen, reached by tapping a heading, but only for what belongs to one
category alone — the firing parameters, importing into it, and deleting it.

Two deliberate departures from what the doc draws:

- **The loop control keeps three cells, not two.** The doc shows `1×` and `∞`.
  Shipping only those would remove the only way to have the audio stop by itself
  while the screen stays black, so `30s` sits between them. Everything else about
  the control is the doc's.
- **The trim timeline is a tick grid, not a waveform.** The doc draws bars.
  Drawing a real waveform means decoding the file through a recording API, and
  this app deliberately asks for no microphone permission — requesting one it
  never uses is a red flag in store review. Fake bars would be a lie about what
  the app knows, so the grid, the handles and the ruler do the job honestly.

Three "UX upgrades" are pencilled into the doc's notes column rather than into a
screen. Where they stand:

- **Get-out line** — built. The excuse now shows on the blackout screen, so the
  moment the noise fires you already have the sentence to say. It is the reason
  every catalog entry carries an `excuse`.
- **Dry run** — already covered by the preview button on every sound row: it
  plays the sound without the blackout, no vibration, no media session. Adding a
  second rehearsal mode would have cost a seventh toggle, and the design is
  explicit that settings holds six.
- **Volume-key arm** — not built. Catching a double volume-down from a pocket
  means a native key/media-button service on top of `audio_service`, and on
  Android that only works reliably while something already holds the media
  session — i.e. only *after* a firing, which is the one moment it is not
  needed. It would ship a permission-shaped feature that works sometimes.

The doc's counts (`47 SOUNDS`, `8` per category) are placeholder copy; the real
merged library reports itself.

## Notes and workarounds

- The Android window is app-dark from process start: `values/styles.xml` uses a
  dark parent even in the OS's light mode, and `values-v31/styles.xml` overrides
  `windowSplashScreenBackground`/`AnimatedIcon`. Android 12+ ignores
  `windowBackground` on cold start and draws the launcher icon on white instead,
  which flashed a white circle before a black app.
- The tip banner lives in `MaterialApp.builder`, above the navigator, so it needs
  its own `Material` ancestor (or Flutter paints the debug underline over every
  letter) and it hides itself while `blackoutActive` or `modalActive` is set —
  the banner's corner is exactly where a bottom sheet puts CANCEL.
- **Firing latency.** On the emulator the first fire took ~8 s, almost all of it
  Android starting the media foreground service (it logged
  `startForegroundDelayMs:48650`). Worth timing on real hardware — if it is slow
  there too, the delay fuse is the mitigation.
- The hold-to-exit gesture is gated on **wall-clock time**, not on the animation
  finishing, and ignores pointers in the first 500 ms. A frame stall while the
  media service starts used to hand the controller one huge tick, filling the bar
  instantly and bouncing the user straight back out.
- `android/build.gradle.kts` applies `kotlin-android` to the `file_picker`
  subproject. Flutter 3.44's built-in Kotlin decides by grepping a plugin's build
  file for a KGP apply line; file_picker has one inside a dead
  `if (!isAgp9OrAbove)` branch, so neither side applies KGP, its Kotlin never
  compiles, and the build fails on `FilePickerPlugin`. Remove once upstream drops
  that branch.
- `file_picker` 11 and `wakelock_plus` 1.7 disagree on `win32`, so wakelock_plus
  is pinned to 1.5.2. Only Windows desktop cares, and this app targets phones.
