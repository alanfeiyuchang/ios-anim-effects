/** cards.shuffle · 洗牌 (Cards+Shuffle.swift) */
import { motion, type Transition } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, black, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { CreditCard, Stage } from "./shared";

const THEMES = [0, 3, 2, 4];
const NUMBERS = ["4821", "0937", "5510", "7264"];
const CARD_W = 160;
const PULL_SCALE = 1.02;
const SEPARATION = 175;
const DECK_HALF = (CARD_W * 0.94) / 2;

export default function Shuffle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [order, setOrder] = useState([0, 1, 2, 3]);
  const [pulled, setPulled] = useState<number | null>(null);
  const [transition, setTransition] = useState<Transition>(spring(0.32, 0.8));
  const pulledRef = useRef<number | null>(null);
  const orderRef = useRef(order);
  orderRef.current = order;
  const timer = useRef(0);
  useEffect(() => () => window.clearTimeout(timer.current), []);

  const tilt = ctx.n("tilt");
  const w = CARD_W * PULL_SCALE;
  const h = (w * 158) / 250;
  const a = (tilt * Math.PI) / 180;
  const pulledHalf = (w * Math.cos(a) + h * Math.sin(a)) / 2;
  const clearance = pulledHalf + DECK_HALF + 6;

  const offsetX = (isPulled: boolean) => {
    if (pulled === null) return 0;
    const separation = Math.max(SEPARATION, clearance);
    const cardX = (separation + DECK_HALF - pulledHalf) / 2;
    return isPulled ? cardX : cardX - separation;
  };

  const shuffle = () => {
    if (pulledRef.current !== null) return;
    const top = orderRef.current[0];
    haptics.tap("soft");
    pulledRef.current = top;
    setTransition(spring(0.32, 0.8));
    setPulled(top);
    // Reorder once the pull has landed: the card then fully clears the deck, so the z-order drop is invisible.
    timer.current = window.setTimeout(() => {
      setTransition(spring(ctx.n("response"), ctx.n("damping")));
      setOrder((o) => [...o.slice(1), o[0]]);
      pulledRef.current = null;
      setPulled(null);
    }, 300);
  };
  useAutoplay(ctx.isPreview, shuffle, { every: 1.4 });

  return (
    <Stage gap={24}>
      <div onClick={shuffle} style={{ position: "relative", width: 340, height: 220, flexShrink: 0, transform: "translateY(20px)", cursor: "pointer" }}>
        {THEMES.map((theme, id) => {
          const depth = order.indexOf(id);
          const isPulled = pulled === id;
          return (
            <motion.div
              key={id}
              initial={false}
              animate={{
                x: offsetX(isPulled),
                y: isPulled ? -24 : depth * -16,
                scale: isPulled ? PULL_SCALE : 1 - depth * 0.06,
                rotate: isPulled ? tilt : 0,
              }}
              transition={transition}
              style={{ position: "absolute", left: 170 - CARD_W / 2, top: 110 - (CARD_W * 158) / 500, zIndex: order.length - depth }}
            >
              <motion.div
                initial={false}
                animate={{ boxShadow: isPulled ? `0 12px 16px ${black(0.22)}` : `0 8px 12px ${black(0.16)}` }}
                transition={transition}
                style={{ borderRadius: (18 * CARD_W) / 250 }}
              >
                <CreditCard theme={theme} width={CARD_W} last4={NUMBERS[id]} />
              </motion.div>
            </motion.div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap to shuffle" zh="点击洗牌" />
    </Stage>
  );
}
