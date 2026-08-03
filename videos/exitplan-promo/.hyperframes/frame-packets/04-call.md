# Frame packet: 04-call

## Project inputs

- Project: C:\Users\jfduq\Documents\exit-plan\videos\exitplan-promo
- Design tokens: C:\Users\jfduq\Documents\exit-plan\videos\exitplan-promo\frame.md
- RULES_DIR: C:\Users\jfduq\.agents\skills\hyperframes-animation\rules

## Assigned storyboard block

## Frame 4 — Fake call, real escape

- scene: the phone rings — incoming-call screen, amber ring pulse, caption slams
- duration: 5s
- poster: 3.5s
- transition_in: cut
- status: outline
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

## Selected motion rule: ambient-glow-bloom

---
name: ambient-glow-bloom
description: Un-triggered soft radial glow that blooms in behind a hero element and holds with a bounded idle breathe, or a single-pass traveling sweep across a surface. No click, no word-sync — it just blooms. Finite, deterministic, seek-safe.
metadata:
  tags: glow, bloom, ambient, radial, sweep, hero, presence, finite, un-triggered
---

# Ambient Glow Bloom

A soft radial glow that **blooms in behind a hero element** (card, logo, metric) and holds, giving it presence. Unlike `press-release-spring`'s click-triggered burst or `asr-keyword-glow`'s word-timed envelope, this glow is **un-triggered** — it blooms on the hero's settle and stays lit. Two forms: a **hero bloom** that swells behind a settling element then breathes, and a **traveling sweep** that translates a soft highlight across a surface exactly once.

## How It Works

A radial-gradient layer sits **behind** the hero (glow `z-index: 1`, hero `z-index: 2` — a glow in front occludes it), starting at `opacity: 0`. Over the bloom-in window it ramps `opacity: 0 → peak` with a gentle `scale` swell, timed so `BLOOM_START + BLOOM_DUR` lands on the hero's settle — glow and hero resolve as ONE beat ("powering on"), never glow-then-card. After bloom-in:

1. **Hero bloom** — a **bounded idle breathe** during the hold: a finite `ease: "none"` tween advances a `phase` proxy and `onUpdate` nudges opacity + scale a hair around peak (never a `yoyo` loop). `sin(0) = 0` → the breathe starts exactly at the bloom's resting state.
2. **Traveling sweep** — a narrow highlight band at one edge translates **once** across to the other (`x` off-surface to off-surface), clipped to the surface (`overflow: hidden`). One pass, no return — a repeating sweep reads as a loading shimmer, not a reveal accent (the shimmer-sweep variation below is the sanctioned exception).

Peak opacity stays restrained (**≤ 0.45 hard ceiling**) so the glow gives presence without washing the frame; the glow color is **darker + more saturated** than the element it backs (a same-hue, same-lightness glow disappears into the surface).

## Recipe

```html
<!-- inside a standard scene clip -->
<div class="bloom-stage">
  <div class="bloom-glow" id="bloom-glow"></div>
  <!-- z-index: 1; inset: GLOW_INSET (negative); background: {glowGradient} -->
  <div class="hero-card" id="hero-card">{HeroLabel}</div>
  <!-- z-index: 2 -->
</div>
<!-- sweep form: <div class="sweep" id="sweep"> inside the overflow:hidden surface -->
```

```js
// ── Form A: HERO BLOOM ── bloom in soft, landing on the hero's settle.
tl.fromTo(
  "#bloom-glow",
  { opacity: 0, scale: GLOW_START_SCALE },
  { opacity: GLOW_PEAK_OPACITY, scale: 1, duration: BLOOM_DUR, ease: "power2.out" },
  BLOOM_START,
);
// Bounded breathe during the hold — finite phase tween, NOT a yoyo loop.
const glow = document.getElementById("bloom-glow");
const phase = { p: 0 };
tl.to(
  phase,
  {
    p: Math.PI * 2 * BREATHE_CYCLES,
    duration: BREATHE_DUR,
    ease: "none",
    onUpdate: () => {
      const s = Math.sin(phase.p);
      glow.style.opacity = String(GLOW_PEAK_OPACITY + s * OPACITY_AMP);
      glow.style.transform = `scale(${1 + s * SCALE_AMP})`;
    },
  },
  BLOOM_START + BLOOM_DUR,
);

// ── Form B: TRAVELING SWEEP ── one finite pass, constant glide.
tl.fromTo(
  "#sweep",
  { x: SWEEP_START_X, opacity: 0 },
  { x: SWEEP_END_X, opacity: SWEEP_PEAK_OPACITY, duration: SWEEP_DUR, ease: "none" },
  SWEEP_START,
);
tl.to("#sweep", { opacity: 0, duration: SWEEP_FADE_DUR, ease: "power1.in" }, SWEEP_FADE_START);
```

