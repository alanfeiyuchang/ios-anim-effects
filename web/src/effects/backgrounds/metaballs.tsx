/** backgrounds.metaballs · 液态融球 (Backgrounds+Metaballs.swift) */
import { useEffect, useRef } from "react";
import { useHaptics, type DemoProps, type Point } from "../../kit";
import { GooRenderer, acquire, release } from "./_gl";
import { BackgroundClock, BgHint, Layer, Stage, TAU, circle, prep, rand, rgb01, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

type Circle = [number, number, number]; // x, y, r

class MercuryModel {
  clock = new BackgroundClock();
  touch: Point | null = null;
  onPinch: () => void = () => {};
  time = 0;
  drop: Point | null = null;
  attached = false;
  private vx = 0;
  private vy = 0;
  private latched = false;

  static core(w: number, h: number, t: number) {
    const side = Math.min(w, h);
    return { x: w / 2, y: h / 2, r: side * (0.13 + 0.015 * Math.sin(t * 1.7)) };
  }
  static dropRadius(w: number, h: number) {
    return Math.min(w, h) * 0.075;
  }

  step(now: number, speed: number, w: number, h: number, pinch: number, simulated: Point | null) {
    const t = this.clock.advance(now, speed);
    this.time = t;
    const dt = this.clock.delta;
    if (dt <= 0) return;
    const core = MercuryModel.core(w, h, t);
    const target = this.touch ?? simulated;
    if (!target) this.latched = false;
    if (target && !this.latched) this.follow(target, core, dt, pinch);
    else if (this.drop) this.springHome(this.drop, core, dt);
  }

  private follow(target: Point, core: { x: number; y: number; r: number }, dt: number, pinch: number) {
    let current: Point;
    if (this.drop) current = this.drop;
    else {
      const dx = target.x - core.x;
      const dy = target.y - core.y;
      const length = Math.max(Math.hypot(dx, dy), 0.001);
      current = { x: core.x + (dx / length) * core.r * 0.6, y: core.y + (dy / length) * core.r * 0.6 };
      this.attached = true;
    }
    const k = 1 - Math.exp(-dt * 9);
    const next = { x: current.x + (target.x - current.x) * k, y: current.y + (target.y - current.y) * k };
    this.vx = (next.x - current.x) / dt;
    this.vy = (next.y - current.y) / dt;
    this.drop = next;
    const stretch = Math.hypot(next.x - core.x, next.y - core.y) - core.r;
    if (this.attached && stretch > pinch) {
      this.attached = false;
      this.latched = true;
      this.onPinch();
    }
  }

  private springHome(current: Point, core: { x: number; y: number; r: number }, dt: number) {
    const omega = (2 * Math.PI) / 0.5;
    const damping = 0.55;
    const ox = current.x - core.x;
    const oy = current.y - core.y;
    this.vx += (-omega * omega * ox - 2 * damping * omega * this.vx) * dt;
    this.vy += (-omega * omega * oy - 2 * damping * omega * this.vy) * dt;
    const next = { x: current.x + this.vx * dt, y: current.y + this.vy * dt };
    const distance = Math.hypot(next.x - core.x, next.y - core.y);
    const speed = Math.hypot(this.vx, this.vy);
    if (distance < core.r * 0.35 && speed < 40) {
      this.drop = null;
      this.attached = false;
      this.vx = 0;
      this.vy = 0;
    } else this.drop = next;
  }

  circles(count: number, w: number, h: number, pinch: number): Circle[] {
    const t = this.time;
    const core = MercuryModel.core(w, h, t);
    const side = Math.min(w, h);
    const orbit = side * 0.34;
    const out: Circle[] = [[core.x, core.y, core.r]];
    for (let i = 0; i < Math.max(count, 0); i++) {
      const a = 0.5 + rand(i, 1) * 0.7;
      const b = 0.5 + rand(i, 2) * 0.7;
      const p = rand(i, 3) * TAU;
      out.push([core.x + orbit * Math.sin(t * a + p), core.y + orbit * Math.cos(t * b + p * 1.3), side * (0.05 + rand(i, 4) * 0.05)]);
    }
    const drop = this.drop;
    if (!drop) return out;
    const dropR = MercuryModel.dropRadius(w, h);
    out.push([drop.x, drop.y, dropR]);
    if (this.attached) {
      const dx = drop.x - core.x;
      const dy = drop.y - core.y;
      const length = Math.hypot(dx, dy);
      const stretch = Math.max(length - core.r, 0);
      const thin = Math.max(1 - stretch / Math.max(pinch, 1), 0);
      const links = Math.max(Math.floor(length / 7), 3);
      for (let k = 1; k < links; k++) {
        const f = k / links;
        const base = core.r * 0.5 * (1 - f) + dropR * 0.7 * f;
        out.push([core.x + dx * f, core.y + dy * f, base * (0.3 + 0.7 * thin)]);
      }
    }
    return out;
  }
}

const CHROME = [0x2e333b, 0x8a94a3, 0xeef3f8, 0xa9cbe6, 0x3a414c];

// Metal: a rotating 5-stop linear gradient inside the silhouette; rim: the silhouette minus itself
// shifted 3 pt toward the bottom-right (destinationOut), 85 %, added with plusLighter.
const FRAGMENT = `
uniform vec2 u_from;
uniform vec2 u_to;
uniform vec3 u_c0;
uniform vec3 u_c1;
uniform vec3 u_c2;
uniform vec3 u_c3;
uniform vec3 u_c4;
vec3 chrome(float t) {
  t = clamp(t, 0.0, 1.0) * 4.0;
  if (t < 1.0) return mix(u_c0, u_c1, t);
  if (t < 2.0) return mix(u_c1, u_c2, t - 1.0);
  if (t < 3.0) return mix(u_c2, u_c3, t - 2.0);
  return mix(u_c3, u_c4, t - 3.0);
}
void main() {
  vec2 p = v_uv * u_size;
  vec2 d = u_to - u_from;
  float t = dot(p - u_from, d) / max(dot(d, d), 1e-4);
  float s = sil(v_uv);
  float cut = sil(v_uv - vec2(3.0) / u_size);
  float rim = clamp(s - cut, 0.0, 1.0) * 0.85;
  vec3 col = chrome(t) * s + vec3(0.957, 0.980, 1.0) * rim;
  gl_FragColor = vec4(min(col, vec3(s)), s);
}`;

export default function Metaballs({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const shadow = useRef<HTMLCanvasElement>(null);
  const metal = useRef<HTMLCanvasElement>(null);
  const shapes = useRef<HTMLCanvasElement | null>(null);
  const goo = useRef<GooRenderer | null>(null);
  const model = useModel(() => new MercuryModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);
  const start = useRef<number | null>(null);
  model.onPinch = () => haptics.tap("rigid");

  useEffect(() => {
    const el = metal.current;
    if (!el) return;
    const r = acquire(el, () => new GooRenderer(el, FRAGMENT));
    goo.current = r;
    shapes.current = document.createElement("canvas");
    return () => {
      release(el, r);
      goo.current = null;
    };
  }, []);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    const pinch = ctx.n("pinch");
    const gooRadius = ctx.n("goo");
    if (start.current === null) start.current = now;
    let simulated: Point | null = null;
    if (ctx.isPreview) {
      // Every 3.2 s a "finger" drags outward from the pool past the pinch, then lifts.
      const clock = now - start.current + 2.2;
      const cycle = clock % 3.2;
      if (cycle < 2) {
        const angle = Math.floor(clock / 3.2) * 2.4;
        const reach = Math.min(w, h) * (0.12 + (0.3 * cycle) / 2);
        simulated = { x: w / 2 + reach * Math.cos(angle), y: h / 2 + reach * Math.sin(angle) };
      }
    }
    model.step(now, ctx.n("speed"), w, h, pinch, simulated);
    const circles = model.circles(ctx.i("count"), w, h, pinch);

    const gs = prep(shadow.current, w, h, k);
    if (gs) {
      gs.fillStyle = "rgba(0,0,0,0.6)";
      for (const [x, y, r] of circles) {
        gs.beginPath();
        circle(gs, x, y + 5, r);
        gs.fill();
      }
    }
    const scale = gooRadius > 10 ? 0.5 : 1;
    const gm = prep(shapes.current, w, h, scale);
    if (gm && shapes.current) {
      gm.fillStyle = "#fff";
      gm.beginPath();
      for (const [x, y, r] of circles) circle(gm, x, y, r);
      gm.fill();
      const spin = now * 0.35;
      const dx = 0.5 * Math.cos(spin);
      const dy = 0.5 * Math.sin(spin);
      const colors = CHROME.map(rgb01);
      goo.current?.render(shapes.current, gooRadius, w, h, k, {
        u_from: [w * (0.5 + dx), h * (0.5 + dy)],
        u_to: [w * (0.5 - dx), h * (0.5 - dy)],
        u_c0: colors[0],
        u_c1: colors[1],
        u_c2: colors[2],
        u_c3: colors[3],
        u_c4: colors[4],
      });
    }
  });

  const touch = useBackgroundsTouch(
    (p) => (model.touch = p),
    () => (model.touch = null),
  );

  return (
    <Stage rootRef={root} background="#101216" handlers={touch}>
      <Layer canvasRef={shadow} blur={6} />
      <Layer canvasRef={metal} />
      <BgHint ctx={ctx} en="Drag a droplet out of the pool" zh="从液池里拖出一颗液滴" />
    </Stage>
  );
}
