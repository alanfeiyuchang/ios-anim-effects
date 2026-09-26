/** scroll.transition-list · 边缘渐隐列表 (Scroll+Transition.swift) */
import { useRef } from "react";
import { anim, useAutoplay, type DemoProps } from "../../kit";
import { ROW_HEIGHT, ScrollKitRow, edgePhase, perspectivePx, useScroller, swiftBlur } from "./_kit";

const COUNT = 24;
const GAP = 10;
const TOP = 16;

export default function TransitionList({ ctx }: DemoProps) {
  const sc = useScroller({ axis: "y" });
  const down = useRef(false);

  useAutoplay(
    ctx.isPreview,
    () => {
      down.current = !down.current;
      sc.scrollTo(down.current ? 620 : 0, anim.smoothD(2.2));
    },
    { every: 2.8 },
  );

  const style = ctx.i("style");
  const strength = ctx.n("strength");
  const viewport = sc.size.height;

  return (
    <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
      <div ref={sc.contentRef} style={{ padding: `${TOP}px 20px 16px`, display: "flex", flexDirection: "column", gap: GAP }}>
        {Array.from({ length: COUNT }, (_, i) => {
          const phase = edgePhase(TOP + i * (ROW_HEIGHT + GAP) - sc.offset, ROW_HEIGHT, viewport);
          const v = Math.abs(phase) * strength;
          const scale = style === 0 ? 1 - v * 0.15 : 1;
          const blur = style === 1 ? v * 10 : 0;
          const fold = style === 2 ? phase * 60 * strength : 0;
          return (
            <ScrollKitRow
              key={i}
              index={i}
              lang={ctx.lang}
              style={{
                flexShrink: 0,
                opacity: 1 - v * 0.8,
                transform: `scale(${scale}) perspective(${perspectivePx(300, ROW_HEIGHT, 0.6)}px) rotateX(${fold}deg)`,
                filter: swiftBlur(blur),
              }}
            />
          );
        })}
      </div>
    </div>
  );
}
