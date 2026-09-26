/** backgrounds.rain · 雨夜 (Backgrounds+Rain.swift) */
import { useRef } from "react";
import { Palette, alpha, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, circle, ellipse, fract, nowSec, prep, rand, rgba, sizeOf, useFrameLoop, useModel, useRatio } from "./_support";

class RainModel {
  clock = new BackgroundClock();
  flashStart = -100;
  flash(now: number) {
    const e = now - this.flashStart;
    if (e < 0) return 0;
    if (e < 0.08) return 1;
    if (e < 0.16) return 0.25;
    if (e < 0.24) return 0.85;
    return Math.max(0, 0.85 * Math.exp(-(e - 0.24) * 6));
  }
}

const LIGHTS = [Palette.amber, Palette.coral, Palette.sky, "#FFE0A3", Palette.pink];

function drawCityLights(g: CanvasRenderingContext2D, w: number, h: number) {
  for (let i = 0; i < 9; i++) {
    const r = Math.min(w, h) * (0.05 + 0.06 * rand(i, 21));
    const x = rand(i, 22) * w;
    const y = h * (0.62 + 0.32 * rand(i, 23));
    g.fillStyle = alpha(LIGHTS[i % LIGHTS.length], 0.4);
    g.beginPath();
    circle(g, x, y, r);
    g.fill();
  }
}

export default function Rain({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const lights = useRef<HTMLCanvasElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new RainModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);
  const drawn = useRef("");

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    const key = `${w}x${h}@${k}`;
    if (drawn.current !== key) {
      drawn.current = key;
      const gl = prep(lights.current, w, h, k);
      if (gl) drawCityLights(gl, w, h);
    }
    const t = model.clock.advance(now, ctx.n("speed"));
    const flash = model.flash(now);
    const g = prep(canvas.current, w, h, k);
    if (!g) return;
    // Streaks
    const theta = (ctx.n("wind") * Math.PI) / 180;
    const slope = Math.tan(theta);
    const dirX = Math.sin(theta);
    const dirY = Math.cos(theta);
    const far = new Path2D();
    const near = new Path2D();
    const count = Math.max(ctx.i("count"), 0);
    for (let i = 0; i < count; i++) {
      const depth = rand(i, 1);
      const length = 12 + 22 * depth;
      const span = h + length + 20;
      const y = fract(rand(i, 2) + t * (0.9 + 0.8 * depth)) * span - length;
      const x0 = (rand(i, 3) * 1.8 - 0.4) * w;
      const x = x0 + slope * (y - h / 2);
      const path = depth > 0.55 ? near : far;
      path.moveTo(x - length * dirX, y - length * dirY);
      path.lineTo(x, y);
    }
    g.lineCap = "round";
    g.strokeStyle = rgba(0xc9d8ff, 0.22 + flash * 0.3);
    g.lineWidth = 0.7;
    g.stroke(far);
    g.strokeStyle = rgba(0xc9d8ff, 0.5 + flash * 0.4);
    g.lineWidth = 1.3;
    g.stroke(near);
    // Ripples
    g.lineWidth = 1;
    for (let i = 0; i < 14; i++) {
      const cycle = t * 1.25 + rand(i, 31);
      const p = fract(cycle);
      const seed = i * 97 + Math.floor(cycle);
      const rx = 3 + 16 * p;
      const ry = rx * 0.28;
      const x = rand(seed, 32) * w;
      const y = h * (0.84 + 0.14 * rand(seed, 33));
      g.strokeStyle = `rgba(255,255,255,${(1 - p) * 0.35})`;
      g.beginPath();
      ellipse(g, x - rx, y - ry, rx * 2, ry * 2);
      g.stroke();
    }
    if (flash > 0.001) {
      g.fillStyle = rgba(0xdde6ff, flash * 0.55);
      g.fillRect(0, 0, w, h);
    }
  });

  const strike = () => {
    model.flashStart = nowSec();
  };
  useAutoplay(ctx.isPreview, strike, { every: 4.5, delay: 1.5 });

  return (
    <Stage
      rootRef={root}
      background="linear-gradient(#0B1220, #14203A, #1B2740)"
      handlers={{
        onClick: () => {
          haptics.tap("heavy");
          strike();
        },
      }}
    >
      <Layer canvasRef={lights} blur={16} />
      <Layer canvasRef={canvas} />
      <SampleTitle title="18°" subtitle={ctx.t("Light rain · Umbrella advised", "小雨 · 建议带伞")} size={44} top={36} />
      <BgHint ctx={ctx} en="Tap for lightning" zh="点击召唤闪电" />
    </Stage>
  );
}
