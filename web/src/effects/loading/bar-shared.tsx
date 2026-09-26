/** Shared pieces of Loading+BarVariations.swift: the fake-progress loop and the header row. */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { CircleCheck, type LucideIcon } from "lucide-react";
import { NumericText, Palette, anim, cubicBezier, springAt } from "../../kit";
import type { Run } from "./shared";
import { springSmooth } from "./shared";

/**
 * `barVarSimulate`: 0 (smooth 0.35 s), wait 0.7 s, then irregular 4–14 % chunks (smooth 0.45 s)
 * every 0.22–0.42 s. `set(value, transition)` changes the model value; `get` reads it back.
 */
export async function barVarSimulate(run: Run, speed: number, get: () => number, set: (v: number, t: Transition) => void, onStep?: () => void) {
  set(0, springSmooth(0.35));
  await run.sleep(0.7);
  while (get() < 1) {
    const step = (0.04 + Math.random() * 0.1) * speed;
    set(Math.min(1, get() + step), springSmooth(0.45));
    onStep?.();
    await run.sleep(0.22 + Math.random() * 0.2);
  }
}

/** `BarVarHeader`: a Label whose symbol swaps to a green check when done, and a rolling percentage. */
export function BarVarHeader({ icon: Icon, title, value, done }: { icon: LucideIcon; title: string; value: number; done: boolean }) {
  const percent = Math.round(value * 100);
  return (
    <div style={{ display: "flex", alignItems: "center", fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>
      <span style={{ display: "flex", alignItems: "center", gap: 7, color: done ? Palette.green : Palette.label, transition: "color 0.3s" }}>
        <span style={{ position: "relative", width: 19, height: 19, display: "grid", placeItems: "center" }}>
          <AnimatePresence mode="popLayout" initial={false}>
            <motion.span
              key={done ? "done" : "icon"}
              initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
              exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              transition={anim.snappyD(0.3)}
              style={{ display: "grid" }}
            >
              {done ? <CircleCheck size={18} fill="currentColor" stroke="var(--ml-elevated)" strokeWidth={2.2} /> : <Icon size={17} fill="currentColor" strokeWidth={1.4} />}
            </motion.span>
          </AnimatePresence>
        </span>
        {title}
      </span>
      <span style={{ flex: 1 }} />
      <span style={{ color: Palette.secondaryLabel }}>
        <NumericText value={percent} text={`${percent}%`} />
      </span>
    </div>
  );
}

/** Evenly spaced hex stops interpolated at `f` in sRGB. */
export function stopColor(stops: number[], f: number, opacity = 1): string {
  const u = Math.min(Math.max(f, 0), 1) * (stops.length - 1);
  const i = Math.min(Math.floor(u), stops.length - 2);
  const t = u - i;
  const ch = (v: number, s: number) => (v >> s) & 0xff;
  const m = (s: number) => Math.round(ch(stops[i], s) + (ch(stops[i + 1], s) - ch(stops[i], s)) * t);
  return `rgb(${m(16)} ${m(8)} ${m(0)} / ${opacity})`;
}

/** `ringVarSimulate` (Loading+RingVariations.swift): 5–15 % chunks every 0.3–0.5 s after a 0.7 s wait. */
export async function ringVarSimulate(
  run: Run,
  speed: number,
  get: () => number,
  set: (v: number, t: Transition) => void,
  animation: Transition = springSmooth(0.45),
  onStep?: () => void,
) {
  set(0, springSmooth(0.35));
  await run.sleep(0.7);
  while (get() < 1) {
    const step = (0.05 + Math.random() * 0.1) * speed;
    set(Math.min(1, get() + step), animation);
    onStep?.();
    await run.sleep(0.3 + Math.random() * 0.2);
  }
}

/** One-shot keyframes `Cubic(peak, rise) → Spring(1, .bouncy)` on a trigger (−1 elapsed = rest). */
export function popScale(t: number, peak: number, rise: number) {
  if (t < 0) return 1;
  if (t < rise) return 1 + (peak - 1) * cubicInOut(t / rise);
  return peak + (1 - peak) * springAt(t - rise, 0.5, 0.7);
}
const cubicInOut = cubicBezier(0.42, 0, 0.58, 1);
