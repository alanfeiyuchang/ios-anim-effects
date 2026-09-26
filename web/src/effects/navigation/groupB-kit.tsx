/**
 * Shared pieces for the group-B Navigation ports: keyframe tracks (`keyframeAnimator`), a StrictMode-safe
 * elapsed clock, the web twin of `pageSafeHorizontalDrag`, and SF-Symbol-like filled glyphs whose shape
 * matters in tab bars.
 */
import { useEffect, useId, useRef, useState, type CSSProperties } from "react";
import { springAt, useLatest, usePan, type PanState } from "../../kit";

// MARK: - Keyframe tracks

export type Keyframe =
  | { k: "cubic"; v: number; d: number }
  | { k: "linear"; v: number; d: number }
  | { k: "spring"; v: number; d: number; r: number; z: number };

/** `.bouncy` as (response, dampingFraction). */
export const BOUNCY: [number, number] = [0.5, 0.7];

export const cubicKF = (v: number, d: number): Keyframe => ({ k: "cubic", v, d });
export const linearKF = (v: number, d: number): Keyframe => ({ k: "linear", v, d });
export const springKF = (v: number, d: number, s: [number, number] = BOUNCY): Keyframe => ({ k: "spring", v, d, r: s[0], z: s[1] });

export const trackDuration = (frames: Keyframe[]) => frames.reduce((s, f) => s + f.d, 0);

/**
 * Value of a `KeyframeTrack` `t` seconds after its trigger (t < 0: `initial`). Cubic keyframes are a
 * Catmull-Rom spline through their neighbours (zero velocity at the ends of a cubic run), spring
 * keyframes run the SwiftUI spring from the previous value, linear ones lerp.
 */
export function track(t: number, initial: number, frames: Keyframe[]): number {
  if (t < 0) return initial;
  const times: number[] = [0];
  const values: number[] = [initial];
  for (const f of frames) {
    times.push(times[times.length - 1] + f.d);
    values.push(f.v);
  }
  const tangent = (i: number): number => {
    const into = i > 0 ? frames[i - 1] : null;
    const out = i < frames.length ? frames[i] : null;
    if (!into || !out || into.k !== "cubic" || out.k !== "cubic") return 0;
    const dt = times[i + 1] - times[i - 1];
    return dt > 0 ? (values[i + 1] - values[i - 1]) / dt : 0;
  };
  for (let i = 0; i < frames.length; i++) {
    const f = frames[i];
    const t1 = times[i + 1];
    if (t >= t1) continue;
    const from = values[i];
    const local = t - times[i];
    if (f.k === "linear") return from + (f.v - from) * (f.d > 0 ? local / f.d : 1);
    if (f.k === "spring") return from + (f.v - from) * springAt(local, f.r, f.z);
    const h = f.d;
    const s = h > 0 ? local / h : 1;
    const m0 = tangent(i) * h;
    const m1 = tangent(i + 1) * h;
    const s2 = s * s;
    const s3 = s2 * s;
    return (2 * s3 - 3 * s2 + 1) * from + (s3 - 2 * s2 + s) * m0 + (-2 * s3 + 3 * s2) * f.v + (s3 - s2) * m1;
  }
  return frames.length ? frames[frames.length - 1].v : initial;
}

/**
 * Seconds since `trigger` last changed (−1 before the first change), re-rendering every frame for
 * `duration` seconds. Unlike the kit's `useElapsed(…, true)` it survives StrictMode's double effects.
 */
