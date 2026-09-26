/** gestures.newtons-cradle · 牛顿摆 (Gestures+NewtonsCradle.swift) */
import { useId, useRef, useState } from "react";
import { DemoHint, Palette, black, clamp, useAutoplay, useHaptics, usePan, type DemoProps, type Point } from "../../kit";
import { useFrameLoop } from "./_a-common";

const STAGE = { w: 300, h: 290 };
const PIVOT_Y = 40;
const D = 36;
const SPACING = 36.6;
const MAX_ANGLE = 0.9;
const GRAVITY = 2000;
const H = 1 / 240;

const pivotX = (index: number, count: number) => STAGE.w / 2 + (index - (count - 1) / 2) * SPACING;

/** The Swift `CradleModel`: pendulums at 240 Hz with alternating-pass contact resolution. */
class CradleModel {
  theta: number[] = [];
  omega: number[] = [];
  held: number | null = null;
  heldTarget = 0;
  private scriptRelease: number | null = null;
  private pendingLift: { index: number; angle: number } | null = null;
  private accumulator = 0;
  private lastHaptic = -1;

  get isSettled() {
    return (
      this.held === null &&
      this.pendingLift === null &&
      this.scriptRelease === null &&
      this.omega.every((w) => Math.abs(w) < 0.02) &&
      this.theta.every((t) => Math.abs(t) < 0.003)
    );
  }

  configure(count: number) {
    if (this.theta.length === count) return;
    this.theta = Array(count).fill(0);
    this.omega = Array(count).fill(0);
    this.held = null;
  }

  lift(index: number, angle: number) {
    this.pendingLift = { index, angle };
  }

  grab(index: number, angle: number) {
    if (index < 0 || index >= this.theta.length) return;
    this.scriptRelease = null;
    this.held = index;
    this.heldTarget = clamp(angle, -MAX_ANGLE, MAX_ANGLE);
  }

  release(tangentialSpeed: number, length: number) {
    const index = this.held;
    if (index === null || index >= this.omega.length) return;
    this.held = null;
    this.omega[index] = clamp(tangentialSpeed / Math.max(length, 1), -9, 9);
  }

  step(now: number, raw: number, length: number, restitution: number, onImpact: () => void) {
    if (this.pendingLift && this.pendingLift.index < this.theta.length) {
      this.held = this.pendingLift.index;
      this.heldTarget = this.pendingLift.angle;
      this.pendingLift = null;
      this.scriptRelease = now + 0.55;
    }
    if (this.scriptRelease !== null && now >= this.scriptRelease) {
      this.scriptRelease = null;
      if (this.held !== null) this.omega[this.held] = 0;
      this.held = null;
    }
    this.accumulator = Math.min(this.accumulator + Math.max(raw, 0), 0.08);
    let impact = 0;
    let steps = 0;
    while (this.accumulator >= H && steps < 24) {
      impact = Math.max(impact, this.integrate(Math.max(length, 1), restitution));
      this.accumulator -= H;
      steps += 1;
    }
    if (impact > 260 && (this.lastHaptic < 0 || now - this.lastHaptic > 0.07)) {
      this.lastHaptic = now;
      onImpact();
    }
  }

  private integrate(length: number, restitution: number) {
    const count = this.theta.length;
    const k = GRAVITY / length;
    for (let i = 0; i < count; i++) {
      if (i === this.held) {
        this.theta[i] += (this.heldTarget - this.theta[i]) * 0.25;
        this.omega[i] = 0;
        continue;
      }
      const alpha = -k * Math.sin(this.theta[i]) - 0.12 * this.omega[i];
      this.omega[i] += alpha * H;
      this.theta[i] += this.omega[i] * H;
    }
    let impact = 0;
    for (let pass = 0; pass < 3; pass++) {
      const forward = pass % 2 === 0;
      for (let s = 0; s < Math.max(count - 1, 0); s++) {
        const i = forward ? s : count - 2 - s;
        impact = Math.max(impact, this.resolve(i, i + 1, length, restitution));
      }
    }
    return impact;
  }

  private resolve(i: number, j: number, length: number, e: number) {
    const { theta, omega } = this;
    const gap = SPACING + length * (Math.sin(theta[j]) - Math.sin(theta[i])) - D;
    if (gap >= 0) return 0;
    const ci = Math.max(Math.cos(theta[i]), 0.2);
    const cj = Math.max(Math.cos(theta[j]), 0.2);
    const vi = length * omega[i] * ci;
    const vj = length * omega[j] * cj;
    let closing = 0;
    if (vi > vj) {
      closing = vi - vj;
      let ni = vi;
      let nj = vj;
      if (this.held === i) nj = vi * (1 + e) - e * vj;
      else if (this.held === j) ni = vj * (1 + e) - e * vi;
      else {
        ni = ((1 - e) / 2) * vi + ((1 + e) / 2) * vj;
        nj = ((1 + e) / 2) * vi + ((1 - e) / 2) * vj;
      }
      omega[i] = ni / (length * ci);
      omega[j] = nj / (length * cj);
    }
    const overlap = -gap;
    if (this.held === i) theta[j] += overlap / (length * cj);
    else if (this.held === j) theta[i] -= overlap / (length * ci);
    else {
      theta[i] -= overlap / 2 / (length * ci);
      theta[j] += overlap / 2 / (length * cj);
    }
    return closing;
  }
}

