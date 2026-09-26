/** backgrounds.autumn-wind · 秋风落叶 (Backgrounds+WeatherVariations.swift) */
import { useRef } from "react";
import { useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, TAU, circle, fract, prep, rand, rgba, sizeOf, useFrameLoop, useModel, useRatio } from "./_support";

class LeafModel {
  clock = new BackgroundClock();
  windOffset = 0;
  spin = 0;
  private gust = 0;
  step(now: number, speed: number) {
    const t = this.clock.advance(now, speed);
    const dt = this.clock.delta;
    this.gust *= Math.exp(-dt * 1.6);
    this.windOffset += (18 + this.gust) * dt;
    this.spin += this.gust * 0.012 * dt;
    return t;
  }
  blow() {
    this.gust = Math.min(this.gust + 220, 420);
  }
}

const COLORS = [0xffb347, 0xff7a5c, 0xd7263d, 0xc9892b];

const OUTLINE = (() => {
  const p = new Path2D();
  p.moveTo(0, -8);
  p.quadraticCurveTo(7, 0, 0, 8);
  p.quadraticCurveTo(-7, 0, 0, -8);
  p.closePath();
  return p;
})();

export default function AutumnWind({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const sun = useRef<HTMLCanvasElement>(null);
  const farCanvas = useRef<HTMLCanvasElement>(null);
  const nearCanvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new LeafModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);
  const drawn = useRef("");

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    const key = `${w}x${h}@${k}`;
    if (drawn.current !== key) {
      drawn.current = key;
      const gs = prep(sun.current, w, h, k);
      if (gs) {
        gs.fillStyle = rgba(0xffd27a, 0.55);
        gs.beginPath();
        circle(gs, w * 0.3, h * 0.82, 90);
        gs.fill();
      }
    }
    const t = model.step(now, ctx.n("speed"));
    const flutter = ctx.n("flutter");
    const gf = prep(farCanvas.current, w, h, k);
    const gn = prep(nearCanvas.current, w, h, k);
    if (!gf || !gn) return;
    const wrapW = w + 60;
    const wrapH = h + 60;
    const count = Math.max(ctx.i("count"), 0);
    const ribs = new Path2D();
    const leaves: { m: DOMMatrix; color: number; near: boolean }[] = [];
    for (let i = 0; i < count; i++) {
      const depth = rand(i, 61);
      const omega = 1.1 + 0.9 * rand(i, 62);
      const phase = t * omega + rand(i, 63) * TAU;
      const fall = 26 + 34 * depth;
      const sway = (14 + 18 * depth) * flutter;
      const drop = fall * (t + Math.sin(2 * phase) / (4 * omega));
      const y = fract((rand(i, 64) * wrapH + drop) / wrapH) * wrapH - 30;
      const rawX = rand(i, 65) * wrapW + sway * Math.sin(phase) + model.windOffset * (0.5 + depth);
      const x = fract(rawX / wrapW) * wrapW - 30;
      const tilt = 0.7 * flutter * Math.cos(phase);
      const twirl = model.spin * (rand(i, 66) - 0.5) * 2;
      const flip = Math.cos(t * (0.8 + rand(i, 67)) + rand(i, 68) * 6);
      const flipX = flip >= 0 ? Math.max(flip, 0.15) : Math.min(flip, -0.15);
      const scale = 0.55 + 0.75 * depth;
      const m = new DOMMatrix().translate(x, y).rotate(((tilt + twirl) * 180) / Math.PI).scale(flipX * scale, scale);
      const color = Math.floor(rand(i, 69) * 4) % 4;
      leaves.push({ m, color, near: depth >= 0.35 });
      if (depth >= 0.35) {
        const rib = new Path2D();
        rib.moveTo(0, -7);
        rib.lineTo(0, 10);
        ribs.addPath(rib, m);
      }
    }
    for (let c = 0; c < 4; c++) {
      const far = new Path2D();
      const near = new Path2D();
      for (const leaf of leaves) if (leaf.color === c) (leaf.near ? near : far).addPath(OUTLINE, leaf.m);
      gf.fillStyle = rgba(COLORS[c], 0.6);
      gf.fill(far);
      gn.fillStyle = rgba(COLORS[c]);
      gn.fill(near);
    }
    gn.strokeStyle = "rgba(0,0,0,0.22)";
    gn.lineWidth = 0.8;
    gn.stroke(ribs);
  });

  useAutoplay(ctx.isPreview, () => model.blow(), { every: 4.0, delay: 1.2 });

  return (
    <Stage
      rootRef={root}
      background="linear-gradient(#2B1B3D, #7A3B45, #E0894A)"
      handlers={{
        onClick: () => {
          haptics.tap("soft");
          model.blow();
        },
      }}
    >
      <Layer canvasRef={sun} blur={40} />
      <Layer canvasRef={farCanvas} blur={1.6} />
      <Layer canvasRef={nearCanvas} />
      <SampleTitle title="14°" subtitle={ctx.t("Breezy · Leaves falling", "微风 · 落叶纷飞")} size={44} top={36} />
      <BgHint ctx={ctx} en="Tap for a gust of wind" zh="点击刮起一阵风" />
    </Stage>
  );
}
