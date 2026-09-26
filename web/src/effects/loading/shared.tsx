/**
 * Shared pieces of the Loading category: a rate-continuous phase clock (the Swift files'
 * `SpinnerPhaseClock` / `AmbientPhaseClock`), easing helpers and SwiftUI-like shapes
 * (`Circle().trim(from:to:)`, arbitrary trimmed paths, angular-gradient strokes).
 */
import { animate, useMotionValue, useMotionValueEvent, type Transition } from "motion/react";
import { useCallback, useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";

export const frac = (x: number) => x - Math.floor(x);

/** Cubic ease-in-out on 0…1 (clamped): the Swift helpers' `spinEaseInOut` / `easeInOutCubic`. */
export function easeInOutCubic(x: number): number {
  const u = Math.min(Math.max(x, 0), 1);
  return u < 0.5 ? 4 * u * u * u : 1 - Math.pow(-2 * u + 2, 3) / 2;
}

/**
 * A phase (in cycles, or seconds × rate) that advances at `rate` per second and stays continuous
 * when the rate changes, re-rendering every frame (or at `fps`). `running` false freezes it.
 */
export function usePhase(rate: number, fps?: number, running = true): number {
  const [phase, setPhase] = useState(0);
  const value = useRef(0);
  const rateRef = useRef(rate);
  rateRef.current = rate;
  useEffect(() => {
    if (!running) return;
    let raf = 0;
    let prev = 0;
    let lastEmit = 0;
    const step = (now: number) => {
      if (prev) value.current += ((now - prev) / 1000) * rateRef.current;
      prev = now;
      if (!fps || now - lastEmit >= 1000 / fps - 1) {
        lastEmit = now;
        setPhase(value.current);
      }
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [fps, running]);
  return phase;
}

/** The fps cap for continuously animating demos: 30 in previews (`MotionFrameRate`). */
export const previewFps = (isPreview: boolean) => (isPreview ? 30 : undefined);

/**
 * `Circle().trim(from:to:).stroke(...)` in a `size` × `size` frame. The circle is inscribed in the
 * frame (radius size/2 − inset) and starts at 3 o'clock going clockwise, like SwiftUI's.
 */
export function TrimCircle({
  size,
  lineWidth,
  from = 0,
  to = 1,
  color,
  cap = "round",
  inset = 0,
  rotate = 0,
  style,
  dash,
  dashOffset,
}: {
  size: number;
  lineWidth: number;
  from?: number;
  to?: number;
  color: string;
  cap?: "round" | "butt" | "square";
  inset?: number;
  /** Degrees, clockwise (SwiftUI `rotationEffect`). */
  rotate?: number;
  style?: CSSProperties;
  /** Dash pattern in points (`StrokeStyle(dash:)`); ignores from/to. */
  dash?: number[];
  dashOffset?: number;
}) {
  const r = size / 2 - inset;
  const circumference = 2 * Math.PI * r;
  const len = Math.max(0, Math.min(to, 1) - Math.max(from, 0));
  const visible = dash ? true : len > 0.0005;
  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      style={{ position: "absolute", left: 0, top: 0, overflow: "visible", transform: rotate ? `rotate(${rotate}deg)` : undefined, ...style }}
    >
      {visible && (
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={color}
          strokeWidth={lineWidth}
          strokeLinecap={cap}
          strokeDasharray={dash ? dash.join(" ") : `${len * circumference} ${circumference * 2}`}
          strokeDashoffset={dash ? dashOffset ?? 0 : -Math.max(from, 0) * circumference}
        />
      )}
    </svg>
  );
}

/** An SVG path trimmed to `trim` (0…1) of its length, like `shape.trim(from: 0, to: trim)`. */
export function TrimPath({
  d,
  width,
  height,
  trim = 1,
  from = 0,
  color,
  lineWidth,
  cap = "round",
  join = "round",
  style,
}: {
  d: string;
  width: number;
  height: number;
  trim?: number;
  from?: number;
  color: string;
  lineWidth: number;
  cap?: "round" | "butt" | "square";
  join?: "round" | "miter" | "bevel";
  style?: CSSProperties;
}) {
  const len = trim - from;
  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} style={{ overflow: "visible", ...style }}>
      {len > 0.001 && (
        <path
          d={d}
          pathLength={1}
          fill="none"
          stroke={color}
          strokeWidth={lineWidth}
          strokeLinecap={cap}
          strokeLinejoin={join}
          strokeDasharray={`${len} 2`}
          strokeDashoffset={-from}
        />
      )}
    </svg>
  );
}

