/** gestures.verlet-rope · 吊坠绳索 (Gestures+VerletRope.swift) */
import { motion } from "motion/react";
import { Star } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, black, clamp, hex, spring, useAutoplay, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";
import { useFrameLoop } from "./_a-common";

const STAGE = { w: 300, h: 320 };
const ANCHOR = { x: 150, y: 26 };
const LINKS = 14;
const CHARM = 52;
const H = 1 / 120;

/** Verlet cord (the Swift `RopeModel`), fixed 1/120 s steps. */
class RopeModel {
  points: Point[];
  previous: Point[];
  grab: Point | null = null;
  private accumulator = 0;

  constructor() {
    const initial = Array.from({ length: LINKS + 1 }, (_, i) => ({ x: ANCHOR.x + i * 4, y: ANCHOR.y + i * 12 }));
    this.points = initial.map((p) => ({ ...p }));
    this.previous = initial.map((p) => ({ ...p }));
  }

  get end() {
    return this.points[this.points.length - 1];
  }

  get isSettled() {
    return this.grab === null && this.points.every((p, i) => Math.abs(p.x - this.previous[i].x) < 0.025 && Math.abs(p.y - this.previous[i].y) < 0.025);
  }

  get endDirection(): Point {
    const a = this.points[this.points.length - 2];
    const b = this.points[this.points.length - 1];
    const d = Math.max(Math.hypot(b.x - a.x, b.y - a.y), 0.0001);
    return { x: (b.x - a.x) / d, y: (b.y - a.y) / d };
  }

  step(raw: number, length: number, gravity: number, iterations: number) {
    this.accumulator = Math.min(this.accumulator + Math.max(raw, 0), 0.1);
    const link = length / LINKS;
    let steps = 0;
    while (this.accumulator >= H && steps < 14) {
      this.integrate(link, gravity, Math.max(iterations, 1));
      this.accumulator -= H;
      steps += 1;
    }
  }

  release(velocity: Point) {
    this.grab = null;
    const last = this.points.length - 1;
    const vx = clamp(velocity.x, -3200, 3200);
    const vy = clamp(velocity.y, -3200, 3200);
    this.previous[last] = { x: this.points[last].x - vx * H, y: this.points[last].y - vy * H };
  }

  kick(velocity: Point) {
    if (this.grab) return;
    const last = this.points.length - 1;
    this.previous[last].x -= velocity.x * H;
    this.previous[last].y -= velocity.y * H;
  }

  private integrate(link: number, gravity: number, iterations: number) {
    const pts = this.points;
    const prev = this.previous;
    const last = pts.length - 1;
    const g = gravity * H * H;
    for (let i = 1; i <= last; i++) {
      const p = pts[i];
      const vx = (p.x - prev[i].x) * 0.997;
      const vy = (p.y - prev[i].y) * 0.997;
      prev[i] = { ...p };
      pts[i] = { x: p.x + vx, y: p.y + vy + g };
    }
    pts[0] = { ...ANCHOR };
    if (this.grab) pts[last] = reachable(this.grab, link * last);
    for (let k = 0; k < iterations; k++) {
      for (let i = 0; i < last; i++) {
        const a = pts[i];
        const b = pts[i + 1];
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const d = Math.max(Math.hypot(dx, dy), 0.0001);
        const diff = (d - link) / d;
        const wa = i === 0 ? 0 : 1;
        const wb = i + 1 === last ? (this.grab === null ? 0.35 : 0) : 1;
        const total = wa + wb;
        if (total <= 0) continue;
        a.x += (dx * diff * wa) / total;
        a.y += (dy * diff * wa) / total;
        b.x -= (dx * diff * wb) / total;
        b.y -= (dy * diff * wb) / total;
      }
    }
  }
}

function reachable(p: Point, reach: number): Point {
  const dx = p.x - ANCHOR.x;
  const dy = p.y - ANCHOR.y;
  const d = Math.hypot(dx, dy);
  if (d <= reach || d <= 0) return p;
  return { x: ANCHOR.x + (dx / d) * reach, y: ANCHOR.y + (dy / d) * reach };
}

/** `RopeLayer.smooth`: quadratic curves through the link midpoints. */
function smoothPath(points: Point[]) {
  let d = `M${points[0].x} ${points[0].y}`;
  for (let i = 1; i < points.length - 1; i++) {
    const c = points[i];
    const n = points[i + 1];
    d += ` Q${c.x} ${c.y} ${(c.x + n.x) / 2} ${(c.y + n.y) / 2}`;
  }
  const l = points[points.length - 1];
  return d + ` L${l.x} ${l.y}`;
}

