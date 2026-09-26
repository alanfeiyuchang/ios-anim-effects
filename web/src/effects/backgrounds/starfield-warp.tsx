/** backgrounds.starfield-warp · 星际跃迁 (Backgrounds+Warp.swift) */
import { useEffect, useRef } from "react";
import { localPoint, useHaptics, type DemoProps, type Point } from "../../kit";
import { BgHint, Layer, Stage, TAU, circle, clampv, fract, prep, radial, rand, rgba, sizeOf, useFrameLoop, useModel, useRatio } from "./_support";

class WarpModel {
  private last: number | null = null;
  phase = 0;
  velocity = 0.6;
  boost = 0;
  boosting = false;

  step(now: number, base: number, autoBoost: boolean) {
    let dt = 0;
    if (this.last !== null) dt = Math.min(Math.max(now - this.last, 0), 0.05);
    this.last = now;
    const boosted = this.boosting || autoBoost;
    const target = base * (boosted ? 7 : 1);
    this.velocity += (target - this.velocity) * (1 - Math.exp(-dt * (boosted ? 4.5 : 2.2)));
    this.phase += dt * this.velocity * 0.22;
    this.boost = clampv((this.velocity / Math.max(base, 0.01) - 1) / 6, 0, 1);
    return this.phase;
  }
}

function drawCore(g: CanvasRenderingContext2D, cx: number, cy: number, reach: number, boost: number) {
  const radius = reach * (0.9 + boost * 0.5);
  g.beginPath();
  circle(g, cx, cy, radius);
  g.fillStyle = radial(g, cx, cy, 0, radius, [
    [0, rgba(0x4f7cff, 0.22 + 0.4 * boost)],
    [0.5, rgba(0x2a1f7a, 0.18)],
    [1, "rgba(0,0,0,0)"],
  ]);
  g.fill();
}

function drawStar(g: CanvasRenderingContext2D, i: number, cx: number, cy: number, reach: number, phase: number, trail: number) {
  const z = Math.max(fract(rand(i, 3) - phase), 0.015);
  const tailZ = Math.min(z + trail + 0.004, 1);
  const angle = rand(i, 1) * TAU;
  const spread = 0.12 + rand(i, 2) * 0.88;
  const dx = Math.cos(angle);
  const dy = Math.sin(angle);
  const head = reach * ((spread * 0.16) / z);
  const tail = reach * ((spread * 0.16) / tailZ);
  const tx = cx + dx * tail;
  const ty = cy + dy * tail;
  const hx = cx + dx * head;
  const hy = cy + dy * head;
  const closeness = 1 - z;
  const a = Math.min(1, closeness * 1.5);
  const color = i % 7 === 0 ? 0xb9a4ff : i % 5 === 0 ? 0x9fe3ff : 0xffffff;
  // Offscreen stars never show; skip the gradient for them.
  if ((hx < -4 && tx < -4) || (hy < -4 && ty < -4) || (hx > cx * 2 + 4 && tx > cx * 2 + 4) || (hy > cy * 2 + 4 && ty > cy * 2 + 4)) return;
  const gr = g.createLinearGradient(tx, ty, hx, hy);
  gr.addColorStop(0, rgba(color, 0));
  gr.addColorStop(0.5, rgba(color, a * 0.55));
  gr.addColorStop(1, rgba(color, a));
  g.strokeStyle = gr;
  g.lineWidth = 0.4 + closeness * 2.2;
  g.beginPath();
  g.moveTo(tx, ty);
  g.lineTo(hx, hy);
  g.stroke();
}

export default function StarfieldWarp({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new WarpModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);
  const press = useRef<{ id: number; start: Point; timer: number } | null>(null);
  const start = useRef<number | null>(null);

  useEffect(() => () => window.clearTimeout(press.current?.timer), []);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    if (start.current === null) start.current = now;
    const autoBoost = ctx.isPreview && fract((now - start.current + 2) / 6) > 0.62;
    const phase = model.step(now, ctx.n("speed"), autoBoost);
    const g = prep(canvas.current, w, h, ratio());
    if (!g) return;
    const cx = w / 2;
    const cy = h / 2;
    const reach = Math.max(w, h) * 0.5;
    drawCore(g, cx, cy, reach, model.boost);
    g.lineCap = "round";
    const trail = model.velocity * 0.02 * ctx.n("streak");
    const count = Math.max(ctx.i("count"), 0);
    for (let i = 0; i < count; i++) drawStar(g, i, cx, cy, reach, phase, trail);
  });

  // A long press that fails as soon as the finger moves 10 pt; the boost waits for a 150 ms still hold.
  const end = () => {
    if (press.current) window.clearTimeout(press.current.timer);
    press.current = null;
    model.boosting = false;
  };
  const handlers = {
    onPointerDown: (e: React.PointerEvent<HTMLElement>) => {
      end();
      e.currentTarget.setPointerCapture?.(e.pointerId);
      const timer = window.setTimeout(() => {
        if (!press.current || model.boosting) return;
        model.boosting = true;
        haptics.tap("medium");
      }, 150);
      press.current = { id: e.pointerId, start: localPoint(e, e.currentTarget), timer };
    },
    onPointerMove: (e: React.PointerEvent<HTMLElement>) => {
      const p = press.current;
      if (!p || p.id !== e.pointerId) return;
      const q = localPoint(e, e.currentTarget);
      if (Math.hypot(q.x - p.start.x, q.y - p.start.y) > 10) end();
    },
    onPointerUp: end,
    onPointerCancel: end,
  };

  return (
    <Stage rootRef={root} background="#020208" handlers={handlers}>
      <Layer canvasRef={canvas} />
      <BgHint ctx={ctx} en="Press and hold to warp" zh="长按进入跃迁" />
    </Stage>
  );
}