## Variations

- **Bloom-and-hold** — for scenes <3s or a hero with its own idle, skip the breathe: the single `fromTo` is the whole recipe.
- **Pulse-on-arrival** — bloom slightly PAST peak (`GLOW_OVERSHOOT_OPACITY`, `scale: 1.06`), then a second adjacent tween eases down to a steady hold — one breath punctuating the landing, no ongoing loop.
- **Multi-hero relay** — stagger per-glow `BLOOM_START` by ~0.15–0.3s across a row; shrink `OPACITY_AMP` / `SCALE_AMP` per the `/√N` rule below.
- **Diagonal raked sweep** — angle `{sweepGradient}` (~105°) across a wordmark: the classic one-pass logo sheen. Narrower `SWEEP_WIDTH`, higher `SWEEP_PEAK_OPACITY`.

### Shimmer sweep (text-clipped status-phrase working-state)

The sweep re-aimed **inside type**: a soft highlight gradient clipped into a status phrase ("Thinking…", "Analyzing dataset…") via `background-clip: text` travels left→right through the letterforms — the grey-on-grey shimmer that says _still working_. Unlike every other form here it legitimately **repeats while the status is live**: the repetition is diegetic working-state, not idle wobble (same defense as a blinking caret — the motion performs status). Two things keep it honest: it is **bounded** (one finite tween whose pass count is computed from the status window, never `repeat: -1`), and it is **killed at resolve** — the moment the status completes, the shimmer stops dead; a shimmer surviving into the answer beat turns a working indicator into decoration.

```js
// Status shimmer — N passes as ONE bounded tween. Killed at resolve.
const status = document.getElementById("status-phrase");
// CSS on #status-phrase: background: {shimmerGradient}; background-size: 300% 100%;
// -webkit-background-clip: text; background-clip: text; color: transparent;
const shimmer = { p: 0 };
const PASSES = Math.round(STATUS_DUR / PASS_PERIOD); // whole passes, computed up front
tl.to(
  shimmer,
  {
    p: PASSES,
    duration: STATUS_DUR,
    ease: "none",
    onUpdate: () => {
      const t = shimmer.p % 1; // 0→1 within each pass; percent axis inverted → left→right travel
      status.style.backgroundPosition = `${(1 - t) * 100}% 50%`;
    },
  },
  STATUS_START,
);
tl.set(status, { backgroundPosition: "100% 50%" }, STATUS_START + STATUS_DUR); // resolve: dead.
```

Keep it a whisper: `{shimmerGradient}` is the status text's own grey with one slightly-lighter band (highlight stop a step above the base, nothing near white); `background-size` ~300% keeps the band narrow in the glyphs; `PASS_PERIOD` 1.2–1.8s — slower reads as a sheen accent, faster as a spinner. Whole-number `PASSES` lands the band at its start position exactly at the kill frame, so the `tl.set` is visually a no-op. This is the working-state cousin of `gradient-text-sweep`: reach **here** when the sweep _means_ "in progress," **there** when the gradient is the typographic treatment itself.

## Values

