/** backgrounds.aurora · 极光 (Backgrounds+Aurora.swift) */
import { useRef } from "react";
import type { DemoProps, Point } from "../../kit";
import {
  BackgroundClock,
  BgHint,
  Layer,
  SampleTitle,
  Stage,
  circle,
  even,
  linear,
  prep,
  rand,
  rgba,
  sizeOf,
  useBackgroundsTouch,
  useFrameLoop,
  useModel,
  useRatio,
} from "./_support";

/** Where (x) and how strongly (0…1) the finger stirs the aurora. */
interface Stir {
  x: number;
  amount: number;
}
const weight = (s: Stir, px: number, width: number) => {
  if (s.amount <= 0.001) return 0;
  const d = (px - s.x) / Math.max(width * 0.2, 1);
  return s.amount * Math.exp(-d * d);
};

class Surge {
  target: Point | null = null;
  stir: Stir = { x: 0, amount: 0 };
  step(k: number): Stir {
    if (this.target) this.stir.x = this.stir.amount < 0.02 ? this.target.x : this.stir.x + (this.target.x - this.stir.x) * k;
    this.stir.amount += ((this.target ? 1 : 0) - this.stir.amount) * k;
    return this.stir;
  }
}

const RIBBONS: [number, number][] = [
  [0x21d4a8, 0x3af2c0],
  [0x3ac4ff, 0x6e7bff],
  [0x7cffb2, 0x21d4a8],
  [0xa46bff, 0xff5fa2],
];

function ribbonY(i: number, x: number, w: number, h: number, t: number, stir: Stir) {
  const base = h * (0.3 + 0.09 * i);
  const u = x / Math.max(w, 1);
  const wave1 = Math.sin(u * (3.2 + i * 0.7) + t * (0.6 + i * 0.17) + i * 1.9);
  const wave2 = Math.sin(u * 7.1 - t * (0.9 + i * 0.11));
  const lift = weight(stir, x, w) * h * 0.07;
  return base + wave1 * h * 0.08 + wave2 * h * 0.025 - lift;
}

function drawStars(g: CanvasRenderingContext2D, w: number, h: number, t: number) {
  for (let i = 0; i < 70; i++) {
    const x = rand(i, 1) * w;
    const y = rand(i, 2) * h * 0.8;
    const r = 0.4 + rand(i, 3) * 1.1;
    const rate = 1.5 + rand(i, 4) * 2;
    const twinkle = 0.3 + 0.7 * (0.5 + 0.5 * Math.sin(t * rate + i));
    g.beginPath();
    circle(g, x, y, r);
    g.fillStyle = `rgba(255,255,255,${twinkle * 0.8})`;
    g.fill();
  }
}

function ribbonPath(i: number, w: number, h: number, t: number, stir: Stir) {
  const p = new Path2D();
  for (let x = -40; x <= w + 40; x += 10) {
    const y = ribbonY(i, x, w, h, t, stir);
    if (x === -40) p.moveTo(x, y);
    else p.lineTo(x, y);
  }
  return p;
}

function drawRibbon(g: CanvasRenderingContext2D, i: number, w: number, h: number, t: number, stir: Stir) {
  const path = ribbonPath(i, w, h, t, stir);
  const [c0, c1] = RIBBONS[i % RIBBONS.length];
  const lineWidth = h * (0.1 + 0.04 * Math.sin(t * 0.5 + i));
  const shading = linear(g, 0, 0, w, 0, [
    [0, rgba(c0, 0)],
    [0.3, rgba(c0, 0.9)],
    [0.7, rgba(c1, 0.8)],
    [1, rgba(c1, 0)],
  ]);
  g.lineCap = "round";
  g.lineJoin = "round";
  g.strokeStyle = shading;
  g.globalAlpha = 1;
  g.lineWidth = lineWidth;
  g.stroke(path);
  // A fainter, thinner echo above gives the curtain vertical depth.
  g.save();
  g.translate(0, -lineWidth * 0.9);
  g.globalAlpha = 0.35;
  g.lineWidth = lineWidth * 0.6;
  g.stroke(path);
  g.restore();
}

