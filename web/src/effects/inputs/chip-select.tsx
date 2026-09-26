/** inputs.chip-select (Inputs+ChipSelect.swift) */
import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { Check } from "lucide-react";
import { useId, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, demoCard, spring, textStyle, useAutoplay, useHaptics, type DemoProps } from "../../kit";

const TOPICS: [string, string][] = [
  ["Design", "设计"],
  ["Motion", "动效"],
  ["Swift", "Swift"],
  ["Typography", "字体排印"],
  ["3D", "3D"],
  ["Color", "色彩"],
  ["Prototyping", "原型"],
  ["Sound", "声音"],
  ["AI", "AI"],
];
const ORDER = [0, 5, 1, 7, 3, 4, 8, 0, 5, 7, 3, 8];

export default function ChipSelect({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const group = useId();
  const [selected, setSelected] = useState<Set<number>>(() => new Set([1, 4]));
  const step = useRef(0);
  const t = spring(ctx.n("response"), ctx.n("damping"));
  const zh = ctx.lang === "zh";

  const toggle = (index: number) => {
    haptics.selection();
    setSelected((s) => {
      const next = new Set(s);
      if (next.has(index)) next.delete(index);
      else next.add(index);
      return next;
    });
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      toggle(ORDER[step.current % ORDER.length]);
      step.current += 1;
    },
    { every: 0.8, delay: 0.4 },
  );

  const ink = ctx.scheme === "dark" ? "255 255 255" : "0 0 0";

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ position: "relative" }}>
        <div style={{ ...demoCard(24), width: 310, padding: 20, display: "flex", flexDirection: "column", gap: 14 }}>
          <div style={{ display: "flex", alignItems: "baseline", gap: 4 }}>
            <span style={{ ...textStyle.headline }}>{zh ? "选择你的兴趣" : "Pick your interests"}</span>
            <div style={{ flex: 1 }} />
            {zh && <span style={{ ...textStyle.subheadline, color: Palette.secondaryLabel }}>已选</span>}
            <NumericText value={selected.size} style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.indigo }} />
            <span style={{ ...textStyle.subheadline, color: Palette.secondaryLabel }}>{zh ? "个" : "selected"}</span>
          </div>
          <LayoutGroup id={group}>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
              {TOPICS.map((topic, index) => {
                const on = selected.has(index);
                return (
                  <motion.button
                    key={index}
                    type="button"
                    layout
                    onClick={() => toggle(index)}
                    whileTap={{ scale: ctx.n("press") }}
                    transition={{ layout: t, scale: spring(0.25, 0.6), default: t }}
                    style={{
                      position: "relative",
                      height: 36,
                      padding: "0 14px",
                      borderRadius: 18,
                      display: "flex",
                      alignItems: "center",
                      gap: 5,
                      color: on ? "#fff" : Palette.label,
                      background: `rgb(${ink} / 0.07)`,
                      boxShadow: `0 4px 8px ${alpha(Palette.indigo, on ? 0.3 : 0)}`,
                      transitionProperty: "box-shadow, color",
                      transitionDuration: "0.3s",
                    }}
                  >
                    <motion.span
                      layout
                      initial={false}
                      animate={{ opacity: on ? 1 : 0 }}
                      transition={t}
                      style={{ position: "absolute", inset: 0, borderRadius: 18, background: Palette.primary }}
                    />
                    <AnimatePresence initial={false} mode="popLayout">
                      {on && (
                        <motion.span
                          key="check"
                          layout
                          initial={{ scale: 0.3, opacity: 0 }}
                          animate={{ scale: 1, opacity: 1 }}
                          exit={{ scale: 0.3, opacity: 0 }}
                          transition={t}
                          style={{ position: "relative", display: "grid" }}
                        >
                          <Check size={13} strokeWidth={3.6} />
                        </motion.span>
                      )}
                    </AnimatePresence>
                    <motion.span layout="position" transition={t} style={{ position: "relative", fontSize: 15, fontWeight: 500, whiteSpace: "nowrap" }}>
                      {zh ? topic[1] : topic[0]}
                    </motion.span>
                  </motion.button>
                );
              })}
            </div>
          </LayoutGroup>
        </div>
        <div style={{ position: "absolute", left: -20, right: -20, bottom: -34, display: "flex", justifyContent: "center" }}>
          <DemoHint ctx={ctx} en="Tap tags to pick your interests" zh="点选你感兴趣的标签" />
        </div>
      </div>
    </div>
  );
}
