/** backgrounds.particle-repulsion · 排斥粒子场 (Backgrounds+ParticleRepulsion.swift) */
import { useRef } from "react";
import { Palette, alpha, type DemoProps, type Point } from "../../kit";
import { BgHint, Layer, Stage, circle, prep, radial, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

const LEVELS = 8;
/** Eight displacement levels: dim white dot at home → sky → hot pink (≥ 18 pt away). */
const LEVEL_STYLES = Array.from({ length: LEVELS }, (_, k) => {
  const t = k / (LEVELS - 1);
  const calm = [1, 1, 1, 0.36];
  const sky = [0x3a / 255, 0xc4 / 255, 0xff / 255, 1];
  const pink = [1, 0x5f / 255, 0xa2 / 255, 1];
  const [from, to, u] = t < 0.5 ? [calm, sky, t / 0.5] : [sky, pink, (t - 0.5) / 0.5];
  const c = from.map((f, i) => f + (to[i] - f) * u);
  return { radius: 1.1 + 1.0 * t, color: `rgba(${c[0] * 255},${c[1] * 255},${c[2] * 255},${c[3]})` };
});

class SwarmModel {
  private last: number | null = null;
  private w = 0;
  private h = 0;
  private home: number[] = [];
  private pos: number[] = [];
  private vel: number[] = [];
  touch: Point | null = null;
  userTouched = false;
  pointer: Point | null = null;
  private static spacing = 16;

  private rebuild(w: number, h: number) {
    this.w = w;
    this.h = h;
    const s = SwarmModel.spacing;
    const columns = Math.max(Math.floor(w / s), 1);
    const rows = Math.max(Math.floor(h / s), 1);
    const ox = (w - (columns - 1) * s) / 2;
    const oy = (h - (rows - 1) * s) / 2;
    this.home = [];
    for (let r = 0; r < rows; r++) for (let c = 0; c < columns; c++) this.home.push(ox + c * s, oy + r * s);
    this.pos = this.home.slice();
    this.vel = this.home.map(() => 0);
  }

  step(now: number, w: number, h: number, radius: number, strength: number, stiffness: number, simulated: Point | null) {
    if (w !== this.w || h !== this.h || this.home.length === 0) this.rebuild(w, h);
    let dt = 1 / 60;
    if (this.last !== null) dt = Math.min(Math.max(now - this.last, 0), 1 / 30);
    this.last = now;
    this.pointer = this.touch ?? simulated;
    const p = this.pointer;
    const damping = 2 * Math.sqrt(stiffness) * 0.45;
    const push = strength * 5200;
    const { pos, vel, home } = this;
    for (let i = 0; i < pos.length; i += 2) {
      let ax = stiffness * (home[i] - pos[i]) - damping * vel[i];
      let ay = stiffness * (home[i + 1] - pos[i + 1]) - damping * vel[i + 1];
      if (p) {
        const dx = pos[i] - p.x;
        const dy = pos[i + 1] - p.y;
        const distance = Math.max(Math.sqrt(dx * dx + dy * dy), 0.001);
        if (distance < radius) {
          const falloff = 1 - distance / radius;
          const force = falloff * falloff * push;
          ax += (dx / distance) * force;
          ay += (dy / distance) * force;
        }
      }
      vel[i] += ax * dt;
      vel[i + 1] += ay * dt;
      pos[i] += vel[i] * dt;
      pos[i + 1] += vel[i + 1] * dt;
    }
  }

  draw(g: CanvasRenderingContext2D) {
    const bins = LEVEL_STYLES.map(() => new Path2D());
    const { pos, home } = this;
    for (let i = 0; i < pos.length; i += 2) {
      const dx = pos[i] - home[i];
      const dy = pos[i + 1] - home[i + 1];
      const offset = Math.sqrt(dx * dx + dy * dy);
      const level = Math.round(Math.min(offset / 18, 1) * (LEVELS - 1));
      circle(bins[level], pos[i], pos[i + 1], LEVEL_STYLES[level].radius);
    }
    const p = this.pointer;
    if (p) {
      g.beginPath();
      circle(g, p.x, p.y, 70);
      g.fillStyle = radial(g, p.x, p.y, 0, 70, [
        [0, alpha(Palette.violet, 0.28)],
        [1, alpha(Palette.violet, 0)],
      ]);
      g.fill();
    }
    bins.forEach((path, level) => {
      g.fillStyle = LEVEL_STYLES[level].color;
      g.fill(path);
    });
  }
}

export default function ParticleRepulsion({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new SwarmModel());
  const ratio = useRatio(root);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    // Previews always wander; the detail stage wanders until the first touch so it never looks empty.
    const simulated =
      ctx.isPreview || !model.userTouched ? { x: w * (0.5 + 0.32 * Math.sin(now * 0.9)), y: h * (0.5 + 0.3 * Math.sin(now * 1.37)) } : null;
    model.step(now, w, h, ctx.n("radius"), ctx.n("strength"), ctx.n("stiffness"), simulated);
    const g = prep(canvas.current, w, h, ratio());
    if (g) model.draw(g);
  });

  const touch = useBackgroundsTouch(
    (p) => {
      model.userTouched = true;
      model.touch = p;
    },
    () => (model.touch = null),
  );

  return (
    <Stage rootRef={root} background="linear-gradient(#070914, #10142A)" handlers={touch}>
      <Layer canvasRef={canvas} />
      <BgHint ctx={ctx} en="Tap or swipe sideways through the particles" zh="点击或横向划过粒子" />
    </Stage>
  );
}
