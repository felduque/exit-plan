// Synthesizes the bundled escape sounds of EXITPLAN as 16-bit mono WAV files.
//
//   dart run tool/gen_audio.dart
//
// Output: assets/audio/<category>/<slug>.wav  (22.05 kHz, mono, 4-8 s loops)
//
// Everything is generated from scratch with plain arithmetic: no samples are
// downloaded, so nothing here belongs to a third party. Ambient beds are made
// loop-seamless by crossfading their tail over their head (see `loopify`), and
// every file gets short fades at both edges so a repeat never clicks.
//
// Curation rule from the spec: only sounds that buy a *credible* excuse. No
// memes, no voices, no laughter, and never a real brand's tone.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int kSampleRate = 22050;
const double kTwoPi = 2 * pi;

final Random _rnd = Random(20260725);

// ---------------------------------------------------------------------------
// Buffer helpers
// ---------------------------------------------------------------------------

Float64List buffer(double seconds) =>
    Float64List((seconds * kSampleRate).round());

int samples(double seconds) => (seconds * kSampleRate).round();

/// Mixes [src] into [dst] starting at [at] seconds, scaled by [gain].
void mixIn(Float64List dst, Float64List src, double at, {double gain = 1}) {
  final offset = samples(at);
  for (var i = 0; i < src.length; i++) {
    final j = offset + i;
    if (j < 0 || j >= dst.length) continue;
    dst[j] += src[i] * gain;
  }
}

/// One-pole low-pass. Cheap, and its gentle slope is what makes filtered noise
/// read as "distant" rather than "processed".
Float64List lowpass(Float64List x, double cutoffHz) {
  final a = 1 - exp(-kTwoPi * cutoffHz / kSampleRate);
  final out = Float64List(x.length);
  var y = 0.0;
  for (var i = 0; i < x.length; i++) {
    y += a * (x[i] - y);
    out[i] = y;
  }
  return out;
}

Float64List highpass(Float64List x, double cutoffHz) {
  final lp = lowpass(x, cutoffHz);
  final out = Float64List(x.length);
  for (var i = 0; i < x.length; i++) {
    out[i] = x[i] - lp[i];
  }
  return out;
}

Float64List bandpass(Float64List x, double lowHz, double highHz) =>
    lowpass(highpass(x, lowHz), highHz);

Float64List whiteNoise(double seconds) {
  final b = buffer(seconds);
  for (var i = 0; i < b.length; i++) {
    b[i] = _rnd.nextDouble() * 2 - 1;
  }
  return b;
}

/// Integrated noise: heavier at the bottom, which is what fire and thunder are.
Float64List brownNoise(double seconds) {
  final b = buffer(seconds);
  var y = 0.0;
  for (var i = 0; i < b.length; i++) {
    y = y * 0.985 + (_rnd.nextDouble() * 2 - 1) * 0.06;
    b[i] = y;
  }
  normalize(b, 1);
  return b;
}

void normalize(Float64List b, double peak) {
  var maxAbs = 0.0;
  for (final v in b) {
    final a = v.abs();
    if (a > maxAbs) maxAbs = a;
  }
  if (maxAbs < 1e-9) return;
  final k = peak / maxAbs;
  for (var i = 0; i < b.length; i++) {
    b[i] *= k;
  }
}

void fadeEdges(Float64List b, double seconds) {
  final n = min(samples(seconds), b.length ~/ 2);
  for (var i = 0; i < n; i++) {
    final w = i / n;
    b[i] *= w;
    b[b.length - 1 - i] *= w;
  }
}

