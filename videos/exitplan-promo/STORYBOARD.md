---
format: 1080x1920
duration: 29s
message: "A believable reason to leave, one tap away"
arc: Hook → Sound library → Delay fuse → Fake call → Privacy → Brand/CTA
audience: US adults 25-34, slight female skew
mode: autonomous
music: understated dark electronic — low dry pulse, no swell, no drop
---

## Video direction

**No narration.** The dialogue track is empty by design — narration is added later by the
user. There is no VO to pace against, so every frame paces its reveals against its own
**burned-in caption**, which is the frame's spoken line made visible: the caption words
land first, the supporting visual answers them. Same discipline as VO pacing — nothing
front-loads, reveals spread across the back ~50%.

**Palette (from `frame.md`, dark register only — this video never uses the orange
register as a full ground).** `ink-black #08090B` ground everywhere · `cream #F2F2F3`
caption + primary type · `fire-orange #E8A33D` the single accent (caption keyword, rule
stubs, fuse marks, icon glow) · `cream-muted #8A8C93` chrome · `border-dark #282726`
hairlines. No second hue anywhere. Frames 1–6 all run the dark register so the app's own
near-black screens sit flush in the frame instead of floating on a colored card.

**Type.** Poppins by role from `frame.md`'s ramp. Captions use the display ramp
(`h1`/`display`), lowercase 800–900, negative-tracked — except the literal product name
in Frame 6, which is set as written ("ExitPlan — Fake Call & Escape"). IBM Plex Mono
uppercase 0.14em is chrome only.

**Caption law (this video's captions are burned into the frames — the caption pipeline
is OFF).** Every frame carries its brief-specified caption as a real composed element,
never a pill overlay. Rules, all frames:
- Caption sits in the **lower third**, left-anchored at `pad-x`, with its last baseline
  **no lower than 88% of canvas height** — clear of the very bottom edge.
- Minimum caption size **4.5cqw** (≈49px at 1080 wide) so it reads on a phone.
- Interpunct-separated lists (`47 SOUNDS · DOORBELL · ALARM · SIREN`) are mono-chrome
  uppercase at the small end; sentence captions are lowercase display at the large end.
- Exactly **one** word or clause per caption may take `fire-orange`. Never two.
- The caption is the frame's first reveal. Visuals answer it.

**Device law (load-bearing — every app screen in this video).** The eight supplied PNGs
are 1080x1920 store frames carrying a baked headline this video must not show. Use the
device region ONLY, cropped in CSS — never letterbox the whole file:
- holder `635 x 1411`, `background-image: url(assets/<file>)`,
  `background-size: 1080px 1920px`, `background-position: -223px -478px` (with bezel).
- screen-only variant: holder `619 x 1395`, `background-position: -231px -486px`.
- Scale the holder with `transform: scale()`; never resize `background-size`.
- Any region carrying a "WhatsApp" label is masked by an opaque `ink-black` plate or
  cropped out (see Frame 4). This is a hard brief constraint.

**Motion grammar.** Long-tail settles, `power3` default — smooth, never bouncy, no
overshoot anywhere in this video. One camera feel across all six frames: the device is
always the still object and the type moves around it. Handheld is expressed as a
**finite, deterministic low-amplitude jitter** on the device layer (`sine-wave-loop`,
low register, index-derived — never `repeat`/`yoyo`, never `Math.random`), not as a
camera pan. Fast cuts: no frame exceeds 5s and every seam is a hard `cut` except the
single crossfade into the outro.

**Rhythm / held frames.** Frames 1 and 4 are the energy peaks. **Frame 3 is a deliberate
held beat** — the screen goes black and the frame holds nearly still; that stillness is
the joke and the setup for Frame 4's ring. **Frame 6 is a held lockup.** Frames 2 and 5
carry sequential reveals. This alternation is what keeps 25s from reading uniform.

**Tone guardrails (hard).** The framing is personal convenience and comfort — a friend
showing you a trick. Never imply harassment, malicious deception, spying, or an
emergency service. No "prank" language, no siren-red alarm styling, no 911/emergency
iconography. Frame 5's claims are the app's real settings copy.

**Negative list.** No live-action footage or stock people (none exists — see `BRIEF.md`).
No iOS or WhatsApp logos, wordmarks, or labels. No fabricated Google Play badge artwork —
Frame 6's store line is brand type in a hairline pill. No rounded corners except the
device bezel and the app icon's own artwork. No shadows, no gradients as ground, no
second accent hue. No slideshow (front-load then freeze). No screensaver (independent
floating elements). No lazy breathing, no back-half pan or push.

---

## Frame 1 — Hook

