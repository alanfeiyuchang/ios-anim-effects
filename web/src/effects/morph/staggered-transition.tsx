/** morph.staggered-transition · 错峰转场 (Morph+StaggeredTransition.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Calendar, CreditCard, MessageCircle, PersonStanding } from "lucide-react";
import { useState } from "react";
import { Palette, anim, black, delayed, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { diag, sheen } from "./_shared";

const notices: { Icon: typeof Calendar; fill: boolean; color: string; app: [string, string]; message: [string, string] }[] = [
  { Icon: MessageCircle, fill: true, color: Palette.green, app: ["Messages", "信息"], message: ["Lunch at 12:30?", "12:30 一起吃午饭？"] },
  { Icon: Calendar, fill: false, color: Palette.red, app: ["Calendar", "日历"], message: ["Design review in 15 min", "15 分钟后设计评审"] },
  { Icon: PersonStanding, fill: false, color: Palette.coral, app: ["Fitness", "健身"], message: ["Close your move ring", "完成今天的活动圆环"] },
  { Icon: CreditCard, fill: false, color: Palette.indigo, app: ["Wallet", "钱包"], message: ["Payment received", "已收到一笔付款"] },
];

export default function StaggeredTransition({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [shown, setShown] = useState(false);
  const lang = ctx.lang === "zh" ? 1 : 0;
  const distance = ctx.n("distance");
  const stagger = ctx.n("stagger");
  const response = ctx.n("response");

  const toggle = () => {
    haptics.tap();
    setShown((s) => !s);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 2.0, delay: 0.3 });

  return (
    <div style={{ position: "absolute", inset: 0, padding: 18, display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
      <div style={{ flex: 1, alignSelf: "stretch", display: "flex", flexDirection: "column", gap: 8 }}>
        <AnimatePresence>
          {shown &&
            notices.map((notice, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, filter: "blur(8px)", scale: 0.92, y: distance }}
                animate={{ opacity: 1, filter: "blur(0px)", scale: 1, y: 0, transition: delayed(spring(response, 0.82), index * stagger) }}
                exit={{
                  opacity: 0,
                  filter: "blur(8px)",
                  scale: 0.92,
                  y: -distance * 0.5,
                  transition: delayed(anim.easeIn(0.22), (notices.length - 1 - index) * stagger * 0.6),
                }}
                style={{
                  transformOrigin: "50% 0%",
                  height: 54,
                  flexShrink: 0,
                  padding: "0 12px",
                  borderRadius: 18,
                  ...glass("regular"),
                  boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 4px 8px ${black(0.06)}`,
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                }}
              >
                <span style={{ width: 34, height: 34, borderRadius: 9, background: sheen(notice.color), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
                  <notice.Icon size={17} strokeWidth={2.4} fill={notice.fill ? "currentColor" : "none"} />
                </span>
                <div style={{ display: "flex", flexDirection: "column", gap: 2, minWidth: 0 }}>
                  <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel }}>{notice.app[lang]}</span>
                  <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{notice.message[lang]}</span>
                </div>
                <span style={{ flex: 1 }} />
                <span style={{ fontSize: 11, lineHeight: "13px", color: Palette.tertiaryLabel }}>{lang ? "刚刚" : "now"}</span>
              </motion.div>
            ))}
        </AnimatePresence>
      </div>
      <button
        type="button"
        onClick={toggle}
        style={{ position: "relative", height: 42, padding: "0 20px", borderRadius: 21, background: diag(Palette.indigo, Palette.violet), color: "#fff", fontSize: 15, fontWeight: 600, flexShrink: 0 }}
      >
        <AnimatePresence initial={false} mode="popLayout">
          <motion.span key={String(shown)} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={spring(response, 0.82)} style={{ display: "inline-block" }}>
            {shown ? (lang ? "全部清除" : "Clear all") : lang ? "显示通知" : "Show notifications"}
          </motion.span>
        </AnimatePresence>
      </button>
    </div>
  );
}
