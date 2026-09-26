/** gestures.spring-chain · 弹簧链 (Gestures+SpringChain.swift) */
import { useLayoutEffect, useRef, useState } from "react";
import { DemoHint, useAutoplay, usePan, type DemoProps, type Point } from "../../kit";
import { useFrameLoop, useScript } from "./_a-common";

/** SwiftUI `Color(hue:saturation:brightness:)` → rgb components. */
function hsb(h: number, s: number, v: number): [number, number, number] {
  const i = Math.floor(h * 6);
  const f = h * 6 - i;
  const p = v * (1 - s);
  const q = v * (1 - f * s);
  const t = v * (1 - (1 - f) * s);
  const [r, g, b] = [
    [v, t, p],
    [q, v, p],
    [p, v, t],
    [p, q, v],
    [t, p, v],
    [v, p, q],
  ][((i % 6) + 6) % 6];
  return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
}
const rgba = ([r, g, b]: [number, number, number], a = 1) => `rgb(${r} ${g} ${b} / ${a})`;

/** Per-frame spring chain: dot 0 chases the target, dot i chases dot i − 1 (the Swift `ChainModel`). */
class ChainModel {
  positions: Point[] = [];
  velocities: Point[] = [];

  step(raw: number, count: number, target: Point, response: number, damping: number) {
    if (this.positions.length !== count) {
      const seed = this.positions[this.positions.length - 1] ?? target;
      while (this.positions.length < count) {
        this.positions.push({ ...seed });
        this.velocities.push({ x: 0, y: 0 });
      }
      this.positions = this.positions.slice(0, count);
      this.velocities = this.velocities.slice(0, count);
    }
    const dt = Math.min(Math.max(raw, 0), 1 / 30);
    if (dt <= 0) return;
    const substeps = 4;
    const h = dt / substeps;
    for (let k = 0; k < substeps; k++) {
      for (let index = 0; index < this.positions.length; index++) {
        const goal = index === 0 ? target : this.positions[index - 1];
        const r = index === 0 ? response * 0.8 : response;
        const omega = (2 * Math.PI) / Math.max(r, 0.03);
        const stiffness = omega * omega;
        const friction = 2 * damping * omega;
        const v = this.velocities[index];
        const p = this.positions[index];
        v.x += (stiffness * (goal.x - p.x) - friction * v.x) * h;
        v.y += (stiffness * (goal.y - p.y) - friction * v.y) * h;
        p.x += v.x * h;
        p.y += v.y * h;
      }
    }
  }
}

export default function SpringChain({ ctx }: DemoProps) {
  const host = useRef<HTMLDivElement>(null);
  const model = useRef(new ChainModel()).current;
  const sleep = useScript();
  const [size, setSize] = useState({ w: 340, h: ctx.isPreview ? 340 : 400 });
  const [touched, setTouched] = useState(false);
  const [awake, setAwake] = useState(true);
  const target = useRef<Point | null>(null);
  const phase = useRef(0);
  const held = useRef(false);
  const count = Math.max(ctx.i("count"), 2);
  const center = { x: size.w / 2, y: size.h / 2 };

  useLayoutEffect(() => {
    const el = host.current;
    if (el) setSize({ w: el.offsetWidth, h: el.offsetHeight });
  }, []);

  useFrameLoop(
    (dt) => model.step(dt, count, target.current ?? center, ctx.n("link"), ctx.n("damping")),
    awake,
    ctx.isPreview ? 30 : undefined,
  );

  const wake = () => {
    sleep.cancel();
    setAwake(true);
  };

  const pan = usePan({
    onStart: ({ start }) => {
      const head = model.positions[0] ?? center;
      if (Math.hypot(start.x - head.x, start.y - head.y) > 56) return;
      held.current = true;
    },
    onChange: ({ location }) => {
      if (!held.current) return;
      setTouched(true);
      wake();
      target.current = location;
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      sleep.cancel();
      sleep.after(2.2, () => setAwake(false));
    },
  });

  useAutoplay(
    ctx.isPreview || !touched,
    () => {
      if (!(ctx.isPreview || !touched)) return;
      wake();
      phase.current += 0.85;
      target.current = {
        x: center.x + Math.cos(phase.current) * size.w * 0.33,
        y: center.y + Math.sin(phase.current * 2) * size.h * 0.26,
      };
    },
    { every: 0.42, delay: 0.2 },
  );

  const positions = model.positions;
  const n = positions.length;
  const first = positions[0];
  const last = positions[n - 1];
  return (
    <div ref={host} {...pan} style={{ ...pan.style, position: "absolute", inset: 0 }}>
      {n > 1 && (
        <svg width={size.w} height={size.h} style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
          <defs>
            <linearGradient id="a-chain-thread" gradientUnits="userSpaceOnUse" x1={first.x} y1={first.y} x2={last.x} y2={last.y}>
              <stop offset="0" stopColor={rgba(hsb(0.46, 0.7, 0.95), 0.5)} />
              <stop offset="1" stopColor={rgba(hsb(0.74, 0.7, 0.95), 0.1)} />
            </linearGradient>
          </defs>
          <polyline
            points={positions.map((p) => `${p.x},${p.y}`).join(" ")}
            fill="none"
            stroke="url(#a-chain-thread)"
            strokeWidth={3}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      )}
      {positions.map((p, index) => {
        const t = index / Math.max(n - 1, 1);
        const d = 52 - 36 * t;
        const c = hsb(0.46 + 0.28 * t, 0.7, 0.95);
        return (
          <div
            key={index}
            style={{
              position: "absolute",
              left: p.x - d / 2,
              top: p.y - d / 2,
              width: d,
              height: d,
              borderRadius: "50%",
              background: `linear-gradient(180deg, color-mix(in srgb, ${rgba(c)}, white 16%), ${rgba(c)})`,
              boxShadow: `0 4px ${10 - 6 * t}px ${rgba(c, 0.45)}`,
              opacity: 1 - 0.65 * t,
              zIndex: n - index,
              pointerEvents: "none",
            }}
          />
        );
      })}
      <DemoHint ctx={ctx} en="Grab the big dot and drag" zh="按住大圆点拖动" style={{ position: "absolute", left: 0, right: 0, bottom: 14, pointerEvents: "none" }} />
    </div>
  );
}
