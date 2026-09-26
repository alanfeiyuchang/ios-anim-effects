/** gestures.fling-inertia · 惯性甩动与撞墙反弹 (Gestures+Fling.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, black, clamp, hex, spring, useAutoplay, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";
import { TAU, useFrameLoop } from "./_a-common";

const ARENA = 290;

/** Frame-stepped puck physics, the Swift `FlingModel` verbatim. */
class FlingModel {
  position: Point;
  velocity = { x: 0, y: 0 };
  isHeld = false;
  squash = { x: 0, y: 0 };
  trail: Point[] = [];
  private lastImpact = -1;

  constructor(position: Point) {
    this.position = position;
  }

  get isResting() {
    return !this.isHeld && Math.abs(this.velocity.x) < 1 && Math.abs(this.velocity.y) < 1;
  }

  get isSettled() {
    return this.isResting && Math.abs(this.squash.x) < 0.002 && Math.abs(this.squash.y) < 0.002 && this.trail.length === 0;
  }

  step(raw: number, now: number, bounds: { w: number; h: number }, glide: number, restitution: number, onImpact: () => void) {
    const dt = Math.min(Math.max(raw, 0), 1 / 20);
    const relax = Math.exp(-dt * 16);
    this.squash.x *= relax;
    this.squash.y *= relax;

    if (!this.isHeld && dt > 0) {
      const friction = Math.exp(-dt / Math.max(glide, 0.05));
      this.velocity.x *= friction;
      this.velocity.y *= friction;
      if (Math.hypot(this.velocity.x, this.velocity.y) < 6) this.velocity = { x: 0, y: 0 };
      const p = this.position;
      p.x += this.velocity.x * dt;
      p.y += this.velocity.y * dt;
      let impact = 0;
      if (p.x < 0 || p.x > bounds.w) {
        p.x = p.x < 0 ? -p.x : 2 * bounds.w - p.x;
        impact = Math.max(impact, Math.abs(this.velocity.x));
        this.squash.x = (this.velocity.x < 0 ? -1 : 1) * Math.min(Math.abs(this.velocity.x) / 2600, 0.22);
        this.velocity.x = -this.velocity.x * restitution;
      }
      if (p.y < 0 || p.y > bounds.h) {
        p.y = p.y < 0 ? -p.y : 2 * bounds.h - p.y;
        impact = Math.max(impact, Math.abs(this.velocity.y));
        this.squash.y = (this.velocity.y < 0 ? -1 : 1) * Math.min(Math.abs(this.velocity.y) / 2600, 0.22);
        this.velocity.y = -this.velocity.y * restitution;
      }
      if (impact > 700 && (this.lastImpact < 0 || now - this.lastImpact > 0.08)) {
        this.lastImpact = now;
        onImpact();
      }
    }
    this.position.x = clamp(this.position.x, 0, Math.max(bounds.w, 0));
    this.position.y = clamp(this.position.y, 0, Math.max(bounds.h, 0));

    const speed = Math.hypot(this.velocity.x, this.velocity.y);
    if (speed > 60 && !this.isHeld) {
      this.trail.push({ ...this.position });
      if (this.trail.length > 10) this.trail.splice(0, this.trail.length - 10);
    } else if (this.trail.length) {
      this.trail.shift();
    }
  }
}