- scene: "need an excuse to leave?" builds in massive lowercase type, one clause in amber
- duration: 4s
- poster: 3.4s
- transition_in: cut
- status: animated
- type: hook
- persuasion: Problem recognition
- beat: the whispered question
- blueprint: kinetic-type-beats (Adapt)
- asset_candidates: none
- focal: the type itself
- roles: —
- sfx: none
- src: compositions/frames/01-hook.html

Cold open on the reason anyone downloads this. No product yet, no device — just the
question, delivered like someone leaning in to whisper it. This is the whole hook: if the
viewer has ever wanted out of a meeting, they are now watching.

Adapt: keep the multi-beat statement build and the locked finale; drop the spring-pop
(this video has no overshoot) and land on a long-tail settle instead. The "beats" are the
caption's own three chunks, so the hook frame and the caption frame are one thing.

Scene 1 (0.0–0.9s): black field, empty. `need an` enters as the first chunk, lowercase
`h1` cream, left-anchored at pad-x in the upper-middle third — per-word staggered reveal
(`dynamic-content-sequencing`) on a long-tail settle (`power3`). Centered-left composition,
one element, ~55% empty. Nothing else on screen.
Scene 2 (0.9–1.7s): `excuse` hard-cuts in beneath it at `display` scale in **fire-orange** —
the one amber clause of the frame, and the largest thing in the video so far
(`discrete-text-sequence`, hard cut, no fade). The line above holds dead still. A 36x2px
amber rule stub sits above the block as the only ornament.
Scene 3 (1.7–2.4s): `to leave?` lands on the third line in cream, completing the read as a
three-line left-anchored stack occupying the middle ~45% of the frame — waterfall cut at
word granularity across the seam (`cut-catalog.md`), matched direction with Scene 2's
entry so it reads as one continuous build, not three slides.
Scene 4 (2.4–3.0s): fully built, held STILL. A mono kicker `EXITPLAN` fades up small at
the very top-left as the only new mark. No drift, no push — the stillness sells the
whisper. Cut out hard on the beat.

## Frame 2 — 47 sounds

- scene: the app home device lands, then the sound library scrolls behind the count
- duration: 4.5s
- poster: 4s
- transition_in: cut
- status: animated
- type: product_intro
- persuasion: Capability / breadth
- beat: "oh, there's a whole library"
- blueprint: device-surface-showcase (Adapt)
- asset_candidates: capture/assets/screenshot_1_home.png, capture/assets/screenshot_3_library.png
- focal: assets/screenshot_1_home.png
- roles: screenshot_1_home = cutout (hero device) · screenshot_3_library = supporting (the scroll behind)
- sfx: none (brief: background music only, no other audio)
- src: compositions/frames/02-sounds.html

The answer to the hook, and the breadth proof in one shot. The home screen's four quick-exit
cards read instantly; the library scroll behind it proves the 47 isn't marketing.

Adapt: keep the held-hero device with its screens cycling; instead of cycling screens
inside one device, hold the home device as the hero and run the library as a second,
smaller, dimmed device plate behind it — breadth stated spatially rather than in sequence.
Signature move (device held as hero while its content performs) is kept.

