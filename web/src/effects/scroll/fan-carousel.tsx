/** scroll.fan-carousel · 扇形手牌轮播 (Scroll+FanCarousel.swift) */
import { useRef, useState } from "react";
import { Palette, alpha, black, clamp, fonts, spring, useAutoplay, white, type DemoProps } from "../../kit";
import { FadeText, ScrollKit, ScrollKitArt, SnapMarkers, brightness, strideSnap, useScroller, useSelectionTick } from "./_kit";

const COUNT = 9;
const CARD_W = 140;
const CARD_H = 190;
const PITCH = 110;
const WIDTH = 340;
const INITIAL = 3;

export default function FanCarousel({ ctx }: DemoProps) {
  const [current, setCurrent] = useState(INITIAL);
  const direction = useRef(1);
  const scripted = useRef(false);
  const sc = useScroller({
    axis: "x",
    initial: INITIAL * PITCH,
    snap: strideSnap(PITCH),
    onScroll: (o) => setCurrent(clamp(Math.round(o / PITCH), 0, COUNT - 1)),
    onPhase: (p) => {
      if (p === "interacting") scripted.current = false;
    },
  });
  useSelectionTick(current, ctx.isPreview, scripted);

  const select = (i: number) => {
    scripted.current = false;
    sc.scrollTo(i * PITCH, spring(0.5, 0.86));
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      scripted.current = true;
      if (current + direction.current >= COUNT || current + direction.current < 0) direction.current = -direction.current;
      sc.scrollTo((current + direction.current) * PITCH, spring(0.6, 0.86));
    },
    { every: 1.3 },
  );

  const step = ctx.n("step");
  const radius = ctx.n("radius");
  const pad = (WIDTH - CARD_W) / 2;
  const contentWidth = pad * 2 + CARD_W + (COUNT - 1) * PITCH;
  const height = CARD_H + 80;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 8 }}>
      <div {...sc.props} style={{ ...sc.props.style, width: WIDTH, height, flexShrink: 0 }}>
        <div ref={sc.contentRef} style={{ position: "relative", width: contentWidth, height: "100%" }}>
          <SnapMarkers count={COUNT} pitch={PITCH} />
          {Array.from({ length: COUNT }, (_, i) => {
            const d = (i * PITCH - sc.offset) / PITCH;
            const theta = (d * step * Math.PI) / 180;
            const arcX = radius * Math.sin(theta);
            const arcY = radius * (1 - Math.cos(theta));
            const near = Math.min(Math.abs(d), 1);
            const focused = i === current;
            return (
              <div
                key={i}
                onClick={() => select(i)}
                style={{
                  position: "absolute",
                  left: pad + i * PITCH,
                  top: (height - CARD_H) / 2,
                  width: CARD_W,
                  height: CARD_H,
                  // The app's recording draws later cards on top (the zIndex has no effect inside its LazyHStack).
                  cursor: "pointer",
                  transform: `translate(${arcX - d * PITCH}px, ${arcY - 24}px) scale(${1 - near * 0.1}) rotate(${theta}rad)`,
                  filter: brightness(-near * 0.08),
                }}
              >
                <div
                  style={{
                    position: "absolute",
                    inset: 0,
                    borderRadius: 18,
                    boxShadow: focused ? `0 8px 18px ${alpha(Palette.violet, 0.45)}` : `0 4px 8px ${black(0.15)}`,
                    transition: "box-shadow 0.25s ease-out",
                  }}
                />
                <div style={{ position: "absolute", inset: 0, borderRadius: 18, overflow: "hidden" }}>
                  <ScrollKitArt index={i} lang={ctx.lang} showsTitle={false} />
                  <div
                    style={{
                      position: "absolute",
                      left: 12,
                      top: 12,
                      fontFamily: fonts.rounded,
                      fontSize: 20,
                      lineHeight: "24px",
                      fontWeight: 800,
                      fontVariantNumeric: "tabular-nums",
                      color: "#fff",
                    }}
                  >
                    {i + 1}
                  </div>
                </div>
                <div style={{ position: "absolute", inset: 0, borderRadius: 18, boxShadow: `inset 0 0 0 1px ${white(0.3)}` }} />
              </div>
            );
          })}
        </div>
      </div>
      <FadeText text={ScrollKit.title(current, ctx.lang)} style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }} />
    </div>
  );
}
