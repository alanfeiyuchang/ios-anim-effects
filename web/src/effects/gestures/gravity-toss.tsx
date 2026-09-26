/** gestures.gravity-toss · 重力抛掷 (Gestures+GravityToss.swift) */
import { motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, black, clamp, spring, useAutoplay, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";

const ARENA = { w: 300, h: 300 };
const RADIUS = 28;

interface TossFrame {
  x: number;
  y: number;
  spin: number;
  squash: number;
}

/** Frame-stepped ball physics (TossModel), ported as-is. */
class TossModel {
  x: number;
  y: number;
  vx = 0;
  vy = 0;
  isHeld = false;
  private spin = 0;
  private spinVelocity = 0;
  private squash = 0;
  private onFloor = true;
  private lastDate: number | null = null;
  private lastImpact: number | null = null;

  constructor(p: Point) {
    this.x = p.x;
    this.y = p.y;
  }

  get isSettled() {
    return !this.isHeld && this.onFloor && Math.abs(this.vx) < 2 && Math.abs(this.vy) < 1 && this.squash < 0.002;
  }

  resetClock() {
    this.lastDate = null;
  }

  release(vx: number, vy: number) {
    this.vx = vx;
    this.vy = vy;
    this.isHeld = false;
    this.onFloor = false;
    this.lastDate = null;
  }

  step(date: number, radius: number, gravity: number, restitution: number, friction: number, onImpact: (() => void) | null): TossFrame {
    const raw = this.lastDate === null ? 0 : date - this.lastDate;
    this.lastDate = date;
    const dt = Math.min(Math.max(raw, 0), 1 / 30);
    this.squash *= Math.exp(-dt * 22);
    const floorY = ARENA.h - radius;

    if (this.isHeld || dt === 0) return { x: this.x, y: this.y, spin: this.spin, squash: this.squash };

    if (!this.onFloor) {
      this.vy += gravity * dt;
    } else {
      this.vx *= Math.exp(-(dt * friction));
      if (Math.abs(this.vx) < 2) this.vx = 0;
    }
    this.x += this.vx * dt;
    this.y += this.vy * dt;

    if (this.y >= floorY) {
      this.y = floorY;
      const impact = this.vy;
      if (impact > 0) {
        this.squash = Math.min(impact / 3200, 0.25);
        if (onImpact && impact > 700 && (this.lastImpact === null || date - this.lastImpact > 0.08)) {
          this.lastImpact = date;
          onImpact();
        }
        this.vy = -impact * restitution;
        this.vx *= 0.92;
        if (Math.abs(this.vy) < 60) {
          this.vy = 0;
          this.onFloor = true;
        }
      }
    }
    if (this.y < radius) {
      this.y = radius;
      this.vy = Math.abs(this.vy) * restitution;
    }
    if (this.x < radius || this.x > ARENA.w - radius) {
      this.x = clamp(this.x, radius, Math.max(ARENA.w - radius, radius));
      this.vx = -this.vx * restitution;
    }

    // Rolling on the floor spins at v / r; in the air the spin slowly decays.
    if (this.onFloor || this.y >= floorY - 0.5) {
      this.spinVelocity = this.vx / Math.max(radius, 1);
    } else {
      this.spinVelocity *= Math.exp(-dt * 0.4);
    }
    this.spin += this.spinVelocity * dt;
    return { x: this.x, y: this.y, spin: this.spin, squash: this.squash };
  }
}

export default function GravityToss({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const model = useRef(new TossModel({ x: 150, y: 272 })).current;
  const [held, setHeld] = useState(false);
  const [awake, setAwake] = useState(true);
  const [wakeID, setWakeID] = useState(0);
  const grabStart = useRef<Point | null>(null);
  const userTouched = useRef(false);
  const ballRef = useRef<HTMLDivElement>(null);
  const squashRef = useRef<HTMLDivElement>(null);
  const stripeRef = useRef<HTMLDivElement>(null);
  const shadowRef = useRef<HTMLDivElement>(null);
  const params = useRef({ gravity: 0, bounce: 0, friction: 0 });
  params.current = { gravity: ctx.n("gravity"), bounce: ctx.n("bounce"), friction: ctx.n("friction") };
  const hapticsRef = useRef(haptics);
  hapticsRef.current = haptics;

  const render = (f: TossFrame) => {
    if (ballRef.current) ballRef.current.style.transform = `translate(${f.x - RADIUS}px, ${f.y - RADIUS}px)`;
    if (squashRef.current) squashRef.current.style.transform = `scale(${1 + f.squash}, ${1 - f.squash})`;
    if (stripeRef.current) stripeRef.current.style.transform = `rotate(${f.spin}rad)`;
    if (shadowRef.current) {
      const height = Math.max(ARENA.h - RADIUS - f.y, 0);
      const fade = Math.max(1 - height / ARENA.h, 0.15);
      const s = shadowRef.current.style;
      s.width = `${RADIUS * 1.8 * fade}px`;
      s.height = `${8 * fade}px`;
      s.left = `${f.x - (RADIUS * 1.8 * fade) / 2}px`;
      s.top = `${ARENA.h - 5 - (8 * fade) / 2}px`;
      s.background = black(0.18 * fade);
    }
  };

  // TimelineView(.animation(minimumInterval:, paused: !awake))
  useEffect(() => {
    if (!awake) return;
    let raf = 0;
    let last = 0;
    const minInterval = ctx.isPreview ? 1000 / 30 : 0;
    const tick = (now: number) => {
      raf = requestAnimationFrame(tick);
      if (minInterval && now - last < minInterval - 1) return;
      last = now;
      const p = params.current;
      const allowHaptics = !ctx.isPreview && userTouched.current;
      render(model.step(now / 1000, RADIUS, p.gravity, p.bounce, p.friction, allowHaptics ? () => hapticsRef.current.tap("soft") : null));
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [awake, ctx.isPreview]);

  // Sleep watcher: every 0.3 s, stop the timeline once the ball has settled.
  useEffect(() => {
    let cancelled = false;
    let timer = 0;
    const check = () => {
      if (cancelled) return;
      if (model.isSettled) {
        setAwake(false);
        return;
      }
      timer = window.setTimeout(check, 300);
    };
    timer = window.setTimeout(check, 300);
    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [wakeID, model]);

  const wake = () => {
    setAwake(true);
    model.resetClock();
    setWakeID((w) => w + 1);
  };

  const endHold = (vx: number, vy: number) => {
    if (!grabStart.current) return;
    grabStart.current = null;
    model.release(vx, vy);
    setHeld(false);
    wake();
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!grabStart.current) {
        grabStart.current = { x: model.x, y: model.y };
        model.isHeld = true;
        model.vx = 0;
        model.vy = 0;
        userTouched.current = true;
        wake();
        setHeld(true);
        haptics.tap("light");
      }
      const start = grabStart.current;
      model.x = clamp(start.x + translation.x, RADIUS, ARENA.w - RADIUS);
      model.y = clamp(start.y + translation.y, RADIUS, ARENA.h - RADIUS);
    },
    onEnd: ({ velocity }) => endHold(clamp(velocity.x, -3200, 3200), clamp(velocity.y, -3200, 3200)),
  });

  const randomToss = () => {
    if (model.isHeld) return;
    const towardCenter = model.x > ARENA.w / 2 ? -1 : 1;
    model.release(towardCenter * (260 + Math.random() * 360), -(900 + Math.random() * 350));
    wake();
  };
  useAutoplay(ctx.isPreview, randomToss, { every: 3.0, delay: 0.4 });

  const heldT = held ? spring(0.25, 0.7) : spring(0.3, 0.7);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
      <div style={{ position: "relative", width: ARENA.w, height: ARENA.h, flexShrink: 0 }}>
        {/* TossArena */}
        <div style={{ position: "absolute", inset: 0, borderRadius: 34, background: Palette.elevated, boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 16px ${black(0.08)}` }}>
          <div style={{ position: "absolute", left: 20, right: 20, bottom: 1, height: 1, background: Palette.labelAlpha(0.06) }} />
        </div>
        <div ref={shadowRef} style={{ position: "absolute", borderRadius: "50%", filter: "blur(3px)", pointerEvents: "none" }} />
        <div ref={ballRef} style={{ position: "absolute", left: 0, top: 0, width: RADIUS * 2, height: RADIUS * 2, transform: `translate(${150 - RADIUS}px, ${272 - RADIUS}px)` }}>
          <div ref={squashRef} style={{ width: "100%", height: "100%", transformOrigin: "50% 100%" }}>
            <motion.div
              {...pan}
              initial={false}
              animate={{
                scale: held ? 1.08 : 1,
                boxShadow: held ? `0 10px 16px ${alpha(Palette.coral, 0.5)}` : `0 4px 8px ${alpha(Palette.coral, 0.3)}`,
              }}
              transition={heldT}
              style={{
                width: "100%",
                height: "100%",
                borderRadius: "50%",
                background: `linear-gradient(135deg, ${Palette.amber}, ${Palette.coral})`,
                overflow: "hidden",
                position: "relative",
                touchAction: "none",
                cursor: "grab",
                boxShadow: `0 4px 8px ${alpha(Palette.coral, 0.3)}`,
              }}
            >
              <div ref={stripeRef} style={{ position: "absolute", left: 0, right: 0, top: RADIUS - 4, height: 8 }}>
                <div style={{ width: "100%", height: "100%", borderRadius: 4, background: white(0.85) }} />
              </div>
              <div style={{ position: "absolute", inset: 5, borderRadius: "50%", background: `linear-gradient(${white(0.45)}, transparent 50%)` }} />
            </motion.div>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Grab the ball and throw it" zh="抓起小球抛出去" />
    </div>
  );
}