export default function FlingInertia({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const model = useRef(new FlingModel({ x: 113, y: 113 })).current;
  const grab = useRef<Point | null>(null);
  const userTouched = useRef(false);
  const [isDragging, setDragging] = useState(false);
  const [awake, setAwake] = useState(true);
  const puck = ctx.n("size");
  const bounds = { w: ARENA - puck, h: ARENA - puck };

  useFrameLoop(
    (dt, now) => {
      model.step(dt, now, bounds, ctx.n("glide"), ctx.n("bounce"), () => {
        if (userTouched.current) haptics.tap("soft");
      });
      if (model.isSettled) setAwake(false);
    },
    awake,
    ctx.isPreview ? 30 : undefined,
  );
  const wake = () => setAwake(true);

  const release = (velocity: Point) => {
    model.velocity = { x: clamp(velocity.x, -4200, 4200), y: clamp(velocity.y, -4200, 4200) };
    model.isHeld = false;
    setDragging(false);
    wake();
  };

  const pan = usePan({
    onChange: ({ start, location }) => {
      if (!grab.current) {
        const live = model.position;
        const d = Math.hypot(start.x - (live.x + puck / 2), start.y - (live.y + puck / 2));
        if (d > puck / 2 + 26) return;
        const wasMoving = !model.isResting;
        grab.current = { x: start.x - live.x, y: start.y - live.y };
        model.isHeld = true;
        model.velocity = { x: 0, y: 0 };
        userTouched.current = true;
        wake();
        setDragging(true);
        haptics.tap(wasMoving ? "medium" : "light");
      }
      const g = grab.current;
      model.position = { x: clamp(location.x - g.x, 0, bounds.w), y: clamp(location.y - g.y, 0, bounds.h) };
    },
    onEnd: ({ velocity }) => {
      if (!grab.current) return;
      grab.current = null;
      release(velocity);
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (model.isHeld) return;
      const speed = 1500 + Math.random() * 1100;
      const angle = Math.random() * TAU;
      model.velocity = { x: Math.cos(angle) * speed, y: Math.sin(angle) * speed };
      wake();
    },
    { every: 2.6, delay: 0.3 },
  );

  const { position, squash, trail } = model;
  const sx = Math.abs(squash.x);
  const sy = Math.abs(squash.y);
  const ax = squash.x < 0 ? 0 : squash.x > 0 ? 100 : 50;
  const ay = squash.y < 0 ? 0 : squash.y > 0 ? 100 : 50;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: ARENA, height: ARENA, flexShrink: 0 }}>
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: 34,
            background: `radial-gradient(circle at 11px 11px, ${Palette.labelAlpha(0.12)} 0.9px, transparent 1.3px) 0 0 / 22px 22px, ${Palette.elevated}`,
            boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 16px ${black(0.08)}`,
          }}
        />
        {trail.map((p, index) => {
          const t = (index + 1) / Math.max(trail.length, 1);
          const r = (puck / 2) * (0.35 + 0.5 * t);
          return (
            <div
              key={index}
              style={{
                position: "absolute",
                left: p.x + puck / 2 - r,
                top: p.y + puck / 2 - r,
                width: r * 2,
                height: r * 2,
                borderRadius: "50%",
                background: hex(Palette.sky, 0.22 * t),
                pointerEvents: "none",
              }}
            />
          );
        })}
        <div
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            width: puck,
            height: puck,
            transform: `translate(${position.x}px, ${position.y}px) scale(${1 - sx + sy * 0.5}, ${1 - sy + sx * 0.5})`,
            transformOrigin: `${ax}% ${ay}%`,
            cursor: "grab",
          }}
        >
          <Puck isDragging={isDragging} />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Flick the puck — catch it mid-flight" zh="甩动圆球，飞行中也能接住" />
    </div>
  );
}

function Puck({ isDragging }: { isDragging: boolean }) {
  return (
    <motion.div
      initial={false}
      animate={{
        scale: isDragging ? 1.08 : 1,
        boxShadow: `0 ${isDragging ? 10 : 5}px ${isDragging ? 18 : 10}px ${hex(Palette.sky, isDragging ? 0.55 : 0.35)}`,
      }}
      transition={isDragging ? spring(0.25, 0.7) : spring(0.3, 0.7)}
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: "50%",
        background: `linear-gradient(135deg, ${Palette.mint}, ${Palette.sky})`,
      }}
    >
      <div style={{ position: "absolute", inset: 5, borderRadius: "50%", background: `linear-gradient(180deg, ${white(0.55)}, transparent 50%)` }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: `inset 0 0 0 1px ${white(0.35)}` }} />
    </motion.div>
  );
}
