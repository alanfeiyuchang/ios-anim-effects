/**
 * Pull-to-refresh host shared by `pull-refresh` and the refresh variations (the web twin of
 * `FeedbackRefreshList` + `RefreshVarHost`): a downward pan on the list is the pull, rubber-banded;
 * the indicator lives in the gap above the rows.
 */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent, type Transition } from "motion/react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { DemoHint, Palette, anim, demoCard, rubberBand, spring, useAutoplay, useHaptics, usePan, useTimeouts, type DemoContext } from "../../kit";

export interface RefreshClock {
  start: number;
  end: number;
}

/** Seconds since the refresh started (performance clock), clamped at zero. */
export const refreshElapsed = (clock: RefreshClock) => Math.max(performance.now() / 1000 - clock.start, 0);
/** 0 → 1 over the first quarter second of a refresh. */
export const refreshRamp = (e: number) => Math.min(e / 0.25, 1);

export interface IndicatorProps {
  progress: number;
  pull: number;
  refreshing: boolean;
  clock: RefreshClock;
  /** A real finger drives the pull (so the indicator may buzz). */
  userDriven: boolean;
}

export interface RefreshHostOptions {
  ctx: DemoContext;
  threshold: number;
  holdHeight: number;
  height: number;
  rowCount: number;
  renderRow: (item: number) => ReactNode;
  indicator: (p: IndicatorProps) => ReactNode;
  /** Indicator box: the variations clip a 300-wide box; `pull-refresh` centres a 28 pt dial. */
  clipIndicator?: boolean;
  /** Scripted pull: [first shift fraction of the threshold, its duration, overshoot past the threshold, its duration, wait]. */
  script: [number, number, number, number, number];
  doneSpring: Transition;
  insertion: { initial: Record<string, number>; origin?: string };
  /** `pull-refresh` animates its `armed` flip with a spring and buzzes before it. */
  onArmedChange?: (armed: boolean) => void;
}

export function RefreshHost(o: RefreshHostOptions) {
  const { ctx, threshold, holdHeight } = o;
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const finger = useMotionValue(0);
  const shift = useMotionValue(0);
  const [pull, setPull] = useState(0);
  const [refreshing, setRefreshing] = useState(false);
  const [clock, setClock] = useState<RefreshClock>({ start: -1e9, end: -1e9 });
  const [items, setItems] = useState([3, 2, 1, 0]);
  const [userDriven, setUserDriven] = useState(false);
  const nextItem = useRef(4);
  const armed = useRef(false);
  const refreshingRef = useRef(false);
  const userDrivenRef = useRef(false);
  const fingerAnim = useRef<ReturnType<typeof animate> | null>(null);
  const shiftAnim = useRef<ReturnType<typeof animate> | null>(null);
  const live = !ctx.isPreview;

  const update = () => setPull(finger.get() + shift.get());
  useMotionValueEvent(finger, "change", update);
  useMotionValueEvent(shift, "change", update);
  useEffect(() => () => {
    fingerAnim.current?.stop();
    shiftAnim.current?.stop();
  }, []);

  const shiftTo = (v: number, t: Transition) => {
    shiftAnim.current?.stop();
    shiftAnim.current = animate(shift, v, t);
  };

  const updateArmed = (value: number, buzz: boolean) => {
    const now = value >= threshold;
    if (now === armed.current) return;
    armed.current = now;
    if (now && buzz && live) haptics.tap("medium");
    o.onArmedChange?.(now);
  };

  const release = () => {
    if (refreshingRef.current) return;
    const current = finger.get() + shift.get();
    if (current < threshold) {
      shiftTo(0, spring(0.4, 0.75));
      updateArmed(0, false);
      return;
    }
    const start = performance.now() / 1000;
    setClock((c) => ({ ...c, start }));
    refreshingRef.current = true;
    setRefreshing(true);
    shiftTo(holdHeight, spring(0.4, 0.9));
    const buzz = live && userDrivenRef.current;
    clearAll();
    after(ctx.n("duration"), () => {
      const id = nextItem.current++;
      setItems((list) => [id, ...list].slice(0, 4));
      shiftTo(0, o.doneSpring);
      refreshingRef.current = false;
      setRefreshing(false);
      setClock((c) => ({ ...c, end: performance.now() / 1000 }));
      armed.current = false;
      o.onArmedChange?.(false);
      if (buzz) haptics.success();
    });
  };

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        const value = rubberBand(Math.max(translation.y, 0), 240, 0.8);
        fingerAnim.current?.stop();
        finger.set(value);
        userDrivenRef.current = true;
        setUserDriven(true);
        if (refreshingRef.current) return;
        updateArmed(value + shift.get(), true);
      },
      onEnd: () => {
        release();
        fingerAnim.current = animate(finger, 0, spring(0.4, 0.9));
      },
    },
    4,
  );

  const simulate = () => {
    if (refreshingRef.current) return;
    userDrivenRef.current = false;
    setUserDriven(false);
    clearAll();
    const [frac, d1, extra, d2, wait] = o.script;
    shiftTo(threshold * frac, anim.easeOut(d1));
    after(d1, () => {
      if (refreshingRef.current) return;
      shiftTo(threshold + extra, anim.easeOut(d2));
      updateArmed(threshold + extra, false);
      after(wait, () => release());
    });
  };

  useAutoplay(ctx.isPreview, simulate, { every: ctx.n("duration") + 2.6, delay: 0.6 });

  const offsetY = useMotionValue(0);
  useEffect(() => offsetY.set(pull), [pull, offsetY]);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ ...demoCard(22), position: "relative", width: 300, height: o.height, flexShrink: 0 }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: 22, overflow: "hidden", background: Palette.surface }}>
          <div style={{ position: "absolute", left: 0, top: 0, width: 300, height: Math.max(pull, 1), overflow: o.clipIndicator === false ? "visible" : "hidden" }}>
            {o.indicator({ progress: Math.min(pull / threshold, 1.2), pull, refreshing, clock, userDriven: userDriven && live })}
          </div>
          <motion.div
            {...(live ? pan : {})}
            style={{ position: "absolute", left: 0, top: 0, width: 300, height: o.height, y: offsetY, background: Palette.elevated, touchAction: "pan-x", cursor: live ? "grab" : undefined }}
          >
            <AnimatePresence initial={false} mode="popLayout">
              {items.map((item) => (
                <motion.div
                  key={item}
                  layout
                  initial={{ ...o.insertion.initial, opacity: 0 }}
                  animate={{ y: 0, scale: 1, opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={o.doneSpring}
                  style={{ transformOrigin: o.insertion.origin ?? "50% 50%" }}
                >
                  {o.renderRow(item)}
                </motion.div>
              ))}
            </AnimatePresence>
          </motion.div>
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 22, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Pull the list down" zh="向下拖动列表" />
    </div>
  );
}

/** `.frame(height:)` rows with a bottom inset divider. */
export function DividerRow({ height, inset, scheme, children }: { height: number; inset: number; scheme: "dark" | "light"; children: ReactNode }) {
  return (
    <div style={{ position: "relative", height, padding: "0 14px", display: "flex", alignItems: "center", gap: 12 }}>
      {children}
      <div style={{ position: "absolute", left: inset, right: 0, bottom: 0, height: 0.5, background: scheme === "dark" ? "rgb(84 84 88 / 0.6)" : "rgb(60 60 67 / 0.29)" }} />
    </div>
  );
}
