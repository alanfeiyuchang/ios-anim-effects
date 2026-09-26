/** cards.wallet-stack · 钱包卡片堆叠 (Cards+Wallet.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, black, delayed, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { CreditCard, Stage } from "./shared";

const THEMES = [0, 2, 3, 5];
const NUMBERS = ["4821", "0937", "5510", "7264"];

export default function WalletStack({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState<number | null>(null);
  const autoStep = useRef(0);

  useAutoplay(
    ctx.isPreview,
    () => {
      const sequence = [2, null, 0, null, 3, null];
      setSelected(sequence[autoStep.current % sequence.length]);
      autoStep.current += 1;
    },
    { every: 1.6 },
  );

  const select = (i: number) => {
    haptics.tap("soft");
    setSelected((s) => (s === i ? null : i));
  };

  const others = THEMES.map((_, i) => i).filter((i) => i !== selected);
  const pileSlot = (i: number) => Math.max(others.indexOf(i), 0);
  const tucked = (i: number) => selected !== null && selected !== i;
  const offsetY = (i: number) => (selected === null ? i * ctx.n("peek") : i === selected ? 0 : 168 + pileSlot(i) * 10);
  const scale = (i: number) => (tucked(i) ? 0.9 + pileSlot(i) * 0.03 : 1);

  return (
    <Stage>
      <div style={{ position: "relative", width: 250, height: 340, flexShrink: 0 }}>
        {THEMES.map((theme, i) => (
          <motion.div
            key={i}
            onClick={() => select(i)}
            initial={false}
            animate={{ y: offsetY(i), scale: scale(i), filter: `brightness(${tucked(i) ? 0.96 : 1})` }}
            transition={delayed(spring(ctx.n("response"), ctx.n("damping")), i * 0.035)}
            style={{ position: "absolute", left: 0, top: 0, zIndex: i, transformOrigin: "50% 0%", cursor: "pointer" }}
          >
            <div style={{ borderRadius: 18, boxShadow: `0 6px 10px ${black(0.18)}` }}>
              <CreditCard theme={theme} last4={NUMBERS[i]} />
            </div>
          </motion.div>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap a card" zh="点击一张卡片" />
    </Stage>
  );
}
