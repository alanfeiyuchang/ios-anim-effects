/** cards.accordion · 手风琴卡片 (Cards+Accordion.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { ChevronDown, Plane, ShoppingBag, Utensils, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, black, spring, useAutoplay, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { Stage, diag, tr, type LText } from "./shared";

interface Item {
  title: LText;
  subtitle: LText;
  Icon: LucideIcon;
  filled: boolean;
  colors: string[];
  amount: string;
  bars: number[];
  notes: [LText, LText];
}

const ITEMS: Item[] = [
  {
    title: ["Travel", "旅行"], subtitle: ["12 transactions", "12 笔交易"], Icon: Plane, filled: true, colors: [Palette.sky, Palette.blue], amount: "$1,284",
    bars: [22, 36, 28, 44, 30, 18, 40], notes: [["Largest: flight to Tokyo · $486", "最大一笔：飞往东京 · $486"], ["64% of monthly budget", "已用月度预算 64%"]],
  },
  {
    title: ["Dining", "餐饮"], subtitle: ["28 transactions", "28 笔交易"], Icon: Utensils, filled: false, colors: [Palette.amber, Palette.coral], amount: "$642",
    bars: [30, 24, 40, 20, 44, 34, 26], notes: [["Largest: Friday dinner · $92", "最大一笔：周五晚餐 · $92"], ["On track · $158 left", "进度正常 · 剩余 $158"]],
  },
  {
    title: ["Shopping", "购物"], subtitle: ["9 transactions", "9 笔交易"], Icon: ShoppingBag, filled: true, colors: [Palette.violet, Palette.pink], amount: "$918",
    bars: [18, 28, 22, 34, 26, 44, 38], notes: [["Largest: running shoes · $139", "最大一笔：跑鞋 · $139"], ["12% over budget", "超出预算 12%"]],
  },
];

export default function Accordion({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [expanded, setExpanded] = useState<number | null>(null);
  const autoStep = useRef(0);
  const sp = spring(ctx.n("response"), ctx.n("damping"));

  const toggle = (i: number) => {
    haptics.tap("soft");
    setExpanded((e) => (e === i ? null : i));
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      const sequence = [0, 1, 2, null];
      setExpanded(sequence[autoStep.current % sequence.length]);
      autoStep.current += 1;
    },
    { every: 1.6 },
  );

  const recedes = (i: number) => ctx.b("dim") && expanded !== null && expanded !== i;

  return (
    <Stage gap={16}>
      <div style={{ width: 300, display: "flex", flexDirection: "column", gap: 10 }}>
        {ITEMS.map((item, i) => (
          <motion.div
            key={i}
            initial={false}
            animate={{ scale: recedes(i) ? 0.97 : 1, opacity: recedes(i) ? 0.6 : 1 }}
            transition={sp}
            onClick={() => toggle(i)}
            style={{ cursor: "pointer" }}
          >
            <Card item={item} expanded={expanded === i} ctx={ctx} transition={sp} />
          </motion.div>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap a card" zh="点击卡片" />
    </Stage>
  );
}

function Card({ item, expanded, ctx, transition }: { item: Item; expanded: boolean; ctx: DemoContext; transition: Transition }) {
  const { Icon } = item;
  return (
    <motion.div
      initial={false}
      animate={{
        height: expanded ? "auto" : 62,
        boxShadow: expanded ? `0 10px 18px ${black(0.14)}` : `0 4px 8px ${black(0.06)}`,
      }}
      transition={transition}
      style={{ position: "relative", borderRadius: 20, background: Palette.elevated, overflow: "hidden" }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 12, padding: 12 }}>
        <div style={{ width: 38, height: 38, borderRadius: 11, background: diag(item.colors), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
          <Icon size={18} strokeWidth={item.filled ? 0 : 2.4} fill={item.filled ? "currentColor" : "none"} style={{ transform: Icon === Plane ? "rotate(45deg)" : undefined }} />
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{tr(ctx, item.title)}</span>
          <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{tr(ctx, item.subtitle)}</span>
        </div>
        <span style={{ flex: 1 }} />
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, fontVariantNumeric: "tabular-nums" }}>{item.amount}</span>
        <motion.span initial={false} animate={{ rotate: expanded ? 180 : 0 }} transition={transition} style={{ display: "grid", color: Palette.secondaryLabel }}>
          <ChevronDown size={14} strokeWidth={3} />
        </motion.span>
      </div>
      <AnimatePresence initial={false}>
        {expanded && (
          <motion.div
            key="details"
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            transition={transition}
            style={{ display: "flex", flexDirection: "column", gap: 12, padding: "0 14px 14px" }}
          >
            <div style={{ height: 0.5, background: Palette.labelAlpha(0.2) }} />
            <div style={{ display: "flex", alignItems: "flex-end", gap: 10, height: 44 }}>
              {item.bars.map((h, b) => (
                <div key={b} style={{ width: 18, height: h, borderRadius: 9, background: `linear-gradient(${item.colors.join(", ")})`, opacity: b === 4 ? 1 : 0.35 }} />
              ))}
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
              {item.notes.map((note, n) => (
                <div key={n} style={{ display: "flex", alignItems: "center", gap: 6 }}>
                  <div style={{ width: 5, height: 5, borderRadius: "50%", background: item.colors[0] }} />
                  <span style={{ fontSize: 12, lineHeight: "16px", color: n === 0 ? Palette.label : Palette.secondaryLabel }}>{tr(ctx, note)}</span>
                </div>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
      <div style={{ position: "absolute", inset: 0, borderRadius: 20, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
    </motion.div>
  );
}
