---
workflow: product-launch-video
flow: automation
storyboard: no
message: "A believable reason to leave, one tap away"
destination: tiktok
aspect: 1080x1920
language: es
length: 29s
angle: product
---

## Intent

A 25-second vertical promo for **ExitPlan — Fake Call & Escape**, an Android app that
plays realistic fake calls, doorbells and alarms so you have a believable reason to
leave an awkward situation.

Tone is UGC, conversational, dry humour — a friend showing you a trick, not a
corporate ad. Handheld feel, realistic indoor lighting. Fast cuts, no scene longer
than 5 seconds. Large burned-in captions on every scene, readable on a phone.

Audience: US adults 25–34, slight female skew.

Visual style: dark palette (near-black), one warm amber accent, matching the app.

## Assets

- video/screenshot_1_home.png — app home, four quick-exit cards + fuse/loop row. Scene 2.
- video/screenshot_2_fuse.png — delay-fuse onboarding screen with 0s/5/10/30 selector. Scene 3.
- video/screenshot_3_library.png — sound library, 47 sounds / 6 categories. Scene 2 support.
- video/screenshot_4_custom_exit.png — custom exit builder.
- video/screenshot_5_fake_calls.png — fake-call template list.
- video/screenshot_6_incoming_call.png — incoming-call screen (contact + photo). Scene 4.
- video/screenshot_7_live_call.png — live-call screen. Scene 4 support.
- video/screenshot_8_privacy.png — settings / privacy screen. Scene 5.

All eight are pre-composed 1080x1920 store frames (headline + device mockup). Only the
device region is used; this video supplies its own captions.

## Customizations

- ~~**No voiceover, no spoken audio.** Dialogue track stays empty.~~ **Superseded
  2026-08-03:** the user supplied `video/voice video.mp3`, confirmed by acoustic
  analysis to be narration (mono, 7 speech gaps of 0.36–0.87s), not music. Staged as
  `assets/audio/narration.mp3` and hand-mounted in `index.html` on track 10, spanning
  0 → 14.838s. The user chose to keep the 25s cut, so scenes 05 and 06 run without
  voice (~10s of tail silence). Re-running `assemble-index.mjs` drops that element —
  re-add it after any re-assembly.
- **No background music.** HeyGen's catalog needs an interactive sign-in (the user's
  login failed) and local MusicGen needs Python, which is not installed on this
  machine. Shipped with no music bed.
- Burned-in captions are part of each frame's design, not the caption pipeline.

## Notes

- HyperFrames renders from HTML, so the briefed live-action plates (person in a meeting,
  hand under a table, walking out a door) cannot be filmed. Those beats are realized as
  design-led equivalents built from the real app screens, keeping the same 6-beat
  structure, caption copy and timing. Live plates can be dropped in per-scene later.
- Never imply the app is used to harass, deceive maliciously, or spy on anyone.
  Framing is personal convenience and feeling safe.
- Never imply it is an emergency service.
- Do not show iOS or WhatsApp logos or wordmarks prominently — crop or avoid the
  regions of screenshots 5/6/7 that carry the "WhatsApp" label.
- Captions must be large and readable on a phone screen.
