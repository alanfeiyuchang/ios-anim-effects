/** inputs.nps-scale (Inputs+NPSScale.swift) */
import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { useId, useRef, useState } from "react";
import { DemoHint, Palette, clamp, delayed, demoCard, fonts, spring, springDB, textStyle, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";

const BAR = 20;
const GAP = 5;
const ROW = BAR * 11 + GAP * 10;
const PREVIEW = [9, 4, 7, 10, 2, 8];

const colorFor = (v: number) => (v >= 9 ? Palette.mint : v >= 7 ? Palette.amber : Palette.coral);

export default function NPSScale({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const group = useId();
  const [score, setScore] = useState<number | null>(null);
  const [previous, setPrevious] = useState(0);
  const scoreRef = useRef<number | null>(null);
  const step = useRef(0);

  const select = (value: number) => {
    if (value === scoreRef.current) return;
    haptics.selection();
    setPrevious(scoreRef.current ?? 0);
    scoreRef.current = value;
    setScore(value);
  };

  const pan = usePan({
    onChange: ({ location }) => select(clamp(Math.floor(location.x / (BAR + GAP)), 0, 10)),
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      select(PREVIEW[step.current % PREVIEW.length]);
      step.current += 1;
    },
    { every: 1.3, delay: 0.3 },
  );

  const zh = ctx.lang === "zh";
  const caption =
    score === null ? (zh ? "选择一个分数" : "Pick a score") : score >= 9 ? (zh ? "推荐者" : "Promoter") : score >= 7 ? (zh ? "被动者" : "Passive") : zh ? "贬损者" : "Detractor";
  const selected = score ?? -1;
  const ink = ctx.scheme === "dark" ? "255 255 255" : "0 0 0";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: ROW + 36, padding: 18, display: "flex", flexDirection: "column", gap: 14 }}>
        <span style={{ ...textStyle.headline }}>{zh ? "您有多大可能向朋友推荐我们？" : "How likely are you to recommend us?"}</span>
        <LayoutGroup id={group}>
          <div {...pan} style={{ ...pan.style, width: ROW, height: 96, display: "flex", alignItems: "flex-end", gap: GAP, cursor: "pointer" }}>
            {Array.from({ length: 11 }, (_, value) => {
              const on = value <= selected;
              const base = 18 + value * 2;
              const delay = Math.abs(value - previous) * ctx.n("stagger");
              return (
                <div key={value} style={{ width: BAR, display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
                  <div style={{ height: 24, width: 28, display: "grid", placeItems: "center" }}>
                    {value === selected && (
                      <motion.div
                        layoutId="bubble"
                        transition={spring(0.35, 0.72)}
                        style={{
                          width: 28,
                          height: 24,
                          borderRadius: 8,
                          background: colorFor(value),
                          display: "grid",
                          placeItems: "center",
                          color: "#fff",
                          fontFamily: fonts.rounded,
                          fontSize: 13,
                          fontWeight: 700,
                          fontVariantNumeric: "tabular-nums",
                        }}
                      >
                        {value}
                      </motion.div>
                    )}
                  </div>
                  <motion.div
                    initial={false}
                    animate={{ height: on ? base + 14 : base, backgroundColor: on ? colorFor(selected) : `rgb(${ink} / 0.1)` }}
                    transition={{ height: delayed(spring(ctx.n("response"), ctx.n("damping")), delay), backgroundColor: springDB(0.25, 0) }}
                    style={{ width: BAR, borderRadius: 5 }}
                  />
                  <span
                    style={{
                      fontFamily: fonts.rounded,
                      fontSize: 10,
                      fontWeight: 600,
                      lineHeight: "12px",
                      fontVariantNumeric: "tabular-nums",
                      color: value === selected ? Palette.label : Palette.secondaryLabel,
                    }}
                  >
                    {value}
                  </span>
                </div>
              );
            })}
          </div>
        </LayoutGroup>
        <div style={{ display: "flex", alignItems: "center", ...textStyle.caption2, fontWeight: 500, color: Palette.tertiaryLabel }}>
          <span>{zh ? "不太可能" : "Not likely"}</span>
          <div style={{ flex: 1 }} />
          <div style={{ display: "grid", placeItems: "center" }}>
            <AnimatePresence initial={false}>
              <motion.span
                key={caption}
                initial={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
                animate={{ opacity: 1, filter: "blur(0px)", scale: 1 }}
                exit={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
                transition={springDB(0.3, 0)}
                style={{ gridArea: "1 / 1", ...textStyle.caption, fontWeight: 700, color: score === null ? Palette.secondaryLabel : colorFor(score), whiteSpace: "nowrap" }}
              >
                {caption}
              </motion.span>
            </AnimatePresence>
          </div>
          <div style={{ flex: 1 }} />
          <span>{zh ? "非常可能" : "Very likely"}</span>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap or drag across the bars" zh="点击或横向拖过柱子" style={{ paddingBottom: 18 }} />
    </div>
  );
}
