/**
 * SwiftUI animation curves as `motion` transitions, matched mathematically.
 *
 * SwiftUI's `spring(response:dampingFraction:)` is a unit-mass spring with
 *   stiffness = (2π / response)²   and   damping = 4π · dampingFraction / response,
 * so the same numbers give the same curve here. `spring(duration:bounce:)` is
 * response = duration, dampingFraction = 1 − bounce.
 */
import type { Transition } from "motion/react";

export function spring(response = 0.55, dampingFraction = 0.825): Transition {
  const r = Math.max(response, 0.01);
  return {
    type: "spring",
    stiffness: (2 * Math.PI / r) ** 2,
    damping: (4 * Math.PI * dampingFraction) / r,
    mass: 1,
    restDelta: 0.0005,
    restSpeed: 0.001,
  };
}

/** `spring(duration:bounce:)` / `Spring(duration:bounce:)`. */
export function springDB(duration = 0.5, bounce = 0): Transition {
  const damping = bounce >= 0 ? 1 - bounce : 1 / (1 + bounce);
  return spring(duration, damping);
}

const bezier = (duration: number, ease: [number, number, number, number]): Transition => ({
  type: "tween",
  duration,
  ease,
});

/** The named SwiftUI animations. `anim.easeInOut(0.3)` ≙ `.easeInOut(duration: 0.3)`. */
export const anim = {
  /** `.spring()` */
  spring: spring(0.55, 0.825),
  /** `.default` / `.smooth` (iOS 17+). */
  smooth: springDB(0.5, 0),
  smoothD: (duration: number, extraBounce = 0) => springDB(duration, extraBounce),
  /** `.snappy` */
  snappy: springDB(0.5, 0.15),
  snappyD: (duration: number, extraBounce = 0) => springDB(duration, 0.15 + extraBounce),
  /** `.bouncy` */
  bouncy: springDB(0.5, 0.3),
  bouncyD: (duration: number, extraBounce = 0) => springDB(duration, 0.3 + extraBounce),
  /** `.interactiveSpring()` */
  interactive: spring(0.15, 0.86),
  easeInOut: (duration = 0.35) => bezier(duration, [0.42, 0, 0.58, 1]),
  easeIn: (duration = 0.35) => bezier(duration, [0.42, 0, 1, 1]),
  easeOut: (duration = 0.35) => bezier(duration, [0, 0, 0.58, 1]),
  linear: (duration = 0.35): Transition => ({ type: "tween", duration, ease: "linear" }),
  /** `.timingCurve(a, b, c, d, duration:)` */
  curve: (a: number, b: number, c: number, d: number, duration = 0.35) => bezier(duration, [a, b, c, d]),
};

/** Adds a delay to any transition: `delayed(anim.spring, 0.1)` ≙ `.spring().delay(0.1)`. */
export function delayed(t: Transition, delay: number): Transition {
  return { ...t, delay };
}

/** Repeats a tween forever: `.easeInOut(duration: 1).repeatForever(autoreverses: true)`. */
export function forever(t: Transition, autoreverses = true): Transition {
  return { ...t, repeat: Infinity, repeatType: autoreverses ? "reverse" : "loop" };
}

/**
 * Closed-form progress (0 → 1) of a SwiftUI spring `elapsed` seconds after it started, for
 * timeline-driven code (TimelineView, keyframes): `from + (to − from) · springAt(t, 0.3, 0.5)`.
 */
export function springAt(elapsed: number, response = 0.55, dampingFraction = 0.825): number {
  if (elapsed <= 0) return 0;
  const w0 = (2 * Math.PI) / Math.max(response, 0.01);
  const z = dampingFraction;
  if (z < 1) {
    const wd = w0 * Math.sqrt(1 - z * z);
    return 1 - Math.exp(-z * w0 * elapsed) * (Math.cos(wd * elapsed) + ((z * w0) / wd) * Math.sin(wd * elapsed));
  }
  if (z === 1) return 1 - Math.exp(-w0 * elapsed) * (1 + w0 * elapsed);
  const s = Math.sqrt(z * z - 1);
  const r1 = -w0 * (z - s);
  const r2 = -w0 * (z + s);
  return 1 - (r2 * Math.exp(r1 * elapsed) - r1 * Math.exp(r2 * elapsed)) / (r2 - r1);
}

/** Cubic bezier easing evaluated at progress `x` (0…1). */
export function cubicBezier(x1: number, y1: number, x2: number, y2: number): (x: number) => number {
  const cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx;
  const cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by;
  const sx = (t: number) => ((ax * t + bx) * t + cx) * t;
  const sy = (t: number) => ((ay * t + by) * t + cy) * t;
  const dx = (t: number) => (3 * ax * t + 2 * bx) * t + cx;
  return (x: number) => {
    if (x <= 0) return 0;
    if (x >= 1) return 1;
    let t = x;
    for (let i = 0; i < 8; i++) {
      const d = dx(t);
      if (Math.abs(d) < 1e-6) break;
      t -= (sx(t) - x) / d;
    }
    return sy(Math.min(Math.max(t, 0), 1));
  };
}

export const ease = {
  inOut: cubicBezier(0.42, 0, 0.58, 1),
  in: cubicBezier(0.42, 0, 1, 1),
  out: cubicBezier(0, 0, 0.58, 1),
};

export const clamp = (v: number, lo = 0, hi = 1) => Math.min(Math.max(v, lo), hi);
export const mix = (a: number, b: number, t: number) => a + (b - a) * t;
/** Progress of `t` through the window `[start, start + duration]`, clamped to 0…1. */
export const progress = (t: number, start: number, duration: number) =>
  duration <= 0 ? (t >= start ? 1 : 0) : clamp((t - start) / duration);

/** UIScrollView-style rubber band (Swift `rubberBand(_:limit:coefficient:)`). */
export function rubberBand(offset: number, limit: number, coefficient = 0.55): number {
  if (offset === 0) return 0;
  const sign = offset < 0 ? -1 : 1;
  const x = Math.abs(offset);
  return sign * (1 - 1 / ((x * coefficient) / limit + 1)) * limit;
}
