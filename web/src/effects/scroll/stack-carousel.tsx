/** scroll.stack-carousel · 堆叠轮播 (Scroll+StackCarousel.swift) */
import { useRef, useState } from "react";
import { black, clamp, spring, useAutoplay, type DemoProps } from "../../kit";
import { FadeText, ScrollKit, ScrollKitArt, SnapMarkers, brightness, strideSnap, swiftBlur, useScroller, useSelectionTick } from "./_kit";

const COUNT = 8;
const CARD_W = 190;
const CARD_H = 240;
const SPACING = 16;
const PITCH = CARD_W + SPACING;
const WIDTH = 340;

export default function StackCarousel({ ctx }: DemoProps) {
  const [current, setCurrent] = useState(0);
  const direction = useRef(1);
  const scripted = useRef(false);
  const sc = useScroller({
    axis: "x",
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

  const peek = ctx.n("peek");
  const shrink = ctx.n("shrink");
  const pad = (WIDTH - CARD_W) / 2;
  const contentWidth = pad * 2 + COUNT * CARD_W + (COUNT - 1) * SPACING;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div {...sc.props} style={{ ...sc.props.style, width: WIDTH, height: 260, flexShrink: 0 }}>
        <div ref={sc.contentRef} style={{ position: "relative", width: contentWidth, height: "100%" }}>
          <SnapMarkers count={COUNT} pitch={PITCH} />
          {Array.from({ length: COUNT }, (_, i) => {
            const d = (i * PITCH - sc.offset) / PITCH;
            const past = Math.max(-d, 0);
            const pull = past * PITCH * (1 - peek);
            const scale = Math.max(1 - past * shrink, 0.5);
            return (
              <div
                key={i}
                onClick={() => select(i)}
                style={{
                  position: "absolute",
                  left: pad + i * PITCH,
                  top: 10,
                  width: CARD_W,
                  height: CARD_H,
                  cursor: "pointer",
                  transform: `translateX(${pull}px) scale(${scale})`,
                  filter: [brightness(-Math.min(past, 3) * 0.18), swiftBlur(Math.min(past * 1.5, 3))].filter(Boolean).join(" "),
                }}
              >
                <div style={{ position: "absolute", inset: 0, borderRadius: 26, overflow: "hidden", boxShadow: `0 6px 10px ${black(0.14)}` }}>
                  <ScrollKitArt index={i + 1} lang={ctx.lang} />
                </div>
              </div>
            );
          })}
        </div>
      </div>
      <FadeText text={ScrollKit.title(current + 1, ctx.lang)} style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }} />
    </div>
  );
}