function drawRays(g: CanvasRenderingContext2D, i: number, w: number, h: number, t: number, stir: Stir) {
  const bins = [new Path2D(), new Path2D(), new Path2D()];
  for (let x = 4 + i * 1.7; x < w; x += 6) {
    const shimmer = (0.5 + 0.5 * Math.sin(x * 0.09 + t * 1.3 + i * 2.1)) * (0.55 + 0.45 * Math.sin(x * 0.023 - t * 0.4 + i));
    const flare = weight(stir, x, w);
    const y = ribbonY(i, x, w, h, t, stir) + h * 0.03;
    const length = h * (0.1 + 0.2 * shimmer) * (1 + 1.1 * flare);
    const bin = Math.max(0, Math.min(Math.floor((shimmer + flare) * 3), 2));
    bins[bin].moveTo(x, y);
    bins[bin].lineTo(x, y - length);
  }
  const color = RIBBONS[i % RIBBONS.length][0];
  const base = h * (0.3 + 0.09 * i);
  const shading = linear(g, 0, base + h * 0.1, 0, base - h * 0.32, even([rgba(color, 0.9), rgba(color, 0.35), rgba(color, 0)]));
  const alphas = [0.25, 0.5, 0.85];
  g.strokeStyle = shading;
  g.lineWidth = 2.4;
  g.lineCap = "round";
  for (let b = 0; b < 3; b++) {
    g.globalAlpha = alphas[b];
    g.stroke(bins[b]);
  }
  g.globalAlpha = 1;
}

function drawRidge(g: CanvasRenderingContext2D, w: number, h: number) {
  const peaks = [0.86, 0.79, 0.84, 0.73, 0.81, 0.77, 0.88];
  g.beginPath();
  g.moveTo(0, h);
  peaks.forEach((peak, index) => g.lineTo((w * index) / (peaks.length - 1), h * peak));
  g.lineTo(w, h);
  g.closePath();
  g.fillStyle = linear(g, 0, h * 0.72, 0, h, even(["#0A1624", "#02050A"]));
  g.fill();
}

export default function Aurora({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const stars = useRef<HTMLCanvasElement>(null);
  const rays = useRef<HTMLCanvasElement>(null);
  const ribbons = useRef<HTMLCanvasElement>(null);
  const ridge = useRef<HTMLCanvasElement>(null);
  const clock = useModel(() => new BackgroundClock());
  const surge = useModel(() => new Surge());
  const ratio = useRatio(root);
  const drawn = useRef("");

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    const t = clock.advance(now, ctx.n("speed"));
    const stir = surge.step(clock.follow(5));
    const intensity = ctx.n("intensity");
    const blur = ctx.n("blur");
    const gs = prep(stars.current, w, h, k);
    if (gs) drawStars(gs, w, h, t);
    const gr = prep(rays.current, w, h, k);
    // Inside each layer every stroke is blurred and added (plusLighter); the layer itself composites normally.
    if (gr) {
      gr.globalCompositeOperation = "lighter";
      for (let i = 0; i < RIBBONS.length; i++) drawRays(gr, i, w, h, t, stir);
    }
    const gb = prep(ribbons.current, w, h, k);
    if (gb) {
      gb.globalCompositeOperation = "lighter";
      for (let i = 0; i < RIBBONS.length; i++) drawRibbon(gb, i, w, h, t, stir);
    }
    if (rays.current && ribbons.current) {
      rays.current.style.filter = `blur(${Math.max(1.5, blur * 0.12)}px)`;
      ribbons.current.style.filter = `blur(${blur}px)`;
      rays.current.style.opacity = ribbons.current.style.opacity = String(intensity);
    }
    const key = `${w}x${h}@${k}`;
    if (drawn.current !== key) {
      drawn.current = key;
      const gd = prep(ridge.current, w, h, k);
      if (gd) drawRidge(gd, w, h);
    }
  });

  const touch = useBackgroundsTouch(
    (p) => (surge.target = p),
    () => (surge.target = null),
  );

  return (
    <Stage rootRef={root} background="linear-gradient(#02040C, #071A2E, #0B2A3A)" handlers={touch}>
      <Layer canvasRef={stars} />
      <Layer canvasRef={rays} />
      <Layer canvasRef={ribbons} />
      <Layer canvasRef={ridge} />
      <SampleTitle title={ctx.t("Tonight", "今夜")} subtitle={ctx.t("Aurora activity · High", "极光活跃度 · 高")} size={26} top={40} />
      <BgHint ctx={ctx} en="Drag sideways to stir the sky" zh="左右拖动搅动夜空" />
    </Stage>
  );
}
