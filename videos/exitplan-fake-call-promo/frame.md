---
version: alpha
name: ExitPlan Dark — Frame (video / frame layer)
description: >
  Video-first design system for ExitPlan. Dark, near-black canvas with a warm amber accent.
  The app is about fake calls and escapes, so the frame feels urgent, personal, and a little cinematic.
  Space Grotesk carries display and chrome; JetBrains Mono handles the small uppercase labels.
unit: the frame — 1080x1920 vertical primary
principle: dark canvas · amber accent · phone UI as hero · motion is the message

colors:
  bg: "#0A0A0A"
  surface: "#141414"
  surface-2: "#1E1E1E"
  primary: "#F5A623"
  primary-dim: "rgba(245,166,35,0.15)"
  text: "#FFFFFF"
  text-muted: "#A0A0A0"
  text-dim: "#6B6B6B"
  border: "rgba(255,255,255,0.10)"
  positive: "#34C759"
  negative: "#FF3B30"

radii:
  pill: "100px"
  card-lg: "18px"
  card-md: "14px"
  card-sm: "10px"
  circle: "50%"

typography:
  mono-label:
    fontFamily: "JetBrains Mono"
    cqw: 0.9
    weight: 500
    tracking: "0.12em"
    upper: true
    color: "text-muted"
  body:
    fontFamily: "Space Grotesk"
    cqw: 1.1
    weight: 400
    lineHeight: 1.45
    color: "text-muted"
  h3:
    fontFamily: "Space Grotesk"
    cqw: 1.8
    weight: 600
    lineHeight: 1.15
    tracking: "-0.02em"
    color: "text"
  h2:
    fontFamily: "Space Grotesk"
    cqw: 2.6
    weight: 600
    lineHeight: 1.1
    tracking: "-0.02em"
    color: "text"
  h1:
    fontFamily: "Space Grotesk"
    cqw: 4.0
    weight: 700
    lineHeight: 1.05
    tracking: "-0.02em"
    color: "text"
  stat-num:
    fontFamily: "Space Grotesk"
    cqw: 3.2
    weight: 700
    lineHeight: 1.0
    color: "primary"

spacing:
  pad-x: "6cqw"
  pad-y-top: "6cqw"
  gap-cards: "2cqw"

components:
  phone-card:
    backgroundColor: "{colors.surface}"
    border: "1.5px solid {colors.border}"
    rounded: "{radii.card-lg}"
    shadow: "0 24px 60px rgba(0,0,0,0.5)"
    description: "Device mockup / app screenshot holder. Dark surface with subtle border and deep shadow."
  tag-pill:
    backgroundColor: "{colors.primary-dim}"
    textColor: "{colors.primary}"
    rounded: "{radii.pill}"
    typography: "{typography.mono-label}"
    description: "Small uppercase label pill."
  cta-button:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.bg}"
    rounded: "{radii.pill}"
    typography: "Space Grotesk 700"
    description: "The one solid amber CTA."
  accent-line:
    backgroundColor: "{colors.primary}"
    size: "50×3, 2px radius"
    description: "Amber rule above headlines."
  stat-pill:
    backgroundColor: "{colors.surface-2}"
    border: "1.5px solid {colors.border}"
    rounded: "{radii.card-md}"
    typography: "{typography.stat-num} + {typography.mono-label}"
    description: "Count-up or feature stat card."
---

# ExitPlan Dark — Frame (video / frame layer)

## Overview

ExitPlan at frame scale is **dark, urgent, and personal**. The canvas is near-black; the only warm
accent is amber. The phone itself is the hero — not the app chrome — because the product is the
call screen that fools whoever is watching. Motion is fast, percussive, and timed to the voiceover:
words slam, the phone flips in, the interface reveals itself beat by beat.

**Key characteristics:**

- **Near-black ground** (#0A0A0A) on every frame.
- **Amber accent** (#F5A623) for labels, CTAs, rules, and the one stat highlight.
- **Phone UI as hero** — device mockups held center, screenshots inside them.
- **Space Grotesk** for display and body; **JetBrains Mono** for uppercase chrome labels.
- **High contrast** — white headlines on black, amber for the action.

## The Frame

- **Primary:** 1080×1920 (9:16).
- **Safe area:** `pad-x` 6cqw; top 6cqw; bottom reserves ~17% for captions.

## Colors

`{colors.bg}` is the universal ground. `{colors.primary}` amber carries every accent: eyebrows, CTAs,
rules, and the stat highlight. Headlines are `{colors.text}` white; body is `{colors.text-muted}` gray.
Cards sit on `{colors.surface}` with `{colors.border}` hairlines.

## Typography

- **h1** — 4.0cqw, Space Grotesk 700, white, tight line.
- **h2** — 2.6cqw, Space Grotesk 600, white.
- **h3** — 1.8cqw, Space Grotesk 600, white.
- **body** — 1.1cqw, Space Grotesk 400, muted gray.
- **mono-label** — 0.9cqw, JetBrains Mono 500, uppercase, amber or gray.
- **stat-num** — 3.2cqw, Space Grotesk 700, amber.

## Depth & Surface

Depth comes from deep shadows on phone cards, subtle hairline borders, and layered surfaces.
No glassmorphism, no heavy gradients.

## Composition Rules

### Do

- Start every frame on near-black.
- Let amber carry every accent.
- Center the phone/device mockup as the hero.
- Use uppercase mono labels for small captions.
- Keep captions large and in the bottom band.

### Don't

- No second accent color.
- No pure white backgrounds.
- No tiny body text.
- No over-busy frames — the phone UI is already dense.

## Frame Treatments

### 1 · Cover (hook · big type + phone reveal)

**Ground** near-black. **Focal** h1 headline left or center, amber accent-line above, phone mockup
entering from below. **Accent** amber rule + CTA. **Density** low.

### 2 · Problem (awkward situation)

**Ground** near-black. **Focal** kinetic type beat or a small scene card. **Accent** amber keywords.
**Density** low.

### 3 · Product / App home

**Ground** near-black. **Focal** phone card showing ExitPlan home with Fake calls highlighted.
**Accent** amber label. **Density** medium.

### 4 · Feature demo (editor / schedule)

**Ground** near-black. **Focal** phone card showing the template editor with schedule chips.
**Accent** amber on "NOW" / selected state. **Density** medium.

### 5 · Payoff (incoming call)

**Ground** near-black. **Focal** full-screen incoming call UI inside a phone frame or full-bleed.
**Accent** green/red call buttons, amber caption. **Density** medium-high.

### 6 · CTA / Play Store

**Ground** near-black. **Focal** Play Store card + app icon + "Instalar" button + app name.
**Accent** amber CTA. **Density** low.
