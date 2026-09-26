/** backgrounds.lava-lamp · 熔岩灯 (Backgrounds+LavaLamp.swift) */
import { useEffect, useRef } from "react";
import { useHaptics, type DemoProps } from "../../kit";
import { GooRenderer, acquire, release } from "./_gl";
import { BackgroundClock, BgHint, Layer, Stage, TAU, ellipse, nowSec, prep, rand, rgb01, sizeOf, useFrameLoop, useModel, useRatio, useTap } from "./_support";

const LIFETIME = 9;
interface Drop {
  x: number;
  time: number;
}
type Rect = [number, number, number, number]; // x, y, w, h

/** Pools first (two), then one rect per free blob, then one per tap-released blob. */
function shapes(w: number, h: number, t: number, count: number, risers: { x: number; progress: number }[]): Rect[] {
  const rects: Rect[] = [
    [-w * 0.1, h * 0.86, w * 1.2, h * 0.3],
    [w * 0.15, -h * 0.12, w * 0.7, h * 0.18],
  ];
  const side = Math.min(w, h);
  for (let i = 0; i < Math.max(count, 0); i++) {
    const rate = 0.25 + 0.35 * rand(i, 1);
    const phase = rand(i, 2) * TAU;
    const wave = Math.sin(t * rate + phase);
    const velocity = Math.cos(t * rate + phase);
    const radius = side * (0.08 + 0.07 * rand(i, 3));
    const stretch = 0.16 * Math.abs(velocity);
    const rx = radius * (1 - stretch * 0.6);
    const ry = radius * (1 + stretch);
    const x = w * (0.18 + 0.64 * rand(i, 4)) + 18 * Math.sin(t * 0.3 + i);
    const y = h * (0.5 + 0.42 * wave);
    rects.push([x - rx, y - ry, rx * 2, ry * 2]);
  }
  for (const r of risers) {
    // Half a sine: buds out of the pool, peaks at mid-life, sinks back in.
    const lift = Math.sin(r.progress * Math.PI);
    const velocity = Math.cos(r.progress * Math.PI);
    const radius = side * 0.11 * (0.6 + 0.4 * Math.min(r.progress * 6, 1));
    const rx = radius * (1 - 0.1 * Math.abs(velocity));
    const ry = radius * (1 + 0.16 * Math.abs(velocity));
    const y = h * (0.95 - 0.7 * lift);
    rects.push([r.x - rx, y - ry, rx * 2, ry * 2]);
  }
  return rects;
}

/** A blurred (σ 5) white ellipse, approximated with an elliptical radial falloff. */
function softSpot(g: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, alpha: number) {
  const sigma = 5;
  const a = w / 2;
  const b = h / 2;
  const erf = (v: number) => {
    const s = Math.sign(v);
    const q = Math.abs(v);
    const tt = 1 / (1 + 0.3275911 * q);
    return s * (1 - ((((1.061405429 * tt - 1.453152027) * tt + 1.421413741) * tt - 0.284496736) * tt + 0.254829592) * tt * Math.exp(-q * q));
  };
  const peak = alpha * erf(a / (sigma * Math.SQRT2)) * erf(b / (sigma * Math.SQRT2));
  const A = a + 2 * sigma;
  const B = b + 2 * sigma;
  g.save();
  g.translate(x + a, y + b);
  g.scale(A, B);
  const gr = g.createRadialGradient(0, 0, 0, 0, 0, 1);
  const edge = Math.min(a / A, b / B);
  gr.addColorStop(0, `rgba(255,255,255,${peak})`);
  gr.addColorStop(edge * 0.55, `rgba(255,255,255,${peak * 0.9})`);
  gr.addColorStop(edge, `rgba(255,255,255,${peak * 0.5})`);
  gr.addColorStop(1, "rgba(255,255,255,0)");
  g.fillStyle = gr;
  g.beginPath();
  g.arc(0, 0, 1, 0, TAU);
  g.fill();
  g.restore();
}

// Wax: a vertical FFD36B → FF8A3D → FF3C7A gradient plus the gloss (added), inside the silhouette.
const FRAGMENT = `
uniform vec3 u_c0;
uniform vec3 u_c1;
uniform vec3 u_c2;
void main() {
  float y = v_uv.y * 2.0;
  vec3 wax = y < 1.0 ? mix(u_c0, u_c1, y) : mix(u_c1, u_c2, y - 1.0);
  vec4 gloss = texture2D(u_extra, v_uv);
  float s = sil(v_uv);
  vec3 col = min(wax + gloss.rgb, vec3(1.0)) * s;
  gl_FragColor = vec4(col, s);
}`;

