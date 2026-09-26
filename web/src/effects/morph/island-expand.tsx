/** morph.island-expand · 灵动岛展开 (Morph+IslandExpand.swift) */
import { motion } from "motion/react";
import { CarFront as Car, MessageCircle, Phone } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, anim, black, delayed, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { sheen } from "./_shared";

export default function IslandExpand({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [wide, setWide] = useState(false);
  const [tall, setTall] = useState(false);
  const [showContent, setShowContent] = useState(false);
  const zh = ctx.lang === "zh";
  const response = ctx.n("response");
  const damping = ctx.n("damping");
  const lag = ctx.n("stagger");
  const [opening, setOpening] = useState(true);

  const toggle = () => {
    haptics.tap(wide ? "light" : "medium");
    if (!wide) {
      setOpening(true);
      setWide(true);
      setTall(true);
      setShowContent(true);
    } else {
      setOpening(false);
      setShowContent(false);
      setTall(false);
      setWide(false);
    }
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.9 });

  // Each axis rides its own withAnimation: width first, then height, then the content cross-fade.
  const widthT = opening ? spring(response, damping) : delayed(spring(response, damping), 0.05 + lag);
  const tallT = opening ? delayed(spring(response * 1.1, Math.min(damping + 0.06, 1)), lag) : delayed(spring(response, 0.86), 0.05);
  const contentT = opening ? delayed(anim.easeOut(0.3), lag * 2 + 0.05) : anim.easeIn(0.14);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <motion.div
        onClick={toggle}
        initial={false}
        animate={{
          width: wide ? 300 : 126,
          height: tall ? 156 : 37,
          borderRadius: tall ? 42 : 18.5,
          boxShadow: `0 ${tall ? 10 : 3}px ${tall ? 18 : 6}px ${black(0.25)}`,
        }}
        transition={{ width: widthT, height: tallT, borderRadius: tallT, boxShadow: tallT }}
        style={{ marginTop: 30, position: "relative", background: "#000", overflow: "hidden", cursor: "pointer", flexShrink: 0 }}
      >
        <motion.div
          initial={false}
          animate={{ opacity: showContent ? 0 : 1 }}
          transition={contentT}
          style={{ position: "absolute", left: 0, right: 0, top: 0, height: 37, padding: "0 14px", display: "flex", alignItems: "center", color: Palette.green }}
        >
          <Car size={15} strokeWidth={1.6} fill="currentColor" />
          <span style={{ flex: 1 }} />
          <span style={{ fontSize: 13, fontWeight: 600, fontVariantNumeric: "tabular-nums" }}>4m</span>
        </motion.div>
        <motion.div
          initial={false}
          animate={{ opacity: showContent ? 1 : 0, filter: `blur(${showContent ? 0 : 8}px)`, scale: showContent ? 1 : 0.9 }}
          transition={contentT}
          style={{
            position: "absolute",
            left: "50%",
            top: 0,
            marginLeft: -150,
            width: 300,
            height: 156,
            padding: "20px 20px 0",
            transformOrigin: "50% 0%",
            display: "flex",
            flexDirection: "column",
            gap: 12,
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 40, height: 40, borderRadius: 20, background: sheen(Palette.green), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
              <Car size={20} strokeWidth={1.6} fill="currentColor" />
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 2, minWidth: 0 }}>
              <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, color: white(0.6) }}>{zh ? "即将到达" : "Arriving in"}</span>
              <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: "#fff", whiteSpace: "nowrap" }}>{zh ? "灰色轿车 · 7KD 214" : "Grey sedan · 7KD 214"}</span>
            </div>
            <span style={{ flex: 1 }} />
            <span style={{ fontSize: 22, lineHeight: "28px", fontWeight: 700, fontVariantNumeric: "tabular-nums", color: Palette.green, whiteSpace: "nowrap" }}>
              {zh ? "4 分钟" : "4 min"}
            </span>
          </div>
          <div style={{ position: "relative", height: 6, borderRadius: 3, background: white(0.15) }}>
            <div style={{ position: "absolute", left: 0, top: 0, width: 170, height: 6, borderRadius: 3, background: Palette.green }} />
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12, lineHeight: "16px", fontWeight: 600, color: white(0.75) }}>
            <span>{zh ? "在主街上车" : "Pickup at Main St."}</span>
            <span style={{ flex: 1 }} />
            <Phone size={13} strokeWidth={1.4} fill="currentColor" />
            <MessageCircle size={13} strokeWidth={1.4} fill="currentColor" />
          </div>
        </motion.div>
      </motion.div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the island" zh="点击灵动岛" style={{ paddingBottom: 16 }} />
    </div>
  );
}
