/**
 * Shared pieces for the buttons-a ports: SwiftUI keyframe tracks, `LatchedPress`, long-press gestures,
 * `.blurReplace` swaps, and a few SF-Symbol shapes whose outline matters.
 */
import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useId, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { cubicBezier, springAt, useLatest, type Point } from "../../kit";

// MARK: - Keyframe tracks (keyframeAnimator / KeyframeAnimator)

export type Keyframe =
  | { k: "cubic"; v: number; d: number }
  | { k: "linear"; v: number; d: number }
  | { k: "spring"; v: number; d: number; r: number; z: number }
  | { k: "move"; v: number; d: 0 };

/** `.bouncy` / `.snappy` / `.smooth` as (response, dampingFraction). */
export const BOUNCY: [number, number] = [0.5, 0.7];
export const SNAPPY: [number, number] = [0.5, 0.85];
export const SMOOTH: [number, number] = [0.5, 1];

export const cubicKF = (v: number, d: number): Keyframe => ({ k: "cubic", v, d });
export const linearKF = (v: number, d: number): Keyframe => ({ k: "linear", v, d });
export const springKF = (v: number, d: number, s: [number, number] = BOUNCY): Keyframe => ({ k: "spring", v, d, r: s[0], z: s[1] });
export const moveKF = (v: number): Keyframe => ({ k: "move", v, d: 0 });

export const trackDuration = (frames: Keyframe[]) => frames.reduce((s, f) => s + f.d, 0);

/**
 * Value of a `KeyframeTrack` `t` seconds after its trigger (t < 0: the resting `initial` value).
 * Cubic keyframes form a Catmull-Rom spline through their neighbours (zero velocity where the run
 * starts or ends), spring keyframes run the SwiftUI spring from the previous value, linear ones lerp.
 */
