/** text.blur-reveal · 逐字模糊显现 (Text+BlurReveal.swift) */
import { AnimatePresence, animate, usePresence } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, useAutoplay, type DemoProps } from "../../kit";
import { Glyphs, serifCJK } from "./_text-kit";

const PHRASES = {
  zh: ["每一个字，\n都经过精心雕琢。", "细节不是细节，\n它们就是设计。", "安静，\n但令人难忘。"],
  en: ["Crafted with intention,\ndown to every glyph.", "The details are not details.\nThey make the design.", "Quiet, yet\nimpossible to forget."],
};

export default function BlurReveal({ ctx }: DemoProps) {
  const [visible, setVisible] = useState(false);
  const [index, setIndex] = useState(0);
  const duration = ctx.n("duration");
  const phrases = PHRASES[ctx.lang];

  const visibleRef = useRef(visible);
  const toggle = () => {
    const now = !visibleRef.current;
    visibleRef.current = now;
    if (now) setIndex((i) => i + 1);
    setVisible(now);
  };

  useAutoplay(ctx.isPreview, toggle, { every: Math.max(duration, 0.6) + 1.2, delay: 0.2, intro: false });
  const appeared = useRef(false);
  useEffect(() => {
    if (appeared.current) return;
    appeared.current = true;
    if (!ctx.isPreview) toggle();
  }, [ctx.isPreview]);

  return (
    <div
      onClick={toggle}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 24, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: 310, height: 120, display: "grid", placeItems: "center" }}>
        <AnimatePresence>
          {visible && (
            <RevealText
              key={index}
              text={phrases[index % phrases.length]}
              duration={duration}
              blur={ctx.n("blur")}
              window={ctx.n("window")}
            />
          )}
        </AnimatePresence>
      </div>
      <DemoHint ctx={ctx} en="Tap to reveal / dismiss" zh="点击显现 / 隐藏" />
    </div>
  );
}

/** The transition's renderer: `progress` runs 0 → 1 on insertion and back to 0 on removal (linear). */
function RevealText({ text, duration, blur, window: win }: { text: string; duration: number; blur: number; window: number }) {
  const [isPresent, safeToRemove] = usePresence();
  const [progress, setProgress] = useState(0);
  const current = useRef(0);
  useEffect(() => {
    const target = isPresent ? 1 : 0;
    const controls = animate(current.current, target, {
      duration,
      ease: "linear",
      onUpdate: (v) => {
        current.current = v;
        setProgress(v);
      },
      onComplete: () => {
        if (!isPresent) safeToRemove?.();
      },
    });
    return () => controls.stop();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isPresent]);

  const w = Math.min(Math.max(win, 0.05), 1);
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", pointerEvents: "none" }}>
      <Glyphs
        text={text}
        style={{ fontFamily: serifCJK, fontSize: 28, fontWeight: 600, lineHeight: "34px", color: Palette.label }}
        glyph={(i, n) => {
          const start = n > 1 ? (i / (n - 1)) * (1 - w) : 0;
          const local = Math.min(Math.max((progress - start) / w, 0), 1);
          const eased = 1 - Math.pow(1 - local, 3);
          return {
            opacity: eased,
            filter: blur > 0 && eased < 1 ? `blur(${(1 - eased) * blur}px)` : undefined,
            transform: `translateY(${(1 - eased) * 10}px)`,
          };
        }}
      />
    </div>
  );
}
