/** scroll.infinite-carousel · 无限循环轮播 (Scroll+InfiniteCarousel.swift) */
import { motion } from "motion/react";
import { Palette, clamp, spring, useAutoplay, type DemoProps } from "../../kit";
import { ScrollKitArt, SnapMarkers, brightness, strideSnap, swiftBlur, useScroller } from "./_kit";

const BASE = 6;
const COPIES = 5;
const CARD_W = 180;
const CARD_H = 220;
const SPACING = 14;
const PITCH = CARD_W + SPACING;
const WIDTH = 340;

export default function InfiniteCarousel({ ctx }: DemoProps) {
  const total = BASE * COPIES;
  const sc = useScroller({
    axis: "x",
    initial: BASE * 2 * PITCH,
    snap: strideSnap(PITCH),
    onPhase: (p) => {
      if (p !== "idle") return;
      // Jump (without animation) to the same card in the middle copy.
      const index = Math.round(sc.get() / PITCH);
      const target = BASE * 2 + (index % BASE);
      if (target !== index) sc.scrollTo(target * PITCH, null);
    },
  });
  const current = clamp(Math.round(sc.offset / PITCH), 0, total - 1);

  useAutoplay(
    ctx.isPreview || ctx.b("auto"),
    () => {
      if (sc.phaseRef.current.phase !== "idle") return;
      const index = Math.round(sc.get() / PITCH);
      if (index >= BASE * 4 - 1 || index <= BASE) {
        sc.scrollTo((BASE * 2 + (index % BASE)) * PITCH, null);
        return;
      }
      sc.scrollTo((index + 1) * PITCH, spring(0.55, 0.86));
    },
    { every: ctx.n("interval"), delay: 1.0 },
  );

  const shrink = ctx.n("scale");
  const sideBlur = ctx.n("blur");
  const margin = (WIDTH - CARD_W) / 2;
  const contentWidth = margin * 2 + total * CARD_W + (total - 1) * SPACING;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div {...sc.props} style={{ ...sc.props.style, width: WIDTH, height: 230, flexShrink: 0 }}>
        <div ref={sc.contentRef} style={{ position: "relative", width: contentWidth, height: "100%" }}>
          <SnapMarkers count={total} pitch={PITCH} />
          {Array.from({ length: total }, (_, i) => {
            const d = clamp((i * PITCH - sc.offset) / PITCH, -2, 2);
            const far = Math.min(Math.abs(d), 1.5);
            if (Math.abs(i * PITCH - sc.offset) > WIDTH * 1.5) return null;
            return (
              <div
                key={i}
                style={{
                  position: "absolute",
                  left: margin + i * PITCH,
                  top: 5,
                  width: CARD_W,
                  height: CARD_H,
                  borderRadius: 26,
                  overflow: "hidden",
                  zIndex: 40 - Math.abs(i - current),
                  transform: `translateX(${-d * 60}px) scale(${1 - shrink * far})`,
                  filter: [swiftBlur(sideBlur * far), brightness(-0.12 * far)].filter(Boolean).join(" "),
                  opacity: 1 - 0.3 * far,
                }}
              >
                <ScrollKitArt index={(i % BASE) * 2} lang={ctx.lang} />
              </div>
            );
          })}
        </div>
      </div>
      <div style={{ display: "flex", gap: 6, flexShrink: 0 }}>
        {Array.from({ length: BASE }, (_, i) => {
          const on = i === current % BASE;
          return (
            <motion.div
              key={i}
              animate={{ width: on ? 20 : 7 }}
              transition={spring(0.4, 0.72)}
              style={{ height: 7, borderRadius: 4, background: on ? Palette.aurora : Palette.labelAlpha(0.18) }}
            />
          );
        })}
      </div>
    </div>
  );
}