Scene 1 (0.0–1.0s): caption enters first, lower third: `47 SOUNDS · DOORBELL · ALARM · SIREN`
as mono uppercase 0.14em, cream, with `47 SOUNDS` in fire-orange — per-word staggered
reveal (`dynamic-content-sequencing`), long-tail. Field otherwise black.
Scene 2 (1.0–2.1s): the home device (device law, with bezel) arrives from slightly below
and settles centered in the upper ~70%, occupying ~45% of the canvas — a single long-tail
rise, no bounce (`spring-pop-entrance`, smooth register). Layered-depth composition, 3
layers: black ground / dimmed library plate (not yet visible) / hero device. Low-amplitude
handheld jitter (`sine-wave-loop`) starts on the device layer and continues to frame end.
Scene 3 (2.1–3.1s): the library device plate fades up behind and to the right at ~40%
opacity and ~0.8 scale, and its screen content **scrolls upward** through the sound list
(`viewport-change` on the plate's background-position) — the list visibly keeps going,
which is the proof. Asymmetric 60/40, hero device forward and sharp, plate behind and
soft (static blur on the plate layer only — no rule needed).
Scene 4 (3.1–4.0s): the four quick-exit cards on the hero screen get a sequential amber
keyword glow (`asr-keyword-glow`) sweeping card 01→04 in a staggered cascade, then
everything settles and holds. No push, no drift — jitter only.

## Frame 3 — Set a fuse

- scene: a touch taps the 10-second fuse, the screen goes fully black, the frame holds
- duration: 4.5s
- poster: 4.1s
- transition_in: cut
- status: animated
- type: feature_showcase
- persuasion: Mechanism / how it works
- beat: the deadpan hold
- blueprint: cursor-ui-demo (Adapt)
- asset_candidates: capture/assets/screenshot_2_fuse.png
- focal: assets/screenshot_2_fuse.png
- roles: screenshot_2_fuse = cutout (hero device)
- sfx: none (brief: background music only, no other audio)
- src: compositions/frames/03-fuse.html

The mechanism, and the dry joke: you arm it, the screen goes dark, and nothing happens.
Yet. This is the video's held beat — the deliberate stillness that makes Frame 4 land.

Adapt: keep the cursor-drives-the-UI signature, but the "cursor" is a **touch dot**, not a
macOS pointer — this is a phone. One tap only, on the fuse selector. Everything after the
tap is the frame refusing to move.

Scene 1 (0.0–1.0s): the fuse device (device law, with bezel) is already centered in the
upper ~70% at ~48% of canvas, holding from Frame 2's cut at matched scale — cut-the-curve
across the seam, same position and jitter phase, so the two frames read as one continuous
handheld take. Caption `set a fuse. walk away.` enters lower third, lowercase display
cream with `fuse` in fire-orange, per-word staggered reveal.
Scene 2 (1.0–1.9s): an amber touch dot arrives from lower-right, travels to the `10` cell
of the FUSE selector and presses — compression then long-tail recovery, with a single
expanding amber ripple (`cursor-click-ripple` / `press-release-spring`, smooth register).
The `10` cell's highlight snaps on at the moment of contact — a hard state change on the
click, not a fade.
Scene 3 (1.9–2.6s): the touch dot lifts and leaves frame lower-right, and the device
screen **cuts to full black** — an instant hard cut of the screen layer only (the bezel,
its edge highlight and the jitter all continue unbroken, which is what sells it as the
same real phone). One faint amber dot remains on the dark screen, the app's own
dark-screen hint.
Scene 4 (2.6–4.0s): HELD. Nothing moves but the device jitter and one slow amber
countdown mark — a thin amber rule under the caption that draws itself right-to-left
(`svg-path-draw`) as the fuse burns down. No other motion anywhere. The frame is
deliberately, comically still.

## Frame 4 — Fake call, real escape

- scene: the phone rings — incoming-call screen, amber ring pulse, caption slams
- duration: 5.5s
- poster: 4.6s
- transition_in: cut
- status: animated
- type: feature_showcase
- persuasion: Payoff / the promise delivered
- beat: the ring
- blueprint: device-surface-showcase (Adapt)
- asset_candidates: capture/assets/screenshot_6_incoming_call.png, capture/assets/screenshot_7_live_call.png
- focal: assets/screenshot_6_incoming_call.png
- roles: screenshot_6_incoming_call = cutout (hero device) · screenshot_7_live_call = supporting (the answered state)
- sfx: none (brief: background music only, no other audio)
- src: compositions/frames/04-call.html

The payoff. The fuse burns out and the phone rings for real — a full incoming-call screen
with a contact name and photo. This is the frame that makes the product make sense.

Adapt: keep the held-hero device cycling its screens through a real flow (incoming →
answered); the camera stays locked and the screen state does the work. The energy comes
from the ring pulse, not from moving the camera.

**⚠ Masking (hard constraint).** `screenshot_6_incoming_call.png` carries the subtitle
"WhatsApp voice call…" inside the device. After cropping to the device rect, cover the
subtitle line with an opaque `ink-black` plate spanning the screen width at the subtitle's
band, and set the app's own neutral string `incoming call` over it in `cream-muted` at the
caption ramp's small end. `screenshot_7_live_call.png` carries no wordmark and needs no
mask. Verify at snapshot: no "WhatsApp" pixel survives in either.

Scene 1 (0.0–0.6s): hard cut from Frame 3's black screen straight into the lit call
screen at the identical device position and scale — the screen layer swaps, the bezel
never moves (inverse zoom-through at the screen layer, `cut-catalog.md`). The transition
IS the ring starting.
Scene 2 (0.6–1.8s): concentric amber ring pulses emanate from the device edge outward, 3
finite pulses, each a single long-tail expansion at decreasing opacity
(`ambient-glow-bloom`, finite — never looped). The contact photo and name are already
lit on the screen. Layered-depth, device forward, rings behind it.
Scene 3 (1.8–3.1s): caption slams in lower third — `fake call,` in cream then `real escape`
in fire-orange, two beats on a kinetic beat-slam (`kinetic-beat-slam`, smooth settle, no
overshoot), the second beat landing on the third ring pulse. This is the loudest type
moment after Frame 1.
Scene 4 (3.1–4.2s): the screen swaps to the **answered** state (live-call screen, timer at
00:00) on a hard state cut — the accept happened, the escape is underway. Ring pulses stop
dead at the swap; the sudden absence of motion is the punctuation.
Scene 5 (4.2–5.0s): held on the live call, caption still lit, jitter only. No push.

## Frame 5 — Offline, no account, no data

- scene: three claims stack up over the settings screen, each landing on its own beat
- duration: 5.5s
- poster: 5s
- transition_in: cut
- status: animated
- type: benefit_highlight
- persuasion: Objection handling / trust
- beat: the reassurance
- blueprint: grid-card-assemble (Adapt)
- asset_candidates: capture/assets/screenshot_8_privacy.png
- focal: assets/screenshot_8_privacy.png
- roles: screenshot_8_privacy = supporting (dimmed background plate, ~35%)
- sfx: none
- src: compositions/frames/05-privacy.html

The objection this app has to answer before anyone installs it: where does this go? It
doesn't. Nothing leaves the phone. Three claims, three beats, the real settings screen
behind them as evidence rather than decoration.

Adapt: keep the staggered self-assembling cascade, but the items are three full-width
claim LINES rather than a tile grid — 9:16 has no room for a grid and the claims are
words, not objects. The device drops to a dimmed background plate for the first time in
the video, which is what makes this frame feel like the exhale before the CTA.

Scene 1 (0.0–1.1s): the settings device (device law, screen-only crop — no bezel) fades up
full-bleed-ish behind, scaled to fill the upper ~80%, dimmed to ~35% opacity and softened
(`depth-of-field-blur`). Its six green toggle rows are legible enough to read as real
settings. Nothing else yet. Layered-depth, 3 layers.
Scene 2 (1.1–2.0s): claim 1 — `works offline` — assembles in as a left-anchored lowercase
`h2` line, cream, preceded by the system's amber `/` mono bullet marker (long-tail settle,
`center-outward-expansion` collapsed to a single line's arrival).
Scene 3 (2.0–2.9s): claim 2 — `no account` — lands beneath it on its own beat, same
treatment, staggered cascade continuing.
Scene 4 (2.9–3.8s): claim 3 — `no data` — lands, and takes the frame's single **fire-orange**
clause. The three lines now read as one left-anchored stack in the middle third, the
dimmed settings screen behind them. This is the back-half reveal — nothing was
front-loaded.
Scene 5 (3.8–5.0s): held. A hairline `border-dark` rule draws under the stack and a mono
`100% OFFLINE · NO ACCOUNTS` chrome line fades in beneath it at the small end — the app's
own footer string, quoted. Settles still; jitter only.

## Frame 6 — ExitPlan

- scene: the fuse icon lights, the name sets beneath it, the store line lands
- duration: 5.5s
- poster: 4.6s
- transition_in: crossfade
- status: animated
- type: branding
- persuasion: Ask
- beat: the lockup
- blueprint: logo-assemble-lockup (Adapt)
- asset_candidates: capture/assets/app_icon.png
- focal: assets/app_icon.png
- roles: app_icon = cutout (hero mark)
- sfx: none
- src: compositions/frames/06-cta.html

The lockup. The real app icon is a burning fuse — an amber line with a glowing head —
which is the whole product in one mark and ties straight back to Frame 3. Let it light,
then set the name and the ask.

Adapt: keep the mark-comes-to-exist signature and the resolve-into-a-centered-lockup
ending. The build is the icon's own fuse **drawing itself** rather than parts orbiting in —
the mark's internal logic is already a build, so use it.

**No official Google Play badge artwork exists in the assets and none may be fabricated.**
Render the ask as a hairline `border-dark` pill containing mono uppercase
`GET IT ON GOOGLE PLAY` in cream, with a small amber rule stub at its left. Type only.

Scene 1 (0.0–1.0s): crossfade in from Frame 5 onto a clean black field. The app icon
arrives centered in the upper-middle at ~22% of canvas width, its amber fuse line drawing
on left-to-right (`svg-path-draw`) and its glowing head blooming as the line completes
(`ambient-glow-bloom`, finite). Centered composition — the only centered frame in the
video, which is what makes it read as the end.
Scene 2 (1.0–1.9s): `ExitPlan` sets beneath the mark at `display` scale in cream — set as
written, not lowercased, since it is the product name. One long-tail settle, no overshoot.
Scene 3 (1.9–2.7s): the subtitle `Fake Call & Escape` fades up beneath it at the `lead`
ramp in `cream-muted`, and a 36x2px amber rule stub lands between mark and name.
Scene 4 (2.7–3.4s): the store pill assembles at the lower third — hairline pill outline
draws first, then `GET IT ON GOOGLE PLAY` fades up inside it (mono uppercase 0.14em,
cream). This is the frame's one lower-third element and sits within the caption band's
88% ceiling.
Scene 5 (3.4–4.0s): held lockup, everything still. The icon's glow holds at full. This is
the video's only real exit — let the amber head be the last thing lit before the cut to
black.
