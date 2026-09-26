/**
 * Shared pieces of the Charts category (ChartEffects.swift): `ChartTapCue`, the `ChartEntrance`
 * replay, and small numeric helpers used by several chart demos.
 */
import { Hand } from "lucide-react";
import { useEffect, useMemo, useReducer, useRef } from "react";
import { animate, motion, motionValue, type MotionValue, type Transition } from "motion/react";
import { Palette, useLatest, useStageRuntime, type DemoContext } from "../../kit";

/**
 * `ChartEntrance.replay(isStill:reset:then:)`: chart demos start empty and play their entrance a
 * few frames after appearing (0.05 s). On the web the component's initial state is the "reset"
 * state, so this only schedules `play` once on mount.
 */
export function useChartEntrance(play: () => void, delay = 0.05) {
  const latest = useLatest(play);
  const fired = useRef(false);
  useEffect(() => {
    if (fired.current) return;
    const id = window.setTimeout(() => {
      fired.current = true;
      latest.current();
    }, delay * 1000);
    return () => window.clearTimeout(id);
  }, [delay, latest]);
}

/**
 * `ChartTapCue`: the bottom hint of tap-to-morph charts (footnote, medium, secondary). With Reduce
 * Motion a hand glyph pulses three times in front of it, since the arrival intro is skipped.
 */
export function ChartTapCue({ ctx, en, zh, style }: { ctx: DemoContext; en: string; zh: string; style?: React.CSSProperties }) {
  const { reduceMotion } = useStageRuntime();
  if (ctx.isPreview) return null;
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 5,
        fontSize: 13,
        lineHeight: "18px",
        fontWeight: 500,
        color: Palette.secondaryLabel,
        ...style,
      }}
    >
      {reduceMotion && (
        <motion.span
          animate={{ opacity: [1, 0.35, 1, 0.35, 1, 0.35, 1] }}
          transition={{ duration: 2.4 }}
          style={{ display: "grid" }}
        >
          <Hand size={13} fill="currentColor" strokeWidth={1.5} />
        </motion.span>
      )}
      <span>{ctx.t(en, zh)}</span>
    </div>
  );
}

/** Swift's `Double.random(in: lo...hi)`. */
export const randomIn = (lo: number, hi: number) => lo + Math.random() * (hi - lo);
/** Swift's `Int.random(in: lo...hi)` (inclusive). */
export const randomInt = (lo: number, hi: number) => lo + Math.floor(Math.random() * (hi - lo + 1));

/**
 * Swift Charts' default look, measured from the app's recordings (dark stage): dashed hairline
 * grid, secondary axis labels.
 */
export const swiftCharts = {
  /** `AxisGridLine` default / `StrokeStyle(lineWidth: 0.5, dash: [3, 4])` colour. */
  grid: Palette.labelAlpha(0.22),
  /** Default `AxisValueLabel` font size (caption2-ish) and colour. */
  labelSize: 11,
  labelColor: Palette.secondaryLabel,
};

/**
 * A fixed-size array of animatable numbers (several `@State` values each animated by its own
 * `withAnimation`), re-rendering the component once per frame while any of them moves.
 *
 *     const grow = useAnimatedNumbers(6, 0);
 *     grow.to(i, 1, delayed(spring(0.55, 0.75), i * 0.06));
 *     grow.get(i)
 */
export function useAnimatedNumbers(count: number, initial: number | number[]) {
  const [, force] = useReducer((n: number) => n + 1, 0);
  const frame = useRef(0);
  const mvs = useMemo<MotionValue<number>[]>(
    () => Array.from({ length: count }, (_, i) => motionValue(Array.isArray(initial) ? initial[i] ?? 0 : initial)),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [count],
  );
  useEffect(() => {
    const unsubs = mvs.map((mv) =>
      mv.on("change", () => {
        if (frame.current) return;
        frame.current = requestAnimationFrame(() => {
          frame.current = 0;
          force();
        });
      }),
    );
    return () => {
      unsubs.forEach((u) => u());
      cancelAnimationFrame(frame.current);
      frame.current = 0;
      mvs.forEach((mv) => mv.stop());
    };
  }, [mvs]);
  return useMemo(
    () => ({
      mvs,
      get: (i: number) => mvs[i].get(),
      all: () => mvs.map((mv) => mv.get()),
      to: (i: number, target: number, transition: Transition) => animate(mvs[i], target, transition),
      set: (i: number, value: number) => {
        mvs[i].stop();
        mvs[i].set(value);
      },
    }),
    [mvs],
  );
}
