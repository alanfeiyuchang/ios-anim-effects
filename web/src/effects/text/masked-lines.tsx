/** text.masked-lines · 遮罩逐行上浮 (Text+MaskedLines.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, spring, useHaptics, type DemoProps } from "../../kit";
import { fittedSize, serifCJK, useTask } from "./_text-kit";

type Phase = "below" | "shown" | "above";
const LINE_H = 50;

const HEADLINES = {
  zh: [
    { eyebrow: "第 01 章 · 动效", lines: ["好的动效", "从不喧宾夺主，", "只为意图服务。"] },
    { eyebrow: "第 02 章 · 节奏", lines: ["节奏感", "来自每一次停顿", "与每一次出发。"] },
    { eyebrow: "第 03 章 · 质感", lines: ["质感藏在", "毫秒之间，", "也藏在分寸里。"] },
  ],
  en: [
    { eyebrow: "CHAPTER 01 · MOTION", lines: ["Great motion", "never shouts.", "It explains."] },
    { eyebrow: "CHAPTER 02 · RHYTHM", lines: ["Rhythm lives", "in every pause", "and every start."] },
    { eyebrow: "CHAPTER 03 · CRAFT", lines: ["Craft hides", "between the", "milliseconds."] },
  ],
};

export default function MaskedLines({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [phase, setPhaseState] = useState<Phase>("below");
  const [index, setIndex] = useState(0);
  const [skips, setSkips] = useState(0);
  const phaseRef = useRef<Phase>("below");
  const stagger = ctx.n("stagger");
  const response = ctx.n("response");

  const setPhase = (p: Phase) => {
    phaseRef.current = p;
    setPhaseState(p);
  };
  const advance = () => {
    setPhase("below");
    setIndex((i) => i + 1);
  };

  useTask(skips, async (sleep) => {
    if (skips > 0) {
      if (phaseRef.current === "shown") {
        setPhase("above");
        if (!(await sleep(0.4 + stagger * 2))) return;
      }
      advance();
      if (!(await sleep(0.05))) return;
    } else if (!(await sleep(0.35))) return;
    for (;;) {
      setPhase("shown");
      if (!(await sleep(2.8))) return;
      setPhase("above");
      if (!(await sleep(0.8 + stagger * 3))) return;
      advance();
      if (!(await sleep(0.08))) return;
    }
  });

  const skip = () => {
    if (ctx.isPreview) return;
    haptics.selection();
    setSkips((s) => s + 1);
  };

  const headline = HEADLINES[ctx.lang][index % 3];
  const shown = phase === "shown";
  const count = headline.lines.length;
  const lastLineLands = 0.08 + Math.max(count - 1, 0) * stagger + response * 0.8;
  const tilt = ctx.n("tilt");

  return (
    <div onClick={skip} style={{ position: "absolute", inset: 0, cursor: "pointer" }}>
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div key={index} style={{ width: 290, display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 10 }}>
          <motion.span
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: shown ? 1 : 0, y: shown ? 0 : 6 }}
            transition={anim.easeOut(0.35)}
            style={{ fontSize: 12, lineHeight: "16px", fontWeight: 800, letterSpacing: 1.6, color: Palette.coral, whiteSpace: "pre" }}
          >
            {headline.eyebrow}
          </motion.span>
          <div style={{ display: "flex", flexDirection: "column", alignSelf: "stretch" }}>
            {headline.lines.map((line, i) => {
              const size = fittedSize(line, 38, 290, (s) => `700 ${s}px ${serifCJK}`);
              return (
                <div key={i} style={{ height: LINE_H, overflow: "hidden", display: "flex", alignItems: "center" }}>
                  <motion.span
                    initial={{ y: LINE_H, rotate: tilt }}
                    animate={{ y: phase === "below" ? LINE_H : phase === "shown" ? 0 : -LINE_H, rotate: phase === "below" ? tilt : 0 }}
                    transition={delayed(spring(response, 0.85), 0.08 + i * stagger)}
                    style={{
                      display: "inline-block",
                      transformOrigin: "left bottom",
                      fontFamily: serifCJK,
                      fontSize: size,
                      fontWeight: 700,
                      lineHeight: `${Math.round(size * 1.25)}px`,
                      color: Palette.label,
                      whiteSpace: "pre",
                    }}
                  >
                    {line}
                  </motion.span>
                </div>
              );
            })}
          </div>
          <motion.div
            initial={{ scaleX: 0.001 }}
            animate={{ scaleX: shown ? 1 : 0.001 }}
            transition={shown ? delayed(spring(0.6, 0.9), lastLineLands + 0.2) : anim.easeIn(0.25)}
            style={{ width: 96, height: 4, borderRadius: 2, background: Palette.sunset, transformOrigin: "left center", marginTop: 6 }}
          />
        </div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 14, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
        <DemoHint ctx={ctx} en="Tap for the next headline" zh="点击切换下一组标题" />
      </div>
    </div>
  );
}
