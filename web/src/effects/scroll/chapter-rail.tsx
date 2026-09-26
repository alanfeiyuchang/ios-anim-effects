/** scroll.chapter-rail · 章节导轨 (Scroll+ChapterRail.swift) */
import { motion } from "motion/react";
import { useRef } from "react";
import { NumericText, Palette, PlaceholderLines, anim, black, clamp, glass, spring, useAutoplay, type DemoProps } from "../../kit";
import { FadeText, ScrollKitArt, useScroller } from "./_kit";

const TITLES: [string, string][] = [["Timing", "时长"], ["Easing", "缓动"], ["Springs", "弹簧"], ["Choreography", "编排"], ["Restraint", "克制"]];
const HEIGHTS = [300, 340, 300, 360, 320];
const SPACING = 24;
const TOP = 56;
const TARGETS = [200, 480, 820, 1150, 1500, 0];

const start = (i: number) => TOP + HEIGHTS.slice(0, i).reduce((a, h) => a + h + SPACING, 0);

/** Continuous chapter position: 2.5 = halfway through chapter 3. */
function chapterPosition(y: number) {
  for (let i = 0; i < TITLES.length; i++) {
    const length = HEIGHTS[i] + SPACING;
    if (y < start(i) + length) return i + clamp((y - start(i)) / length);
  }
  return TITLES.length;
}

export default function ChapterRail({ ctx }: DemoProps) {
  const sc = useScroller({ axis: "y" });
  const step = useRef(0);
  useAutoplay(
    ctx.isPreview,
    () => {
      const target = TARGETS[step.current % TARGETS.length];
      step.current += 1;
      sc.scrollTo(target, anim.smoothD(1.1));
    },
    { every: 1.5 },
  );

  // (+0.5: a jump to a chapter lands on its start despite scroll positions rounding to device pixels)
  const reading = chapterPosition(sc.offset + 40 + 0.5);
  const active = Math.min(Math.floor(reading), TITLES.length - 1);
  const gap = ctx.n("gap");
  const length = gap * (TITLES.length - 1);
  const fill = clamp(reading * gap, 0, length);
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
        <div ref={sc.contentRef} style={{ padding: `${TOP}px 48px 260px 20px`, display: "flex", flexDirection: "column", gap: SPACING }}>
          {TITLES.map((title, i) => (
            <div key={i} style={{ height: HEIGHTS[i], flexShrink: 0, display: "flex", flexDirection: "column", gap: 12 }}>
              <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 800, fontVariantNumeric: "tabular-nums", color: Palette.accent }}>{String(i + 1).padStart(2, "0")}</div>
              <div style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{zh ? title[1] : title[0]}</div>
              <PlaceholderLines count={4} />
              <div style={{ position: "relative", height: 70, borderRadius: 14, overflow: "hidden", flexShrink: 0 }}>
                <ScrollKitArt index={i + 2} lang={ctx.lang} showsTitle={false} />
              </div>
              <PlaceholderLines count={3} />
            </div>
          ))}
        </div>
      </div>
      {/* The rail */}
      <div
        style={{
          position: "absolute",
          right: 16,
          top: "50%",
          marginTop: -(length + 28) / 2,
          width: 24,
          height: length + 28,
          padding: "14px 0",
          borderRadius: 12,
          ...glass("ultraThin"),
        }}
      >
        <div style={{ position: "relative", width: 24, height: length }}>
          <div style={{ position: "absolute", left: 11, top: 0, width: 2, height: length, borderRadius: 1, background: Palette.labelAlpha(0.1) }} />
          <div
            style={{
              position: "absolute",
              left: 11,
              top: 0,
              width: 2,
              height: length,
              borderRadius: 1,
              background: `linear-gradient(${Palette.mint}, ${Palette.sky}, ${Palette.violet})`,
              transformOrigin: "50% 0%",
              transform: `scaleY(${Math.max(fill / Math.max(length, 1), 0.001)})`,
            }}
          />
          {TITLES.map((_, i) => {
            const on = i === active;
            const lit = on || i < active;
            return (
              <div
                key={i}
                onClick={() => sc.scrollTo(start(i) - 40, anim.smoothD(0.7))}
                style={{ position: "absolute", left: 0, top: i * gap - 12, width: 24, height: 24, display: "grid", placeItems: "center", cursor: "pointer" }}
              >
                <motion.div
                  initial={false}
                  animate={{ width: on ? 10 : 8, height: on ? 24 : 8 }}
                  transition={spring(0.35, 0.62)}
                  style={{
                    borderRadius: 999,
                    background: lit ? Palette.primary : Palette.elevated,
                    boxShadow: lit ? "none" : `inset 0 0 0 1px ${Palette.labelAlpha(0.25)}`,
                  }}
                />
              </div>
            );
          })}
        </div>
      </div>
      {ctx.b("chip") && (
        <div style={{ position: "absolute", left: 0, right: 0, top: 10, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
          <motion.div
            layout
            transition={spring(0.5, 0.85)}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 6,
              padding: "5px 12px 5px 5px",
              borderRadius: 999,
              ...glass("regular"),
              boxShadow: `0 3px 8px ${black(0.1)}`,
            }}
          >
            <div style={{ width: 20, height: 20, borderRadius: "50%", background: Palette.primary, color: "#fff", display: "grid", placeItems: "center", fontSize: 12, fontWeight: 700 }}>
              <NumericText value={active} text={String(active + 1)} />
            </div>
            <FadeText text={zh ? TITLES[active][1] : TITLES[active][0]} style={{ fontSize: 13, lineHeight: "18px", fontWeight: 600 }} />
          </motion.div>
        </div>
      )}
    </div>
  );
}
