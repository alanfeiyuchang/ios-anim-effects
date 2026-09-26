/** gestures.notch-slide · 分段刻口滑动支付 (Gestures+NotchSlide.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useTransform } from "motion/react";
import { Check, CreditCard } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, black, delayed, rubberBand, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { colorGradient, useScript } from "./_a-common";

const STEPS: [string, string][] = [
  ["Review", "核对"],
  ["Verify", "验证"],
  ["Authorize", "授权"],
  ["Pay", "支付"],
];
const TRACK = 290;
const KNOB = 56;
const INSET = 4;
const MAX_X = TRACK - KNOB - INSET * 2;
const notch = (k: number) => (MAX_X * k) / 4;

export default function NotchSlide({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const resetTask = useScript();
  const [raw, setRawState] = useState(0);
  const [done, setDone] = useState(false);
  const x = useMotionValue(0);
  const st = useRef({ raw: 0, done: false, held: false, passed: 0 });
  const s = st.current;
  const sticky = ctx.n("sticky");
  const cascade = ctx.n("cascade");

  /** Quadratic stickiness near each interior notch; identity elsewhere. */
  const attracted = (value: number) => {
    if (sticky <= 0) return value;
    for (let k = 1; k <= 3; k++) {
      const d = value - notch(k);
      if (Math.abs(d) < sticky) return notch(k) + (d * Math.abs(d)) / sticky;
    }
    return value;
  };
  const litCount = (v: number) => {
    let count = 0;
    for (let k = 1; k <= 4; k++) if (v >= notch(k) - 2) count = k;
    return count;
  };

  /** `raw = value` (withAnimation when `t` is given): the knob shows `attracted(raw)`. */
  const setRaw = (value: number, t?: ReturnType<typeof spring>) => {
    s.raw = value;
    setRawState(value);
    if (t) animate(x, attracted(value), t);
    else {
      x.stop();
      x.set(attracted(value));
    }
  };
  const setDoneBoth = (v: boolean) => {
    s.done = v;
    setDone(v);
  };

  const reset = () => {
    setRaw(0, spring(0.5, 0.78));
    s.passed = 0;
  };
  const commit = (haptic: boolean) => {
    setRaw(MAX_X, spring(0.3, 0.8));
    setDoneBoth(true);
    s.passed = 4;
    if (haptic) haptics.success();
    resetTask.cancel();
    resetTask.after(1.8, () => {
      setDoneBoth(false);
      reset();
    });
  };

  useEffect(() => () => script.cancel(), [script]);

  const pan = usePan({
    onChange: ({ translation }) => {
      if (s.done) return;
      if (!s.held) {
        s.held = true;
        script.cancel();
      }
      const t = translation.x;
      setRaw(t < 0 ? rubberBand(t, 16) : t > MAX_X ? MAX_X + rubberBand(t - MAX_X, 16) : t);
      const now = litCount(attracted(s.raw));
      if (now > s.passed) haptics.tap("rigid");
      s.passed = now;
    },
    onEnd: () => {
      if (!s.held) return;
      s.held = false;
      if (s.done) return;
      if (s.raw >= MAX_X * 0.97) commit(true);
      else reset();
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (s.done || s.held) return;
      script.cancel();
      const e = anim.easeInOut(0.32);
      for (let k = 1; k <= 4; k++) script.after((k - 1) * 0.4, () => setRaw(notch(k) + (k < 4 ? 4 : 0), e));
      script.after(1.6, () => commit(false));
    },
    { every: 3.6, delay: 0.6 },
  );

  const lit = litCount(attracted(raw));
  const active = done ? 3 : Math.min(lit, 3);
  const knobX = useTransform(x, (v) => INSET + v);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ width: TRACK, display: "flex" }}>
        {STEPS.map((step, i) => {
          const on = i <= active && (raw > 2 || done);
          return (
            <div
              key={i}
              style={{
                flex: 1,
                textAlign: "center",
                fontSize: 12,
                lineHeight: "16px",
                fontWeight: on ? 700 : 500,
                color: on ? Palette.label : Palette.secondaryLabel,
                transition: "color 0.2s ease-out",
              }}
            >
              {ctx.t(...step)}
            </div>
          );
        })}
      </div>
      <div style={{ position: "relative", width: TRACK, height: KNOB + INSET * 2, flexShrink: 0 }}>
        <div style={{ position: "absolute", inset: 0, display: "flex", gap: 3, borderRadius: 999, overflow: "hidden" }}>
          {[0, 1, 2, 3].map((index) => {
            const isLit = index < lit || done;
            return (
              <div key={index} style={{ position: "relative", flex: 1, background: Palette.labelAlpha(0.07) }}>
                <motion.div
                  initial={false}
                  animate={{ opacity: isLit ? 1 : 0, scaleY: isLit ? 1 : 0.6 }}
                  transition={delayed(spring(0.3, 0.5), isLit ? 0 : (3 - index) * cascade * 0.85)}
                  style={{ position: "absolute", inset: 0 }}
                >
                  <div style={{ position: "absolute", inset: 0, background: Palette.primary }} />
                  <motion.div
                    initial={false}
                    animate={{ opacity: done ? 1 : 0 }}
                    transition={delayed(anim.easeOut(0.25), index * cascade)}
                    style={{ position: "absolute", inset: 0, background: colorGradient(Palette.green) }}
                  />
                </motion.div>
              </div>
            );
          })}
        </div>
        <motion.div
          {...pan}
          style={{
            ...pan.style,
            position: "absolute",
            top: INSET,
            left: 0,
            x: knobX,
            width: KNOB,
            height: KNOB,
            borderRadius: "50%",
            background: "#fff",
            boxShadow: `0 4px 8px ${black(0.18)}`,
            display: "grid",
            placeItems: "center",
            cursor: "grab",
          }}
        >
          <AnimatePresence mode="popLayout" initial={false}>
            <motion.span
              key={done ? "check" : "card"}
              initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
              exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              transition={anim.snappyD(0.3)}
              style={{ display: "grid", color: done ? Palette.green : Palette.indigo }}
            >
              {done ? <Check size={22} strokeWidth={3.2} /> : <CreditCard size={22} strokeWidth={2.6} />}
            </motion.span>
          </AnimatePresence>
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Drag through every checkpoint" zh="拖过每一个刻口" />
    </div>
  );
}
