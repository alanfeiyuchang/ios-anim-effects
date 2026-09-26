/**
 * Haptics on the web: phones' browsers cannot drive the Taptic Engine (iOS Safari has no vibration
 * API at all), so every haptic becomes a small, quick shake of the whole demo stage, like a phone
 * buzzing in the hand. Same call sites as Swift's `Haptics`:
 *
 *     const haptics = useHaptics();
 *     haptics.tap("medium"); haptics.success(); haptics.selection();
 *
 * Calls made while an autoplay action runs (grid previews, the detail intro) stay silent, exactly
 * like the app, where simulated taps never buzz.
 */
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, type ReactNode } from "react";

export type ImpactStyle = "light" | "medium" | "heavy" | "soft" | "rigid";

export interface Haptics {
  tap(style?: ImpactStyle): void;
  success(): void;
  error(): void;
  warning(): void;
  selection(): void;
}

/** Peak offset (canvas px) per impact style. */
const IMPACT: Record<ImpactStyle, number> = { soft: 1.3, light: 1.6, medium: 2.4, rigid: 2.6, heavy: 3.4 };

type Pulse = { at: number; amp: number };

interface HapticRuntime {
  fire(pulses: Pulse[]): void;
  muted: { current: boolean };
}

const noopRuntime: HapticRuntime = { fire: () => {}, muted: { current: false } };
const HapticContext = createContext<HapticRuntime>(noopRuntime);

/** One decaying buzz (-1…1), the same curve the trailer uses to shake its phone. */
const buzz = (e: number) => (e > 0 && e < 0.35 ? Math.sin(e * 95) * Math.exp(-e * 13) : 0);

/**
 * Wraps the demo canvas; shakes it on every haptic. `enabled` is false for grid previews.
 */
export function HapticStage({ enabled, children }: { enabled: boolean; children: ReactNode }) {
  const node = useRef<HTMLDivElement>(null);
  const pulses = useRef<{ start: number; amp: number }[]>([]);
  const frame = useRef(0);
  const muted = useRef(false);

  const tick = useCallback(() => {
    const now = performance.now() / 1000;
    pulses.current = pulses.current.filter((p) => now - p.start < 0.4);
    let x = 0;
    for (const p of pulses.current) x += p.amp * buzz(now - p.start);
    if (node.current) node.current.style.transform = x === 0 ? "" : `translate3d(${x.toFixed(2)}px,0,0)`;
    frame.current = pulses.current.length > 0 ? requestAnimationFrame(tick) : 0;
  }, []);

  const runtime = useMemo<HapticRuntime>(
    () => ({
      muted,
      fire(list) {
        if (!enabled || muted.current) return;
        const now = performance.now() / 1000;
        for (const p of list) pulses.current.push({ start: now + p.at, amp: p.amp });
        if (!frame.current) frame.current = requestAnimationFrame(tick);
      },
    }),
    [enabled, tick],
  );

  useEffect(() => () => cancelAnimationFrame(frame.current), []);

  return (
    <HapticContext.Provider value={runtime}>
      <div ref={node} style={{ width: "100%", height: "100%", willChange: "transform" }}>
        {children}
      </div>
    </HapticContext.Provider>
  );
}

export function useHaptics(): Haptics {
  const runtime = useContext(HapticContext);
  return useMemo<Haptics>(
    () => ({
      tap: (style = "light") => runtime.fire([{ at: 0, amp: IMPACT[style] }]),
      selection: () => runtime.fire([{ at: 0, amp: 1 }]),
      success: () => runtime.fire([{ at: 0, amp: 2.2 }, { at: 0.11, amp: 1.6 }]),
      warning: () => runtime.fire([{ at: 0, amp: 2.2 }, { at: 0.14, amp: 2.2 }]),
      error: () => runtime.fire([{ at: 0, amp: 2.4 }, { at: 0.08, amp: 2.4 }, { at: 0.16, amp: 1.8 }]),
    }),
    [runtime],
  );
}

/** Runs `action` with haptics muted (autoplay: simulated taps never buzz). */
export function useSilently(): (action: () => void) => void {
  const runtime = useContext(HapticContext);
  return useCallback(
    (action) => {
      const was = runtime.muted.current;
      runtime.muted.current = true;
      try {
        action();
      } finally {
        runtime.muted.current = was;
      }
    },
    [runtime],
  );
}
