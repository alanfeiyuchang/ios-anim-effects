/** cards.notification-stack · 通知堆叠 (Cards+NotificationStack.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Calendar, CloudSun, Footprints, MessageCircle, type LucideIcon } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, anim, black, delayed, fonts, hex, spring, useAutoplay, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { diag, tr, type LText } from "./shared";

interface Item {
  app: LText;
  message: LText;
  time: LText;
  Icon: LucideIcon;
  filled: boolean;
  colors: string[];
}

const ITEMS: Item[] = [
  { app: ["Messages", "信息"], message: ["Mia: Dinner at 8? I booked the terrace.", "Mia：八点吃饭？我订了露台位。"], time: ["now", "现在"], Icon: MessageCircle, filled: true, colors: [Palette.green, Palette.mint] },
  { app: ["Calendar", "日历"], message: ["Design review starts in 15 minutes", "设计评审将在 15 分钟后开始"], time: ["2m", "2 分钟前"], Icon: Calendar, filled: false, colors: [Palette.red, Palette.coral] },
  { app: ["Fitness", "健身"], message: ["You closed all three rings today", "今天你合上了全部三个圆环"], time: ["18m", "18 分钟前"], Icon: Footprints, filled: true, colors: [Palette.pink, Palette.violet] },
  { app: ["Weather", "天气"], message: ["Clear skies all afternoon, 24°", "整个下午晴朗，24°"], time: ["1h", "1 小时前"], Icon: CloudSun, filled: false, colors: [Palette.sky, Palette.blue] },
];

const ROW_H = 60;
const GAP = 6;
const PLATE = 12;

export default function NotificationStack({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [expanded, setExpanded] = useState(false);
  const toggle = () => {
    haptics.tap("soft");
    setExpanded((e) => !e);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 2.0 });
  const sp = spring(ctx.n("response"), ctx.n("damping"));

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 10, width: 300 }}>
        {/* Lock-screen clock: condenses when the list needs the room. */}
        <div style={{ width: 300, display: "flex", flexDirection: "column", alignItems: "center" }}>
          <motion.div initial={false} animate={{ height: expanded ? 34 : 64 }} transition={sp} style={{ overflow: "visible", display: "flex", justifyContent: "center" }}>
            <motion.span
              initial={false}
              animate={{ scale: expanded ? 0.5 : 1 }}
              transition={sp}
              style={{ fontFamily: fonts.rounded, fontSize: 60, lineHeight: "72px", fontWeight: 600, fontVariantNumeric: "tabular-nums", transformOrigin: "50% 0", display: "block" }}
            >
              9:41
            </motion.span>
          </motion.div>
          <motion.div
            initial={false}
            animate={{ height: expanded ? 0 : 20, opacity: expanded ? 0 : 1 }}
            transition={sp}
            style={{ overflow: "hidden", fontSize: 15, lineHeight: "20px", fontWeight: 500, color: Palette.secondaryLabel }}
          >
            {ctx.t("Tuesday, June 9", "6月9日 星期二")}
          </motion.div>
        </div>
        <div style={{ width: 300, display: "flex", alignItems: "center" }}>
          <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{ctx.t("Notifications", "通知中心")}</span>
          <span style={{ flex: 1 }} />
          <span
            onClick={toggle}
            style={{ position: "relative", display: "grid", padding: "5px 10px", borderRadius: 999, background: Palette.elevated, fontSize: 12, lineHeight: "16px", fontWeight: 600, cursor: "pointer" }}
          >
            <AnimatePresence initial={false} mode="popLayout">
              <motion.span key={expanded ? "less" : "new"} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={anim.snappy}>
                {expanded ? ctx.t("Show less", "收起") : ctx.t("4 new", "4 条新通知")}
              </motion.span>
            </AnimatePresence>
          </span>
        </div>
        <motion.div
          initial={false}
          animate={{ height: expanded ? 4 * ROW_H + 3 * GAP : ROW_H + 2 * PLATE }}
          transition={sp}
          style={{ position: "relative", width: 300 }}
        >
          {ITEMS.map((item, i) => {
            const order = expanded ? i : ITEMS.length - 1 - i;
            const t = delayed(sp, order * ctx.n("stagger"));
            const shown = expanded || i === 0;
            return (
              <motion.div
                key={i}
                initial={false}
                animate={{ y: expanded ? i * (ROW_H + GAP) : i * PLATE, scale: expanded ? 1 : 1 - i * 0.05, opacity: expanded || i < 3 ? 1 : 0 }}
                transition={t}
                onClick={toggle}
                style={{
                  position: "absolute",
                  left: 0,
                  top: 0,
                  width: 300,
                  height: ROW_H,
                  transformOrigin: "50% 0",
                  zIndex: ITEMS.length - i,
                  borderRadius: 18,
                  background: Palette.elevated,
                  boxShadow: `0 4px 10px ${black(0.08)}`,
                  cursor: "pointer",
                }}
              >
                <motion.div initial={false} animate={{ opacity: shown ? 1 : 0.001 }} transition={t} style={{ position: "absolute", inset: 0 }}>
                  <Row item={item} ctx={ctx} />
                </motion.div>
                <motion.div
                  initial={false}
                  animate={{ opacity: shown ? 0 : 1 }}
                  transition={t}
                  style={{ position: "absolute", inset: 0, borderRadius: 18, background: hex(item.colors[0], 0.14), pointerEvents: "none" }}
                />
                <div style={{ position: "absolute", inset: 0, borderRadius: 18, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
              </motion.div>
            );
          })}
        </motion.div>
        <div style={{ width: 300, paddingTop: 4, display: ctx.isPreview ? "none" : "block" }}>
          <DemoHint ctx={ctx} en="Tap the stack" zh="点击通知组" />
        </div>
      </div>
    </div>
  );
}

function Row({ item, ctx }: { item: Item; ctx: DemoContext }) {
  const { Icon } = item;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "0 12px", width: 300, height: ROW_H }}>
      <div style={{ width: 38, height: 38, borderRadius: 10, background: diag(item.colors), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
        <Icon size={19} strokeWidth={item.filled ? 0 : 2.4} fill={item.filled ? "currentColor" : "none"} />
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 2, minWidth: 0, flex: 1 }}>
        <div style={{ display: "flex", alignItems: "center" }}>
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{tr(ctx, item.app)}</span>
          <span style={{ flex: 1 }} />
          <span style={{ fontSize: 11, lineHeight: "13px", color: Palette.secondaryLabel }}>{tr(ctx, item.time)}</span>
        </div>
        <span style={{ fontSize: 13, lineHeight: "18px", color: Palette.secondaryLabel, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{tr(ctx, item.message)}</span>
      </div>
    </div>
  );
}
