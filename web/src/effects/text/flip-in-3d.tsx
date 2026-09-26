/** text.flip-in-3d · 3D 翻转入场 (Text+FlipIn.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, delayed, fonts, spring, useHaptics, type DemoProps } from "../../kit";
import { GradientText, chars, useTask } from "./_text-kit";

type Phase = "hidden" | "shown" | "exited";
const ANGLE: Record<Phase, number> = { hidden: -100, shown: 0, exited: 100 };
const WORDS = { zh: ["让文字跃动", "每帧都讲究", "质感即品牌"], en: ["KINETIC", "MOTION", "DELIGHT"] };

export default function FlipIn3D({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [phase, setPhase] = useState<Phase>("hidden");
  const [index, setIndex] = useState(0);
  const [shownIndex, setShownIndex] = useState(0);
  const [skips, setSkips] = useState(0);
  const phaseRef = useRef<Phase>("hidden");
  const indexRef = useRef(0);
  const words = WORDS[ctx.lang];
  const zh = ctx.lang === "zh";

  const set = (p: Phase) => {
    phaseRef.current = p;
    setPhase(p);
  };
  // Next word without animation: the letters (keyed by word) mount hidden, ready to flip in.
  const advance = () => {
    set("hidden");
    indexRef.current += 1;
    setIndex(indexRef.current);
  };

  useTask(skips, async (sleep) => {
    if (skips > 0) {
      if (phaseRef.current === "shown") {
        set("exited");
        if (!(await sleep(0.45))) return;
      }
      advance();
      if (!(await sleep(0.05))) return;
    } else if (!(await sleep(0.3))) return;
    for (;;) {
      set("shown");
      setShownIndex(indexRef.current);
      if (!(await sleep(2.2))) return;
      set("exited");
      if (!(await sleep(0.9))) return;
      advance();
      if (!(await sleep(0.08))) return;
    }
  });

  const skip = () => {
    if (ctx.isPreview) return;
    haptics.selection();
    setSkips((s) => s + 1);
  };

  const letters = chars(words[index % words.length]);
  const size = zh ? 46 : 54;
  const horizontal = ctx.i("axis") === 0;
  const visible = phase === "shown";
  const active = shownIndex % words.length;

  return (
    <div onClick={skip} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 30, cursor: "pointer" }}>
      <div style={{ display: "flex", gap: zh ? 2 : 1, filter: `drop-shadow(0 10px 14px ${alpha(Palette.coral, 0.28)})` }}>
        {letters.map((letter, i) => (
          <motion.span
            key={`${index}-${i}`}
            initial={{ [horizontal ? "rotateX" : "rotateY"]: ANGLE.hidden, y: 12, opacity: 0, filter: "blur(5px)" }}
            animate={{
              rotateX: horizontal ? ANGLE[phase] : 0,
              rotateY: horizontal ? 0 : ANGLE[phase],
              y: visible ? 0 : 12,
              opacity: visible ? 1 : 0,
              filter: visible ? "blur(0px)" : "blur(5px)",
            }}
            transition={delayed(spring(ctx.n("response"), ctx.n("damping")), i * ctx.n("stagger"))}
            style={{ display: "inline-block", transformPerspective: size * 2 }}
          >
            <GradientText fill={Palette.sunset} style={{ fontFamily: fonts.rounded, fontSize: size, fontWeight: 900, lineHeight: `${Math.round(size * 1.2)}px` }}>
              {letter}
            </GradientText>
          </motion.span>
        ))}
      </div>
      <div style={{ display: "flex", gap: 6 }}>
        {words.map((_, i) => (
          <motion.span
            key={i}
            initial={false}
            animate={{ width: i === active ? 20 : 6 }}
            transition={spring(0.45, 0.75)}
            style={{ height: 6, borderRadius: 3, background: i === active ? Palette.sunset : Palette.labelAlpha(0.15) }}
          />
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap for the next word" zh="点击切换下一个词" />
    </div>
  );
}
