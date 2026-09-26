/** text.rotating-words · 轮播词 (Text+RotatingWords.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useLayoutEffect, useRef, useState } from "react";
import { Palette, alpha, fonts, springDB, useAutoplay, type DemoProps } from "../../kit";
import { GradientText } from "./_text-kit";

const WORDS = {
  zh: ["更流畅", "更灵动", "更高级", "更有温度"],
  en: ["faster", "delightful", "beautiful", "yours"],
};
const TINTS = [Palette.indigo, Palette.pink, Palette.mint, Palette.coral];
const WORD_FONT = { fontFamily: fonts.rounded, fontSize: 40, fontWeight: 800, lineHeight: "48px" } as const;

export default function RotatingWords({ ctx }: DemoProps) {
  const [index, setIndex] = useState(0);
  const words = WORDS[ctx.lang];
  const tint = TINTS[index % TINTS.length];
  const word = words[index % words.length];
  const transition = springDB(0.55, ctx.n("bounce"));
  const blur = ctx.n("blur");
  const interval = Math.max(ctx.n("interval"), 0.5);

  const advance = () => setIndex((i) => i + 1);
  useAutoplay(true, advance, { every: interval, delay: interval });

  // The pill is sized by the current word (a hidden copy in SwiftUI): measure every word once.
  const measurer = useRef<HTMLDivElement>(null);
  const [widths, setWidths] = useState<number[]>([]);
  useLayoutEffect(() => {
    const measure = () => {
      const el = measurer.current;
      if (el) setWidths(Array.from(el.children).map((c) => (c as HTMLElement).offsetWidth));
    };
    measure();
    void document.fonts?.ready.then(measure);
  }, [ctx.lang]);
  const width = (widths[index % words.length] ?? 120) + 44;

  return (
    <div onClick={advance} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12, cursor: "pointer" }}>
      <div ref={measurer} aria-hidden style={{ position: "absolute", visibility: "hidden", display: "flex", flexDirection: "column", alignItems: "flex-start" }}>
        {words.map((w) => (
          <span key={w} style={{ ...WORD_FONT, whiteSpace: "pre" }}>
            {w}
          </span>
        ))}
      </div>
      <span style={{ fontFamily: fonts.rounded, fontSize: 34, fontWeight: 700, lineHeight: "41px", color: Palette.label }}>{ctx.t("Make it", "让你的界面")}</span>
      <motion.div
        initial={false}
        animate={{ width, backgroundColor: alpha(tint, 0.13), boxShadow: `inset 0 0 0 1px ${alpha(tint, 0.25)}` }}
        transition={transition}
        style={{ position: "relative", height: 66, borderRadius: 33, overflow: "hidden" }}
      >
        <AnimatePresence initial={false}>
          <motion.div
            key={index}
            initial={{ y: 34, opacity: 0, scale: 0.92, filter: `blur(${blur}px)` }}
            animate={{ y: 0, opacity: 1, scale: 1, filter: "blur(0px)" }}
            exit={{ y: -34, opacity: 0, scale: 0.92, filter: `blur(${blur}px)` }}
            transition={transition}
            style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}
          >
            <GradientText fill={`linear-gradient(to right, ${tint}, ${Palette.violet})`} style={WORD_FONT}>
              {word}
            </GradientText>
          </motion.div>
        </AnimatePresence>
      </motion.div>
    </div>
  );
}
