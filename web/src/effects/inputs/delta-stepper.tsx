/** inputs.delta-stepper (Inputs+DeltaStepper.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Minus, Plus } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, anim, demoCard, ease, fonts, mix, progress, spring, springAt, textStyle, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { CupSaucer, PressScale } from "./_a-common";

const SCRIPT = [1, 1, 1, 0, 0, 1, 0, 0, -1, -1, 0, 0];

export default function DeltaStepper({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [count, setCountState] = useState(3);
  const countRef = useRef(3);
  const [chips, setChips] = useState<{ id: number; total: number }[]>([]);
  const [taps, setTaps] = useState(0);
  const lastTap = useRef(-Infinity);
  const runningTotal = useRef(0);
  const nextID = useRef(0);
  const step = useRef(0);

  const tap = (delta: number) => {
    const target = Math.max(countRef.current + delta, 0);
    if (target === countRef.current) return;
    haptics.tap();
    countRef.current = target;
    setCountState(target);
    setTaps((t) => t + 1);
    const now = performance.now() / 1000;
    const same = runningTotal.current > 0 === delta > 0 && runningTotal.current !== 0;
    if (now - lastTap.current <= ctx.n("window") && same) runningTotal.current += delta;
    else runningTotal.current = delta;
    lastTap.current = now;
    const chip = { id: nextID.current++, total: runningTotal.current };
    setChips([chip]);
    after(0.95, () => setChips((c) => c.filter((x) => x.id !== chip.id)));
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const action = SCRIPT[step.current % SCRIPT.length];
      step.current += 1;
      if (action !== 0) tap(action);
    },
    { every: 0.28, delay: 0.4 },
  );

  // Squash on every tap: cubic out to (1 + s, 1 − 0.8 s) in 70 ms, bouncy spring back over 300 ms.
  const squash = ctx.n("squash");
  const t = useElapsed(taps, 0.37, true);
  let k = 0;
  if (t >= 0 && t < 0.37) k = t < 0.07 ? ease.inOut(progress(t, 0, 0.07)) : mix(1, 0, springAt(t - 0.07, 0.3, 0.7));
  const zh = ctx.lang === "zh";

  const button = (delta: number) => (
    <PressScale scale={0.88} onClick={() => tap(delta)} transition={spring(0.22, 0.55)} style={{ width: 52, height: 52 }}>
      <div
        style={{
          width: 52,
          height: 52,
          borderRadius: "50%",
          display: "grid",
          placeItems: "center",
          background: delta > 0 ? Palette.primary : alpha(Palette.indigo, 0.12),
          color: delta > 0 ? "#fff" : Palette.indigo,
        }}
      >
        {delta > 0 ? <Plus size={21} strokeWidth={3} /> : <Minus size={21} strokeWidth={3} />}
      </div>
    </PressScale>
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), width: 300, padding: 20, display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, ...textStyle.headline }}>
          <CupSaucer size={21} color={Palette.amber} />
          <span>{zh ? "请团队喝咖啡" : "Buy the team coffee"}</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 22 }}>
          {button(-1)}
          <div style={{ position: "relative", width: 96, height: 70, display: "grid", placeItems: "center" }}>
            <div style={{ transform: `scale(${1 + squash * k}, ${1 - squash * 0.8 * k})`, transformOrigin: "50% 100%" }}>
              <NumericText value={count} style={{ fontFamily: fonts.rounded, fontSize: 52, fontWeight: 700, lineHeight: "62px" }} />
            </div>
            <AnimatePresence>
              {chips.map((chip) => (
                <motion.div
                  key={chip.id}
                  initial={{ scale: 0.6, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  exit={{ scale: 0.6, opacity: 0 }}
                  transition={spring(0.3, 0.6)}
                  style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", pointerEvents: "none" }}
                >
                  <Chip total={chip.total} rise={ctx.n("rise")} />
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
          {button(1)}
        </div>
        <NumericText
          value={count}
          text={zh ? `¥${count * 25}` : `$${count * 4}`}
          style={{ fontFamily: fonts.rounded, ...textStyle.title3, fontWeight: 700, color: Palette.secondaryLabel }}
        />
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap + quickly several times" zh="快速连点 + 几次" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Chip({ total, rise }: { total: number; rise: number }) {
  const up = total > 0;
  const color = up ? Palette.mint : Palette.coral;
  return (
    <motion.div
      initial={{ x: 30, y: up ? -20 : 10, opacity: 1 }}
      animate={{ x: 30, y: up ? -rise - 20 : rise + 10, opacity: 0 }}
      transition={anim.easeOut(0.9)}
      style={{
        fontFamily: fonts.rounded,
        fontSize: Math.abs(total) > 1 ? 17 : 14,
        fontWeight: 800,
        fontVariantNumeric: "tabular-nums",
        color: "#fff",
        padding: "4px 9px",
        borderRadius: 20,
        background: color,
        boxShadow: `0 3px 6px ${alpha(color, 0.4)}`,
        whiteSpace: "nowrap",
      }}
    >
      {(up ? "+" : "−") + Math.abs(total)}
    </motion.div>
  );
}