export default function NewtonsCradle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const model = useRef(new CradleModel()).current;
  const grabbed = useRef<number | null>(null);
  const userTouched = useRef(false);
  const [awake, setAwake] = useState(true);
  const uid = useId().replace(/:/g, "");
  const count = clamp(ctx.i("balls"), 3, 7);
  const length = ctx.n("length");
  model.configure(count);

  useFrameLoop(
    (dt, now) => {
      model.configure(count);
      model.step(now, dt, length, ctx.n("restitution"), () => {
        if (userTouched.current) haptics.tap("rigid");
      });
      if (model.isSettled) setAwake(false);
    },
    awake,
    ctx.isPreview ? 30 : undefined,
  );
  const lastCount = useRef(count);
  if (lastCount.current !== count) {
    lastCount.current = count;
    if (!awake) setAwake(true);
  }

  const centers = (): Point[] =>
    model.theta.slice(0, count).map((a, i) => ({ x: pivotX(i, count) + length * Math.sin(a), y: PIVOT_Y + length * Math.cos(a) }));

  const ballIndex = (p: Point) => {
    let best: number | null = null;
    let bestDistance = Infinity;
    centers().forEach((c, i) => {
      const d = Math.hypot(p.x - c.x, p.y - c.y);
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    });
    return bestDistance < D / 2 + 18 ? best : null;
  };

  const pan = usePan({
    onChange: ({ start, location }) => {
      if (grabbed.current === null) {
        const index = ballIndex(start);
        if (index === null) return;
        grabbed.current = index;
        userTouched.current = true;
        setAwake(true);
        haptics.tap("light");
      }
      const index = grabbed.current;
      const px = pivotX(index, count);
      model.grab(index, Math.atan2(location.x - px, Math.max(location.y - PIVOT_Y, 1)));
    },
    onEnd: ({ velocity }) => {
      if (grabbed.current === null) return;
      grabbed.current = null;
      const angle = model.held !== null ? (model.theta[model.held] ?? 0) : 0;
      const tangential = velocity.x * Math.cos(angle) - velocity.y * Math.sin(angle);
      model.release(tangential, length);
      setAwake(true);
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      setAwake(true);
      const index = Math.random() < 0.5 ? 0 : count - 1;
      model.lift(index, index === 0 ? -0.75 : 0.75);
    },
    { every: 3.4, delay: 0.3 },
  );

  const r = D / 2;
  const left = pivotX(0, count) - 34;
  const right = pivotX(count - 1, count) + 34;
  const floorY = PIVOT_Y + length + r + 16;
  const balls = centers();

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: STAGE.w, height: STAGE.h }}>
        <svg width={STAGE.w} height={STAGE.h} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
          <defs>
            <linearGradient id={`${uid}-bar`} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="rgb(217 217 217)" />
              <stop offset="1" stopColor="rgb(128 128 128)" />
            </linearGradient>
            <radialGradient id={`${uid}-chrome`} cx="0.325" cy="0.3" r="0.75" fx="0.325" fy="0.3">
              <stop offset="0" stopColor="#fff" />
              <stop offset="0.25" stopColor="rgb(219 219 219)" />
              <stop offset="0.7" stopColor="rgb(133 133 133)" />
              <stop offset="1" stopColor="rgb(66 66 66)" />
            </radialGradient>
          </defs>
          <rect x={left} y={PIVOT_Y - 8} width={right - left} height={8} rx={4} fill={`url(#${uid}-bar)`} />
          {balls.map((c, i) => {
            const lift = clamp((floorY - r - 16 - c.y) / 80);
            const w = 34 * (1 - 0.45 * lift);
            return <ellipse key={`s${i}`} cx={c.x} cy={floorY} rx={w / 2} ry={3} fill={black(0.16 * (1 - 0.7 * lift))} />;
          })}
          {balls.map((c, i) => (
            <line key={`l${i}`} x1={pivotX(i, count)} y1={PIVOT_Y} x2={c.x} y2={c.y} stroke={Palette.labelAlpha(0.35)} strokeWidth={1} />
          ))}
          {balls.map((c, i) => (
            <g key={`b${i}`}>
              <circle cx={c.x} cy={c.y} r={r} fill={`url(#${uid}-chrome)`} />
              <circle cx={c.x} cy={c.y} r={r - 0.5} fill="none" stroke={black(0.18)} strokeWidth={1} />
            </g>
          ))}
        </svg>
      </div>
      <DemoHint ctx={ctx} en="Pull an end ball aside and let go" zh="把一端的球拉开再松手" style={{ position: "absolute", left: 0, right: 0, bottom: 10 }} />
    </div>
  );
}