export function track(t: number, initial: number, frames: Keyframe[]): number {
  if (t < 0) return initial;
  const times: number[] = [0];
  const values: number[] = [initial];
  for (const f of frames) {
    times.push(times[times.length - 1] + f.d);
    values.push(f.v);
  }
  // Tangent (units per second) at point i, for cubic segments.
  const tangent = (i: number): number => {
    const into = i > 0 ? frames[i - 1] : null;
    const out = i < frames.length ? frames[i] : null;
    if (!into || !out || into.k !== "cubic" || out.k !== "cubic") return 0;
    const dt = times[i + 1] - times[i - 1];
    return dt > 0 ? (values[i + 1] - values[i - 1]) / dt : 0;
  };
  for (let i = 0; i < frames.length; i++) {
    const f = frames[i];
    const t0 = times[i];
    const t1 = times[i + 1];
    if (t >= t1 || f.k === "move") continue;
    const from = values[i];
    const local = t - t0;
    if (f.k === "linear") return from + (f.v - from) * (f.d > 0 ? local / f.d : 1);
    if (f.k === "spring") return from + (f.v - from) * springAt(local, f.r, f.z);
    // cubic hermite
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
 * `duration` seconds. Like the kit's `useElapsed(…, startIdle)`, but it never restarts on remount
 * (StrictMode) or when `duration` changes mid-flight.
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

// MARK: - LatchedPress

/**
 * DemoKit's `LatchedPress`: a pressed look that lasts at least `minimumHold`, with `onPress` fired
 * `pressDelay` after a real press starts and `onRelease` when it lets go. Spread `handlers` on the
 * button; OR the returned `held` with any forced (autoplay) press.
 */
export function useLatchedPress(opts: { minimumHold?: number; pressDelay?: number; onPress?: () => void; onRelease?: () => void } = {}) {
  const { minimumHold = 0.14, pressDelay = 0 } = opts;
  const latest = useLatest(opts);
  const [held, setHeld] = useState(false);
  const heldRef = useRef(false);
  const down = useRef(false);
  const pressedAt = useRef(0);
  const releaseTimer = useRef(0);
  const pressTimer = useRef(0);
  const hold = Math.max(minimumHold, pressDelay > 0 ? pressDelay + 0.04 : 0);

  useEffect(
    () => () => {
      window.clearTimeout(releaseTimer.current);
      window.clearTimeout(pressTimer.current);
    },
    [],
  );

  const end = useCallback(() => {
    if (!heldRef.current) return;
    heldRef.current = false;
    setHeld(false);
    latest.current.onRelease?.();
  }, [latest]);

  const begin = useCallback(() => {
    window.clearTimeout(releaseTimer.current);
    pressedAt.current = performance.now();
    if (heldRef.current) return;
    heldRef.current = true;
    setHeld(true);
    const onPress = latest.current.onPress;
    if (!onPress) return;
    window.clearTimeout(pressTimer.current);
    if (pressDelay <= 0) onPress();
    else pressTimer.current = window.setTimeout(() => latest.current.onPress?.(), pressDelay * 1000);
  }, [latest, pressDelay]);

  const release = useCallback(() => {
    if (!down.current) return;
    down.current = false;
    window.clearTimeout(releaseTimer.current);
    const remaining = hold - (performance.now() - pressedAt.current) / 1000;
    if (remaining <= 0) end();
    else releaseTimer.current = window.setTimeout(end, remaining * 1000);
  }, [hold, end]);

  const handlers = {
    onPointerDown: (e: React.PointerEvent<HTMLElement>) => {
      if (e.button !== 0) return;
      down.current = true;
      begin();
    },
    onPointerUp: release,
    onPointerLeave: release,
    onPointerCancel: release,
  };
  return { held, handlers };
}

// MARK: - Long press (onLongPressGesture(minimumDuration:maximumDistance:perform:onPressingChanged:))

export function useLongPress(opts: { duration: number; maximumDistance?: number; onPressingChanged: (pressing: boolean) => void; onComplete: () => void }) {
  const latest = useLatest(opts);
  const state = useRef<{ id: number; x: number; y: number; timer: number } | null>(null);
  useEffect(() => () => window.clearTimeout(state.current?.timer), []);

  const stop = (complete: boolean) => {
    const s = state.current;
    if (!s) return;
    window.clearTimeout(s.timer);
    state.current = null;
    if (complete) latest.current.onComplete();
    latest.current.onPressingChanged(false);
  };

  return {
    onPointerDown: (e: React.PointerEvent<HTMLElement>) => {
      if (state.current || e.button !== 0) return;
      e.currentTarget.setPointerCapture(e.pointerId);
      const timer = window.setTimeout(() => stop(true), latest.current.duration * 1000);
      state.current = { id: e.pointerId, x: e.clientX, y: e.clientY, timer };
      latest.current.onPressingChanged(true);
    },
    onPointerMove: (e: React.PointerEvent<HTMLElement>) => {
      const s = state.current;
      if (!s || s.id !== e.pointerId) return;
      const scale = e.currentTarget.getBoundingClientRect().width / (e.currentTarget.offsetWidth || 1) || 1;
      if (Math.hypot(e.clientX - s.x, e.clientY - s.y) / scale > (latest.current.maximumDistance ?? 10)) stop(false);
    },
    onPointerUp: (e: React.PointerEvent<HTMLElement>) => state.current?.id === e.pointerId && stop(false),
    onPointerCancel: (e: React.PointerEvent<HTMLElement>) => state.current?.id === e.pointerId && stop(false),
    style: { touchAction: "none" as const, cursor: "pointer" },
  };
}

// MARK: - Transitions

/** `.transition(.blurReplace)` between keyed children inside a ZStack. */
export function BlurReplace({ id, children, style, align = "center" }: { id: string; children: ReactNode; style?: CSSProperties; align?: "center" | "leading" }) {
  return (
    <div style={{ display: "grid", justifyItems: align === "center" ? "center" : "start", alignItems: "center", ...style }}>
      <AnimatePresence initial={false}>
        <motion.div
          key={id}
          initial={{ opacity: 0, scale: 0.8, filter: "blur(6px)" }}
          animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
          exit={{ opacity: 0, scale: 0.8, filter: "blur(6px)" }}
          transition={{ type: "spring", stiffness: (2 * Math.PI / 0.5) ** 2, damping: (4 * Math.PI) / 0.5, mass: 1 }}
          style={{ gridArea: "1 / 1", display: "flex", alignItems: "center", whiteSpace: "nowrap" }}
        >
          {children}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}

/** `.contentTransition(.symbolEffect(.replace))`: the old symbol scales down and blurs out as the new one pops in. */
export function SymbolReplace({ id, children, style }: { id: string; children: ReactNode; style?: CSSProperties }) {
  return (
    <span style={{ display: "inline-grid", placeItems: "center", ...style }}>
      <AnimatePresence initial={false}>
        <motion.span
          key={id}
          initial={{ scale: 0.3, opacity: 0, filter: "blur(4px)" }}
          animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
          exit={{ scale: 0.3, opacity: 0, filter: "blur(4px)" }}
          transition={{ type: "spring", stiffness: (2 * Math.PI / 0.35) ** 2, damping: (4 * Math.PI * 0.8) / 0.35, mass: 1 }}
          style={{ gridArea: "1 / 1", display: "grid", placeItems: "center" }}
        >
          {children}
        </motion.span>
      </AnimatePresence>
    </span>
  );
}

// MARK: - Misc

/** The app's `sportHash`: deterministic 0..<1. */
export function sportHash(x: number): number {
  const n = Math.sin(x * 12.9898 + 78.233) * 43758.5453;
  return n - Math.floor(n);
}

export const easeInOutCurve = cubicBezier(0.42, 0, 0.58, 1);

/** Gradient hairline inside a rounded shape (`shape.strokeBorder(gradient, lineWidth:)`). */
export function GradientBorder({ radius, width, gradient, style }: { radius: number | string; width: number; gradient: string; style?: CSSProperties }) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: radius,
        padding: width,
        background: gradient,
        WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
        WebkitMaskComposite: "xor",
        mask: "linear-gradient(#000 0 0) content-box exclude, linear-gradient(#000 0 0)",
        pointerEvents: "none",
        ...style,
      }}
    />
  );
}

