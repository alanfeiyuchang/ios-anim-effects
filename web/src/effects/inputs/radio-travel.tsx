/** inputs.radio-travel · 流动单选 (Inputs+RadioTravel.swift) */
import { LayoutGroup, animate, motion, useMotionValue, useTransform } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, demoCard, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";

const ROW = 56;
const DOT = 10;
const PREVIEW_ORDER = [3, 0, 2, 1];
const OPTIONS = [
  { title: ["Standard", "标准配送"], eta: ["5–7 days", "5–7 天"], price: 0 },
  { title: ["Express", "快速配送"], eta: ["2–3 days", "2–3 天"], price: 6 },
  { title: ["Next day", "次日达"], eta: ["Tomorrow", "明天送达"], price: 12 },
  { title: ["Same day", "当日达"], eta: ["By 9 pm", "今晚 9 点前"], price: 18 },
] as const;

const dotCenter = (i: number) => i * ROW + ROW / 2;

export default function RadioTravel({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [selected, setSelected] = useState(1);
  const sel = useRef(1);
  const generation = useRef(0);
  const step = useRef(0);
  const topEdge = useMotionValue(79);
  const bottomEdge = useMotionValue(89);
  const height = useTransform(() => Math.max(bottomEdge.get() - topEdge.get(), DOT));
  const zh = ctx.lang === "zh";

  const choose = (index: number, muted = false) => {
    if (index === sel.current) return;
    generation.current += 1;
    const current = generation.current;
    const movingDown = index > sel.current;
    const newTop = dotCenter(index) - DOT / 2;
    const newBottom = dotCenter(index) + DOT / 2;
    const head = spring(ctx.n("head"), 0.8);
    const tail = spring(ctx.n("tail"), 0.7);
    sel.current = index;
    setSelected(index);
    if (movingDown) animate(bottomEdge, newBottom, head);
    else animate(topEdge, newTop, head);
    after(ctx.n("lag"), () => {
      if (current !== generation.current) return;
      if (movingDown) animate(topEdge, newTop, tail);
      else animate(bottomEdge, newBottom, tail);
      after(0.12, () => !muted && haptics.selection());
    });
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const target = PREVIEW_ORDER[step.current % PREVIEW_ORDER.length];
      step.current += 1;
      choose(target, true);
    },
    { every: 1.2, delay: 0.4 },
  );

  const total = 42 + OPTIONS[selected].price;
  const cur = zh ? "¥" : "$";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 310, padding: 12, display: "flex", flexDirection: "column", gap: 10 }}>
        <div style={{ position: "relative" }}>
          <LayoutGroup>
            {OPTIONS.map((o, index) => {
              const isSelected = index === selected;
              return (
                <div
                  key={index}
                  onClick={() => choose(index)}
                  style={{ position: "relative", height: ROW, padding: "0 12px", display: "flex", alignItems: "center", gap: 12, cursor: "pointer" }}
                >
                  {isSelected && (
                    <motion.div
                      layoutId="radio-highlight"
                      transition={spring(0.4, 0.8)}
                      style={{ position: "absolute", inset: 0, borderRadius: 14, background: "rgb(110 123 255 / 0.1)" }}
                    />
                  )}
                  <div
                    style={{
                      position: "relative",
                      width: 22,
                      height: 22,
                      borderRadius: "50%",
                      boxShadow: `inset 0 0 0 2px ${isSelected ? Palette.indigo : Palette.labelAlpha(0.25)}`,
                      transition: "box-shadow 0.25s ease-in-out",
                      flexShrink: 0,
                    }}
                  />
                  <div style={{ position: "relative", display: "flex", flexDirection: "column", gap: 1 }}>
                    <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label }}>{ctx.t(o.title[0], o.title[1])}</span>
                    <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{ctx.t(o.eta[0], o.eta[1])}</span>
                  </div>
                  <span style={{ flex: 1 }} />
                  <span
                    style={{
                      position: "relative",
                      fontSize: 15,
                      fontWeight: 500,
                      fontVariantNumeric: "tabular-nums",
                      color: isSelected ? Palette.indigo : Palette.secondaryLabel,
                    }}
                  >
                    {o.price === 0 ? ctx.t("Free", "免运费") : `${cur}${o.price}`}
                  </span>
                </div>
              );
            })}
          </LayoutGroup>
          <motion.div
            style={{
              position: "absolute",
              left: 12 + 11 - DOT / 2,
              top: 0,
              y: topEdge,
              width: DOT,
              height,
              borderRadius: DOT / 2,
              background: Palette.indigo,
              pointerEvents: "none",
            }}
          />
        </div>
        <div style={{ height: 1, background: Palette.labelAlpha(0.12), transform: "scaleY(0.5)" }} />
        <div style={{ display: "flex", alignItems: "center", padding: "0 8px", fontSize: 15, lineHeight: "20px", fontWeight: 600, fontVariantNumeric: "tabular-nums" }}>
          <span style={{ color: Palette.secondaryLabel }}>{ctx.t("Total", "合计")}</span>
          <span style={{ flex: 1 }} />
          <span style={{ color: Palette.label }}>
            <NumericText value={total} text={`${cur}${total.toFixed(2)}`} />
          </span>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Choose another option" zh="选择另一个选项" style={{ paddingBottom: 14 }} />
    </div>
  );
}