export function useSince(trigger: number, duration: number): number {
  const [elapsed, setElapsed] = useState(-1);
  const start = useRef<{ trigger: number; at: number } | null>(null);
  const initial = useRef(trigger);
  const dur = useLatest(duration);
  useEffect(() => {
    if (trigger === initial.current && start.current === null) return;
    if (!start.current || start.current.trigger !== trigger) start.current = { trigger, at: performance.now() };
    const began = start.current.at;
    let raf = 0;
    const step = (now: number) => {
      const e = (now - began) / 1000;
      setElapsed(Math.min(e, dur.current));
      if (e < dur.current) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [trigger, dur]);
  return elapsed;
}

// MARK: - pageSafeHorizontalDrag

/**
 * `pageSafeHorizontalDrag(minimumDistance:onChanged:onEnded:)`: engages only once the drag has travelled
 * mostly horizontally, then follows the finger in any direction. `onEnd(null)` = system cancellation.
 */
export function useHorizontalDrag(
  handlers: { onChange?: (s: PanState) => void; onEnd?: (s: PanState | null) => void },
  minimumDistance = 10,
) {
  const engaged = useRef(false);
  const latest = useLatest(handlers);
  return usePan(
    {
      onChange: (s) => {
        if (!engaged.current) {
          if (!(Math.abs(s.translation.x) > Math.abs(s.translation.y))) return;
          engaged.current = true;
        }
        latest.current.onChange?.(s);
      },
      onEnd: (s) => {
        if (!engaged.current) return;
        engaged.current = false;
        latest.current.onEnd?.(s);
      },
    },
    minimumDistance,
  );
}

// MARK: - Glyphs (filled SF Symbols whose silhouette matters)

export type GlyphName =
  | "house.fill"
  | "chart.bar.fill"
  | "bell.fill"
  | "person.fill"
  | "bag.fill"
  | "play.rectangle.fill"
  | "person.crop.circle.fill"
  | "music.note"
  | "square.stack.fill"
  | "dot.radiowaves";

/** A filled SF-Symbol look-alike drawn at `size` points in `currentColor`. */
export function Glyph({ name, size, style }: { name: GlyphName; size: number; style?: CSSProperties }) {
  const mask = useId();
  const common = { width: size, height: size, viewBox: "0 0 24 24", style: { display: "block", overflow: "visible", ...style } } as const;
  switch (name) {
    case "house.fill":
      return (
        <svg {...common}>
          <path
            fillRule="evenodd"
            fill="currentColor"
            stroke="currentColor"
            strokeWidth={1.2}
            strokeLinejoin="round"
            d="M12 2.6 L1.8 11.2 L3.4 12.6 L4.4 11.8 V20 A1.6 1.6 0 0 0 6 21.6 H18 A1.6 1.6 0 0 0 19.6 20 V11.8 L20.6 12.6 L22.2 11.2 Z M9.8 21.6 V16 A1 1 0 0 1 10.8 15 H13.2 A1 1 0 0 1 14.2 16 V21.6 Z"
          />
        </svg>
      );
    case "chart.bar.fill":
      return (
        <svg {...common}>
          <rect x={2.5} y={13} width={5} height={8.5} rx={1.3} fill="currentColor" />
          <rect x={9.5} y={7.5} width={5} height={14} rx={1.3} fill="currentColor" />
          <rect x={16.5} y={2.5} width={5} height={19} rx={1.3} fill="currentColor" />
        </svg>
      );
    case "bell.fill":
      return (
        <svg {...common}>
          <path
            fill="currentColor"
            stroke="currentColor"
            strokeWidth={1.4}
            strokeLinejoin="round"
            d="M3.3 16.8 A1 1 0 0 0 4 18.4 H20 A1 1 0 0 0 20.7 16.8 C19.3 15.4 18.2 13.9 18.2 9.4 A6.2 6.2 0 0 0 5.8 9.4 C5.8 13.9 4.7 15.4 3.3 16.8 Z"
          />
          <path fill="currentColor" d="M9.2 19.6 H14.8 A2.8 2.6 0 0 1 9.2 19.6 Z" />
        </svg>
      );
    case "person.fill":
      return (
        <svg {...common}>
          <circle cx={12} cy={7} r={4.6} fill="currentColor" />
          <path fill="currentColor" d="M3.2 20.2 C3.2 15.9 7.1 13.3 12 13.3 C16.9 13.3 20.8 15.9 20.8 20.2 A1.4 1.4 0 0 1 19.4 21.6 H4.6 A1.4 1.4 0 0 1 3.2 20.2 Z" />
        </svg>
      );
    case "bag.fill":
      return (
        <svg {...common}>
          <path fill="none" stroke="currentColor" strokeWidth={1.9} strokeLinecap="round" d="M8.4 8.5 V6.6 A3.6 3.6 0 0 1 15.6 6.6 V8.5" />
          <path fill="currentColor" d="M4.6 7.4 H19.4 L20.4 19.8 A2 2 0 0 1 18.4 21.9 H5.6 A2 2 0 0 1 3.6 19.8 Z" />
        </svg>
      );
    case "play.rectangle.fill":
      return (
        <svg {...common}>
          <path
            fillRule="evenodd"
            fill="currentColor"
            d="M5 4 H19 A3 3 0 0 1 22 7 V17 A3 3 0 0 1 19 20 H5 A3 3 0 0 1 2 17 V7 A3 3 0 0 1 5 4 Z M10 8.4 V15.6 L16 12 Z"
          />
        </svg>
      );
    case "person.crop.circle.fill":
      return (
        <svg {...common}>
          <defs>
            <mask id={mask}>
              <rect x={0} y={0} width={24} height={24} fill="#fff" />
              <circle cx={12} cy={9.4} r={3.7} fill="#000" />
              <path fill="#000" d="M5.6 18.6 C6.9 16.1 9.2 14.9 12 14.9 C14.8 14.9 17.1 16.1 18.4 18.6 A8.6 8.6 0 0 1 5.6 18.6 Z" />
            </mask>
          </defs>
          <circle cx={12} cy={12} r={10.4} fill="currentColor" mask={`url(#${mask})`} />
        </svg>
      );
    case "music.note":
      return (
        <svg {...common}>
          <ellipse cx={8.2} cy={18.2} rx={3.9} ry={3.3} fill="currentColor" />
          <rect x={10.2} y={2.6} width={2.1} height={15.6} rx={0.6} fill="currentColor" />
          <path fill="currentColor" d="M11.4 2.6 C12.6 5.4 17.8 5.6 17.8 10.6 C16.8 8.2 13.8 7.6 11.4 7.8 Z" />
        </svg>
      );
    case "square.stack.fill":
      return (
        <svg {...common}>
          <rect x={7} y={1.8} width={10} height={1.8} rx={0.9} fill="currentColor" />
          <rect x={4.6} y={5} width={14.8} height={2} rx={1} fill="currentColor" />
          <rect x={2.4} y={8.6} width={19.2} height={13.6} rx={3} fill="currentColor" />
        </svg>
      );
    case "dot.radiowaves":
      return (
        <svg {...common}>
          <circle cx={12} cy={12} r={2.4} fill="currentColor" />
          <g fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round">
            <path d="M8.2 8.2 A5.4 5.4 0 0 0 8.2 15.8" />
            <path d="M15.8 8.2 A5.4 5.4 0 0 1 15.8 15.8" />
            <path d="M5 5 A9.9 9.9 0 0 0 5 19" />
            <path d="M19 5 A9.9 9.9 0 0 1 19 19" />
          </g>
        </svg>
      );
  }
}

/** SwiftUI's `Color.gradient`: the colour, a touch lighter at the top. */
export const colorGradient = (color: string) => `linear-gradient(180deg, color-mix(in srgb, ${color} 84%, white), ${color})`;