/** SVG path of a trimmed circle arc (for CSS masks): start at 3 o'clock, clockwise. */
export function arcPath(cx: number, cy: number, r: number, from: number, to: number): string {
  const a0 = from * 2 * Math.PI;
  const a1 = to * 2 * Math.PI;
  const large = to - from > 0.5 ? 1 : 0;
  if (to - from >= 0.9999) {
    return `M ${cx + r} ${cy} A ${r} ${r} 0 1 1 ${cx - r} ${cy} A ${r} ${r} 0 1 1 ${cx + r} ${cy}`;
  }
  return `M ${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} A ${r} ${r} 0 ${large} 1 ${cx + r * Math.cos(a1)} ${cy + r * Math.sin(a1)}`;
}

/** A CSS mask image (data URL) that is an SVG stroke of `d` in a `w` × `h` box. */
export function strokeMask(d: string, w: number, h: number, lineWidth: number, cap = "round", pad = 0): CSSProperties {
  const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='${w + pad * 2}' height='${h + pad * 2}' viewBox='${-pad} ${-pad} ${w + pad * 2} ${h + pad * 2}'><path d='${d}' fill='none' stroke='black' stroke-width='${lineWidth}' stroke-linecap='${cap}' stroke-linejoin='round'/></svg>`;
  const url = `url("data:image/svg+xml;utf8,${encodeURIComponent(svg)}")`;
  return {
    WebkitMaskImage: url,
    maskImage: url,
    WebkitMaskSize: "100% 100%",
    maskSize: "100% 100%",
    WebkitMaskRepeat: "no-repeat",
    maskRepeat: "no-repeat",
  };
}

/**
 * A trimmed circle stroked with any CSS background (an `AngularGradient` → `conic-gradient`, a
 * `LinearGradient` …): the background is masked by the arc. `size` is the circle's frame.
 */
export function GradientArc({
  size,
  lineWidth,
  from = 0,
  to = 1,
  background,
  cap = "round",
  inset = 0,
  rotate = 0,
  style,
  children,
}: {
  size: number;
  lineWidth: number;
  from?: number;
  to?: number;
  background: string;
  cap?: "round" | "butt";
  inset?: number;
  rotate?: number;
  style?: CSSProperties;
  children?: ReactNode;
}) {
  const pad = lineWidth;
  const len = to - from;
  if (len <= 0.0005) return null;
  const d = arcPath(size / 2, size / 2, size / 2 - inset, from, to);
  // The mask sits on an inner layer so a `filter` (blur, glow) passed in `style` is not clipped by it.
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        top: 0,
        width: size,
        height: size,
        transform: rotate ? `rotate(${rotate}deg)` : undefined,
        ...style,
      }}
    >
      <div
        style={{
          position: "absolute",
          left: -pad,
          top: -pad,
          width: size + pad * 2,
          height: size + pad * 2,
          background,
          ...strokeMask(d, size, size, lineWidth, cap, pad),
        }}
      >
        {children}
      </div>
    </div>
  );
}

/** `conic-gradient` matching SwiftUI's `AngularGradient(colors:, startAngle: 0°)` (0° = 3 o'clock). */
export function angular(colors: string[], startDeg = 0, endDeg = 360): string {
  const n = colors.length;
  const span = endDeg - startDeg;
  const stops = colors.map((c, i) => `${c} ${(n === 1 ? 0 : (i / (n - 1)) * span).toFixed(2)}deg`);
  if (span < 360) stops.push(`${colors[n - 1]} 360deg`);
  return `conic-gradient(from ${90 + startDeg}deg, ${stops.join(", ")})`;
}

/** `Color.primary.opacity(a)` */
export const primary = (a: number) => `rgb(var(--ml-label-rgb) / ${a})`;

/**
 * `keyframeAnimator(trigger:)`: seconds since `trigger` last changed (−1 before it ever changed),
 * re-rendering every frame for `duration` seconds. Unlike the kit's `useElapsed(…, startIdle)` it
 * compares against the initial trigger value, so StrictMode's double effect run cannot start it.
 */
export function useTriggerElapsed(trigger: number | string | boolean, duration: number): number {
  const initial = useRef(trigger);
  const [elapsed, setElapsed] = useState(-1);
  useEffect(() => {
    if (trigger === initial.current) return;
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
  return trigger === initial.current ? -1 : elapsed;
}

/** SF Symbol `mountain.2.fill`: two overlapping rounded peaks with a snow line (no lucide twin). */
export function Mountains2({ size, color = "currentColor", style }: { size: number; color?: string; style?: CSSProperties }) {
  return (
    <svg width={size} height={size * 0.72} viewBox="0 0 36 26" style={style}>
      <g fill={color} stroke={color} strokeWidth={2.4} strokeLinejoin="round">
        <path d="M2 23.5 L11.5 9 L17 17 L22.5 4.5 L34 23.5 Z" />
      </g>
      <path d="M8.2 14 L11.5 9 L14.6 13.4 L12.6 12.6 L10.4 14.2 Z M18.6 11.6 L22.5 4.5 L26.4 11 L24 10.2 L21.4 12.2 Z" fill="rgb(0 0 0 / 0.14)" />
    </svg>
  );
}

/** SF Symbol `sun.horizon.fill`: a half sun with rays resting on the horizon. */
export function SunHorizon({ size, color = "currentColor", style }: { size: number; color?: string; style?: CSSProperties }) {
  return (
    <svg width={size} height={size * 0.75} viewBox="0 0 32 24" style={style}>
      <path d="M8.5 18 A7.5 7.5 0 0 1 23.5 18 Z" fill={color} />
      <g stroke={color} strokeWidth={2.2} strokeLinecap="round">
        <path d="M3 21.5 H29" />
        <path d="M16 3 V5.8" />
        <path d="M6.3 7.3 L8.3 9.3" />
        <path d="M25.7 7.3 L23.7 9.3" />
        <path d="M1.8 15.5 H4.4" />
        <path d="M30.2 15.5 H27.6" />
      </g>
    </svg>
  );
}

/**
 * A number animated like a SwiftUI `@State` changed inside `withAnimation`: `to(target, curve)`
 * starts from the current presentation value. `target` is the model value (what Swift reads back).
 */
export function useAnimatedNumber(initial = 0) {
  const mv = useMotionValue(initial);
  const [value, setValue] = useState(initial);
  const target = useRef(initial);
  useMotionValueEvent(mv, "change", setValue);
  const to = useCallback(
    (next: number, transition: Transition) => {
      target.current = next;
      animate(mv, next, transition);
    },
    [mv],
  );
  return { value, target, to, mv };
}

/** A cancellable async run: `sleep` rejects once `cancel()` was called. */
export function makeRun() {
  let cancelled = false;
  const timers = new Set<number>();
  return {
    get cancelled() {
      return cancelled;
    },
    cancel() {
      cancelled = true;
      timers.forEach((id) => clearTimeout(id));
    },
    sleep(seconds: number) {
      return new Promise<void>((resolve, reject) => {
        if (cancelled) return reject(new Error("cancelled"));
        const id = window.setTimeout(() => {
          timers.delete(id);
          if (cancelled) reject(new Error("cancelled"));
          else resolve();
        }, seconds * 1000);
        timers.add(id);
      });
    },
  };
}
export type Run = ReturnType<typeof makeRun>;

/**
 * `.task(id: run) { … }`: runs `body` whenever `key` changes, cancelling the previous run.
 * Cancellation surfaces as a rejected `sleep`, which is swallowed here.
 */
export function useTask(key: unknown, body: (run: Run) => Promise<void>) {
  const latest = useRef(body);
  latest.current = body;
  useEffect(() => {
    const run = makeRun();
    latest.current(run).catch(() => {});
    return () => run.cancel();
  }, [key]);
}

/** Fake network progress (`simulateProgress`): irregular chunks with a smooth 0.45 s ease each. */
export async function simulateProgress(run: Run, speed: number, n: { target: { current: number }; to: (v: number, t: Transition) => void }) {
  n.to(0, springSmooth(0.35));
  await run.sleep(0.6);
  while (n.target.current < 1) {
    const step = (0.03 + Math.random() * 0.1) * speed;
    n.to(Math.min(1, n.target.current + step), springSmooth(0.45));
    await run.sleep(0.16 + Math.random() * 0.2);
  }
}

/** `.smooth(duration:)` */
export const springSmooth = (duration: number): Transition => {
  const r = Math.max(duration, 0.01);
  return { type: "spring", stiffness: (2 * Math.PI / r) ** 2, damping: (4 * Math.PI) / r, mass: 1, restDelta: 0.0005, restSpeed: 0.001 };
};

/** `SpinnerCaption`: a centred subheadline title over a secondary footnote. */
export function SpinnerCaption({ title, detail }: { title: string; detail: string }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4, textAlign: "center" }}>
      <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{title}</span>
      <span style={{ fontSize: 13, lineHeight: "18px", color: "var(--ml-label2)" }}>{detail}</span>
    </div>
  );
}
