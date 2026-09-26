/** backgrounds.fireflies · 萤火虫 (Backgrounds+Fireflies.swift) */
import { useRef } from "react";
import { useHaptics, type DemoProps, type Point } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, TAU, circle, nowSec, prep, rand, rgba, sizeOf, useFrameLoop, useModel, useRatio, useTap } from "./_support";

/** A tap that startles nearby fireflies: they flare and scatter, then drift back. */
interface Burst {
  origin: Point;
  time: number;
}

function burstEffect(b: Burst, x: number, y: number, now: number) {
  const age = now - b.time;
  if (age < 0 || age >= 2.5) return { dx: 0, dy: 0, flare: 0 };
  const dx = x - b.origin.x;
  const dy = y - b.origin.y;
  const distance = Math.max(Math.sqrt(dx * dx + dy * dy), 0.001);
  const falloff = Math.exp(-Math.pow(distance / 120, 2));
  const push = 60 * falloff * (1 - Math.exp(-age * 12)) * Math.exp(-age * 2);
  const flare = Math.min(1.43 * falloff * (1 - Math.exp(-age * 20)) * Math.exp(-age * 2.2), falloff);
  return { dx: (dx / distance) * push, dy: (dy / distance) * push, flare };
}

const LIME = 0xd9ff7a;
const GOLD = 0xffd36b;

function drawFirefly(g: CanvasRenderingContext2D, i: number, w: number, h: number, t: number, glow: number, bursts: Burst[], now: number) {
  const r = (salt: number) => rand(i, salt);
  const driftX = 26 * Math.sin(t * (0.3 + 0.4 * r(3)) + r(4) * TAU) + 10 * Math.sin(t * (0.7 + r(5)) + i);
  const driftY = 22 * Math.cos(t * (0.25 + 0.35 * r(6)) + r(7) * TAU) + 9 * Math.sin(t * (0.6 + r(8)) - i);
  const restX = r(1) * w + driftX;
  const restY = (0.12 + r(2) * 0.84) * h + driftY;
  let ox = 0;
  let oy = 0;
  let flare = 0;
  for (const b of bursts) {
    const hit = burstEffect(b, restX, restY, now);
    ox += hit.dx;
    oy += hit.dy;
    flare = Math.max(flare, hit.flare);
  }
  const x = restX + ox;
  const y = restY + oy;
  // Flicker runs on the real clock (2.5–5 s per flash) so the wander-speed slider never changes it.
  const wave = Math.max(0, Math.sin(now * (1.25 + r(9) * 1.25) + r(10) * TAU));
  const pulse = Math.max(0.15 + 0.85 * wave * wave, flare);
  const color = r(11) > 0.5 ? LIME : GOLD;
  const radius = glow * (0.6 + 0.8 * r(12));
  const gr = g.createRadialGradient(x, y, 0, x, y, radius);
  gr.addColorStop(0, rgba(color, 0.9 * pulse));
  gr.addColorStop(0.35, rgba(color, 0.28 * pulse));
  gr.addColorStop(1, rgba(color, 0));
  g.fillStyle = gr;
  g.beginPath();
  circle(g, x, y, radius);
  g.fill();
  g.fillStyle = `rgba(255,255,255,${0.4 + 0.6 * pulse})`;
  g.beginPath();
  circle(g, x, y, 1.3);
  g.fill();
}

export default function Fireflies({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const clock = useModel(() => new BackgroundClock());
  const bursts = useRef<Burst[]>([]);
  const haptics = useHaptics();
  const ratio = useRatio(root);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const t = clock.advance(now, ctx.n("speed"));
    const g = prep(canvas.current, w, h, ratio());
    if (!g) return;
    g.globalCompositeOperation = "lighter";
    const count = Math.max(ctx.i("count"), 0);
    for (let i = 0; i < count; i++) drawFirefly(g, i, w, h, t, ctx.n("glow"), bursts.current, now);
  });

  const tap = useTap((p) => {
    const now = nowSec();
    bursts.current = [...bursts.current.filter((b) => now - b.time < 2.5).slice(-3), { origin: p, time: now }];
    haptics.tap("soft");
  });

  return (
    <Stage rootRef={root} background="linear-gradient(#0B1F2A, #0E2A22, #050E0B)" handlers={tap}>
      <Layer canvasRef={canvas} />
      <SampleTitle title={ctx.t("Midsummer", "仲夏夜")} subtitle={ctx.t("Sleep sounds · 45 min", "助眠白噪音 · 45 分钟")} size={26} />
      <BgHint ctx={ctx} en="Tap to startle the fireflies" zh="点击惊动萤火虫" />
    </Stage>
  );
}
