/** text.spring-chain · 弹簧链字母 (Text+SpringChain.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, fonts, spring, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";
import { chars, randIn } from "./_text-kit";

const COLORS = [Palette.amber, Palette.coral, Palette.pink, Palette.violet];

export default function SpringChain({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [drag, setDrag] = useState({ x: 0, y: 0 });
  const [dragging, setDragging] = useState(false);
  const held = useRef(false);
  const letters = chars(ctx.t("PULL ME", "拉我试试"));
  const leanMax = ctx.n("lean");

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!held.current) {
        held.current = true;
        clearAll();
        setDragging(true);
        haptics.tap("light");
      }
      setDrag(translation);
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      setDragging(false);
      setDrag({ x: 0, y: 0 });
      haptics.tap("light");
    },
  });

  const simulate = () => {
    if (held.current) return;
    setDragging(true);
    setDrag({ x: randIn(-90, 90), y: randIn(-80, 60) });
    clearAll();
    after(0.8, () => {
      setDragging(false);
      setDrag({ x: 0, y: 0 });
    });
  };
  useAutoplay(ctx.isPreview, simulate, { every: 2.4 });

  const lean = dragging ? Math.min(Math.max(drag.x * 0.12, -leanMax), leanMax) : 0;
  const count = letters.length;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 30 }}>
      <div {...pan} style={{ ...pan.style, width: 320, height: 140, display: "flex", alignItems: "center", justifyContent: "center", cursor: "grab" }}>
        <div style={{ display: "flex" }}>
          {letters.map((ch, index) => {
            const position = count > 1 ? index / (count - 1) : 0;
            const slot = Math.round(position * (COLORS.length - 1));
            return (
              <motion.span
                key={index}
                initial={false}
                animate={{ x: drag.x, y: drag.y, rotate: lean }}
                transition={spring(0.15 + index * ctx.n("lag"), dragging ? 0.82 : ctx.n("damping"))}
                style={{
                  display: "inline-block",
                  transformOrigin: "50% 100%",
                  fontFamily: fonts.rounded,
                  fontSize: 56,
                  fontWeight: 800,
                  lineHeight: "67px",
                  whiteSpace: "pre",
                  color: COLORS[Math.min(Math.max(slot, 0), COLORS.length - 1)],
                }}
              >
                {ch}
              </motion.span>
            );
          })}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag the word" zh="拖动单词" />
    </div>
  );
}
