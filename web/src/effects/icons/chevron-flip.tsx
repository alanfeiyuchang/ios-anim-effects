/** icons.chevron-flip · 箭头折翼翻转 (Icons+ChevronFlip.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useEffect, useState } from "react";
import { DemoHint, Palette, delayed, demoCard, spring, textStyle, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { Glyph, tintGradient, type GlyphDef } from "./_icons-kit";

const SHIPPINGBOX_FILL: GlyphDef = [
  {
    d: "M11 21.73a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73z",
    cut: { d: "M12 22V12M3.29 7 12 12l8.71-5M7.5 4.27l9 5.15", sw: 1.6 },
  },
];

const DETAILS: [string, string, string, string][] = [
  ["Items", "商品", "2 × Trail runners", "2 × 越野跑鞋"],
  ["Delivery", "配送", "Thu, 14:00–16:00", "周四 14:00–16:00"],
  ["Total", "合计", "$248.00", "¥1,688.00"],
];

/** bend 1 = "∨", 0 = "—", −1 = "∧" in a 13 × 7 box. */
const chevronPath = (bend: number) => {
  const depth = 3.5 * bend;
  return `M0 ${3.5 - depth}L6.5 ${3.5 + depth}L13 ${3.5 - depth}`;
};

export default function ChevronFlip({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpen] = useState(false);
  const s = spring(ctx.n("response"), ctx.n("damping"));
  const rotate = ctx.i("style") === 1;

  const bend = useMotionValue(1);
  const d = useTransform(bend, chevronPath);
  const target = rotate ? 1 : open ? -1 : 1;
  const response = ctx.n("response");
  const damping = ctx.n("damping");
  useEffect(() => {
    const a = animate(bend, target, spring(response, damping));
    return () => a.stop();
  }, [target, response, damping, bend]);

  const toggle = () => {
    haptics.tap("light");
    setOpen((o) => !o);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.6 });
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ height: 250, width: 290 }}>
        <div style={{ ...demoCard(22), width: 290, padding: 16, overflow: "hidden" }}>
          <div onClick={toggle} style={{ display: "flex", alignItems: "center", gap: 12, paddingBottom: 4, cursor: "pointer" }}>
            <div style={{ width: 36, height: 36, borderRadius: 10, background: tintGradient(Palette.coral), display: "grid", placeItems: "center", color: "#fff" }}>
              <Glyph def={SHIPPINGBOX_FILL} size={20} />
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={{ ...textStyle.subheadline, fontWeight: 600 }}>{zh ? "订单 #4721" : "Order #4721"}</span>
              <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{zh ? "预计周四送达" : "Arriving Thursday"}</span>
            </div>
            <div style={{ flex: 1 }} />
            <div style={{ width: 34, height: 34, borderRadius: "50%", background: Palette.labelAlpha(0.07), display: "grid", placeItems: "center" }}>
              <motion.svg width={13} height={7} viewBox="0 0 13 7" initial={false} animate={{ rotate: rotate && open ? 180 : 0 }} transition={s} style={{ overflow: "visible" }}>
                <motion.path d={d} fill="none" stroke={Palette.label} strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round" />
              </motion.svg>
            </div>
          </div>
          <motion.div initial={false} animate={{ height: open ? 10 + 3 * 16 + 2 * 10 : 0 }} transition={s} style={{ overflow: "visible" }}>
            <div style={{ paddingTop: 10, display: "flex", flexDirection: "column", gap: 10 }}>
              {DETAILS.map((row, i) => (
                <motion.div
                  key={i}
                  initial={false}
                  animate={{ opacity: open ? 1 : 0, y: open ? 0 : -8 }}
                  transition={open ? delayed(s, i * 0.04) : { duration: 0.15, ease: [0.42, 0, 1, 1], delay: (DETAILS.length - 1 - i) * 0.04 }}
                  style={{ display: "flex", ...textStyle.footnote, lineHeight: "16px" }}
                >
                  <span style={{ color: Palette.secondaryLabel }}>{zh ? row[1] : row[0]}</span>
                  <span style={{ flex: 1 }} />
                  <span style={{ fontWeight: 600 }}>{zh ? row[3] : row[2]}</span>
                </motion.div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap the row" zh="点击这一行" />
    </div>
  );
}
