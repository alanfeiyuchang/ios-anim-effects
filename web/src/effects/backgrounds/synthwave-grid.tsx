/** backgrounds.synthwave-grid · 合成波网格 (Backgrounds+Synthwave.swift) */
import { useRef } from "react";
import { fonts, useHaptics, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Layer, Stage, circle, even, fract, linear, prep, radial, rgba, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

/** Steer in −1…1: follows the finger (~180 ms), then a damped spring (0.6 s, 0.7) levels it. */
class Steer {
  fingerX: number | null = null;
  private value = 0;
  private velocity = 0;
  step(dt: number, width: number, preview: number | null) {
    if (dt <= 0) return this.value;
    let target: number | null = null;
    if (preview !== null) target = preview;
    else if (this.fingerX !== null && width > 0) target = Math.min(Math.max((this.fingerX / width - 0.5) * 2, -1), 1);
    if (target !== null) {
      const previous = this.value;
      this.value += (target - this.value) * (1 - Math.exp(-dt / 0.18));
      this.velocity = (this.value - previous) / dt;
    } else {
      const omega = (2 * Math.PI) / 0.6;
      const accel = -omega * omega * this.value - 2 * 0.7 * omega * this.velocity;
      this.velocity += accel * dt;
      this.value += this.velocity * dt;
      if (Math.abs(this.value) < 0.0005 && Math.abs(this.velocity) < 0.001) {
        this.value = 0;
        this.velocity = 0;
      }
    }
    return this.value;
  }
}

const PINK = 0xff3cac;
const FLOOR_TOP = 0x1a0433;
const BLEED = 80;

function bank(g: CanvasRenderingContext2D, w: number, horizon: number, degrees: number) {
  g.translate(w / 2, horizon);
  g.rotate((degrees * Math.PI) / 180);
  g.translate(-w / 2, -horizon);
}

function drawBase(g: CanvasRenderingContext2D, w: number, h: number, horizon: number, t: number, sun: boolean, shift: number) {
  // Sky
  g.fillStyle = linear(g, 0, 0, 0, horizon, even(["#0D0221", "#3B0A5E", "#B0247A"]));
  g.fillRect(-BLEED, -BLEED, w + BLEED * 2, horizon + BLEED);
  if (sun) {
    const radius = Math.min(w, h) * 0.27;
    const cx = w / 2 + shift;
    const cy = horizon - radius * 0.55;
    const halo = radius * 1.8;
    g.beginPath();
    circle(g, cx, cy, halo);
    g.fillStyle = radial(g, cx, cy, radius * 0.8, halo, [
      [0, rgba(PINK, 0.45)],
      [1, rgba(PINK, 0)],
    ]);
    g.fill();
    // The sun minus its sliding stripes (clip(to:options: .inverse)).
    const clip = new Path2D();
    clip.rect(-BLEED * 4, -BLEED * 4, w + BLEED * 8, h + BLEED * 8);
    for (let k = 0; k < 6; k++) {
      const f = fract((k + t * 0.6) / 6);
      clip.rect(cx - radius, cy + radius * f, radius * 2, radius * (0.015 + 0.09 * f));
    }
    g.save();
    g.clip(clip, "evenodd");
    g.beginPath();
    circle(g, cx, cy, radius);
    g.fillStyle = linear(g, 0, cy - radius, 0, cy + radius, even(["#FFE45E", "#FF8A5B", rgba(PINK)]));
    g.fill();
    g.restore();
  }
  // Floor
  g.fillStyle = linear(g, 0, horizon, 0, h, even([rgba(FLOOR_TOP), "#07010F"]));
  g.fillRect(-BLEED, horizon, w + BLEED * 2, h - horizon + BLEED);
}

function gridPath(w: number, h: number, horizon: number, t: number, lines: number, shift: number) {
  const path = new Path2D();
  const cx = w / 2;
  const depth = h - horizon;
  const bottom = h + BLEED;
  const top = cx + shift;
  const foot = cx - shift * 0.5;
  for (let i = -lines; i <= lines; i++) {
    const spread = (i * w * 1.5) / lines;
    const sx = top + i * w * 0.03;
    path.moveTo(sx, horizon);
    const ex = foot + spread;
    const dx = ex - sx;
    path.lineTo(ex + (dx * (bottom - h)) / depth, bottom);
  }
  const f = fract(t);
  for (let j = 0; j < 16; j++) {
    const z = 1 + (j - f) * 0.55;
    if (z <= 0.2) continue;
    const y = horizon + depth * (0.9 / z);
    if (y > h + BLEED) continue;
    path.moveTo(-BLEED, y);
    path.lineTo(w + BLEED, y);
  }
  return path;
}

function drawHaze(g: CanvasRenderingContext2D, w: number, horizon: number) {
  g.fillStyle = linear(g, 0, horizon, 0, horizon + 46, [
    [0, rgba(FLOOR_TOP)],
    [1, rgba(FLOOR_TOP, 0)],
  ]);
  g.fillRect(-BLEED, horizon, w + BLEED * 2, 46);
  g.fillStyle = linear(g, 0, horizon - 14, 0, horizon + 14, [
    [0, rgba(PINK, 0)],
    [0.5, rgba(PINK, 0.55)],
    [1, rgba(PINK, 0)],
  ]);
  g.fillRect(-BLEED, horizon - 14, w + BLEED * 2, 28);
  g.fillStyle = "#FFB3E0";
  g.fillRect(-BLEED, horizon - 0.75, w + BLEED * 2, 1.5);
}

export default function SynthwaveGrid({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const base = useRef<HTMLCanvasElement>(null);
  const glow = useRef<HTMLCanvasElement>(null);
  const top = useRef<HTMLCanvasElement>(null);
  const clock = useModel(() => new BackgroundClock());
  const steer = useModel(() => new Steer());
  const haptics = useHaptics();
  const ratio = useRatio(root);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    const t = clock.advance(now, ctx.n("speed"));
    // Previews cannot be touched: a slow sinusoidal steer stands in for the finger.
    const s = steer.step(clock.delta, w, ctx.isPreview ? 0.7 * Math.sin(t * 0.9) : null);
    const horizon = h * 0.58;
    const shift = s * w * 0.28;
    const degrees = -ctx.n("bank") * s;
    const grid = gridPath(w, h, horizon, t, Math.max(ctx.i("lines"), 2), shift);
    const glowAmount = Math.abs(s);
    const gb = prep(base.current, w, h, k);
    if (gb) {
      bank(gb, w, horizon, degrees);
      drawBase(gb, w, h, horizon, t, ctx.b("sun"), shift * 0.4);
    }
    const gg = prep(glow.current, w, h, k);
    if (gg && glow.current) {
      bank(gg, w, horizon, degrees);
      gg.strokeStyle = rgba(PINK);
      gg.lineWidth = 3 + glowAmount;
      gg.stroke(grid);
      glow.current.style.filter = `blur(${(4 + glowAmount).toFixed(2)}px)`;
    }
    const gt = prep(top.current, w, h, k);
    if (gt) {
      bank(gt, w, horizon, degrees);
      gt.strokeStyle = "#FF9AD5";
      gt.lineWidth = 1.1;
      gt.stroke(grid);
      drawHaze(gt, w, horizon);
    }
  });

  const touch = useBackgroundsTouch(
    (p) => {
      if (steer.fingerX === null) haptics.tap("soft");
      steer.fingerX = p.x;
    },
    () => (steer.fingerX = null),
  );

  const zh = ctx.lang === "zh";
  return (
    <Stage rootRef={root} handlers={touch}>
      <Layer canvasRef={base} />
      <Layer canvasRef={glow} />
      <Layer canvasRef={top} />
      <BgHint ctx={ctx} en="Drag sideways to steer" zh="横向拖动转向" />
      <div style={{ position: "absolute", left: 0, right: 0, top: 34, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
        <div
          style={{
            fontFamily: fonts.rounded,
            fontSize: 26,
            lineHeight: "31px",
            fontWeight: 900,
            fontStyle: "italic",
            letterSpacing: zh ? 4 : 2,
            color: "#fff",
            textShadow: `0 0 20px ${rgba(PINK)}`,
          }}
        >
          {zh ? "午夜驾驶" : "NIGHT DRIVE"}
        </div>
      </div>
    </Stage>
  );
}
