/** text.gravity-digits · 重力落字 (Text+GravityDigits.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, anim, delayed, fonts, springDB, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { randInt } from "./_text-kit";

const SLOT_H = 72;

/** "18452" → ["1", "8", ",", "4", "5", "2"]. */
function characters(value: number): string[] {
  const digits = String(value);
  const result: string[] = [];
  [...digits].forEach((ch, index) => {
    const fromEnd = digits.length - index;
    if (index > 0 && fromEnd % 3 === 0) result.push(",");
    result.push(ch);
  });
  return result;
}

export default function GravityDigits({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [value, setValue] = useState(18_452);
  const duration = ctx.n("duration");
  const bounce = ctx.n("bounce");
  const stagger = ctx.n("stagger");

  const walk = () => {
    haptics.tap("medium");
    setValue((v) => {
      const next = v + randInt(37, 420);
      return next > 99_000 ? 10_000 + randInt(0, 900) : next;
    });
  };
  useAutoplay(ctx.isPreview, walk, { every: 1.6 });

  const list = characters(value);
  return (
    <div onClick={walk} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14, cursor: "pointer" }}>
      <WalkFigure />
      <div style={{ display: "flex" }}>
        {list.map((ch, index) => {
          const delay = (list.length - 1 - index) * stagger;
          const tilt = index % 2 === 0 ? -14 : 14;
          return (
            <div key={index} style={{ position: "relative", width: ch === "," ? 18 : 40, height: SLOT_H, overflow: "hidden" }}>
              <AnimatePresence initial={false}>
                <motion.span
                  key={ch}
                  initial={{ y: -60, opacity: 0, rotate: 0 }}
                  animate={{ y: 0, opacity: 1, rotate: 0, transition: delayed(springDB(duration, bounce), delay) }}
                  exit={{ y: 60, opacity: 0, rotate: tilt, transition: delayed(anim.easeIn(duration * 0.5), delay) }}
                  style={{
                    position: "absolute",
                    inset: 0,
                    display: "grid",
                    placeItems: "center",
                    fontFamily: fonts.rounded,
                    fontSize: 64,
                    fontWeight: 800,
                    fontVariantNumeric: "tabular-nums",
                    color: Palette.label,
                  }}
                >
                  {ch}
                </motion.span>
              </AnimatePresence>
            </div>
          );
        })}
      </div>
      <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("steps today", "今日步数")}</span>
      <DemoHint ctx={ctx} en="Tap to walk" zh="点击走几步" />
    </div>
  );
}

/** SF Symbol `figure.walk`, 24 pt semibold, mint. */
function WalkFigure() {
  return (
    <svg width={18} height={28} viewBox="0 0 18 28" fill="none" stroke={Palette.mint} strokeWidth={2.6} strokeLinecap="round" strokeLinejoin="round">
      <circle cx={10} cy={3.2} r={2.6} fill={Palette.mint} stroke="none" />
      <path d="M9.2 8.2 7.6 16.2" strokeWidth={3.4} />
      <path d="M8.8 9.6 5 12.4 4 15.8" />
      <path d="M9 9.8 12.2 12.6 15 13.4" />
      <path d="M7.6 16.2 11 20.6 12.6 26" />
      <path d="M7.4 17 5.6 21.8 2.6 25.6" />
    </svg>
  );
}
