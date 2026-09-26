/** feedback.stacked-banners · 堆叠通知 (Feedback+Badges.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Calendar, Flame, Mail, MessageCircle, Package, Plus, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";

const SAMPLES: { Icon: LucideIcon; fill: boolean; tint: string; app: [string, string]; message: [string, string] }[] = [
  { Icon: MessageCircle, fill: true, tint: Palette.green, app: ["Messages", "信息"], message: ["Mia: Dinner at 8 tonight?", "米娅：今晚 8 点吃饭？"] },
  { Icon: Calendar, fill: false, tint: Palette.red, app: ["Calendar", "日历"], message: ["Design review in 10 minutes", "10 分钟后开设计评审"] },
  { Icon: Flame, fill: true, tint: Palette.coral, app: ["Fitness", "健身"], message: ["You closed all your rings!", "今日圆环全部合拢！"] },
  { Icon: Mail, fill: true, tint: Palette.blue, app: ["Mail", "邮件"], message: ["Invoice #2041 is ready", "发票 #2041 已开具"] },
  { Icon: Package, fill: true, tint: Palette.amber, app: ["Orders", "订单"], message: ["Your package is out for delivery", "您的包裹正在派送"] },
];
const CARD = 64;

export default function StackedBanners({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [items, setItems] = useState([2, 1, 0]);
  const nextID = useRef(3);
  const [expanded, setExpanded] = useState(false);
  const tick = useRef(0);
  const sp = spring(ctx.n("response"), ctx.n("damping"));
  const peek = ctx.n("peek");
  const zh = ctx.lang === "zh";

  const push = () => {
    haptics.tap("soft");
    const id = nextID.current++;
    setItems((list) => [id, ...list].slice(0, 3));
  };
  const toggle = () => {
    haptics.selection();
    setExpanded((e) => !e);
  };

  useAutoplay(ctx.isPreview, () => {
    tick.current += 1;
    if (tick.current % 4 === 0) toggle();
    else push();
  }, { every: 1.5, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <motion.div
        onClick={toggle}
        initial={false}
        animate={{ height: expanded ? CARD * 3 + 24 : CARD + peek * 2 + 10 }}
        transition={sp}
        style={{ position: "relative", width: 300, flexShrink: 0, cursor: "pointer" }}
      >
        <AnimatePresence initial={false}>
          {items.map((id, index) => {
            const y = expanded ? index * (CARD + 10) : index * peek;
            const scale = expanded ? 1 : 1 - 0.05 * index;
            return (
              <motion.div
                key={id}
                initial={{ y: y - 80, scale: scale * 0.92, opacity: 0 }}
                animate={{ y, scale, opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={sp}
                style={{ position: "absolute", left: 0, right: 0, top: 0, height: CARD, zIndex: 10 - index, transformOrigin: "50% 0%" }}
              >
                <Card sample={SAMPLES[id % SAMPLES.length]} zh={zh} showsContent={expanded || index === 0} dim={expanded ? 0 : 0.07 * index} transition={sp} />
              </motion.div>
            );
          })}
        </AnimatePresence>
      </motion.div>
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <button
          type="button"
          onClick={push}
          style={{ display: "flex", alignItems: "center", gap: 6, height: 38, padding: "0 16px", borderRadius: 19, background: Palette.primary, color: "#fff", fontSize: 15, fontWeight: 600 }}
        >
          <Plus size={16} strokeWidth={2.8} />
          {ctx.t("New", "新通知")}
        </button>
        <DemoHint ctx={ctx} en="Tap the stack" zh="点击堆叠" />
      </div>
    </div>
  );
}

function Card({ sample, zh, showsContent, dim, transition }: { sample: (typeof SAMPLES)[number]; zh: boolean; showsContent: boolean; dim: number; transition: ReturnType<typeof spring> }) {
  const { Icon } = sample;
  return (
    <div style={{ position: "relative", height: CARD, borderRadius: 18, background: Palette.elevated, boxShadow: "0 5px 10px rgb(0 0 0 / 0.1)" }}>
      <motion.div initial={false} animate={{ opacity: showsContent ? 1 : 0 }} transition={transition} style={{ position: "absolute", inset: 0, padding: "0 13px", display: "flex", alignItems: "center", gap: 12 }}>
        <div
          style={{
            width: 38,
            height: 38,
            flexShrink: 0,
            borderRadius: 10,
            background: `linear-gradient(rgb(255 255 255 / 0.12), transparent), ${sample.tint}`,
            display: "grid",
            placeItems: "center",
            color: "#fff",
          }}
        >
          <Icon size={17} strokeWidth={sample.fill ? 2 : 2.4} fill={sample.fill ? "currentColor" : "none"} stroke={sample.fill ? sample.tint : "currentColor"} />
        </div>
        <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 2 }}>
          <div style={{ display: "flex", alignItems: "center" }}>
            <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel }}>{sample.app[zh ? 1 : 0]}</span>
            <span style={{ flex: 1 }} />
            <span style={{ fontSize: 11, lineHeight: "13px", color: Palette.tertiaryLabel }}>{zh ? "现在" : "now"}</span>
          </div>
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{sample.message[zh ? 1 : 0]}</span>
        </div>
      </motion.div>
      <motion.div initial={false} animate={{ opacity: dim }} transition={transition} style={{ position: "absolute", inset: 0, borderRadius: 18, background: "#000", pointerEvents: "none" }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 18, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
    </div>
  );
}