| token                   | range / default                                        | notes                                                                      |
| ----------------------- | ------------------------------------------------------ | -------------------------------------------------------------------------- |
| GLOW_PEAK_OPACITY       | 0.15 (subtle) → 0.30 (default) → **0.45 hard ceiling** | higher washes the frame; a glow you consciously notice is too strong       |
| GLOW_INSET              | −200 to −450px (1920×1080)                             | negative so the halo extends past the hero; too small reads as a tight rim |
| GLOW_START_SCALE        | 0.80–1.0                                               | ≤1.0 — grow into place, never shrink                                       |
| BLOOM_DUR / BLOOM_START | 0.6–1.4s                                               | `BLOOM_START + BLOOM_DUR` ≈ the hero's settle frame                        |
| OPACITY_AMP / SCALE_AMP | 0.02–0.05 / 0.01–0.03 default                          | `PEAK + OPACITY_AMP ≤ 0.45`; push only when the glow is the sole motion    |
| BREATHE_CYCLES          | period 2.5–4s per breath                               | glow breathes slower than element breathing                                |
| SWEEP_WIDTH             | 15–35% of surface (grid) / 8–15% (wordmark)            |                                                                            |
| SWEEP_DUR               | 0.8–1.6s                                               | one deliberate pass — slow enough to read as light                         |
| SWEEP_PEAK_OPACITY      | 0.10 → 0.25 (default) → 0.40                           | same ≤ ~0.45 wash limit; tight sweeps tolerate the high end                |
| SWEEP_START_X / END_X   | fully off-surface both ends                            | no visible spawn/despawn mid-surface; fade reaches 0 as the band clears    |
| PASS_PERIOD (shimmer)   | 1.2–1.8s                                               | with whole-number PASSES                                                   |

## Critical Constraints

- **Glow peak opacity ≤ 0.45** — including breathe amplitude; default to the LOW end (0.15–0.30).
- **Glow behind, hero in front**; glow color darker + more saturated than the hero surface.
- **Land glow and hero as one beat** — before or after reads as two separate events.
- **Breathe is bounded, sweep is one pass** — the only sanctioned repetition is the shimmer sweep, bounded and killed at resolve.
- **Concurrent halos compound** — per-glow amps ≤ default `/√N`, stagger breathe periods (2.6s / 2.9s / 3.3s) so they don't pulse in lockstep.
- **Don't combine a `boxShadow` glow on the hero with this halo layer** — they compete and read muddy; the glow lives on the dedicated layer.

## See also

`sine-wave-loop` (hero breathes on scale/y while the glow breathes on opacity, out of phase) · `press-release-spring` (the click-triggered sibling — never both behind one element) · `counting-dynamic-scale` / `stat-bars-and-fills` (bloom behind a landing stat) · `center-outward-expansion` (sweep across the assembled grid) · `gradient-text-sweep` (the design-beat gradient counterpart).

## Selected motion rule: kinetic-beat-slam

---
name: kinetic-beat-slam
description: Percussive kinetic typography — short phrases slam in on a steady beat with distinct per-phrase entrances, optional rhythm chrome (metronome ticks, beat bar), then a locked finale.
metadata:
  tags: text, kinetic, typography, beat, rhythm, slam, percussive, punchy
---

# Kinetic Beat Slam

Short phrases hit one at a time on a **steady beat**, each with a _different_ entrance, then stack into a locked finale — the recipe for "punchy / rhythmic" text-forward pieces (taglines, manifestos, hype intros). The difference between generic and rhythmic is (1) one shared **onset array** driving every element, (2) **distinct** entrances per phrase rather than one reused helper, and (3) optional **rhythm chrome** that visibly keeps the beat.

## How It Works

A single tempo grid — `PULSE` seconds per sub-beat, `BEATS = [t0, t1, t2, …]` on that grid — is the rhythmic spine; every phrase entrance, accent, and chrome tick reads its time from it, so the piece locks to one pulse instead of drifting hand-tuned offsets. Each phrase gets a different transform axis (scale+blur slam / side snap / rise+rotate) with short attacks (0.35–0.6s on the hit), then the stack holds with a finite low-amplitude breath.

## Recipe

```html
<!-- inside a standard scene clip (hyperframes-core) -->
<div class="kbs-stage">
  <div class="kbs-line" id="p1"><span class="verb">Notice</span> more.</div>
  <div class="kbs-line" id="p2"><span class="verb">Decide</span> faster.</div>
  <div class="kbs-line" id="p3"><span class="verb">Act</span> now.</div>
</div>
<!-- optional rhythm chrome -->
<div class="kbs-metronome" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i></div>
```

```css
.kbs-stage {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 120px 160px; /* title-safe margin */
}
.kbs-line {
  font-family: "Archivo Black", "League Gothic", sans-serif; /* embedded display face */
  font-size: 150px;
  line-height: 0.96;
  letter-spacing: -0.03em;
  color: #f5f5f5;
}
.kbs-line .verb {
  color: #ff5b2e; /* exactly one accent hue */
}
.kbs-metronome {
  position: absolute;
  bottom: 64px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 14px;
}
.kbs-metronome i {
  width: 6px;
  height: 28px;
  background: #ff5b2e;
  opacity: 0.25;
}
```

