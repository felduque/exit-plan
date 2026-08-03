# Bundled audio

Real audio, migrated from a sibling project's curated pack (`smoke/assets/sounds`),
one category at a time: whatever exists there replaces what was here, whatever
does not stays untouched. `ringtone/` is empty and unrelated to this migration —
the fake-call feature reuses these same category sounds as ringtones rather than
shipping a separate set.

```
alarms/      — sirens and wake-ups (emergency)
doorbell/    — bells and knocking (someone at the door)
bad-signal/  — glitch/static (cut a call short); migrated from the source
               pack's signal/ folder — same category, renamed
fire/        — fire crackling
storm/       — thunder, rain, wind
electric/    — buzzing / short-circuit
```

## Origin and licence

Two sources, both confirmed free of copyright and commercial-use restriction
by the pack's owner (2026-07-12), carried over unchanged from the source
project's own note:

- **"Efectos de Sonido — Edwin Arenas"** pack, curated: only effects that buy a
  credible excuse. No memes, no screams, no voices.
- **Pixabay** (`doorbell-*`, `alarm-siren-*`, `signal-glitch-*`,
  `fire-crackling-*`, `storm-*`, `electric-buzz-*` in the source pack, renamed
  on the way in — see `system_catalog.dart` for the current slug per file).

## 🚫 `socials/` was deliberately not migrated

The source pack also has a `socials/` folder (WhatsApp, Discord, Telegram,
Slack, Instagram, TikTok, Twitter, Teams…). It is **excluded on purpose**: those
mp3s are the proprietary notification tones of Meta, Microsoft and ByteDance,
and shipping them — especially under a label naming the brand — is an
Intellectual Property / Impersonation problem for Google Play review, not a
licensing one. The source project's own README documents the same call: it
shipped that folder once, then pulled it before its v1.0.0 release for exactly
this reason.

If this is ever revisited, it needs free-licence audio and generic labels
("Incoming message", "VoIP call"), never a real app or company's name.

## Format

Real mp3s, not the synthesized WAVs `tool/gen_audio.dart` used to produce —
`just_audio` plays either format identically, and nothing in the pipeline
requires WAV specifically. `test/assets_test.dart` checks every id in
`system_catalog.dart` resolves to a real, non-empty mp3.
