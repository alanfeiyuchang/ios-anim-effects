/** backgrounds.snowfall · 飘雪 (Backgrounds+Snowfall.swift) */
import { useRef } from "react";
import type { DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, TAU, circle, clampv, even, fract, linear, prep, rand, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

class SnowModel {
  clock = new BackgroundClock();
  targetWind = 0;
  /** x where the current horizontal drag was first reported. */
  dragStartX: number | null = null;
  wind = 0;
  windOffset = 0;
  step(now: number, speed: number, simulate: boolean) {
    const t = this.clock.advance(now, speed);
    const target = simulate ? 70 * Math.sin(now * 0.45) : this.targetWind;
    this.wind += (target - this.wind) * this.clock.follow(4);
    this.windOffset += this.wind * this.clock.delta;
    return t;
  }
}

function drawDrift(g: CanvasRenderingContext2D, w: number, h: number) {
  g.beginPath();
  g.moveTo(0, h * 0.9);
  g.quadraticCurveTo(w * 0.28, h * 0.8, w * 0.55, h * 0.88);
  g.quadraticCurveTo(w * 0.8, h * 0.95, w, h * 0.86);
  g.lineTo(w, h);
  g.lineTo(0, h);
  g.closePath();
  g.fillStyle = linear(g, 0, h * 0.8, 0, h, even(["#EEF0FF", "#B9BCE6"]));
  g.fill();
}

export default function Snowfall({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const farCanvas = useRef<HTMLCanvasElement>(null);
  const nearCanvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new SnowModel());
  const ratio = useRatio(root);
  const start = useRef<number | null>(null);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    if (start.current === null) start.current = now;
    // The preview gust runs on time since mount (the app uses the absolute clock).
    const t = model.step(ctx.isPreview ? now - start.current + 2 : now, ctx.n("speed"), ctx.isPreview);
    const scale = ctx.n("size");
    const far = new Path2D();
    const near = new Path2D();
    const wrapW = w + 24;
    const wrapH = h + 24;
    const count = Math.max(ctx.i("count"), 0);
    for (let i = 0; i < count; i++) {
      const depth = rand(i, 1);
      const radius = (0.75 + 2.25 * depth) * scale;
      const fall = 20 + 50 * depth;
      const sway = (6 + 14 * depth) * Math.sin(t * (0.8 + rand(i, 2) * 1.2) + rand(i, 3) * TAU);
      const rawX = rand(i, 4) * wrapW + model.windOffset * (0.4 + depth) + sway;
      const x = fract(rawX / wrapW) * wrapW - 12;
      const y = fract(rand(i, 5) + (t * fall) / wrapH) * wrapH - 12;
      circle(depth > 0.6 ? near : far, x, y, radius);
    }
    const gf = prep(farCanvas.current, w, h, k);
    if (gf) {
      drawDrift(gf, w, h);
      gf.fillStyle = "rgba(255,255,255,0.55)";
      gf.fill(far);
    }
    const gn = prep(nearCanvas.current, w, h, k);
    if (gn) {
      gn.fillStyle = "rgba(255,255,255,0.92)";
      gn.fill(near);
    }
  });

  const touch = useBackgroundsTouch(
    (p) => {
      const startX = model.dragStartX ?? p.x;
      model.dragStartX = startX;
      model.targetWind = clampv((p.x - startX) * 1.4, -260, 260);
    },
    () => {
      model.dragStartX = null;
      model.targetWind = 0;
    },
  );

  return (
    <Stage rootRef={root} background="linear-gradient(#141B3A, #2E3566, #6C6A9E)" handlers={touch}>
      <Layer canvasRef={farCanvas} />
      <Layer canvasRef={nearCanvas} blur={1.2} />
      <SampleTitle title="−3°" subtitle={ctx.t("Light snow · Stay cosy", "小雪 · 注意保暖")} size={46} top={36} />
      <BgHint ctx={ctx} en="Drag sideways to blow wind" zh="左右拖动吹起风" light />
    </Stage>
  );
}
