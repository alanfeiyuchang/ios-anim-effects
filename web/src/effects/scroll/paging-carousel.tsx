/** scroll.paging-carousel · 吸附轮播 (Scroll+PagingCarousel.swift) */
import { useRef } from "react";
import { Palette, clamp, spring, useAutoplay, type DemoProps } from "../../kit";
import { ScrollKitArt, SnapMarkers, strideSnap, useScroller } from "./_kit";

const COUNT = 6;
const CARD_W = 210;
const CARD_H = 250;
const WIDTH = 340;

export default function PagingCarousel({ ctx }: DemoProps) {
  const spacing = ctx.n("spacing");
  const pitch = CARD_W + spacing;
  const sc = useScroller({ axis: "x", initial: pitch, snap: strideSnap(pitch) });
  const direction = useRef(1);

  useAutoplay(
    ctx.isPreview,
    () => {
      const now = clamp(Math.round(sc.get() / pitch), 0, COUNT - 1);
      if (now + direction.current >= COUNT || now + direction.current < 0) direction.current = -direction.current;
      sc.scrollTo((now + direction.current) * pitch, spring(0.6, 0.88));
    },
    { every: 1.6 },
  );

  const sideScale = ctx.n("sideScale");
  const margin = (WIDTH - CARD_W) / 2;
  const contentWidth = margin * 2 + COUNT * CARD_W + (COUNT - 1) * spacing;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div {...sc.props} style={{ ...sc.props.style, width: WIDTH, height: 260, flexShrink: 0 }}>
        <div ref={sc.contentRef} style={{ position: "relative", width: contentWidth, height: "100%" }}>
          <SnapMarkers count={COUNT} pitch={pitch} />
          {Array.from({ length: COUNT }, (_, i) => {
            const d = clamp((i * pitch - sc.offset) / pitch, -1, 1);
            const t = Math.abs(d);
            return (
              <div
                key={i}
                style={{
                  position: "absolute",
                  left: margin + i * pitch,
                  top: 5,
                  width: CARD_W,
                  height: CARD_H,
                  borderRadius: 28,
                  overflow: "hidden",
                  transform: `translateY(${10 * t}px) translateY(${CARD_H / 2}px) rotate(${d * 8}deg) translateY(${-CARD_H / 2}px) scale(${1 - (1 - sideScale) * t})`,
                  opacity: 1 - t * 0.35,
                }}
              >
                <ScrollKitArt index={i + 2} lang={ctx.lang} />
              </div>
            );
          })}
        </div>
      </div>
      <PageDots count={COUNT} progress={sc.offset / Math.max(pitch, 1)} />
    </div>
  );
}

/** Liquid page indicator: the trailing edge races to the next dot, then the leading edge catches up. */
function PageDots({ count, progress }: { count: number; progress: number }) {
  const dot = 7;
  const gap = 6;
  const step = dot + gap;
  const clamped = clamp(progress, 0, Math.max(count - 1, 0));
  const page = Math.floor(clamped);
  const f = clamped - page;
  const lead = page * step + Math.max(0, f * 2 - 1) * step;
  const trail = page * step + dot + Math.min(1, f * 2) * step;
  return (
    <div style={{ position: "relative", display: "flex", gap, flexShrink: 0 }}>
      {Array.from({ length: count }, (_, i) => (
        <div key={i} style={{ width: dot, height: dot, borderRadius: "50%", background: Palette.labelAlpha(0.18) }} />
      ))}
      <div style={{ position: "absolute", left: lead, top: 0, width: trail - lead, height: dot, borderRadius: dot / 2, background: Palette.primary }} />
    </div>
  );
}
