import { useCallback, useEffect, useRef, useState } from "react";

/** Shared bits for the inputs-b ports (Palette tokens not in the kit, text-field styling). */

/** `Palette.primaryStrong` (#4B57E0 → #7A45D6, top-leading → bottom-trailing). */
export const PRIMARY_STRONG = "linear-gradient(135deg, #4B57E0, #7A45D6)";
/** `Palette.accentGlow` */
export const ACCENT_GLOW = "rgb(255 106 42 / 0.32)";

/**
 * A plain SwiftUI `TextField` look for real `<input className="ml-b-input">` elements: no chrome,
 * tertiary placeholder, and text selection / touch re-enabled inside the gesture-free canvas.
 */
export function TextInputStyles() {
  return (
    <style>{`
      .ml-canvas .ml-b-input {
        border: 0; outline: none; background: transparent; padding: 0; margin: 0;
        font-family: inherit; min-width: 0;
        -webkit-user-select: text; user-select: text; touch-action: manipulation;
        caret-color: var(--ml-accent);
      }
      .ml-canvas .ml-b-input::placeholder { color: var(--ml-label3); opacity: 1; }
    `}</style>
  );
}

/**
 * `speaker.wave.3.fill` with a variable value: the three waves light up as `level` passes
 * 0, ⅓ and ⅔ (inactive waves stay dimmed, like SF Symbols' variable rendering).
 */
export function SpeakerWaves({ level, size = 24 }: { level: number; size?: number }) {
  const on = (threshold: number) => (level > threshold ? 1 : 0.3);
  return (
    <svg width={size} height={(size * 20) / 28} viewBox="0 0 28 20" fill="none" style={{ display: "block", overflow: "visible" }}>
      <path d="M1.5 6.6h3.6L10.4 2.2c.8-.7 2.1-.1 2.1 1v13.6c0 1.1-1.3 1.7-2.1 1l-5.3-4.4H1.5A1.5 1.5 0 0 1 0 11.9V8.1a1.5 1.5 0 0 1 1.5-1.5Z" fill="currentColor" />
      <path d="M15.6 6.6a4.6 4.6 0 0 1 0 6.8" stroke="currentColor" strokeWidth={2} strokeLinecap="round" opacity={on(0)} />
      <path d="M18.8 3.8a8.6 8.6 0 0 1 0 12.4" stroke="currentColor" strokeWidth={2} strokeLinecap="round" opacity={on(1 / 3)} />
      <path d="M22 1a12.6 12.6 0 0 1 0 18" stroke="currentColor" strokeWidth={2} strokeLinecap="round" opacity={on(2 / 3)} />
    </svg>
  );
}

/** `@State` that async tasks can read back immediately: `[value, set, ref]`. */
export function useLive<T>(initial: T): [T, (v: T) => void, { current: T }] {
  const [value, setValue] = useState(initial);
  const ref = useRef(value);
  const set = useCallback((v: T) => {
    ref.current = v;
    setValue(v);
  }, []);
  return [value, set, ref];
}

/**
 * Swift `Task { … }` with cancellation: `start(async (sleep) => { if (!(await sleep(0.3))) return; … })`.
 * `sleep` resolves false once the task was cancelled (by `cancel`, a newer `start` or unmount).
 */
export function useTask() {
  const gen = useRef(0);
  const running = useRef(false);
  useEffect(() => () => void (gen.current += 1), []);
  const start = useCallback((fn: (sleep: (s: number) => Promise<boolean>, alive: () => boolean) => Promise<void> | void) => {
    const mine = ++gen.current;
    const alive = () => gen.current === mine;
    const sleep = (s: number) => new Promise<boolean>((r) => window.setTimeout(() => r(alive()), s * 1000));
    running.current = true;
    void Promise.resolve(fn(sleep, alive)).finally(() => {
      if (alive()) running.current = false;
    });
  }, []);
  const cancel = useCallback(() => {
    gen.current += 1;
    running.current = false;
  }, []);
  return { start, cancel, running };
}

/** Unmount-safe `Task.sleep` for fire-and-forget sequences. */
export function useSleep() {
  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => void (mounted.current = false);
  }, []);
  return useCallback((s: number) => new Promise<boolean>((r) => window.setTimeout(() => r(mounted.current), s * 1000)), []);
}

/** SF `lock.fill` / `lock.open.fill`. */
export function LockGlyph({ open, size = 17 }: { open: boolean; size?: number }) {
  return (
    <svg width={size * 0.8} height={size} viewBox="0 0 16 20" style={{ display: "block", overflow: "visible" }}>
      <path
        d={open ? "M11.5 8.5V5.2a3.5 3.5 0 0 1 7 0v1.3" : "M4.5 8.5V5.5a3.5 3.5 0 0 1 7 0v3"}
        fill="none"
        stroke="currentColor"
        strokeWidth={2.1}
        strokeLinecap="round"
      />
      <rect x={1} y={8.2} width={14} height={11} rx={2.4} fill="currentColor" />
    </svg>
  );
}

/** `.contentTransition(.symbolEffect(.replace))`: scale + blur swap (blur on a tween so it never goes negative). */
export const SYMBOL_REPLACE = {
  initial: { scale: 0.4, opacity: 0, filter: "blur(3px)" },
  animate: { scale: 1, opacity: 1, filter: "blur(0px)" },
  exit: { scale: 0.4, opacity: 0, filter: "blur(3px)" },
  transition: {
    type: "spring" as const,
    stiffness: (2 * Math.PI / 0.3) ** 2,
    damping: (4 * Math.PI * 0.85) / 0.3,
    mass: 1,
    filter: { type: "tween" as const, duration: 0.2, ease: "easeOut" as const },
    opacity: { type: "tween" as const, duration: 0.2, ease: "easeOut" as const },
  },
};
