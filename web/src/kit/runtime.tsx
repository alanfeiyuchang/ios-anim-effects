/**
 * Autoplay, clocks and small React helpers shared by every demo.
 */
import { createContext, useCallback, useContext, useEffect, useLayoutEffect, useRef, useState } from "react";
import { useSilently } from "./haptics";

export interface StageRuntime {
  /** Master switch for autoplay loops (off when a preview scrolls away or motion is reduced). */
  autoplayEnabled: boolean;
  /** Detail stage: an inactive `useAutoplay` plays its action once shortly after arrival. */
  introPlay: boolean;
  reduceMotion: boolean;
}

export const StageRuntimeContext = createContext<StageRuntime>({
  autoplayEnabled: true,
  introPlay: false,
  reduceMotion: false,
});

export const useStageRuntime = () => useContext(StageRuntimeContext);

/** Keeps the latest value in a ref (for callbacks fired by timers). */
export function useLatest<T>(value: T) {
  const ref = useRef(value);
  useLayoutEffect(() => {
    ref.current = value;
  });
  return ref;
}

/**
 * Swift's `.autoplay(active, every:, delay:, intro:) { action }`.
 * Calls `action` every `every` seconds while `active` (grid previews), silently. On the detail
 * stage (`active` false) it plays `action` once 0.9 s after arrival unless `intro` is false.
 */
export function useAutoplay(
  active: boolean,
  action: () => void,
  opts: { every?: number; delay?: number; intro?: boolean } = {},
) {
  const { every = 1.8, delay = 0.6, intro = true } = opts;
  const { autoplayEnabled, introPlay, reduceMotion } = useStageRuntime();
  const silently = useSilently();
  const latest = useLatest(action);
  const mode = active ? (autoplayEnabled ? "loop" : "idle") : intro && introPlay && !reduceMotion ? "intro" : "idle";

  useEffect(() => {
    if (mode === "idle") return;
    let timer = 0;
    let cancelled = false;
    const run = () => silently(() => latest.current());
    if (mode === "intro") {
      timer = window.setTimeout(() => !cancelled && run(), 900);
    } else {
      const loop = () => {
        if (cancelled) return;
        run();
        timer = window.setTimeout(loop, every * 1000);
      };
      timer = window.setTimeout(loop, delay * 1000);
    }
    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [mode, every, delay, silently, latest]);
}

/**
 * `TimelineView(.animation)`: seconds since mount, re-rendering every frame while `running`.
 * Previews tick at 30 fps like the app (`MotionFrameRate`). Pass `paused` to freeze.
 */
export function useClock(running = true, fps?: number): number {
  const [t, setT] = useState(0);
  const start = useRef<number | null>(null);
  const pausedAt = useRef(0);
  useEffect(() => {
    if (!running) {
      start.current = null;
      return;
    }
    let raf = 0;
    let last = 0;
    const step = (now: number) => {
      if (start.current === null) start.current = now - pausedAt.current * 1000;
      const elapsed = (now - start.current) / 1000;
      if (!fps || now - last >= 1000 / fps - 1) {
        last = now;
        pausedAt.current = elapsed;
        setT(elapsed);
      }
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [running, fps]);
  return t;
}

/** `Task.sleep` loops and one-off delays tied to the component's lifetime. */
export function useTimeouts() {
  const timers = useRef<number[]>([]);
  useEffect(() => () => timers.current.forEach((id) => window.clearTimeout(id)), []);
  const after = useCallback((seconds: number, fn: () => void) => {
    const id = window.setTimeout(() => {
      timers.current = timers.current.filter((x) => x !== id);
      fn();
    }, seconds * 1000);
    timers.current.push(id);
    return () => window.clearTimeout(id);
  }, []);
  const clearAll = useCallback(() => {
    timers.current.forEach((id) => window.clearTimeout(id));
    timers.current = [];
  }, []);
  return { after, clearAll };
}

/** A counter you bump to replay something keyed on it (Swift's `.id(counter)` / `trigger:`). */
export function useTrigger(): [number, () => void] {
  const [n, setN] = useState(0);
  return [n, useCallback(() => setN((v) => v + 1), [])];
}

/** Deterministic pseudo-random 0..<1 (the app's `hash` helper). */
export function hash(index: number, salt = 0): number {
  const x = Math.sin(index * 12.9898 + salt * 78.233) * 43758.5453;
  return x - Math.floor(x);
}

/**
 * `keyframeAnimator(trigger:)` / one-shot timelines: seconds elapsed since `trigger` last changed,
 * re-rendering every frame for `duration` seconds (then it stays at `duration`). Returns -1 before
 * the first trigger when `startIdle` is set, so the timeline can show its resting state.
 */
export function useElapsed(trigger: unknown, duration: number, startIdle = false): number {
  const [elapsed, setElapsed] = useState(startIdle ? -1 : 0);
  // Restart at 0 in the same render the trigger changes, so the frame before the first rAF tick does
  // not show the previous run's end state.
  const [seen, setSeen] = useState(trigger);
  if (!Object.is(seen, trigger)) {
    setSeen(trigger);
    setElapsed(0);
  }
  // Compare with the trigger seen at mount rather than a "first run" flag: StrictMode runs the effect
  // twice on mount, and the second run must stay idle too.
  const idleTrigger = useRef<{ value: unknown } | null>(startIdle ? { value: trigger } : null);
  useEffect(() => {
    if (idleTrigger.current) {
      if (Object.is(idleTrigger.current.value, trigger)) return;
      idleTrigger.current = null;
    }
    let raf = 0;
    const start = performance.now();
    const step = (now: number) => {
      const e = Math.min((now - start) / 1000, duration);
      setElapsed(e);
      if (e < duration) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [trigger, duration, startIdle]);
  return elapsed;
}
