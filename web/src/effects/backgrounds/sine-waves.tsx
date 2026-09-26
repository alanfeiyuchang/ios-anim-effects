/** backgrounds.sine-waves · 层叠波浪 (Backgrounds+SineWaves.swift) */
import { useRef } from "react";
import { useHaptics, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, TAU, circle, nowSec, prep, radial, rgba, sizeOf, useFrameLoop, useModel, useRatio, useTap } from "./_support";

/** A tap-spawned swell: a crest running outward from `x`, amplitude attack 1 − e^(−10t) then e^(−2t) decay. */
interface Swell {
  x: number;
  time: number;
}
function swellShape(s: Swell, px: number, index: number, now: number) {
  const age = now - s.time - index * 0.06;
  if (age <= 0 || age >= 3) return [0, 0];
  const env = (1 - Math.exp(-age * 10)) * Math.exp(-2 * age);
  const front = (Math.abs(px - s.x) - age * 220) / 54;
  return [1.4 * env * Math.exp(-front * front), 0.9 * env];
}

const COLORS = [0xb9d3ff, 0x9cb8ff, 0x7f9bff, 0x6e7bff, 0x7b61ff, 0x5b45d6, 0x3e2fa8];

function drawSun(g: CanvasRenderingContext2D, w: number, h: number, dark: boolean) {
  const cx = w * 0.72;
  const cy = h * 0.36;
  const radius = Math.min(w, h) * 0.42;
  const tint = dark ? 0xa46bff : 0xffb38a;
  g.beginPath();
  circle(g, cx, cy, radius);
  g.fillStyle = radial(g, cx, cy, 0, radius, [
    [0, rgba(tint, dark ? 0.45 : 0.8)],
    [1, rgba(tint, 0)],
  ]);
  g.fill();
}

function wavePath(w: number, h: number, baseline: number, amplitude: number, t: number, i: number, swells: Swell[], now: number) {
  const k1 = 1.4 + i * 0.3;
  const k2 = 3.6 + i * 0.45;
  const s1 = 0.5 + i * 0.16;
  const s2 = 0.35 + i * 0.1;
  const path = new Path2D();
  path.moveTo(0, h);
  for (let x = 0; x <= w + 6; x += 6) {
    const u = (x / Math.max(w, 1)) * TAU;
    const s = Math.sin(u * k1 + t * s1 + i * 1.3) * 0.72 + Math.sin(u * k2 - t * s2 + i) * 0.28;
    let lift = 0;
    let gain = 0;
    for (const sw of swells) {
      const [l, gn] = swellShape(sw, x, i, now);
      lift += l;
      gain += gn;
    }
    gain = Math.min(gain, 1.2);
    lift = Math.min(lift, 1.8);
    path.lineTo(x, baseline + amplitude * ((1 + gain) * s - lift));
  }
  path.lineTo(w + 6, h);
  path.closePath();
  return path;
}

export default function SineWaves({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const clock = useModel(() => new BackgroundClock());
  const swells = useRef<Swell[]>([]);
  const haptics = useHaptics();
  const ratio = useRatio(root);
  const dark = ctx.scheme === "dark";

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const t = clock.advance(now, ctx.n("speed"));
    const g = prep(canvas.current, w, h, ratio());
    if (!g) return;
    drawSun(g, w, h, dark);
    const amplitude = ctx.n("amplitude");
    const count = Math.min(Math.max(ctx.i("layers"), 1), COLORS.length);
    for (let i = 0; i < count; i++) {
      const depth = (i + 1) / count;
      const baseline = h * (0.5 + (0.4 * i) / count);
      const path = wavePath(w, h, baseline, amplitude * (0.55 + 0.6 * depth), t, i, swells.current, now);
      const color = COLORS[COLORS.length - count + i];
      const gr = g.createLinearGradient(0, baseline - amplitude, 0, h);
      gr.addColorStop(0, rgba(color, dark ? 0.55 : 0.75));
      gr.addColorStop(1, rgba(color, dark ? 0.9 : 0.95));
      g.fillStyle = gr;
      g.fill(path);
    }
  });

  const tap = useTap((p) => {
    const now = nowSec();
    swells.current = [...swells.current.filter((s) => now - s.time < 3.5).slice(-3), { x: p.x, time: now }];
    haptics.tap("soft");
  });

  const sky = dark ? "linear-gradient(#0B1026, #1B1F4A, #2A2360)" : "linear-gradient(#FFE3D3, #EBD8FF, #CFE0FF)";
  return (
    <Stage rootRef={root} background={sky} handlers={tap}>
      <Layer canvasRef={canvas} />
      <SampleTitle title={ctx.t("Breathe", "呼吸")} subtitle={ctx.t("4 · 7 · 8 rhythm", "4 · 7 · 8 呼吸法")} color={dark ? "#fff" : "#2A1F5C"} top={46} />
      <BgHint ctx={ctx} en="Tap to send a swell" zh="点击掀起涌浪" />
    </Stage>
  );
}