export default function LavaLamp({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const bloom = useRef<HTMLCanvasElement>(null);
  const wax = useRef<HTMLCanvasElement>(null);
  const heat = useRef<HTMLDivElement>(null);
  const shapesCanvas = useRef<HTMLCanvasElement | null>(null);
  const glossCanvas = useRef<HTMLCanvasElement | null>(null);
  const goo = useRef<GooRenderer | null>(null);
  const clock = useModel(() => new BackgroundClock());
  const drops = useRef<Drop[]>([]);
  const haptics = useHaptics();
  const ratio = useRatio(root);

  useEffect(() => {
    const el = wax.current;
    if (!el) return;
    const r = acquire(el, () => new GooRenderer(el, FRAGMENT));
    goo.current = r;
    shapesCanvas.current = document.createElement("canvas");
    glossCanvas.current = document.createElement("canvas");
    return () => {
      release(el, r);
      goo.current = null;
    };
  }, []);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    const t = clock.advance(now, ctx.n("speed"));
    const count = ctx.i("count");
    const gooRadius = ctx.n("goo");
    const risers = drops.current
      .filter((d) => now - d.time >= 0 && now - d.time < LIFETIME)
      .map((d) => ({ x: d.x, progress: (now - d.time) / LIFETIME }));
    const last = drops.current[drops.current.length - 1];
    const heatAmount = last ? Math.exp(-Math.max(now - last.time, 0) * 1.6) : 0;
    if (heat.current) heat.current.style.opacity = String(heatAmount);
    const rects = shapes(w, h, t, count, risers);

    const gb = prep(bloom.current, w, h, k);
    if (gb && bloom.current) {
      bloom.current.style.filter = `blur(${gooRadius + 16}px)`;
      gb.fillStyle = "rgba(255,122,61,0.5)";
      for (const [x, y, rw, rh] of rects) {
        gb.beginPath();
        ellipse(gb, x - 6, y - 6, rw + 12, rh + 12);
        gb.fill();
      }
    }
    const gs = prep(shapesCanvas.current, w, h, gooRadius > 10 ? 0.5 : 1);
    const gg = prep(glossCanvas.current, w, h, 1);
    if (gs && gg && shapesCanvas.current) {
      gs.fillStyle = "#fff";
      gs.beginPath();
      for (const [x, y, rw, rh] of rects) ellipse(gs, x, y, rw, rh);
      gs.fill();
      gg.globalCompositeOperation = "lighter";
      rects.forEach(([x, y, rw, rh], index) => {
        if (index < 2) softSpot(gg, x + rw * 0.2, y + rh * 0.12, rw * 0.4, 6, 0.55);
        else softSpot(gg, x + rw * 0.2, y + rh * 0.16, rw * 0.34, rh * 0.24, 0.55);
      });
      goo.current?.render(shapesCanvas.current, gooRadius, w, h, k, { u_c0: rgb01(0xffd36b), u_c1: rgb01(0xff8a3d), u_c2: rgb01(0xff3c7a) }, glossCanvas.current);
    }
  });

  const tap = useTap((p) => {
    const now = nowSec();
    const live = drops.current.filter((d) => now - d.time >= 0 && now - d.time < LIFETIME).slice(-3);
    drops.current = [...live, { x: p.x, time: now }];
    haptics.tap("soft");
  });

  return (
    <Stage
      rootRef={root}
      background="radial-gradient(circle 280px at 50% 100%, rgb(255 122 61 / 0.35), transparent), linear-gradient(#1C0826, #2B0A3D, #4A1040)"
      handlers={tap}
    >
      <div
        ref={heat}
        style={{ position: "absolute", inset: 0, opacity: 0, background: "radial-gradient(circle 300px at 50% 100%, rgb(255 154 77 / 0.55), transparent)", pointerEvents: "none" }}
      />
      <Layer canvasRef={bloom} />
      <Layer canvasRef={wax} />
      <BgHint ctx={ctx} en="Tap to heat the lamp" zh="点击加热熔岩灯" />
    </Stage>
  );
}
