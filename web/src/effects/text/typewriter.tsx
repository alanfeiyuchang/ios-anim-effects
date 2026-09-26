/** text.typewriter · 打字机 (Text+Typewriter.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, demoCard, fonts, useHaptics, useLatest, type DemoProps } from "../../kit";
import { chars, randIn, useTask } from "./_text-kit";

const PHRASES = {
  // 14 full-width characters each: long enough to show the rhythm, short enough for one line at 17 pt.
  zh: ["好的设计，会在指尖轻轻呼吸。", "让每一帧动效，都有它的理由。", "从灵感到上线，只差一次回车。"],
  en: ["Hello, world.", "Design in motion.", "Every frame counts."],
};

export default function Typewriter({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [typed, setTyped] = useState("");
  const [isTyping, setIsTyping] = useState(true);
  const phraseIndex = useRef(0);
  const [skips, setSkips] = useState(0);
  const typedRef = useRef("");
  const cps = useLatest(Math.max(ctx.n("speed"), 1));

  const set = (s: string) => {
    typedRef.current = s;
    setTyped(s);
  };

  useTask(`${ctx.lang}-${skips}`, async (sleep) => {
    const list = PHRASES[ctx.lang];
    let index = phraseIndex.current;
    setIsTyping(true);
    while (typedRef.current.length > 0) {
      set(chars(typedRef.current).slice(0, -1).join(""));
      if (!(await sleep(0.018))) return;
    }
    for (;;) {
      const characters = chars(list[index % list.length]);
      setIsTyping(true);
      for (let count = 1; count <= Math.max(characters.length, 1); count++) {
        set(characters.slice(0, count).join(""));
        if (!(await sleep(randIn(0.7, 1.3) / cps.current))) return;
      }
      setIsTyping(false);
      if (!(await sleep(1.4))) return;
      setIsTyping(true);
      while (typedRef.current.length > 0) {
        set(chars(typedRef.current).slice(0, -1).join(""));
        if (!(await sleep(0.5 / cps.current))) return;
      }
      if (!(await sleep(0.25))) return;
      index += 1;
      phraseIndex.current = index;
    }
  });

  const skip = () => {
    if (ctx.isPreview) return;
    haptics.tap("light");
    phraseIndex.current += 1;
    setSkips((s) => s + 1);
  };

  return (
    <div onClick={skip} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
      <div style={{ position: "relative", ...demoCard(24), width: 316, padding: 22, display: "flex", flexDirection: "column", gap: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          {[Palette.red, Palette.amber, Palette.green].map((c) => (
            <span key={c} style={{ width: 9, height: 9, borderRadius: "50%", background: c }} />
          ))}
          <span style={{ flex: 1 }} />
          <span style={{ fontFamily: fonts.mono, fontSize: 12, lineHeight: "16px", color: Palette.tertiaryLabel }}>~/motion</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 2, height: 40 }}>
          <span
            style={{
              fontFamily: fonts.mono,
              fontSize: ctx.lang === "zh" ? 17 : 22,
              fontWeight: 600,
              color: Palette.label,
              whiteSpace: "pre",
              overflow: "hidden",
            }}
          >
            {typed}
          </span>
          <Caret style={ctx.i("caret")} isTyping={isTyping} />
        </div>
        <div style={{ position: "absolute", left: 0, right: 0, bottom: -34, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
          <DemoHint ctx={ctx} en="Tap for the next line" zh="点击输入下一句" />
        </div>
      </div>
    </div>
  );
}

function Caret({ style, isTyping }: { style: number; isTyping: boolean }) {
  const shape =
    style === 1 ? (
      <span style={{ display: "block", width: 16, height: 30, borderRadius: 3, background: Palette.primary, opacity: 0.85 }} />
    ) : style === 2 ? (
      <span style={{ display: "flex", alignItems: "flex-end", height: 30 }}>
        <span style={{ width: 16, height: 3.5, borderRadius: 2, background: Palette.primary }} />
      </span>
    ) : (
      <span style={{ display: "block", width: 3, height: 30, borderRadius: 2, background: Palette.primary }} />
    );
  return (
    <motion.span
      animate={isTyping ? { opacity: 1 } : { opacity: [1, 0] }}
      transition={isTyping ? { duration: 0 } : { duration: 0.5, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
      style={{ display: "block", flexShrink: 0 }}
    >
      {shape}
    </motion.span>
  );
}
