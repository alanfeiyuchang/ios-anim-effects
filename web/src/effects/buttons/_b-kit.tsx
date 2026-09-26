/**
 * Small helpers shared by the buttons-b ports (keyframe tracks, centre-relative placement).
 */
import { motion, useAnimationControls } from "motion/react";
import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { clamp, springAt } from "../../kit";

/**
 * One keyframe of a SwiftUI `KeyframeTrack`:
 * `move` = MoveKeyframe, `linear` = LinearKeyframe, `cubic` = CubicKeyframe, `spring` = SpringKeyframe.
 */
export type Key =
  | { k: "move"; v: number }
  | { k: "linear" | "cubic"; v: number; d: number }
  | { k: "spring"; v: number; d: number; r?: number; z?: number };

export const move = (v: number): Key => ({ k: "move", v });
export const lin = (v: number, d: number): Key => ({ k: "linear", v, d });
export const cub = (v: number, d: number): Key => ({ k: "cubic", v, d });
/** SpringKeyframe(v, duration: d, spring: Spring(response: r, dampingRatio: z)); default `.smooth`-ish spring. */
export const spr = (v: number, d: number, r = 0.5, z = 1): Key => ({ k: "spring", v, d, r, z });

/** Duration of a track. */
export function trackDuration(keys: Key[]): number {
  return keys.reduce((s, key) => s + (key.k === "move" ? 0 : key.d), 0);
}

/**
 * Value of a keyframe track `t` seconds after it started (from `initial`). Runs of cubic keyframes
 * form a Catmull-Rom spline (SwiftUI's behaviour); a run starts and ends at rest.
 */
export function track(t: number, keys: Key[], initial: number): number {
  type Knot = { t: number; v: number; kind: Key["k"]; r?: number; z?: number };
  const knots: Knot[] = [{ t: 0, v: initial, kind: "move" }];
  let time = 0;
  for (const key of keys) {
    if (key.k === "move") {
      knots[knots.length - 1] = { ...knots[knots.length - 1], v: key.v };
      continue;
    }
    time += key.d;
    knots.push({ t: time, v: key.v, kind: key.k, r: key.k === "spring" ? key.r : undefined, z: key.k === "spring" ? key.z : undefined });
  }
  if (t <= 0) return knots[0].v;
  for (let i = 1; i < knots.length; i++) {
    const a = knots[i - 1];
    const b = knots[i];
    if (t > b.t && i < knots.length - 1) continue;
    if (t >= b.t) return b.v;
    const d = b.t - a.t;
    const local = t - a.t;
    const p = d <= 0 ? 1 : clamp(local / d);
    if (b.kind === "linear") return a.v + (b.v - a.v) * p;
    if (b.kind === "spring") return a.v + (b.v - a.v) * springAt(local, b.r ?? 0.5, b.z ?? 1);
    // cubic: Hermite with Catmull-Rom tangents inside a cubic run, zero at its ends.
    const prev = knots[i - 2];
    const next = knots[i + 1];
    const m0 = prev && a.kind === "cubic" ? (b.v - prev.v) / (b.t - prev.t) : 0;
    const m1 = next && next.kind === "cubic" ? (next.v - a.v) / (next.t - a.t) : 0;
    const p2 = p * p;
    const p3 = p2 * p;
    return (2 * p3 - 3 * p2 + 1) * a.v + (p3 - 2 * p2 + p) * d * m0 + (-2 * p3 + 3 * p2) * b.v + (p3 - p2) * d * m1;
  }
  return knots[knots.length - 1].v;
}

/**
 * Places `children` centred on a point given relative to the parent's centre, like a SwiftUI
 * `ZStack` child with `.offset(x:y:)`. The parent must be positioned.
 */
export function At({ x = 0, y = 0, children, style }: { x?: number; y?: number; children?: ReactNode; style?: CSSProperties }) {
  return (
    <div
      style={{
        position: "absolute",
        left: `calc(50% + ${x}px)`,
        top: `calc(50% + ${y}px)`,
        width: 0,
        height: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        ...style,
      }}
    >
      {children}
    </div>
  );
}

/** Seconds on the wall clock (`timeIntervalSinceReferenceDate`, modulo a day to keep precision). */
export const wallSeconds = () => (Date.now() / 1000) % 86400;

/**
 * `keyframeAnimator(trigger:)`: seconds since `trigger` last changed (−1 until it first changes),
 * re-rendering every frame for `duration`. Unlike the kit's `useElapsed(…, startIdle)` it compares
 * values, so React StrictMode's double effect run does not play it on mount.
 */
export function useKeyframes(trigger: unknown, duration: number): number {
  const initial = useRef(trigger);
  const [elapsed, setElapsed] = useState(-1);
  useEffect(() => {
    if (Object.is(trigger, initial.current)) return;
    initial.current = Symbol("played");
    let raf = 0;
    const start = performance.now();
    const step = (now: number) => {
      const e = Math.min((now - start) / 1000, duration);
      setElapsed(e);
      if (e < duration) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [trigger, duration]);
  return elapsed;
}

/** `symbolEffect(.bounce, value:)` that ignores StrictMode's mount re-run (see `useKeyframes`). */
export function Bounce({ trigger, children, style, down = false }: { trigger: unknown; children: ReactNode; style?: CSSProperties; down?: boolean }) {
  const controls = useAnimationControls();
  const prev = useRef(trigger);
  useEffect(() => {
    if (Object.is(prev.current, trigger)) return;
    prev.current = trigger;
    void controls.start({ scale: down ? [1, 0.8, 1.08, 1] : [1, 1.22, 0.94, 1], transition: { duration: 0.45, times: [0, 0.35, 0.7, 1] } });
  }, [trigger, controls, down]);
  return (
    <motion.span animate={controls} style={{ display: "inline-flex", ...style }}>
      {children}
    </motion.span>
  );
}

/** SwiftUI's `Color.gradient`: the colour, a touch lighter at the top. */
export const colorGradient = (color: string, angle = 180) =>
  `linear-gradient(${angle}deg, color-mix(in srgb, ${color}, white 14%), ${color})`;