export default function VerletRope({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const model = useRef(new RopeModel()).current;
  const grabOffset = useRef<Point | null>(null);
  const [isHeld, setHeld] = useState(false);
  const [awake, setAwake] = useState(true);
  const stillFrames = useRef(0);
  const length = ctx.n("length");
  const gravity = ctx.n("gravity");
  const iterations = ctx.i("stiffness");
  const params = `${length}|${gravity}|${iterations}`;
  const lastParams = useRef(params);
  if (lastParams.current !== params) {
    lastParams.current = params;
    if (!awake) setAwake(true);
  }

  useFrameLoop(
    (dt) => {
      model.step(dt, length, gravity, iterations);
      // A swing's apex is momentarily still too: only sleep after ~0.5 s of stillness.
      stillFrames.current = model.isSettled ? stillFrames.current + 1 : 0;
      if (stillFrames.current > 30) setAwake(false);
    },
    awake,
    ctx.isPreview ? 30 : undefined,
  );

  const charmCenter = () => {
    const e = model.end;
    const dir = model.endDirection;
    return { x: e.x + (dir.x * CHARM) / 2, y: e.y + (dir.y * CHARM) / 2 };
  };

  const letGo = (velocity: Point, completed: boolean) => {
    if (!grabOffset.current) return;
    grabOffset.current = null;
    model.release(velocity);
    setHeld(false);
    setAwake(true);
    if (completed) haptics.tap("soft");
  };

  const pan = usePan({
    onChange: ({ start, location }) => {
      if (!grabOffset.current) {
        const c = charmCenter();
        if (Math.hypot(start.x - c.x, start.y - c.y) >= CHARM / 2 + 24) return;
        grabOffset.current = { x: start.x - model.end.x, y: start.y - model.end.y };
        setHeld(true);
        setAwake(true);
        haptics.tap("light");
      }
      const o = grabOffset.current;
      model.grab = { x: location.x - o.x, y: location.y - o.y };
    },
    onEnd: ({ velocity }) => letGo(velocity, true),
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      setAwake(true);
      model.kick({ x: (Math.random() < 0.5 ? 1 : -1) * (900 + Math.random() * 600), y: -Math.random() * 300 });
    },
    { every: 1.8, delay: 0.2 },
  );

  const pts = model.points;
  const dir = model.endDirection;
  const center = charmCenter();
  const angle = Math.atan2(dir.y, dir.x) - Math.PI / 2;
  const cord = smoothPath(pts);

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: STAGE.w, height: STAGE.h }}>
        <svg width={STAGE.w} height={STAGE.h} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
          <path d={cord} transform="translate(0 3)" fill="none" stroke={black(0.12)} strokeWidth={3.5} strokeLinecap="round" strokeLinejoin="round" />
          <path d={cord} fill="none" stroke={Palette.labelAlpha(0.7)} strokeWidth={2.4} strokeLinecap="round" strokeLinejoin="round" />
          <circle cx={ANCHOR.x} cy={ANCHOR.y} r={7} fill={Palette.elevated} />
          <circle cx={ANCHOR.x} cy={ANCHOR.y} r={7} fill="none" stroke={Palette.labelAlpha(0.35)} strokeWidth={1.5} />
          <circle cx={ANCHOR.x} cy={ANCHOR.y} r={2.5} fill={Palette.labelAlpha(0.6)} />
        </svg>
        <div
          style={{
            position: "absolute",
            left: center.x - CHARM / 2,
            top: center.y - CHARM / 2,
            width: CHARM,
            height: CHARM,
            transform: `rotate(${angle}rad)`,
            cursor: "grab",
          }}
        >
          <motion.div
            initial={false}
            animate={{
              scale: isHeld ? 1.08 : 1,
              boxShadow: `0 ${isHeld ? 10 : 6}px ${isHeld ? 18 : 10}px ${hex(Palette.coral, isHeld ? 0.5 : 0.32)}, inset 0 0 0 1px ${white(0.4)}`,
            }}
            transition={isHeld ? spring(0.25, 0.7) : spring(0.3, 0.7)}
            style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.sunset, display: "grid", placeItems: "center", color: "#fff" }}
          >
            <div style={{ position: "absolute", inset: 4, borderRadius: "50%", background: `linear-gradient(180deg, ${white(0.5)}, transparent 50%)` }} />
            <Star size={22} fill="currentColor" strokeWidth={1.5} strokeLinejoin="round" style={{ position: "relative" }} />
          </motion.div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Grab the charm and fling it" zh="抓住吊坠甩出去" style={{ position: "absolute", left: 0, right: 0, bottom: 10 }} />
    </div>
  );
}
