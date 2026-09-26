/** buttons.label-roll · 文字翻滚 (Buttons+LabelRoll.swift) */
import { motion } from "motion/react";
import { ArrowRight } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, delayed, spring, springAt, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { useLatchedPress, useSince } from "./_a-kit";

const TRAVEL = 23;

export default function LabelRoll({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [rolled, setRolled] = useState(false);
  const rolledRef = useRef(false);
  const [rolls, setRolls] = useState(0);
  const { held, handlers } = useLatchedPress();
  const zh = ctx.lang === "zh";
  const title = zh ? "立即开始" : "Get started";
  const chars = Array.from(title);
  const stagger = ctx.n("stagger");
  const response = ctx.n("response");
  const direction = ctx.i("direction") === 1 ? -1 : 1;
  const settle = response * 2 + chars.length * stagger;

  const roll = () => {
    if (rolledRef.current) return;
    haptics.tap();
    rolledRef.current = true;
    setRolled(true);
    setRolls((r) => r + 1);
    after(settle + 0.05, () => {
      rolledRef.current = false;
      setRolled(false);
    });
  };

  useAutoplay(ctx.isPreview, roll, { every: 1.6, delay: 0.5 });

  const since = useSince(rolls, settle);
  const clock = rolled ? Math.max(since, 0) : 0;
  const arrowT = rolled ? delayed(spring(response, 0.85), Math.max(chars.length - 1, 0) * stagger) : { duration: 0 };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
          <div style={{ fontSize: 22, lineHeight: "28px", fontWeight: 700, color: Palette.label }}>{zh ? "让界面动起来" : "Make it move"}</div>
          <div style={{ fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel }}>{zh ? "一套为 iOS 打造的动效词典" : "A motion dictionary for iOS"}</div>
        </div>
        <div style={{ display: "flex", gap: 10 }}>
          <motion.button
            type="button"
            {...handlers}
            onClick={roll}
            initial={false}
            animate={{ scale: held ? 0.97 : 1 }}
            transition={spring(0.25, 0.7)}
            style={{
              position: "relative",
              height: 54,
              padding: "0 22px",
              borderRadius: 27,
              background: ctx.scheme === "dark" ? "#2C2C32" : "#16161A",
              boxShadow: "0 8px 14px rgb(0 0 0 / 0.25)",
              color: "#fff",
              fontSize: 16,
              fontWeight: 600,
              display: "flex",
              alignItems: "center",
              gap: 8,
            }}
          >
            <div style={{ position: "absolute", inset: 1, borderRadius: 27, background: "linear-gradient(rgb(255 255 255 / 0.14), transparent 50%)", pointerEvents: "none" }} />
            <div style={{ position: "absolute", inset: 0, borderRadius: 27, boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.2)", pointerEvents: "none" }} />
            <span style={{ position: "relative", display: "inline-flex", overflow: "hidden", height: 20, lineHeight: "20px", whiteSpace: "pre" }}>
              {chars.map((c, i) => {
                const p = springAt(clock - i * stagger, response, 0.85);
                return (
                  <span key={i} style={{ position: "relative", display: "inline-block" }}>
                    <span style={{ display: "inline-block", transform: `translateY(${-TRAVEL * p * direction}px)` }}>{c}</span>
                    <span style={{ position: "absolute", left: 0, top: 0, transform: `translateY(${TRAVEL * (1 - p) * direction}px)` }}>{c}</span>
                  </span>
                );
              })}
            </span>
            <span style={{ position: "relative", width: 20, height: 24, overflow: "hidden", display: "block" }}>
              {[0, 1].map((k) => (
                <motion.span
                  key={k}
                  initial={false}
                  animate={k === 0 ? { x: rolled ? 22 : 0, opacity: rolled ? 0 : 1 } : { x: rolled ? 0 : -22, opacity: rolled ? 1 : 0 }}
                  transition={arrowT}
                  style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}
                >
                  <ArrowRight size={17} strokeWidth={2.4} />
                </motion.span>
              ))}
            </span>
          </motion.button>
          <div
            style={{
              height: 54,
              padding: "0 18px",
              borderRadius: 27,
              boxShadow: `inset 0 0 0 1px ${Palette.labelAlpha(0.15)}`,
              fontSize: 16,
              fontWeight: 600,
              color: Palette.label,
              display: "flex",
              alignItems: "center",
              whiteSpace: "nowrap",
            }}
          >
            {zh ? "了解更多" : "Learn more"}
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the dark button" zh="点击黑色按钮" style={{ paddingBottom: 18 }} />
    </div>
  );
}
