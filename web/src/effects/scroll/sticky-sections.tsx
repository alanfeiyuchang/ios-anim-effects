/** scroll.sticky-sections · 吸顶分组标题 (Scroll+StickySections.swift) */
import { useRef, useState } from "react";
import { Palette, anim, fonts, glass, useAutoplay, type DemoProps } from "../../kit";
import { ROW_HEIGHT, ScrollKitRow, useScroller, useSelectionTick } from "./_kit";

const SECTIONS: { title: [string, string]; rows: number[]; tint: string }[] = [
  { title: ["Today", "今天"], rows: [0, 1, 2, 3], tint: Palette.indigo },
  { title: ["Yesterday", "昨天"], rows: [4, 5, 6, 7, 8], tint: Palette.coral },
  { title: ["This week", "本周"], rows: [9, 10, 11, 2, 5, 7], tint: Palette.mint },
];
const HEADER = 48;
const GAP = 10;
const TOP = 12;
const STOPS = [0, 170, 400, 700, 400];

/** Content y of each section's header, and where its section ends (the next header's top). */
const LAYOUT = (() => {
  let y = TOP;
  return SECTIONS.map((s) => {
    const start = y;
    y += HEADER + GAP + s.rows.length * (ROW_HEIGHT + GAP);
    return { start, end: y };
  });
})();

/** 0: below the top edge · 1: pinned (or less than half pushed off) · 2: mostly pushed off · 3: gone. */
function band(minY: number) {
  if (minY > 0.5) return 0;
  if (minY > -24) return 1;
  if (minY > -48) return 2;
  return 3;
}

export default function StickySections({ ctx }: DemoProps) {
  const step = useRef(0);
  const scripted = useRef(false);
  const [pinnedSection, setPinnedSection] = useState(0);
  const sc = useScroller({
    axis: "y",
    onPhase: (p) => {
      if (p === "interacting") scripted.current = false;
    },
  });
  useAutoplay(
    ctx.isPreview,
    () => {
      step.current = (step.current + 1) % STOPS.length;
      scripted.current = true;
      sc.scrollTo(STOPS[step.current], anim.smoothD(1.5));
    },
    { every: 2.0 },
  );

  // The header's frame in the scroll view: its natural place, or pinned at 0 until the next header pushes it off.
  const bands = LAYOUT.map(({ start, end }) => band(start - sc.offset > 0 ? start - sc.offset : Math.min(0, end - sc.offset - HEADER)));
  const reading = bands.indexOf(1);
  if (reading >= 0 && reading !== pinnedSection) setPinnedSection(reading);
  useSelectionTick(pinnedSection, ctx.isPreview, scripted);

  const collapsed = ctx.n("collapsed");
  const material = ctx.b("material");
  const tint = ctx.b("tint");

  return (
    <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
      <div ref={sc.contentRef} style={{ paddingTop: TOP, paddingBottom: 24 - GAP }}>
        {SECTIONS.map((s, k) => {
          const pinned = bands[k] === 1 || bands[k] === 2;
          return (
            <div key={k} style={{ display: "flex", flexDirection: "column", gap: GAP, paddingBottom: GAP }}>
              <div style={{ position: "sticky", top: 0, zIndex: 2, height: HEADER, flexShrink: 0 }}>
                <div
                  style={{
                    position: "absolute",
                    inset: 0,
                    ...glass("bar"),
                    boxShadow: `inset 0 -0.5px 0 ${Palette.labelAlpha(0.08)}`,
                    opacity: pinned && material ? 1 : 0,
                    transition: "opacity 0.3s cubic-bezier(0.2, 0.9, 0.3, 1)",
                  }}
                />
                <div style={{ position: "relative", height: "100%", padding: "0 22px", display: "flex", alignItems: "center" }}>
                  <span
                    style={{
                      fontFamily: fonts.rounded,
                      fontWeight: 700,
                      fontSize: pinned ? collapsed : 22,
                      transition: "font-size 0.3s cubic-bezier(0.2, 0.9, 0.3, 1)",
                    }}
                  >
                    {ctx.lang === "zh" ? s.title[1] : s.title[0]}
                  </span>
                  <span style={{ flex: 1 }} />
                  <span
                    style={{
                      padding: "3px 9px",
                      borderRadius: 999,
                      fontSize: 12,
                      lineHeight: "16px",
                      fontWeight: 700,
                      fontVariantNumeric: "tabular-nums",
                      color: pinned && tint ? "#fff" : Palette.secondaryLabel,
                      background: pinned && tint ? s.tint : Palette.labelAlpha(0.07),
                      transition: "background 0.3s, color 0.3s",
                    }}
                  >
                    {s.rows.length}
                  </span>
                </div>
              </div>
              {s.rows.map((r, i) => (
                <ScrollKitRow key={i} index={r} lang={ctx.lang} style={{ margin: "0 20px", flexShrink: 0 }} />
              ))}
            </div>
          );
        })}
      </div>
    </div>
  );
}
