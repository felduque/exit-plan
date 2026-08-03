# Asset inventory

No site was captured (no-capture path). All assets were supplied by the user as
pre-composed 1080x1920 Google Play store frames. Each frame is:
a near-black background, a small colored eyebrow label, a two-line white headline,
and **one device mockup** holding the real app screen.

## Shared geometry — IMPORTANT

Every one of the eight files uses the **identical** device position inside its
1080x1920 canvas (measured, not estimated):

| region                     | x    | y    | w   | h    |
| -------------------------- | ---- | ---- | --- | ---- |
| device incl. bezel         | 223  | 478  | 635 | 1411 |
| live screen inside bezel   | 231  | 486  | 619 | 1395 |

The device region is **the only part of these files this video uses.** The baked-in
headlines and eyebrow labels belong to the store listing, not to this video — this
video supplies its own captions, so every frame must crop to the device rect and
discard the top ~478px. Crop in CSS: size the holder to the rect, put the PNG in as
a `background-image` at `background-size: 1080px 1920px` with
`background-position: -223px -478px` (bezel) or `-231px -486px` (screen only).
Never letterbox the whole 1080x1920 file into a frame.

## Files

- `capture/assets/screenshot_1_home.png` — **App home.** Header `EXITPLAN`, status
  `STANDBY · 4 EXITS READY`, then a 2x2 grid of quick-exit cards (Ding / Alarm clock /
  Signal drop 3 / Fire), each with a colored top rule, a numbered corner, a quoted
  cover line and `TAP TO FIRE`. Below: the FUSE row (0s/5/10/30) and LOOP row
  (1x/30s/∞), then `Browse all — 6 CATEGORIES · 47 SOUNDS` and `Fake calls`.
  Warm amber lives on the Alarm-clock card. The hero screen. → Scene 2.

- `capture/assets/screenshot_2_fuse.png` — **Delay-fuse onboarding.** `STEP 02 · DELAY
  FUSE`, headline "Arm it, then pocket the phone.", body copy about a 5/10/30-second
  fuse and going hands-free, then the FUSE selector with **10** highlighted, and a
  white `Next` button at the bottom. → Scene 3.

- `capture/assets/screenshot_3_library.png` — **Sound library.** `All exits` with an
  `+ IMPORT` button, a category chip row (ALL / DOORBELL / ALARMS / BAD SIGNAL / …)
  and a long scrolling list of named sounds with play + favourite buttons: Ding, Bell,
  Bells, Ting, Doorbell 1-4, then the ALARMS section. Proves the "47 sounds"
  claim visually — a genuinely long list. → Scene 2 (the scroll).

- `capture/assets/screenshot_4_custom_exit.png` — **Custom exit builder.** Secondary;
  not required by the six briefed beats.

- `capture/assets/screenshot_5_fake_calls.png` — **Fake-call template list.** `Fake
  calls` header with `+ NEW`, one saved caller row "Mom" with a photo, a number, an
  edit pencil and a green call button. ⚠ The row carries a small `WhatsApp` text chip
  at approx x 508-604, y 730-750 (full-canvas coords) — must be covered or cropped
  out per the brief. → Scene 4 support, only if masked.

- `capture/assets/screenshot_6_incoming_call.png` — **Incoming-call screen.** Contact
  name "Mom", a round contact photo, red Decline / green Accept buttons, doodle
  wallpaper. ⚠ Carries the subtitle "WhatsApp voice call…" at approx y 755-790 and a
  baked headline naming WhatsApp — the subtitle must be replaced/masked and the
  headline cropped away. → Scene 4 hero once masked.

- `capture/assets/screenshot_7_live_call.png` — **Live-call screen.** "Mom", a running
  `00:00` timer, contact photo, and a control bar (more / video / speaker / mute /
  red hang-up). Carries **no** WhatsApp wordmark inside the device — the safest
  in-call screen. → Scene 4.

- `capture/assets/screenshot_8_privacy.png` — **Settings / privacy.** Six labelled
  toggle rows, all green and on: Loop sound, Haptic support, Max volume override,
  Dark screen hints, Lock-screen controls, In-app tips; footer
  `100% OFFLINE · NO ACCOUNTS`. → Scene 5.

## Not supplied

- No app icon file, no Google Play badge file, and no photography of people.
  Scene 6's icon and store badge must be **drawn in HTML/CSS/SVG** from the brand
  tokens — do not fabricate the official Google Play badge artwork or wordmark;
  use a neutral "GET IT ON GOOGLE PLAY" pill built from brand type.
- No live-action plates exist for the briefed human beats (meeting, hand under table,
  walking out). Those beats are realized typographically / with the device.