/// Turns a bed of length `dur + xfade` into a seamless loop of length `dur` by
/// crossfading the extra tail back over the head.
Float64List loopify(Float64List b, double xfadeSeconds) {
  final m = min(samples(xfadeSeconds), b.length ~/ 3);
  final n = b.length - m;
  final out = Float64List(n);
  out.setRange(0, n, b);
  for (var i = 0; i < m; i++) {
    final w = i / m;
    out[i] = b[i] * w + b[n + i] * (1 - w);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Grains: the small building blocks that get placed on a timeline
// ---------------------------------------------------------------------------

/// A struck bell / chime: fundamental plus slightly inharmonic partials, each
/// decaying faster than the one below it.
Float64List bell(double freq, double dur, {double tau = 0.9}) {
  final b = buffer(dur);
  const partials = <double>[1, 2.01, 2.99, 4.14, 5.43];
  const gains = <double>[1, 0.5, 0.26, 0.12, 0.06];
  for (var p = 0; p < partials.length; p++) {
    final f = freq * partials[p];
    if (f > kSampleRate / 2.2) continue;
    final decay = tau / (1 + p * 0.7);
    for (var i = 0; i < b.length; i++) {
      final t = i / kSampleRate;
      b[i] += sin(kTwoPi * f * t) * gains[p] * exp(-t / decay);
    }
  }
  // A touch of attack noise so the strike has a body to it.
  final click = lowpass(whiteNoise(0.008), 4000);
  for (var i = 0; i < click.length && i < b.length; i++) {
    b[i] += click[i] * 0.25 * (1 - i / click.length);
  }
  fadeEdges(b, 0.002);
  return b;
}

/// Band-limited square via odd harmonics — an electric buzzer, not a synth lead.
Float64List squareTone(double freq, double dur,
    {double amp = 1, double duty = 0}) {
  final b = buffer(dur);
  for (var h = 1; h * freq < kSampleRate / 2.2; h += 2) {
    final g = 1 / h;
    for (var i = 0; i < b.length; i++) {
      b[i] += sin(kTwoPi * freq * h * (i / kSampleRate)) * g;
    }
  }
  normalize(b, amp);
  if (duty > 0) {
    for (var i = 0; i < b.length; i++) {
      b[i] *= 0.7 + 0.3 * sin(kTwoPi * duty * (i / kSampleRate));
    }
  }
  fadeEdges(b, 0.004);
  return b;
}

Float64List sineTone(double freq, double dur, {double amp = 1}) {
  final b = buffer(dur);
  for (var i = 0; i < b.length; i++) {
    b[i] = sin(kTwoPi * freq * (i / kSampleRate)) * amp;
  }
  fadeEdges(b, 0.006);
  return b;
}

/// A noise burst shaped by an exponential decay: pops, crackles, arcs, cracks.
Float64List noiseBurst(double dur,
    {double lowHz = 20, double highHz = 9000, double tau = 0.02}) {
  var b = whiteNoise(dur);
  b = bandpass(b, lowHz, highHz);
  for (var i = 0; i < b.length; i++) {
    b[i] *= exp(-(i / kSampleRate) / tau);
  }
  normalize(b, 1);
  return b;
}

/// Sweeps a sine from [fromHz] to [toHz]; the shape of every siren.
Float64List sweep(double fromHz, double toHz, double dur, {double amp = 1}) {
  final b = buffer(dur);
  var phase = 0.0;
  for (var i = 0; i < b.length; i++) {
    final k = i / b.length;
    final f = fromHz + (toHz - fromHz) * k;
    phase += kTwoPi * f / kSampleRate;
    b[i] = sin(phase) * amp;
  }
  fadeEdges(b, 0.01);
  return b;
}

// ---------------------------------------------------------------------------
// DOORBELL
// ---------------------------------------------------------------------------

Float64List doorbellDing() {
  final b = buffer(6);
  mixIn(b, bell(830, 3.2, tau: 1.3), 0.15);
  normalize(b, 0.9);
  fadeEdges(b, 0.02);
  return b;
}

Float64List doorbellDingDong() {
  final b = buffer(7);
  mixIn(b, bell(880, 2.4, tau: 0.9), 0.15);
  mixIn(b, bell(698, 3.4, tau: 1.3), 0.75);
  normalize(b, 0.9);
  fadeEdges(b, 0.02);
  return b;
}

Float64List doorbellBuzzer() {
  final b = buffer(6);
  for (var at = 0.1; at < 5.4; at += 1.5) {
    mixIn(b, squareTone(185, 0.85, duty: 24), at, gain: 0.8);
  }
  normalize(b, 0.85);
  fadeEdges(b, 0.02);
  return b;
}

Float64List doorbellChime() {
  final b = buffer(7);
  mixIn(b, bell(1046, 1.6, tau: 0.6), 0.1);
  mixIn(b, bell(1318, 1.6, tau: 0.6), 0.45);
  mixIn(b, bell(1568, 3.0, tau: 1.2), 0.8);
  normalize(b, 0.85);
  fadeEdges(b, 0.02);
  return b;
}

Float64List doorbellIntercom() {
  final b = buffer(6);
  for (final at in <double>[0.2, 1.6, 3.4]) {
    final tone = squareTone(400, 0.7, duty: 47);
    // Harsh amplitude modulation: the sound of a cheap door station.
    for (var i = 0; i < tone.length; i++) {
      tone[i] *= 0.6 + 0.4 * sin(kTwoPi * 105 * (i / kSampleRate));
    }
    mixIn(b, tone, at, gain: 0.8);
  }
  normalize(b, 0.85);
  fadeEdges(b, 0.02);
  return b;
}

Float64List doorbellKnock() {
  final b = buffer(5.5);
  void knock(double at, double gain) {
    final thump = lowpass(noiseBurst(0.12, lowHz: 40, highHz: 900, tau: 0.022), 700);
    mixIn(b, thump, at, gain: gain);
    mixIn(b, sineTone(96, 0.07, amp: 0.5), at, gain: gain * 0.6);
  }

  for (final at in <double>[0.15, 0.42, 0.70]) {
    knock(at, 1.0);
  }
  for (final at in <double>[2.6, 2.85, 3.12, 3.38]) {
    knock(at, 0.85);
  }
  normalize(b, 0.9);
  fadeEdges(b, 0.02);
  return b;
}

// ---------------------------------------------------------------------------
// ALARMS
// ---------------------------------------------------------------------------

Float64List alarmSiren() {
  // 1.5 s cycle over 6 s: four whole cycles, so the loop point is silent-clean.
  const dur = 6.0;
  final b = buffer(dur);
  var phase = 0.0;
  for (var i = 0; i < b.length; i++) {
    final t = i / kSampleRate;
    final cycle = (t % 1.5) / 1.5;
    final f = 600 + 600 * (cycle < 0.5 ? cycle * 2 : (1 - cycle) * 2);
    phase += kTwoPi * f / kSampleRate;
    b[i] = sin(phase) * 0.55 + sin(phase * 2) * 0.18;
  }
  normalize(b, 0.92);
  fadeEdges(b, 0.01);
  return b;
}

Float64List alarmClock() {
  final b = buffer(5);
  for (var group = 0.0; group < 4.4; group += 1.5) {
    for (var k = 0; k < 4; k++) {
      mixIn(b, squareTone(2400, 0.1), group + 0.1 + k * 0.2, gain: 0.7);
    }
  }
  normalize(b, 0.9);
  fadeEdges(b, 0.01);
  return b;
}

Float64List alarmTwoTone() {
  final b = buffer(6);
  var at = 0.0;
  var high = true;
  while (at < 5.9) {
    mixIn(b, sineTone(high ? 880 : 660, 0.48, amp: 0.75), at);
    mixIn(b, sineTone(high ? 1760 : 1320, 0.48, amp: 0.2), at);
    at += 0.5;
    high = !high;
  }
  normalize(b, 0.9);
  fadeEdges(b, 0.01);
  return b;
}

Float64List alarmWail() {
  const dur = 8.0;
  final b = buffer(dur);
  var phase = 0.0;
  for (var i = 0; i < b.length; i++) {
    final t = i / kSampleRate;
    final cycle = (t % 4.0) / 4.0;
    final f = 420 + 480 * (0.5 - 0.5 * cos(kTwoPi * cycle));
    phase += kTwoPi * f / kSampleRate;
    b[i] = sin(phase) * 0.6 + sin(phase * 3) * 0.1;
  }
  normalize(b, 0.9);
  fadeEdges(b, 0.01);
  return b;
}

Float64List alarmSmoke() {
  final b = buffer(6);
  for (var group = 0.0; group < 5.0; group += 2.5) {
    for (var k = 0; k < 3; k++) {
      mixIn(b, squareTone(3100, 0.1), group + 0.15 + k * 0.2, gain: 0.75);
    }
  }
  normalize(b, 0.92);
  fadeEdges(b, 0.01);
  return b;
}

Float64List alarmEvacuation() {
  final b = buffer(6);
  for (var at = 0.1; at < 5.5; at += 1.2) {
    mixIn(b, sweep(520, 1500, 0.75, amp: 0.7), at);
  }
  normalize(b, 0.9);
  fadeEdges(b, 0.01);
  return b;
}

// ---------------------------------------------------------------------------
// BAD SIGNAL
// ---------------------------------------------------------------------------

Float64List signalStatic() {
  var b = bandpass(whiteNoise(6.6), 320, 4200);
  // Slow random flicker in level: dead air that is not quite steady.
  var g = 0.6;
  for (var i = 0; i < b.length; i++) {
    if (i % 220 == 0) g = 0.35 + _rnd.nextDouble() * 0.6;
    b[i] *= g;
  }
  b = loopify(b, 0.6);
  normalize(b, 0.8);
  fadeEdges(b, 0.01);
  return b;
}

Float64List signalGlitch() {
  final b = buffer(5);
  // Sample-and-hold noise at a rate that keeps jumping: digital, broken.
  var hold = 0.0;
  var rate = 60;
  for (var i = 0; i < b.length; i++) {
    if (i % rate == 0) {
      hold = _rnd.nextDouble() * 2 - 1;
      if (_rnd.nextDouble() < 0.04) rate = 8 + _rnd.nextInt(180);
    }
    b[i] = hold * 0.55;
  }
  // Gate whole chunks out: the call dropping in and out.
  for (var i = 0; i < b.length; i += samples(0.05)) {
    if (_rnd.nextDouble() < 0.3) {
      for (var j = i; j < min(i + samples(0.05), b.length); j++) {
        b[j] *= 0.05;
      }
    }
  }
  for (var k = 0; k < 14; k++) {
    mixIn(b, noiseBurst(0.05, lowHz: 900, highHz: 8000, tau: 0.01),
        _rnd.nextDouble() * 4.8, gain: 0.5);
  }
  normalize(b, 0.85);
  fadeEdges(b, 0.01);
  return b;
}

Float64List signalDropout() {
  final b = buffer(6);
  // A narrow-band carrier that keeps cutting out, plus static in the gaps.
  final carrier = bandpass(whiteNoise(6), 700, 1600);
  final hiss = bandpass(whiteNoise(6), 1800, 5000);
  var open = true;
  var next = 0;
  for (var i = 0; i < b.length; i++) {
    if (i >= next) {
      open = !open;
      next = i + samples(0.08 + _rnd.nextDouble() * 0.5);
    }
    b[i] = open ? carrier[i] * 0.7 : hiss[i] * 0.5;
  }
  normalize(b, 0.82);
  fadeEdges(b, 0.01);
  return b;
}

Float64List signalCrackle() {
  var bed = bandpass(whiteNoise(6.5), 1200, 6000);
  for (var i = 0; i < bed.length; i++) {
    bed[i] *= 0.22;
  }
  for (var k = 0; k < 160; k++) {
    mixIn(bed, noiseBurst(0.03, lowHz: 800, highHz: 8000, tau: 0.005),
        _rnd.nextDouble() * 6.4, gain: 0.3 + _rnd.nextDouble() * 0.7);
  }
  bed = loopify(bed, 0.5);
  normalize(bed, 0.85);
  fadeEdges(bed, 0.01);
  return bed;
}

Float64List signalInterference() {
  final b = buffer(6);
  // The pulsed buzz a phone induces in a speaker, plus a warbling carrier.
  for (var at = 0.0; at < 5.9; at += 0.6) {
    final burst = squareTone(217, 0.3, amp: 0.5);
    for (var i = 0; i < burst.length; i++) {
      burst[i] *= 0.4 + 0.6 * sin(kTwoPi * 8 * (i / kSampleRate)).abs();
    }
    mixIn(b, burst, at);
  }
  final warble = buffer(6);
  var phase = 0.0;
  for (var i = 0; i < warble.length; i++) {
    final t = i / kSampleRate;
    final f = 1100 + 300 * sin(kTwoPi * 3.3 * t);
    phase += kTwoPi * f / kSampleRate;
    warble[i] = sin(phase) * 0.18;
  }
  mixIn(b, warble, 0);
  mixIn(b, bandpass(whiteNoise(6), 2000, 6000), 0, gain: 0.12);
  normalize(b, 0.85);
  fadeEdges(b, 0.01);
  return b;
}

Float64List signalDeadLine() {
  final b = buffer(6);
  for (var at = 0.0; at < 5.9; at += 1.0) {
    mixIn(b, sineTone(480, 0.5, amp: 0.5), at);
    mixIn(b, sineTone(620, 0.5, amp: 0.5), at);
  }
  normalize(b, 0.85);
  fadeEdges(b, 0.01);
  return b;
}

// ---------------------------------------------------------------------------
// FIRE
// ---------------------------------------------------------------------------

Float64List _crackleBed(double dur,
    {required int pops, required double bedGain, double popGain = 1}) {
  final bed = lowpass(brownNoise(dur), 850);
  for (var i = 0; i < bed.length; i++) {
    bed[i] *= bedGain;
  }
  for (var k = 0; k < pops; k++) {
    final tau = 0.004 + _rnd.nextDouble() * 0.02;
    mixIn(bed, noiseBurst(0.09, lowHz: 500, highHz: 7000, tau: tau),
        _rnd.nextDouble() * (dur - 0.1),
        gain: popGain * (0.25 + _rnd.nextDouble() * 0.75));
  }
  return bed;
}

Float64List fireCrackle() {
  var b = _crackleBed(8.6, pops: 210, bedGain: 0.5);
  b = loopify(b, 0.6);
  normalize(b, 0.85);
  fadeEdges(b, 0.02);
  return b;
}

Float64List fireRoar() {
  var b = lowpass(brownNoise(8.6), 380);
  for (var i = 0; i < b.length; i++) {
    final t = i / kSampleRate;
    // Slow swells: a fire breathing, not a flat noise wall.
    b[i] *= 0.7 + 0.3 * sin(kTwoPi * 0.23 * t) + 0.1 * sin(kTwoPi * 0.7 * t);
  }
  for (var k = 0; k < 90; k++) {
    mixIn(b, noiseBurst(0.08, lowHz: 400, highHz: 5000, tau: 0.012),
        _rnd.nextDouble() * 8.4, gain: 0.35);
  }
  b = loopify(b, 0.7);
  normalize(b, 0.9);
  fadeEdges(b, 0.02);
  return b;
}

Float64List fireEmbers() {
  var b = _crackleBed(8.6, pops: 55, bedGain: 0.16, popGain: 0.7);
  b = loopify(b, 0.6);
  normalize(b, 0.6);
  fadeEdges(b, 0.02);
  return b;
}

Float64List fireBlaze() {
  var roar = lowpass(brownNoise(8.6), 500);
  for (var i = 0; i < roar.length; i++) {
    final t = i / kSampleRate;
    roar[i] *= 0.75 + 0.25 * sin(kTwoPi * 0.31 * t);
  }
  final crackle = _crackleBed(8.6, pops: 320, bedGain: 0.0, popGain: 1.0);
  mixIn(roar, crackle, 0, gain: 0.8);
  mixIn(roar, highpass(whiteNoise(8.6), 3000), 0, gain: 0.1);
  roar = loopify(roar, 0.7);
  normalize(roar, 0.95);
  fadeEdges(roar, 0.02);
  return roar;
}

Float64List fireHiss() {
  var b = bandpass(whiteNoise(7.6), 1500, 7000);
  for (var i = 0; i < b.length; i++) {
    final t = i / kSampleRate;
    b[i] *= 0.5 + 0.5 * sin(kTwoPi * 0.17 * t).abs();
  }
  b = loopify(b, 0.6);
  normalize(b, 0.7);
  fadeEdges(b, 0.02);
  return b;
}

Float64List firePop() {
  var b = lowpass(brownNoise(7.6), 600);
  for (var i = 0; i < b.length; i++) {
    b[i] *= 0.2;
  }
  for (var k = 0; k < 26; k++) {
    final at = _rnd.nextDouble() * 7.3;
    mixIn(b, noiseBurst(0.16, lowHz: 200, highHz: 4500, tau: 0.03), at,
        gain: 0.6 + _rnd.nextDouble() * 0.4);
    // A little resonance so each pop reads as wood, not as a click.
    mixIn(b, sineTone(180 + _rnd.nextDouble() * 220, 0.09, amp: 0.25), at);
  }
  b = loopify(b, 0.5);
  normalize(b, 0.85);
  fadeEdges(b, 0.02);
  return b;
}

// ---------------------------------------------------------------------------
// STORM
// ---------------------------------------------------------------------------

Float64List _rumble(double dur, double cutoff, double attack, double decay) {
  var b = lowpass(lowpass(whiteNoise(dur), cutoff), cutoff);
  for (var i = 0; i < b.length; i++) {
    final t = i / kSampleRate;
    final env = t < attack
        ? t / attack
        : exp(-(t - attack) / decay);
    // Slow wobble gives the rolling quality of real thunder.
    b[i] *= env * (0.75 + 0.25 * sin(kTwoPi * 1.7 * t));
  }
  normalize(b, 1);
  return b;
}

Float64List stormThunder() {
  final b = buffer(8);
  mixIn(b, _rumble(4.5, 130, 0.25, 1.6), 0.7, gain: 0.95);
  mixIn(b, noiseBurst(0.3, lowHz: 300, highHz: 6000, tau: 0.06), 0.72, gain: 0.5);
  mixIn(b, _rumble(3.0, 80, 0.5, 1.2), 4.8, gain: 0.5);
  mixIn(b, highpass(whiteNoise(8), 2500), 0, gain: 0.06);
  normalize(b, 0.92);
  fadeEdges(b, 0.03);
  return b;
}

Float64List stormRain() {
  var b = highpass(whiteNoise(8.6), 1800);
  for (var i = 0; i < b.length; i++) {
    b[i] *= 0.55;
  }
  mixIn(b, lowpass(whiteNoise(8.6), 500), 0, gain: 0.12);
  for (var k = 0; k < 120; k++) {
    mixIn(b, noiseBurst(0.02, lowHz: 2500, highHz: 9000, tau: 0.004),
        _rnd.nextDouble() * 8.4, gain: 0.35);
  }
  b = loopify(b, 0.6);
  normalize(b, 0.8);
  fadeEdges(b, 0.02);
  return b;
}

Float64List stormWind() {
  var b = whiteNoise(8.6);
  b = bandpass(b, 180, 900);
  for (var i = 0; i < b.length; i++) {
    final t = i / kSampleRate;
    // Two slow LFOs beating against each other: gusts that never repeat.
    final gust = 0.45 +
        0.35 * (0.5 - 0.5 * cos(kTwoPi * 0.13 * t)) +
        0.2 * (0.5 - 0.5 * cos(kTwoPi * 0.31 * t));
    b[i] *= gust;
  }
  b = loopify(b, 0.8);
  normalize(b, 0.85);
  fadeEdges(b, 0.02);
  return b;
}

Float64List stormDownpour() {
  var b = whiteNoise(8.6);
  b = bandpass(b, 400, 7000);
  mixIn(b, lowpass(brownNoise(8.6), 400), 0, gain: 0.35);
  for (var k = 0; k < 260; k++) {
    mixIn(b, noiseBurst(0.025, lowHz: 1500, highHz: 9000, tau: 0.005),
        _rnd.nextDouble() * 8.4, gain: 0.3);
  }
  b = loopify(b, 0.6);
  normalize(b, 0.9);
  fadeEdges(b, 0.02);
  return b;
}

Float64List stormDistantThunder() {
  final b = buffer(8);
  mixIn(b, _rumble(5.0, 75, 0.6, 2.2), 0.5, gain: 0.9);
  mixIn(b, _rumble(4.0, 60, 0.8, 1.8), 4.2, gain: 0.6);
  mixIn(b, lowpass(whiteNoise(8), 900), 0, gain: 0.07);
  normalize(b, 0.8);
  fadeEdges(b, 0.03);
  return b;
}

Float64List stormGale() {
  var b = bandpass(whiteNoise(8.6), 150, 1200);
  for (var i = 0; i < b.length; i++) {
    final t = i / kSampleRate;
    b[i] *= 0.4 + 0.6 * (0.5 - 0.5 * cos(kTwoPi * 0.19 * t));
  }
  mixIn(b, highpass(whiteNoise(8.6), 2200), 0, gain: 0.3);
  mixIn(b, _rumble(3.5, 90, 0.4, 1.4), 3.1, gain: 0.45);
  b = loopify(b, 0.8);
  normalize(b, 0.9);
  fadeEdges(b, 0.02);
  return b;
}

// ---------------------------------------------------------------------------
// ELECTRIC
// ---------------------------------------------------------------------------

/// Mains hum: a fundamental plus its harmonics, which is what makes it read as
/// electrical rather than musical. 5 s holds a whole number of 50/60 Hz cycles.
Float64List _mains(double freq, double dur, int harmonics, double tilt) {
  final b = buffer(dur);
  for (var h = 1; h <= harmonics; h++) {
    final f = freq * h;
    if (f > kSampleRate / 2.2) break;
    final g = pow(h, -tilt).toDouble();
    for (var i = 0; i < b.length; i++) {
      b[i] += sin(kTwoPi * f * (i / kSampleRate)) * g;
    }
  }
  normalize(b, 1);
  return b;
}

Float64List electricBuzz() {
  final b = _mains(50, 5, 40, 0.9);
  for (var i = 0; i < b.length; i++) {
    b[i] *= 0.8;
  }
  for (var k = 0; k < 70; k++) {
    mixIn(b, noiseBurst(0.03, lowHz: 1500, highHz: 8000, tau: 0.006),
        _rnd.nextDouble() * 4.9, gain: 0.3);
  }
  normalize(b, 0.9);
  fadeEdges(b, 0.01);
  return b;
}

Float64List electricArc() {
  final b = buffer(5);
  mixIn(b, _mains(100, 5, 20, 1.2), 0, gain: 0.25);
  for (var k = 0; k < 90; k++) {
    mixIn(b, noiseBurst(0.12, lowHz: 1200, highHz: 9000, tau: 0.008 + _rnd.nextDouble() * 0.02),
        _rnd.nextDouble() * 4.85,
        gain: 0.35 + _rnd.nextDouble() * 0.65);
  }
  normalize(b, 0.92);
  fadeEdges(b, 0.01);
  return b;
}

Float64List electricShort() {
  final b = buffer(6);
  void short(double at) {
    mixIn(b, noiseBurst(0.2, lowHz: 600, highHz: 9000, tau: 0.02), at, gain: 0.9);
    // Buzz that sags in pitch as the circuit gives up.
    final sag = sweep(160, 45, 0.9, amp: 0.6);
    mixIn(b, sag, at + 0.05);
    for (var k = 0; k < 12; k++) {
      mixIn(b, noiseBurst(0.05, lowHz: 1500, highHz: 8000, tau: 0.006),
          at + 0.05 + _rnd.nextDouble() * 0.8, gain: 0.4);
    }
  }

  short(0.3);
  short(3.1);
  normalize(b, 0.92);
  fadeEdges(b, 0.02);
  return b;
}

Float64List electricHum() {
  final b = _mains(60, 5, 12, 1.5);
  for (var i = 0; i < b.length; i++) {
    final t = i / kSampleRate;
    b[i] *= 0.5 * (0.9 + 0.1 * sin(kTwoPi * 0.6 * t));
  }
  normalize(b, 0.65);
  fadeEdges(b, 0.01);
  return b;
}

Float64List electricZap() {
  final b = buffer(5);
  for (final at in <double>[0.4, 2.6]) {
    mixIn(b, noiseBurst(0.35, lowHz: 800, highHz: 9000, tau: 0.05), at, gain: 0.9);
    mixIn(b, sweep(2200, 120, 0.3, amp: 0.5), at);
    mixIn(b, _mains(100, 0.6, 16, 1.1), at + 0.1, gain: 0.3);
  }
  mixIn(b, _mains(50, 5, 20, 1.4), 0, gain: 0.12);
  normalize(b, 0.95);
  fadeEdges(b, 0.02);
  return b;
}

Float64List electricTransformer() {
  final b = _mains(100, 6, 30, 1.0);
  for (var i = 0; i < b.length; i++) {
    final t = i / kSampleRate;
    b[i] *= 0.55 * (0.92 + 0.08 * sin(kTwoPi * 2.1 * t));
  }
  for (var k = 0; k < 40; k++) {
    mixIn(b, noiseBurst(0.04, lowHz: 2000, highHz: 8000, tau: 0.005),
        _rnd.nextDouble() * 5.9, gain: 0.25);
  }
  normalize(b, 0.75);
  fadeEdges(b, 0.01);
  return b;
}

// ---------------------------------------------------------------------------
// Catalog — these paths must stay in sync with lib/data/system_catalog.dart.
// ---------------------------------------------------------------------------

final Map<String, Map<String, Float64List Function()>> kCatalog = {
  'doorbell': {
    'ding': doorbellDing,
    'dingdong': doorbellDingDong,
    'buzzer': doorbellBuzzer,
    'chime': doorbellChime,
    'intercom': doorbellIntercom,
    'knock': doorbellKnock,
  },
  'alarms': {
    'siren': alarmSiren,
    'clock': alarmClock,
    'twotone': alarmTwoTone,
    'wail': alarmWail,
    'smoke': alarmSmoke,
    'evacuation': alarmEvacuation,
  },
  'bad-signal': {
    'static': signalStatic,
    'glitch': signalGlitch,
    'dropout': signalDropout,
    'crackle': signalCrackle,
    'interference': signalInterference,
    'dead-line': signalDeadLine,
  },
  'fire': {
    'crackle': fireCrackle,
    'roar': fireRoar,
    'embers': fireEmbers,
    'blaze': fireBlaze,
    'hiss': fireHiss,
    'pop': firePop,
  },
  'storm': {
    'thunder': stormThunder,
    'rain': stormRain,
    'wind': stormWind,
    'downpour': stormDownpour,
    'distant-thunder': stormDistantThunder,
    'gale': stormGale,
  },
  'electric': {
    'buzz': electricBuzz,
    'arc': electricArc,
    'short': electricShort,
    'hum': electricHum,
    'zap': electricZap,
    'transformer': electricTransformer,
  },
};

// ---------------------------------------------------------------------------
// WAV output
// ---------------------------------------------------------------------------

Uint8List encodeWav(Float64List samplesIn, int sampleRate) {
  final dataBytes = samplesIn.length * 2;
  final out = BytesBuilder();

  void ascii(String s) => out.add(s.codeUnits);
  void u32(int v) => out.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
  void u16(int v) => out.add(Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));

  ascii('RIFF');
  u32(36 + dataBytes);
  ascii('WAVE');
  ascii('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(sampleRate);
  u32(sampleRate * 2); // byte rate
  u16(2); // block align
  u16(16); // bits per sample
  ascii('data');
  u32(dataBytes);

  final pcm = Uint8List(dataBytes);
  final view = pcm.buffer.asByteData();
  for (var i = 0; i < samplesIn.length; i++) {
    var v = samplesIn[i];
    if (v > 1) v = 1;
    if (v < -1) v = -1;
    view.setInt16(i * 2, (v * 32767).round(), Endian.little);
  }
  out.add(pcm);
  return out.toBytes();
}

void main(List<String> args) {
  final root = Directory('assets/audio');
  var count = 0;
  var bytes = 0;

  for (final category in kCatalog.entries) {
    final dir = Directory('${root.path}/${category.key}');
    dir.createSync(recursive: true);
    for (final sound in category.value.entries) {
      final data = sound.value();
      final wav = encodeWav(data, kSampleRate);
      final file = File('${dir.path}/${sound.key}.wav');
      file.writeAsBytesSync(wav);
      count++;
      bytes += wav.length;
      final seconds = (data.length / kSampleRate).toStringAsFixed(1);
      stdout.writeln(
          '  ${category.key}/${sound.key}.wav  ${seconds}s  ${(wav.length / 1024).round()} KB');
    }
  }

  stdout.writeln(
      '\n$count files, ${(bytes / 1024 / 1024).toStringAsFixed(1)} MB total in ${root.path}');
}