/** SF Symbols `heart` / `heart.fill` outline in a 24 × 24 box (fills ~20 × 18.5 like the symbol). */
export const HEART_PATH =
  "M12 20.6 C11.7 20.6 11.4 20.5 11.1 20.3 C6.6 17.4 2.2 13.4 2.2 8.9 C2.2 5.8 4.4 3.5 7.3 3.5 C9.3 3.5 11 4.6 12 6.3 C13 4.6 14.7 3.5 16.7 3.5 C19.6 3.5 21.8 5.8 21.8 8.9 C21.8 13.4 17.4 17.4 12.9 20.3 C12.6 20.5 12.3 20.6 12 20.6 Z";

export function HeartGlyph({
  size,
  filled,
  color = "currentColor",
  strokeWidth = 2,
  style,
}: {
  size: number;
  filled: boolean;
  color?: string;
  strokeWidth?: number;
  style?: CSSProperties;
}) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={{ overflow: "visible", ...style }}>
      <path
        d={HEART_PATH}
        fill={filled ? color : "none"}
        stroke={filled ? "none" : color}
        strokeWidth={strokeWidth}
        strokeLinejoin="round"
      />
    </svg>
  );
}

/** Pointer position inside the element, in its unscaled points. */
export function pointIn(e: { clientX: number; clientY: number }, el: HTMLElement): Point {
  const rect = el.getBoundingClientRect();
  const scale = rect.width / (el.offsetWidth || 1) || 1;
  return { x: (e.clientX - rect.left) / scale, y: (e.clientY - rect.top) / scale };
}

/** Seconds since mount, re-rendering every frame for `duration` seconds (a view animating in `onAppear`). */
export function useMountClock(duration: number): number {
  const [elapsed, setElapsed] = useState(0);
  const born = useRef<number | null>(null);
  useEffect(() => {
    if (born.current === null) born.current = performance.now();
    const began = born.current;
    let raf = 0;
    const step = (now: number) => {
      const e = (now - began) / 1000;
      setElapsed(Math.min(e, duration));
      if (e < duration) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [duration]);
  return elapsed;
}

/** A document-unique id usable inside `url(#…)`. */
export function useSvgID(prefix: string): string {
  return prefix + "-" + useId().replace(/[^a-zA-Z0-9]/g, "");
}

/** A button with the app's `SportPressStyle(scale:dim:)`: sinks and dims while pressed. */
export function PressButton({
  scale = 0.96,
  dim = 0.08,
  onClick,
  children,
  style,
}: {
  scale?: number;
  dim?: number;
  onClick: (e: React.MouseEvent) => void;
  children: ReactNode;
  style?: CSSProperties;
}) {
  const [pressed, setPressed] = useState(false);
  return (
    <motion.button
      type="button"
      onClick={onClick}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      onPointerCancel={() => setPressed(false)}
      animate={{ scale: pressed ? scale : 1, filter: pressed ? `brightness(${1 - dim * 1.6})` : "brightness(1)" }}
      transition={{ type: "spring", stiffness: (2 * Math.PI / 0.3) ** 2, damping: (4 * Math.PI * 0.7) / 0.3, mass: 1 }}
      style={style}
    >
      {children}
    </motion.button>
  );
}

/** SF Symbols `checkmark.circle.fill`. */
export function CheckCircleFill({ size, color }: { size: number; color: string }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={{ flexShrink: 0 }}>
      <circle cx="12" cy="12" r="10.5" fill={color} />
      <path d="M7.4 12.3l3.1 3.1 6.1-6.5" fill="none" stroke="#fff" strokeWidth={2.3} strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
