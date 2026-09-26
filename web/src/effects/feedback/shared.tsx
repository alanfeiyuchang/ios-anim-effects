/** Shared pieces of the Feedback category. */
import { animate, useMotionValue, type MotionValue, type Transition } from "motion/react";
import { useCallback, useEffect, useRef, type CSSProperties, type ReactNode } from "react";
import { Palette, alpha } from "../../kit";

/**
 * A motion value driven like a SwiftUI `@State` inside `withAnimation`: `to(target, transition)`
 * animates it, `set(v)` jumps. Stops its running animation on unmount.
 */
export function useAnimated(initial: number): [MotionValue<number>, (target: number, t?: Transition) => void, (v: number) => void] {
  const mv = useMotionValue(initial);
  const running = useRef<ReturnType<typeof animate> | null>(null);
  useEffect(() => () => running.current?.stop(), []);
  const to = useCallback(
    (target: number, t?: Transition) => {
      running.current?.stop();
      if (!t) {
        mv.set(target);
        return;
      }
      running.current = animate(mv, target, t);
    },
    [mv],
  );
  const set = useCallback(
    (v: number) => {
      running.current?.stop();
      mv.set(v);
    },
    [mv],
  );
  return [mv, to, set];
}

/** The indigo → violet capsule button many feedback demos trigger from. */
export function PrimaryCapsule({
  children,
  onClick,
  height = 50,
  paddingX = 22,
  style,
}: {
  children: ReactNode;
  onClick?: () => void;
  height?: number;
  paddingX?: number;
  style?: CSSProperties;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
        height,
        padding: `0 ${paddingX}px`,
        borderRadius: height / 2,
        background: Palette.primary,
        color: "#fff",
        fontSize: 17,
        fontWeight: 600,
        lineHeight: "22px",
        boxShadow: `0 6px 12px ${alpha(Palette.indigo, 0.35)}`,
        whiteSpace: "nowrap",
        ...style,
      }}
    >
      {children}
    </button>
  );
}

/** SwiftUI's `predictedEndTranslation` (roughly where a flick would come to rest). */
export const predicted = (translation: number, velocity: number) => translation + velocity * 0.25;

// MARK: - keyframeAnimator tracks

/** One SwiftUI keyframe: Move / Linear (optional timing curve) / Cubic / Spring. */
export type Keyframe =
  | { move: number }
  | { linear: number; d: number; curve?: (p: number) => number }
  | { cubic: number; d: number }
  | { spring: number; d: number; response?: number; damping?: number };

/** SwiftUI spring presets as (response, damping). */
export const SPRINGS = {
  smooth: { response: 0.5, damping: 1 },
  snappy: { response: 0.5, damping: 0.85 },
  bouncy: { response: 0.5, damping: 0.7 },
} as const;

const kfValue = (k: Keyframe) => ("move" in k ? k.move : "linear" in k ? k.linear : "cubic" in k ? k.cubic : k.spring);
const kfDur = (k: Keyframe) => ("move" in k ? 0 : k.d);

/** Total length of a track in seconds. */
export const trackDuration = (frames: Keyframe[]) => frames.reduce((s, k) => s + kfDur(k), 0);

/**
 * Value of a `KeyframeTrack` `t` seconds after the trigger, starting from `initial`.
 * Cubic keyframes interpolate with Catmull-Rom tangents like SwiftUI's; a trailing spring keeps
 * settling past its nominal duration.
 */
export function track(t: number, initial: number, frames: Keyframe[]): number {
  let from = initial;
  let start = 0;
  // Collect the points for tangents.
  const points: { v: number; time: number; cubic: boolean }[] = [{ v: initial, time: 0, cubic: false }];
  {
    let time = 0;
    for (const k of frames) {
      time += kfDur(k);
      points.push({ v: kfValue(k), time, cubic: "cubic" in k });
    }
  }
  for (let i = 0; i < frames.length; i++) {
    const k = frames[i];
    const d = kfDur(k);
    const last = i === frames.length - 1;
    if ("move" in k) {
      from = k.move;
      continue;
    }
    const end = start + d;
    if (t < end || last) {
      const local = t - start;
      const p = d <= 0 ? 1 : Math.min(Math.max(local / d, 0), 1);
      const to = kfValue(k);
      if ("linear" in k) return from + (to - from) * (k.curve ? k.curve(p) : p);
      if ("spring" in k) {
        const r = k.response ?? 0.5;
        const z = k.damping ?? 1;
        const w0 = (2 * Math.PI) / r;
        // springAt inline (kept local to avoid a circular import)
        const e = Math.max(local, 0);
        let s: number;
        if (z < 1) {
          const wd = w0 * Math.sqrt(1 - z * z);
          s = 1 - Math.exp(-z * w0 * e) * (Math.cos(wd * e) + ((z * w0) / wd) * Math.sin(wd * e));
        } else s = 1 - Math.exp(-w0 * e) * (1 + w0 * e);
        return from + (to - from) * s;
      }
      // Cubic: Hermite with Catmull-Rom tangents.
      const a = points[i];
      const b = points[i + 1];
      const prev = i > 0 ? points[i - 1] : null;
      const next = points[i + 2] ?? null;
      const m0 = a.cubic && prev ? ((b.v - prev.v) / Math.max(b.time - prev.time, 1e-6)) * d : 0;
      const m1 = next && points[i + 2]?.cubic ? ((next.v - a.v) / Math.max(next.time - a.time, 1e-6)) * d : 0;
      const u = p;
      const h00 = 2 * u ** 3 - 3 * u ** 2 + 1;
      const h10 = u ** 3 - 2 * u ** 2 + u;
      const h01 = -2 * u ** 3 + 3 * u ** 2;
      const h11 = u ** 3 - u ** 2;
      return h00 * from + h10 * m0 + h01 * to + h11 * m1;
    }
    from = kfValue(k);
    start = end;
  }
  return from;
}

/** UIKit's `.separator` (SwiftUI `Divider`) for the stage scheme. */
export const separator = (scheme: "dark" | "light") => (scheme === "dark" ? "rgb(84 84 88 / 0.6)" : "rgb(60 60 67 / 0.29)");
