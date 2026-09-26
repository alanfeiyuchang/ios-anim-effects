/** inputs.accelerating-stepper (Inputs+AcceleratingStepper.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Flame, Minus, Plus } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, clamp, demoCard, fonts, spring, textStyle, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { useAutoMute } from "./_a-common";

const MIN = 0;
const MAX = 9990;
const FIRST_DELAY = 0.4;

export default function AcceleratingStepper({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { wrap, muted: autoMuted } = useAutoMute();
  const [value, setValueState] = useState(2000);
  const valueRef = useRef(2000);
  const [holding, setHolding] = useState(0);
  const [speed, setSpeed] = useState(0);
  const [multiplier, setMultiplier] = useState(1);
  const loop = useRef(0);
  const timer = useRef(0);
  const introTimer = useRef(0);
  const step = useRef(0);
  const setValue = (v: number) => {
    valueRef.current = v;
    setValueState(v);
  };

  useEffect(
    () => () => {
      window.clearTimeout(timer.current);
      window.clearTimeout(introTimer.current);
    },
    [],
  );

  const apply = (delta: number, muted: boolean) => {
    const target = clamp(valueRef.current + delta, MIN, MAX);
    if (target === valueRef.current) {
      if (!muted) haptics.tap("rigid");
      return false;
    }
    const atLimit = target === MIN || target === MAX;
    if (!muted) haptics.tap(atLimit ? "rigid" : "soft");
    setValue(target);
    return !atLimit;
  };

  const end = () => {
    loop.current += 1;
    window.clearTimeout(timer.current);
    setHolding(0);
    setSpeed(0);
    setMultiplier(1);
  };

  const begin = (direction: number) => {
    loop.current += 1;
    const run = loop.current;
    window.clearTimeout(timer.current);
    setHolding(direction);
    setSpeed(0);
    setMultiplier(1);
    const muted = autoMuted();
    if (!apply(direction * 10, muted)) return;
    const decay = ctx.n("acceleration");
    const fastest = ctx.n("fastest");
    let interval = FIRST_DELAY;
    let repeats = 0;
    const tick = () => {
      if (run !== loop.current) return;
      repeats += 1;
      const size = repeats > 20 ? 10 : repeats > 8 ? 5 : 1;
      setMultiplier(size);
      if (!apply(direction * 10 * size, muted)) {
        setSpeed(0);
        setMultiplier(1);
        return;
      }
      interval = Math.max(interval * decay, fastest);
      setSpeed(clamp((FIRST_DELAY - interval) / (FIRST_DELAY - fastest)));
      timer.current = window.setTimeout(tick, interval * 1000);
    };
    timer.current = window.setTimeout(tick, interval * 1000);
  };

  useAutoplay(
    ctx.isPreview,
    wrap(() => {
      step.current += 1;
      begin(step.current % 2 === 1 ? 1 : -1);
      window.clearTimeout(introTimer.current);
      introTimer.current = window.setTimeout(end, 2400);
    }),
    { every: 3.4, delay: 0.3 },
  );

  const holdButton = (direction: number) => {
    const active = holding === direction;
    return (
      <motion.div
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          window.clearTimeout(introTimer.current);
          begin(direction);
        }}
        onPointerUp={end}
        onPointerCancel={end}
        animate={{ scale: active ? 0.9 : 1 }}
        transition={spring(0.25, 0.6)}
        style={{ position: "relative", width: 60, height: 60, borderRadius: "50%", cursor: "pointer", flexShrink: 0 }}
      >
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.primary }} />
        <svg width={72} height={72} viewBox="0 0 72 72" style={{ position: "absolute", left: -6, top: -6, overflow: "visible", transform: "rotate(-90deg)" }}>
          <motion.circle
            cx={36}
            cy={36}
            r={35}
            fill="none"
            stroke={Palette.amber}
            strokeWidth={4}
            strokeLinecap="round"
            initial={false}
            animate={{ pathLength: active ? Math.max(speed, 0.02) : 0, opacity: active ? 1 : 0 }}
            transition={{ duration: active ? 0.15 : 0.3, ease: [0, 0, 0.58, 1] }}
          />
        </svg>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: "#fff" }}>
          {direction < 0 ? <Minus size={22} strokeWidth={3} /> : <Plus size={22} strokeWidth={3} />}
        </div>
      </motion.div>
    );
  };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), width: 316, padding: "20px 16px", display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, ...textStyle.subheadline, fontWeight: 600 }}>
          <Flame size={16} fill={Palette.coral} color={Palette.coral} strokeWidth={1.5} />
          <span style={{ color: Palette.secondaryLabel }}>{ctx.t("Daily calorie goal", "每日热量目标")}</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          {holdButton(-1)}
          <div style={{ width: 120, display: "flex", flexDirection: "column", alignItems: "center" }}>
            <NumericText
              value={value}
              text={value.toLocaleString("en-US")}
              style={{ fontFamily: fonts.rounded, fontSize: 40, fontWeight: 700, lineHeight: "48px", filter: ctx.b("blur") ? `blur(${speed * 3}px)` : undefined }}
            />
            <span style={{ ...textStyle.caption, fontWeight: 600, color: Palette.tertiaryLabel }}>kcal</span>
          </div>
          {holdButton(1)}
        </div>
        <div style={{ height: 24, display: "grid", placeItems: "center" }}>
          <AnimatePresence mode="popLayout" initial={false}>
            {multiplier > 1 ? (
              <motion.span
                key={`x${multiplier}`}
                initial={{ scale: 0.4, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.4, opacity: 0 }}
                transition={spring(0.35, 0.55)}
                style={{ ...textStyle.caption, fontWeight: 800, fontVariantNumeric: "tabular-nums", color: "#fff", padding: "4px 10px", borderRadius: 20, background: Palette.sunset }}
              >
                ×{multiplier === 5 ? 5 : 10}
              </motion.span>
            ) : (
              <motion.span
                key="x1"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={spring(0.35, 0.55)}
                style={{ ...textStyle.caption, fontWeight: 700, fontVariantNumeric: "tabular-nums", color: Palette.tertiaryLabel }}
              >
                ×1
              </motion.span>
            )}
          </AnimatePresence>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press and hold + or −" zh="按住 + 或 −" style={{ paddingBottom: 18 }} />
    </div>
  );
}
