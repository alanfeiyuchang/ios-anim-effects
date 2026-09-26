/** backgrounds.halftone-flow · 半调点阵流 (Backgrounds+HalftoneFlow.swift) */
import { useRef } from "react";
import { Palette, useAutoplay, useHaptics, type DemoProps, type Point } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, circle, clampv, even, linear, nowSec, prep, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

interface Sample {
  x: number;
  y: number;
  time: number;
}

/** The ink roller's trail: finger samples 4 pt apart, dropped once fully bled back. */
class Ink {
  samples: Sample[] = [];
  private last: Point | null = null;
  private simulating = false;
  rolling = false;

  roll(p: Point, time: number) {
    this.rolling = true;
    const from = this.last;
    if (!from) {
      this.append(p, time);
      this.last = p;
      return;
    }
    const distance = Math.hypot(p.x - from.x, p.y - from.y);
    if (distance < 4) return;
    const steps = Math.min(Math.floor(distance / 4), 40);
    const n = Math.max(steps, 1);
    for (let k = 1; k <= n; k++) {
      const f = k / n;
      this.append({ x: from.x + (p.x - from.x) * f, y: from.y + (p.y - from.y) * f }, time);
    }
    this.last = p;
  }
  lift() {
    this.rolling = false;
    this.last = null;
  }
  private append(p: Point, time: number) {
    this.samples.push({ x: p.x, y: p.y, time });
    if (this.samples.length > 400) this.samples.splice(0, this.samples.length - 400);
  }
  prepare(now: number, fade: number, simulated: Point | null) {
    if (simulated) {
      this.simulating = true;
      this.roll(simulated, now);
    } else if (this.simulating) {
      this.simulating = false;
      this.lift();
    }
    this.samples = this.samples.filter((s) => now - s.time <= fade);
  }
}

const smoothstep = (x: number) => {
  const t = clampv(x, 0, 1);
  return t * t * (3 - 2 * t);
};
const CORE = 17;
const EDGE = 23;

function inkWeight(samples: Sample[], x: number, y: number, now: number, fade: number) {
  let best = 0;
  for (const s of samples) {
    const dx = x - s.x;
    if (Math.abs(dx) >= EDGE) continue;
    const dy = y - s.y;
    if (Math.abs(dy) >= EDGE) continue;
    const d = Math.sqrt(dx * dx + dy * dy);
    const spatial = 1 - smoothstep((d - CORE) / (EDGE - CORE));
    const fresh = 1 - smoothstep((now - s.time) / fade);
    best = Math.max(best, spatial * fresh);
    if (best >= 0.999) break;
  }
  return best;
}

/** Rise in 80 ms, then a damped swing (decay 2.6/s, 5.5 rad/s) that dips to ≈ −0.23 before settling. */
function envelope(age: number) {
  if (age < 0 || age >= 2.2) return 0;
  return Math.min(age / 0.08, 1) * Math.exp(-2.6 * age) * Math.cos(5.5 * age);
}

const PALETTES = [
  [Palette.indigo, Palette.violet, Palette.pink, Palette.amber],
  [Palette.mint, Palette.sky, Palette.blue],
  ["rgba(255,255,255,0.95)", "rgba(255,255,255,0.45)"],
];

export default function HalftoneFlow({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const clock = useModel(() => new BackgroundClock());
  const ink = useModel(() => new Ink());
  const exposure = useRef({ at: -100, x: 170, y: 170 });
  const haptics = useHaptics();
  const ratio = useRatio(root);
  const start = useRef<number | null>(null);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const t = clock.advance(now, ctx.n("speed"));
    const fade = Math.max(ctx.n("fade"), 0.1);
    if (start.current === null) start.current = now;
    let simulated: Point | null = null;
    if (ctx.isPreview) {
      // Every 3.4 s a "roller" sweeps across the print on a gentle S.
      const clk = now - start.current + 2.6;
      const cycle = clk % 3.4;
      if (cycle < 1.4) {
        const f = cycle / 1.4;
        const lane = Math.floor(clk / 3.4) % 3;
        simulated = { x: w * (0.08 + 0.84 * f), y: h * (0.3 + 0.2 * lane) + 26 * Math.sin(f * Math.PI * 2) };
      }
    }
    ink.prepare(now, fade, simulated);
    const g = prep(canvas.current, w, h, ratio());
    if (!g) return;
    const spacing = Math.max(ctx.n("spacing"), 6);
    const amount = envelope(now - exposure.current.at);
    const ox = exposure.current.x;
    const oy = exposure.current.y;
    const cx = w / 2;
    const cy = h / 2;
    const maxRadius = spacing * 0.46;
    const samples = ink.samples;
    g.beginPath();
    for (let y = spacing / 2; y < h; y += spacing) {
      for (let x = spacing / 2; x < w; x += spacing) {
        const distance = Math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
        let field = Math.sin((x + y) * 0.016 + t * 1.1);
        field += Math.sin((x - y) * 0.021 - t * 0.8);
        field += Math.sin(x * 0.012 + t * 0.6);
        field += Math.sin(distance * 0.035 - t * 1.5);
        const base = clampv((field / 3 + 1) / 2, 0, 1);
        let gamma = 1;
        if (amount !== 0) {
          const ex = x - ox;
          const ey = y - oy;
          const local = 0.6 + 0.4 * Math.exp(-(ex * ex + ey * ey) / 32400);
          gamma = Math.exp(-1.3 * amount * local);
        }
        const exposed = Math.pow(base, gamma);
        const inked = samples.length === 0 ? 0 : inkWeight(samples, x, y, now, fade);
        const n = exposed + (1 - exposed) * inked;
        const radius = maxRadius * (0.1 + 0.9 * n * n);
        if (radius > 0.3) circle(g, x, y, radius);
      }
    }
    const colors = PALETTES[clampv(ctx.i("palette"), 0, 2)];
    g.fillStyle = linear(g, 0, 0, w, h, even(colors));
    g.fill();
  });

  const touch = useBackgroundsTouch(
    (p) => {
      if (!ink.rolling) haptics.tap("soft");
      ink.roll(p, nowSec());
    },
    () => ink.lift(),
  );

  // The flash bulb survives only as the detail page's arrival play; previews demo the roller instead.
  useAutoplay(
    false,
    () => {
      const { w, h } = sizeOf(root.current);
      exposure.current = { at: nowSec(), x: w / 2, y: h / 2 };
    },
    { every: 3.4 },
  );

  return (
    <Stage rootRef={root} background="#0A0A12" handlers={touch}>
      <Layer canvasRef={canvas} />
      <SampleTitle title={ctx.t("Ship faster", "更快交付")} subtitle={ctx.t("Infrastructure that scales with you", "随你成长的基础设施")} />
      <BgHint ctx={ctx} en="Drag sideways to roll ink" zh="横向拖动滚上墨迹" />
    </Stage>
  );
}
