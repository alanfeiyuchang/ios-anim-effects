/** backgrounds.flow-field · 流场游丝 (Backgrounds+FlowField.swift) */
import { useRef } from "react";
import { Palette, alpha, type DemoProps, type Point } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, prep, randIn, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

interface Particle {
  hx: number;
  hy: number;
  /** Samples every 1/30 s of simulated time, oldest first (x, y pairs). */
  trail: number[];
  since: number;
  age: number;
  life: number;
  hue: number;
}

const TRAIL = 14;
const SAMPLE = 1 / 30;

class FlowModel {
  clock = new BackgroundClock();
  touch: Point | null = null;
  particles: Particle[] = [];
  private w = 0;
  private h = 0;

  step(now: number, speed: number, count: number, scale: number, w: number, h: number, simulated: Point | null) {
    const t = this.clock.advance(now, speed);
    const f = 0.011 / Math.max(scale, 0.1);
    if (w !== this.w || h !== this.h || this.particles.length !== count) {
      this.w = w;
      this.h = h;
      this.particles = Array.from({ length: Math.max(count, 0) }, (_, i) => this.spawn(i % 4, randIn(0, 3)));
      // Pre-integrate a full trail so the first frame already shows threads.
      for (let n = 0; n < TRAIL + 2; n++) {
        for (let i = 0; i < this.particles.length; i++) {
          const p = this.particles[i];
          if (this.advance(p, t, SAMPLE, f, null)) this.particles[i] = this.spawn(p.hue, 0);
        }
      }
    }
    const dt = this.clock.delta * speed;
    if (dt <= 0 || w <= 1 || h <= 1) return;
    const vortex = this.touch ?? simulated;
    for (let i = 0; i < this.particles.length; i++) {
      const p = this.particles[i];
      if (this.advance(p, t, dt, f, vortex)) this.particles[i] = this.spawn(p.hue, 0);
    }
  }

  /** Returns true when the particle left the stage or expired. */
  private advance(p: Particle, t: number, dt: number, f: number, vortex: Point | null) {
    const x = p.hx;
    const y = p.hy;
    const angle = (Math.sin(x * f + t * 0.21) + Math.cos(y * f * 1.3 - t * 0.17) + Math.sin((x + y) * f * 0.7 + t * 0.11)) * 1.5;
    let vx = Math.cos(angle) * 55;
    let vy = Math.sin(angle) * 55;
    if (vortex) {
      const dx = x - vortex.x;
      const dy = y - vortex.y;
      const d = Math.max(Math.sqrt(dx * dx + dy * dy), 1);
      if (d < 120) {
        const wgt = 1 - d / 120;
        vx += ((-dy / d) * 190 + (dx / d) * 45) * wgt;
        vy += ((dx / d) * 190 + (dy / d) * 45) * wgt;
      }
    }
    p.hx = x + vx * dt;
    p.hy = y + vy * dt;
    p.since += dt;
    if (p.since >= SAMPLE) {
      p.since = p.since % SAMPLE;
      p.trail.push(p.hx, p.hy);
      if (p.trail.length > TRAIL * 2) p.trail.splice(0, p.trail.length - TRAIL * 2);
    }
    p.age += dt;
    const outside = p.hx < -12 || p.hy < -12 || p.hx > this.w + 12 || p.hy > this.h + 12;
    return outside || p.age > p.life;
  }

  private spawn(hue: number, age: number): Particle {
    const x = randIn(0, Math.max(this.w, 1));
    const y = randIn(0, Math.max(this.h, 1));
    return { hx: x, hy: y, trail: [x, y], since: 0, age, life: randIn(2.5, 6), hue };
  }
}

const HUES = [Palette.indigo, Palette.violet, Palette.sky, Palette.mint];
const SEGMENT_ALPHA = [0.3, 0.62, 1];
const SEGMENT_WIDTH = [0.9, 1.25, 1.6];

export default function FlowField({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new FlowModel());
  const ratio = useRatio(root);
  const start = useRef<number | null>(null);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    if (start.current === null) start.current = now;
    const sim = now - start.current;
    const simulated = ctx.isPreview ? { x: w * (0.5 + 0.28 * Math.cos(sim * 0.5)), y: h * (0.5 + 0.24 * Math.sin(sim * 0.8)) } : null;
    model.step(now, ctx.n("speed"), ctx.i("count"), ctx.n("scale"), w, h, simulated);
    const g = prep(canvas.current, w, h, ratio());
    if (!g) return;
    // Bins: hue (4) × life fade (3) × trail segment (3: tail, mid, head).
    const bins = Array.from({ length: 36 }, () => new Path2D());
    for (const p of model.particles) {
      const fade = Math.min(p.age / 0.6, (p.life - p.age) / 0.8, 1);
      if (fade <= 0.02) continue;
      const level = Math.min(Math.floor(fade * 3), 2);
      const last = p.trail.length / 2;
      if (last <= 0) continue;
      const px = (i: number) => (i < last ? p.trail[i * 2] : p.hx);
      const py = (i: number) => (i < last ? p.trail[i * 2 + 1] : p.hy);
      for (let seg = 0; seg < 3; seg++) {
        const from = Math.floor((last * seg) / 3);
        const to = Math.floor((last * (seg + 1)) / 3);
        if (to <= from) continue;
        const bin = bins[((p.hue % 4) * 3 + level) * 3 + seg];
        bin.moveTo(px(from), py(from));
        for (let i = from + 1; i <= to; i++) bin.lineTo(px(i), py(i));
      }
    }
    g.globalCompositeOperation = "lighter";
    g.lineCap = "round";
    g.lineJoin = "round";
    for (let hue = 0; hue < 4; hue++) {
      for (let level = 0; level < 3; level++) {
        for (let seg = 0; seg < 3; seg++) {
          g.strokeStyle = alpha(HUES[hue], (0.22 + 0.26 * level) * SEGMENT_ALPHA[seg]);
          g.lineWidth = SEGMENT_WIDTH[seg];
          g.stroke(bins[(hue * 3 + level) * 3 + seg]);
        }
      }
    }
  });

  const touch = useBackgroundsTouch(
    (p) => (model.touch = p),
    () => (model.touch = null),
  );

  return (
    <Stage rootRef={root} background="linear-gradient(#05060D, #0B0C1C)" handlers={touch}>
      <Layer canvasRef={canvas} />
      <SampleTitle title={ctx.t("Deep Focus", "深度专注")} subtitle={ctx.t("Flow state · 25:00", "心流模式 · 25:00")} size={26} />
      <BgHint ctx={ctx} en="Tap or drag sideways to stir a vortex" zh="点击或横向拖动以搅出漩涡" />
    </Stage>
  );
}
