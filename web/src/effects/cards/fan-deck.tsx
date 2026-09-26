/** cards.fan-deck · 扇形展开 (Cards+FanDeck.swift) */
import { motion } from "motion/react";
import { Club, Diamond, Heart, Spade, type LucideIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, delayed, fonts, hex, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { Stage } from "./shared";

interface PlayingCard {
  rank: string;
  Suit: LucideIcon;
  red: boolean;
}

const HAND: PlayingCard[] = [
  { rank: "10", Suit: Heart, red: true },
  { rank: "J", Suit: Club, red: false },
  { rank: "Q", Suit: Diamond, red: true },
  { rank: "K", Suit: Spade, red: false },
  { rank: "A", Suit: Heart, red: true },
];

export default function FanDeck({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [fanned, setFanned] = useState(false);
  const [lifted, setLifted] = useState<number | null>(null);
  const autoStep = useRef(0);
  const fannedRef = useRef(false);
  fannedRef.current = fanned;

  // The detail stage deals the fan once on arrival so it never opens on a static pile.
  useEffect(() => {
    if (ctx.isPreview) return;
    const id = window.setTimeout(() => !fannedRef.current && setFanned(true), 550);
    return () => window.clearTimeout(id);
  }, [ctx.isPreview]);

  useAutoplay(
    ctx.isPreview,
    () => {
      switch (autoStep.current % 4) {
        case 0:
          setFanned(true);
          break;
        case 1:
          setLifted(3);
          break;
        case 2:
          setLifted(1);
          break;
        default:
          setLifted(null);
          setFanned(false);
      }
      autoStep.current += 1;
    },
    { every: 1.3, intro: false },
  );

  const count = HAND.length;
  const angle = (i: number) => {
    if (!fanned) return (i - Math.floor(count / 2)) * 1.5;
    const spread = ctx.n("spread");
    return -spread / 2 + (spread * i) / (count - 1);
  };

  const tap = (i: number) => {
    haptics.tap("soft");
    if (!fanned) setFanned(true);
    else if (lifted === i) {
      setLifted(null);
      setFanned(false);
    } else setLifted(i);
  };

  return (
    <Stage gap={20}>
      <div style={{ position: "relative", width: 300, height: 250, flexShrink: 0, transform: "translateY(30px)" }}>
        {HAND.map((card, i) => {
          const order = fanned ? i : count - 1 - i;
          return (
            <motion.div
              key={i}
              initial={false}
              animate={{ y: fanned ? -12 : 0, rotate: angle(i) }}
              transition={delayed(spring(ctx.n("response"), ctx.n("damping")), order * ctx.n("stagger"))}
              style={{ position: "absolute", left: 150 - 52, top: 125 - 75, width: 104, height: 150, transformOrigin: "52px 240px" }}
            >
              <motion.div
                initial={false}
                animate={{ y: lifted === i ? -30 : 0 }}
                transition={spring(0.35, 0.7)}
                onClick={() => tap(i)}
                style={{ cursor: "pointer" }}
              >
                <CardFace card={card} />
              </motion.div>
            </motion.div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap to fan, tap a card to draw it" zh="点击展开，点击单张抽出" style={{ position: "relative", zIndex: 1 }} />
    </Stage>
  );
}

function CardFace({ card }: { card: PlayingCard }) {
  const tint = card.red ? Palette.red : Palette.label;
  const tintSoft = card.red ? hex(Palette.red, 0.14) : Palette.labelAlpha(0.14);
  const { Suit } = card;
  const corner = (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 1, color: tint }}>
      <span style={{ fontFamily: fonts.rounded, fontSize: 17, fontWeight: 700, lineHeight: "20px" }}>{card.rank}</span>
      <Suit size={12} fill="currentColor" strokeWidth={0} />
    </div>
  );
  return (
    <div
      style={{
        position: "relative",
        width: 104,
        height: 150,
        borderRadius: 14,
        background: Palette.elevated,
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 5px 10px ${black(0.14)}`,
      }}
    >
      <div style={{ position: "absolute", inset: 7, borderRadius: 10, boxShadow: `inset 0 0 0 1px ${tintSoft}` }} />
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: tint }}>
        <Suit size={42} fill="currentColor" strokeWidth={0} />
      </div>
      <div style={{ position: "absolute", left: 10, top: 10 }}>{corner}</div>
      <div style={{ position: "absolute", right: 10, bottom: 10, transform: "rotate(180deg)" }}>{corner}</div>
    </div>
  );
}
