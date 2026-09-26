/** backgrounds.slosh-tank · 晃动水箱 (Backgrounds+LiquidVariations.swift) */
import { useRef } from "react";
import { useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, circle, clampv, fract, prep, rand, rgba, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

interface SloshState {
  t: number;
  slope: number;
  velocity: number;
}

class SloshModel {
  clock = new BackgroundClock();
  touching = false;
  /** Desired surface slope (dy/dx) while a finger is down. */
  target = 0;
  private slope = 0;
  private velocity = 0;
  private kickSign = 1;
  step(now: number, stiffness: number, ratio: number): SloshState {
    const t = this.clock.advance(now, 1);
    const dt = this.clock.delta;
    const goal = this.touching ? this.target : 0;
    const damping = 2 * ratio * Math.sqrt(stiffness);
    const accel = stiffness * (goal - this.slope) - damping * this.velocity;
    this.velocity += accel * dt;
    this.slope = clampv(this.slope + this.velocity * dt, -0.6, 0.6);
    return { t, slope: this.slope, velocity: this.velocity };
  }
  /** Simulated shove used by previews: alternates direction. */
  kick() {
    this.velocity += 2.4 * this.kickSign;
    this.kickSign = -this.kickSign;
  }
}

function height(x: number, w: number, h: number, s: SloshState, level: number, tilt: number, phase: number, lift: number) {
  const base = h * (1 - level) + lift;
  const u = x / Math.max(w, 1);
  const slant = s.slope * tilt * (x - w / 2);
  const mode = clampv(s.velocity * 7, -24, 24) * Math.sin(u * 2 * Math.PI);
  const ripple = 3 * Math.sin(u * 11 + s.t * 2.2 + phase) + 1.6 * Math.sin(u * 23 - s.t * 3.1);
  return base + slant + mode + ripple;
}

function surface(w: number, h: number, s: SloshState, level: number, tilt: number, phase: number, lift: number) {
  const fill = new Path2D();
  const crest = new Path2D();
  fill.moveTo(0, h);
  let first = true;
  for (let x = 0; x <= w + 6; x += 6) {
    const y = height(x, w, h, s, level, tilt, phase, lift);
    fill.lineTo(x, y);
    if (first) {
      crest.moveTo(x, y);
      first = false;
    } else crest.lineTo(x, y);
  }
  fill.lineTo(w + 6, h);
  fill.closePath();
  return { fill, crest };
}

export default function SloshTank({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new SloshModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const s = model.step(now, ctx.n("stiffness"), ctx.n("damping"));
    const level = ctx.n("level");
    const g = prep(canvas.current, w, h, ratio());
    if (!g) return;
    const top = h * (1 - level);
    const back = surface(w, h, s, level, 0.82, 1.7, -6);
    let gr = g.createLinearGradient(0, top, 0, h);
    gr.addColorStop(0, rgba(0x3ac4ff, 0.45));
    gr.addColorStop(1, rgba(0x1d4ed8, 0.55));
    g.fillStyle = gr;
    g.fill(back.fill);
    const front = surface(w, h, s, level, 1, 0, 0);
    gr = g.createLinearGradient(0, top, 0, h);
    gr.addColorStop(0, rgba(0x5be7c4, 0.85));
    gr.addColorStop(1, rgba(0x2563eb, 0.9));
    g.fillStyle = gr;
    g.fill(front.fill);
    g.strokeStyle = "rgba(255,255,255,0.25)";
    g.lineWidth = 1;
    g.stroke(back.crest);
    g.strokeStyle = "rgba(255,255,255,0.7)";
    g.lineWidth = 1.5;
    g.stroke(front.crest);
    // Bubbles
    const depth = h * level;
    const bubbles = new Path2D();
    for (let i = 0; i < 16; i++) {
      const rise = fract(rand(i, 71) + s.t * 0.12 * (0.5 + rand(i, 72)));
      const x = rand(i, 73) * w + 6 * Math.sin(s.t * 2 + i);
      const y = h - rise * depth;
      if (y <= height(x, w, h, s, level, 1, 0, 0) + 8) continue;
      circle(bubbles, x, y, 1.5 + 2.5 * rand(i, 74));
    }
    g.strokeStyle = "rgba(255,255,255,0.4)";
    g.lineWidth = 1;
    g.stroke(bubbles);
  });

  const touch = useBackgroundsTouch(
    (p) => {
      model.touching = true;
      const { w } = sizeOf(root.current);
      const u = p.x / Math.max(w, 1);
      model.target = clampv(-(u - 0.5) * 0.9, -0.45, 0.45);
    },
    () => {
      model.touching = false;
      haptics.tap("soft");
    },
  );

  useAutoplay(ctx.isPreview, () => model.kick(), { every: 2.8, delay: 0.5 });

  return (
    <Stage rootRef={root} background="linear-gradient(#0B1426, #12203D)" handlers={touch}>
      <Layer canvasRef={canvas} />
      <SampleTitle title={ctx.t("1.8 L", "1.8 升")} subtitle={ctx.t("Daily goal · 72%", "今日目标 · 72%")} size={40} top={34} />
      <BgHint ctx={ctx} en="Tap or drag sideways to tilt the water" zh="点击或横向拖动让水倾斜" />
    </Stage>
  );
}
