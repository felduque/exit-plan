---
format: 1080x1920
duration: 30s
message: "Una excusa perfecta para salir de cualquier situación incómoda, con llamadas falsas que parecen reales"
arc: Hook → Problem → Product → Feature demo → Payoff → CTA
audience: US adults 25–34, slight female skew
mode: autonomous
---

## Video direction

**Palette system:** near-black canvas (#0A0A0A), amber accent (#F5A623) for labels/rules/CTA, white headlines, gray body, green/red only inside the real phone UI.

**Motion grammar:** fast, percussive, VO-paced reveals. Each frame enters with only what the voiceover says at t=0; subsequent elements reveal on their spoken cue. Default ease is smooth long-tail (`power3`); no bouncy overshoot. Held beats use subtle jitter only — no lazy breathing, no slow pans.

**Rhythm / held-frame allocation:** Frames 1 and 2 are kinetic and quick; Frame 5 (incoming call) is the visual climax and holds; Frame 6 (CTA) is a calm close.

**Negative list:** no second accent color, no pure-white backgrounds, no tiny body text, no over-busy frames, no bouncy entrances.

## Frame 1 — Hook

- scene: Big type asks the viewer about being trapped; a phone starts to rise from the bottom.
- duration: 4s
- transition_in: cut
- status: outline
- src: compositions/frames/01-hook.html
- type: hook
- persuasion: Pain validation
- beat: anxiety
- blueprint: kinetic-type-beats
- asset_candidates: none — typography + phone shape
- voiceover: "¿Alguna vez has estado atrapado en una cita que no termina?"

Open cold on the universal awkward moment. The question is the hook; the phone reveal teases the solution without naming it yet.

## Frame 2 — The need

- scene: Kinetic words build the tension: "reunión", "alarga", "necesitas salir".
- duration: 3s
- transition_in: blur-crossfade
- status: outline
- src: compositions/frames/02-need.html
- type: pain_point
- persuasion: Agitation
- beat: urgency
- blueprint: kinetic-type-beats
- asset_candidates: none — typography only
- voiceover: "Necesitas una salida. Una excusa que nadie dude."

Keep the energy up. The VO names the need; the type slams in on each word.

## Frame 3 — Product intro

- scene: ExitPlan app home appears inside a phone mockup; the "Fake calls" row pulses with an amber highlight.
- duration: 5s
- transition_in: zoom-through
- status: outline
- src: compositions/frames/03-product.html
- type: product_intro
- persuasion: Solution framing
- beat: curiosity
- blueprint: device-surface-showcase
- asset_candidates: assets/screen_home.png — ExitPlan home screen with Fake calls entry
- voiceover: "ExitPlan. La app de llamada falsa que suena y parece real."

Introduce the product by showing the real app home. The phone is hero; the Fake calls row is the focal point.

## Frame 4 — Feature showcase

- scene: Phone mockup shows the template editor: caller name, number, theme picker (Classic / Material / Green chat / Blue chat), schedule chips.
- duration: 8s
- transition_in: push-slide RIGHT
- status: outline
- src: compositions/frames/04-features.html
- type: feature_showcase
- persuasion: Capability stack
- beat: control
- blueprint: cursor-ui-demo
- asset_candidates: assets/screen_editor_top.png — template editor top half; assets/screen_editor_scroll.png — template editor scrolled showing schedule chips and toggles
- voiceover: "Elige quién llama, qué pantalla quieres — Android, WhatsApp — y decide: ahora o dentro de cinco minutos."

A multi-step demo inside the real interface. Reveal each option as the VO names it: contact fields, themes, schedule.

## Frame 5 — Payoff

- scene: Full-screen incoming fake call UI shows "Mom" calling; green accept, red decline buttons.
- duration: 5s
- transition_in: zoom-through
- status: outline
- src: compositions/frames/05-payoff.html
- type: benefit_highlight
- persuasion: Show-don't-tell proof
- beat: relief + excitement
- blueprint: device-surface-showcase
- asset_candidates: assets/screen_incoming_classic_2.png — full-screen incoming fake call
- voiceover: "Cuando suene, solo actúa. Tu teléfono hará el resto."

The climax: the fake call that looks real. Hold the frame so the viewer reads the UI.

## Frame 6 — CTA

- scene: Google Play Store listing for "Llamada Falsa: Excusa Perfecta" with Install button; app icon and name lock up.
- duration: 5s
- transition_in: crossfade
- status: outline
- src: compositions/frames/06-cta.html
- type: cta
- persuasion: Action prompt
- beat: urgency-to-act
- blueprint: titlecard-reveal
- asset_candidates: assets/play_store.png — Google Play Store listing
- voiceover: "Busca 'Llamada Falsa: Excusa Perfecta' en Google Play. Tu excusa perfecta, a un toque."

Calm, confident close. The Play Store card is the only content; the CTA is the action.
