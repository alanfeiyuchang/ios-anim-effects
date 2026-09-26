/** cards.cascade-spread · 层叠展开 (Cards+CascadeSpread.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, black, delayed, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { CreditCard, Stage } from "./shared";

const THEMES = [3, 4, 2, 0];
const NUMBERS = ["1180", "6621", "3047", "4821"];
const CW = 220;
const CH = (220 * 158) / 250;

export default function CascadeSpread({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [spread, setSpread] = useState(false);
  const toggle = () => {
    haptics.tap("soft");
    setSpread((s) => !s);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.9 });

  const gap = ctx.n("gap");
  const stagger = ctx.n("stagger");
  const height = 3 * gap + 150;

  return (
    <Stage gap={16}>
      <div onClick={toggle} style={{ position: "relative", width: 340, height, flexShrink: 0, cursor: "pointer" }}>
        {THEMES.map((theme, i) => {
          const fromFront = 3 - i;
          const t = delayed(spring(0.5, 0.76), spread ? (3 - i) * stagger : i * stagger);
          return (
            <motion.div
              key={i}
              initial={false}
              animate={{ y: spread ? (i - 1.5) * gap : 30 - fromFront * 8, scale: spread ? 0.88 + i * 0.04 : 1 - fromFront * 0.05 }}
              transition={t}
              style={{ position: "absolute", left: 170 - CW / 2, top: height / 2 - CH / 2, zIndex: i }}
            >
              <motion.div initial={false} animate={{ rotateX: spread ? ctx.n("tilt") : 0 }} transition={t} style={{ transformPerspective: CW / 0.6 }}>
                <motion.div
                  initial={false}
                  animate={{ boxShadow: spread ? `0 12px 16px ${black(0.22)}` : `0 5px 8px ${black(0.14)}` }}
                  transition={t}
                  style={{ borderRadius: (18 * CW) / 250 }}
                >
                  <CreditCard theme={theme} width={CW} last4={NUMBERS[i]} />
                </motion.div>
              </motion.div>
            </motion.div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap to spread the pile" zh="点击展开卡堆" />
    </Stage>
  );
}
