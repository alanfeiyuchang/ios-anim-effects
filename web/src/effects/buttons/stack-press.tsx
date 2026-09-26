/** buttons.stack-press · 叠层按压 (Buttons+StackPress.swift) */
import { motion } from "motion/react";
import { ArrowUpRight } from "lucide-react";
import { useRef, useState, type ReactNode } from "react";
import { DemoHint, Palette, delayed, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { useLatchedPress } from "./_a-kit";

const FILLS = [Palette.pink, Palette.coral, Palette.amber];

export default function StackPress({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [autoPressed, setAutoPressed] = useState(false);
  const autoRef = useRef(false);
  const gap = ctx.n("gap");
  const stagger = ctx.n("stagger");
  const damping = ctx.n("damping");
  // The back slab never moves: the stack is shut once the face and middle slab have landed.
  const { held, handlers } = useLatchedPress({
    pressDelay: Math.max(0.12, stagger + 0.1),
    onPress: () => haptics.tap("rigid"),
    onRelease: () => haptics.tap("light"),
  });
  const pressed = held || autoPressed;

  useAutoplay(ctx.isPreview, () => {
    if (ctx.isPreview) {
      autoRef.current = !autoRef.current;
      setAutoPressed(autoRef.current);
    } else {
      setAutoPressed(true);
      after(0.4, () => setAutoPressed(false));
    }
  }, { every: 0.8, delay: 0.3 });

  const slab = (layer: number, content?: ReactNode) => {
    const depth = (2 - layer) * gap;
    const offset = depth + (pressed ? gap * 2 - depth : 0);
    const delay = (layer === 2 ? 0 : layer === 1 ? 1 : 2) * stagger;
    const t = pressed ? delayed(spring(0.22, 0.85), delay) : delayed(spring(0.3, damping), delay);
    return (
      <motion.div
        key={layer}
        initial={false}
        animate={{ x: offset, y: offset }}
        transition={t}
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          width: 220,
          height: 60,
          borderRadius: 16,
          background: FILLS[layer],
          boxShadow: "inset 0 0 0 2px #000",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        {content}
      </motion.div>
    );
  };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
          <div style={{ fontFamily: fonts.mono, fontSize: 11, fontWeight: 800, color: Palette.secondaryLabel }}>{ctx.t("DRAFT · 1,240 words", "草稿 · 1,240 字")}</div>
          <div style={{ fontFamily: fonts.rounded, fontSize: 20, lineHeight: "25px", fontWeight: 800, color: Palette.label }}>{ctx.t("Ready to ship?", "准备好发布了吗？")}</div>
        </div>
        <button type="button" {...handlers} style={{ position: "relative", width: 220 + gap * 2, height: 60 + gap * 2 }}>
          {slab(0)}
          {slab(1)}
          {slab(
            2,
            <span style={{ display: "flex", alignItems: "center", gap: 8, fontFamily: fonts.rounded, fontSize: 17, fontWeight: 800, color: "#000" }}>
              {ctx.lang === "zh" ? "发布" : "Publish"}
              <ArrowUpRight size={19} strokeWidth={2.8} />
            </span>,
          )}
        </button>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press and hold, then release" zh="按住再松开" style={{ paddingBottom: 18 }} />
    </div>
  );
}
