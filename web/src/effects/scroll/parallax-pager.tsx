/** scroll.parallax-pager · 视差分页 (Scroll+ParallaxPager.swift) */
import { useRef } from "react";
import { Palette, black, clamp, spring, useAutoplay, white, type DemoProps } from "../../kit";
import { ScrollKit, SnapMarkers, Sym, strideSnap, useScroller } from "./_kit";

const COUNT = 6;
const SIDE = 250;
const SPACING = 12;
const PITCH = SIDE + SPACING;
const WIDTH = 340;

export default function ParallaxPager({ ctx }: DemoProps) {
  const sc = useScroller({ axis: "x", snap: strideSnap(PITCH) });
  const direction = useRef(1);

  useAutoplay(
    ctx.isPreview,
    () => {
      const now = clamp(Math.round(sc.get() / PITCH), 0, COUNT - 1);
      if (now + direction.current >= COUNT || now + direction.current < 0) direction.current = -direction.current;
      sc.scrollTo((now + direction.current) * PITCH, spring(0.7, 0.9));
    },
    { every: 1.6 },
  );

  const backdrop = ctx.n("backdrop");
  const lead = ctx.n("title");
  const margin = (WIDTH - SIDE) / 2;
  const contentWidth = margin * 2 + COUNT * SIDE + (COUNT - 1) * SPACING;
  const range = contentWidth - WIDTH;
  const progress = clamp(sc.offset / range);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div {...sc.props} style={{ ...sc.props.style, width: WIDTH, height: SIDE + 10, flexShrink: 0 }}>
        <div ref={sc.contentRef} style={{ position: "relative", width: contentWidth, height: "100%" }}>
          <SnapMarkers count={COUNT} pitch={PITCH} />
          {Array.from({ length: COUNT }, (_, i) => (
            <Window key={i} index={i} distance={i * PITCH - sc.offset} backdrop={backdrop} lead={lead} left={margin + i * PITCH} zh={ctx.lang === "zh"} />
          ))}
        </div>
      </div>
      <div style={{ position: "relative", width: 120, height: 4, borderRadius: 2, background: Palette.labelAlpha(0.1), flexShrink: 0 }}>
        <div style={{ position: "absolute", left: 0, top: 0, height: 4, borderRadius: 2, width: Math.max(120 * progress, 4), background: Palette.aurora }} />
      </div>
    </div>
  );
}

/** One card with three layers, each shifted by its own share of the card's distance from centre. */
function Window({ index, distance, backdrop, lead, left, zh }: { index: number; distance: number; backdrop: number; lead: number; left: number; zh: boolean }) {
  const lang = zh ? "zh" : "en";
  const colors = [...ScrollKit.colors(index + 1), ...ScrollKit.colors(index + 3)];
  const fade = 1 - Math.min(Math.abs(distance) / (PITCH / 2), 1);
  return (
    <div style={{ position: "absolute", left, top: 5, width: SIDE, height: SIDE, borderRadius: 28, overflow: "hidden" }}>
      <div
        style={{
          position: "absolute",
          top: 0,
          left: (SIDE - SIDE * 2.2) / 2,
          width: SIDE * 2.2,
          height: SIDE,
          background: `linear-gradient(90deg, ${colors.join(", ")})`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 34,
          transform: `translateX(${-distance * backdrop}px)`,
        }}
      >
        {Array.from({ length: 5 }, (_, k) => {
          const w = 40 + (k % 2) * 30;
          return <div key={k} style={{ width: w, height: w, borderRadius: "50%", flexShrink: 0, background: white(0.1 + (k % 3) * 0.06) }} />;
        })}
      </div>
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "grid",
          placeItems: "center",
          color: white(0.95),
          filter: `drop-shadow(0 6px 10px ${black(0.18)})`,
          transform: `translate(${-distance * 0.3}px, -16px)`,
        }}
      >
        <Sym name={ScrollKit.symbol(index + 2)} size={76} weight={600} />
      </div>
      <div
        style={{
          position: "absolute",
          left: 0,
          bottom: 0,
          padding: 18,
          display: "flex",
          flexDirection: "column",
          gap: 2,
          color: "#fff",
          transform: `translateX(${distance * lead}px)`,
          opacity: fade,
        }}
      >
        <div style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700, whiteSpace: "nowrap" }}>{ScrollKit.title(index + 2, lang)}</div>
        <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, opacity: 0.85, whiteSpace: "nowrap" }}>{ScrollKit.subtitle(index + 2, lang)}</div>
      </div>
      <div style={{ position: "absolute", inset: 0, borderRadius: 28, boxShadow: `inset 0 0 0 1px ${white(0.18)}`, pointerEvents: "none" }} />
    </div>
  );
}
