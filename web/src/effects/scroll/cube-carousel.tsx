/** scroll.cube-carousel · 立方体轮播 (Scroll+CubeCarousel.swift) */
import { motion } from "motion/react";
import { useRef } from "react";
import { Palette, anim, clamp, spring, useAutoplay, type DemoProps } from "../../kit";
import { ScrollKitArt, SnapMarkers, perspectivePx, strideSnap, useScroller } from "./_kit";

const COUNT = 6;
const PAGE = 300;
const HEIGHT = 260;

export default function CubeCarousel({ ctx }: DemoProps) {
  const sc = useScroller({ axis: "x", snap: strideSnap(PAGE) });
  const direction = useRef(1);
  const page = clamp(Math.round(sc.offset / PAGE), 0, COUNT - 1);

  useAutoplay(
    ctx.isPreview,
    () => {
      const now = clamp(Math.round(sc.get() / PAGE), 0, COUNT - 1);
      if (now + direction.current >= COUNT || now + direction.current < 0) direction.current = -direction.current;
      sc.scrollTo((now + direction.current) * PAGE, anim.smoothD(0.8));
    },
    { every: 1.6 },
  );

  const maxAngle = ctx.n("angle");
  const persp = perspectivePx(PAGE, HEIGHT, ctx.n("perspective"));
  const shade = ctx.n("shade");

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div {...sc.props} style={{ ...sc.props.style, width: PAGE, height: HEIGHT, flexShrink: 0 }}>
        <div ref={sc.contentRef} style={{ position: "relative", width: PAGE * COUNT, height: "100%" }}>
          <SnapMarkers count={COUNT} pitch={PAGE} />
          {Array.from({ length: COUNT }, (_, i) => {
            const minX = i * PAGE - sc.offset;
            const t = clamp(minX / PAGE, -1, 1);
            return (
              <div
                key={i}
                style={{
                  position: "absolute",
                  left: i * PAGE,
                  top: 0,
                  width: PAGE,
                  height: HEIGHT,
                  transformOrigin: t < 0 ? "100% 50%" : "0% 50%",
                  transform: `perspective(${persp}px) rotateY(${t * maxAngle}deg)`,
                }}
              >
                <div style={{ position: "absolute", inset: 0, borderRadius: 28, overflow: "hidden" }}>
                  <ScrollKitArt index={i + 3} lang={ctx.lang} />
                  <div style={{ position: "absolute", inset: 0, background: "#000", opacity: Math.min(Math.abs(minX) / PAGE, 1) * shade, pointerEvents: "none" }} />
                </div>
              </div>
            );
          })}
        </div>
      </div>
      <div style={{ display: "flex", gap: 6, flexShrink: 0 }}>
        {Array.from({ length: COUNT }, (_, i) => (
          <motion.div
            key={i}
            animate={{ width: i === page ? 22 : 7 }}
            transition={spring(0.4, 0.7)}
            style={{ height: 7, borderRadius: 4, background: i === page ? Palette.primary : Palette.labelAlpha(0.18) }}
          />
        ))}
      </div>
    </div>
  );
}
