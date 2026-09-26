/** feedback.limit-bounce · 上限回弹 (Feedback+ErrorVariations.swift) */
import { motion } from "motion/react";
import { Minus, Plus } from "lucide-react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { DemoHint, NumericText, Palette, fonts, spring, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { SPRINGS, track } from "./shared";

export default function LimitBounce({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const maxValue = Math.max(ctx.i("max"), 1);
  const [value, setValue] = useState(maxValue);
  const [bumps, setBumps] = useState(0);
  const [flash, setFlash] = useState(false);
  const valueRef = useRef(value);
  valueRef.current = value;
  const autoHits = useRef(0);
  const zh = ctx.lang === "zh";

  useEffect(() => {
    if (value > maxValue) setValue(maxValue);
  }, [maxValue, value]);

  const change = (delta: number) => {
    const next = valueRef.current + delta;
    if (next > maxValue) {
      setBumps((b) => b + 1);
      haptics.tap("rigid");
      setFlash(true);
      clearAll();
      after(0.5, () => setFlash(false));
      return;
    }
    if (next < 1) return;
    haptics.selection();
    valueRef.current = next;
    setValue(next);
  };

  useAutoplay(ctx.isPreview, () => {
    if (valueRef.current >= maxValue) {
      autoHits.current += 1;
      if (autoHits.current > 2) {
        autoHits.current = 0;
        valueRef.current = 1;
        setValue(1);
        return;
      }
    }
    change(1);
  }, { every: 0.8, delay: 0.5 });

  const e = useElapsed(bumps, 0.9, true);
  const sx = e < 0 ? 1 : track(e, 1, [{ cubic: 1 + ctx.n("stretch"), d: 0.1 }, { spring: 1, d: 0.4, ...SPRINGS.bouncy }]);
  const lift = e < 0 ? 0 : track(e, 0, [{ cubic: -ctx.n("lift"), d: 0.1 }, { cubic: 3, d: 0.12 }, { spring: 0, d: 0.3, ...SPRINGS.bouncy }]);
  const flashT = spring(0.3, 0.6);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
        <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{zh ? "票数" : "Tickets"}</span>
        <motion.span
          initial={false}
          animate={{ scale: flash ? 1.06 : 1, color: flash ? Palette.red : "var(--ml-label2)" }}
          transition={flashT}
          style={{ fontSize: 13, lineHeight: "18px", fontWeight: 500 }}
        >
          {zh ? `每单最多 ${maxValue} 张` : `Max ${maxValue} per order`}
        </motion.span>
      </div>
      <div style={{ transform: `scaleX(${sx})`, transformOrigin: "0% 50%" }}>
        <div style={{ position: "relative", width: 200, height: 52, borderRadius: 26, background: Palette.elevated, boxShadow: "0 5px 10px rgb(0 0 0 / 0.08)", display: "flex", alignItems: "center" }}>
          <motion.div
            initial={false}
            animate={{ boxShadow: `inset 0 0 0 ${flash ? 2 : 1}px ${flash ? Palette.red : "rgb(var(--ml-label-rgb) / 0.1)"}` }}
            transition={flashT}
            style={{ position: "absolute", inset: 0, borderRadius: 26, pointerEvents: "none" }}
          />
          <StepButton enabled={value > 1} onClick={() => change(-1)}>
            <Minus size={17} strokeWidth={3} />
          </StepButton>
          <div style={{ flex: 1, display: "flex", justifyContent: "center", transform: `translateY(${lift}px)`, fontFamily: fonts.rounded, fontSize: 26, fontWeight: 700 }}>
            <NumericText value={value} />
          </div>
          <StepButton enabled={value < maxValue} onClick={() => change(1)}>
            <Plus size={17} strokeWidth={3} />
          </StepButton>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap + past the limit" zh="超过上限后继续点 +" />
    </div>
  );
}

function StepButton({ enabled, onClick, children }: { enabled: boolean; onClick: () => void; children: ReactNode }) {
  return (
    <button type="button" onClick={onClick} style={{ position: "relative", width: 56, height: 52, display: "grid", placeItems: "center", color: Palette.indigo, opacity: enabled ? 1 : 0.3 }}>
      {children}
    </button>
  );
}