```js
// ONE tempo grid drives everything — phrases AND the metronome read it.
const PULSE = 0.4; // seconds per sub-beat
const BEATS = [PULSE * 1, PULSE * 5, PULSE * 9]; // phrase onsets, on the grid

// Distinct entrances per phrase (NOT one reused helper).
tl.fromTo(
  "#p1",
  { scale: 1.5, filter: "blur(16px)", opacity: 0 },
  { scale: 1, filter: "blur(0px)", opacity: 1, duration: 0.5, ease: "power4.out" },
  BEATS[0],
);
tl.fromTo(
  "#p2",
  { x: -320, opacity: 0 },
  { x: 0, opacity: 1, duration: 0.45, ease: "expo.out" },
  BEATS[1],
);
tl.fromTo(
  "#p3",
  { y: 90, rotation: 6, opacity: 0 },
  { y: 0, rotation: 0, opacity: 1, duration: 0.55, ease: "circ.out" },
  BEATS[2],
);

// Rhythm chrome: each tick flashes on the SAME grid, not a magic offset.
gsap.utils.toArray(".kbs-metronome i").forEach((tick, i) => {
  tl.to(tick, { opacity: 1, duration: 0.08, yoyo: true, repeat: 1, ease: "none" }, PULSE * (i + 1));
});

// Finale hold: floor (not ceil) so the repeat never overshoots data-duration;
// max(0,…) so a short hold never yields a negative repeat (GSAP reads negative as -1 = infinite).
const holdStart = BEATS[2] + 0.7,
  cycle = 1.6,
  holdDur = SCENE_DURATION - holdStart;
tl.to(
  ".kbs-stage",
  {
    scale: 1.01,
    duration: cycle / 2,
    ease: "sine.inOut",
    yoyo: true,
    repeat: Math.max(0, Math.floor(holdDur / cycle) - 1),
  },
  holdStart,
);
```

## Variations

- **Entrance easing by attack character** — `power4.out` hard slam ⭐ default hit · `expo.out` hardest snap (side-snaps, whip-ins) · `back.out(2)` overshoot pop (accents only, not body words) · `circ.out` heavy rise with momentum. Use **at least 3 distinct easings** across the piece.
- **Rhythm chrome alternatives** — a center beat bar or a `// label` monospace tag pulsing on-beat instead of the 5-tick metronome; mark any decorative that must survive a shader transition per `../../transitions/overview.md`.
- **Finale dressing** — stack + accent underline sweep ([css-marker-patterns](css-marker-patterns.md)); don't just leave the last phrase sitting.

## Values

| token             | range                | notes                                                                                        |
| ----------------- | -------------------- | -------------------------------------------------------------------------------------------- |
| BEATS spacing     | 1.2–1.8s             | <0.8s frantic, >2.5s loses the pulse; keep spacing even — it's a beat                        |
| entrance duration | 0.35–0.6s            | the hit must resolve before the next beat; exits ≤0.25s                                      |
| accent hue        | exactly 1            | the verbs; the rest mono white / near-black                                                  |
| display face      | 150px+, heavy weight | Archivo Black / League Gothic / Oswald — see `hyperframes-creative/references/typography.md` |

## Critical Constraints

- **One beat array, not scattered offsets** — every element times off `BEATS[]` / `PULSE`; this is the single biggest lever for "rhythmic".
- **Different entrance per phrase** — a reused `punchIn()` for all lines is the flat-but-competent tell. Vary the motion axis, reuse the ease _family_.
- **Finale repeat math**: `repeat: Math.max(0, Math.floor(dur / cycle) - 1)` — `Math.ceil` overshoots `data-duration` and trips the `gsap_repeat_ceil_overshoot` lint rule; a negative repeat is read by GSAP as `-1` (infinite).
- **No banned exit animations between scenes** — in a montage the _transition_ is the exit (`../../transitions/overview.md`); only a final scene may fade out.
- **Display font must be embedded** or it silently falls back at render — Anton / Bebas-as-literal are NOT embedded (`Bebas Neue` aliases to League Gothic; verify in `typography.md`).

## See also

`3d-text-depth-layers` (extruded depth on the slammed words) · `css-marker-patterns` (finale underline/circle) · `sine-wave-loop` (the finale breath) · `../adapters/gsap-easing-and-stagger.md` (easing vocabulary).
