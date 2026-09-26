/** scroll.liquid-scrollbar · 液态滚动条 (Scroll+LiquidScrollbar.swift) */
import { motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { Palette, anim, clamp, spring, useAutoplay, type DemoProps } from "../../kit";
import { ScrollKitRow, ScrollVelocityTracker, useScroller } from "./_kit";

const INSET = 6;

export default function LiquidScrollbar({ ctx }: DemoProps) {
  const [velocity, setVelocity] = useState(0);
  const [visible, setVisible] = useState(false);
  const tracker = useRef(new ScrollVelocityTracker());
  const relaxTimer = useRef(0);
  const hideTimer = useRef(0);
  const down = useRef(false);
  useEffect(
    () => () => {
      window.clearTimeout(relaxTimer.current);
      window.clearTimeout(hideTimer.current);
    },
    [],
  );
  const sc = useScroller({
    axis: "y",
    onScroll: (o) => {
      setVelocity(tracker.current.sample(o, 1800));
      // A finger held still sends nothing: after 70 ms the spring pulls the thumb back to its length.
      window.clearTimeout(relaxTimer.current);
      relaxTimer.current = window.setTimeout(() => {
        tracker.current.reset();
        setVelocity(0);
      }, 70);
    },
    onPhase: (p) => {
      if (p !== "idle") {
        window.clearTimeout(hideTimer.current);
        setVisible(true);
      } else {
        window.clearTimeout(relaxTimer.current);
        tracker.current.reset();
        setVelocity(0);
        window.clearTimeout(hideTimer.current);
        hideTimer.current = window.setTimeout(() => setVisible(false), ctx.n("hide") * 1000);
      }
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      down.current = !down.current;
      sc.scrollTo(down.current ? "end" : 0, anim.easeInOut(1.3));
    },
    { every: 2.4 },
  );

  const viewport = Math.max(sc.size.height, 1);
  const range = Math.max(sc.max(), 1);
  const offset = sc.offset;
  const track = viewport - INSET * 2;
  const baseLength = Math.max((track * viewport) / (range + viewport), 28);
  const progress = clamp(offset / range);
  // Overscroll past either end squashes the thumb against that edge.
  const over = offset < 0 ? -offset : Math.max(offset - range, 0);
  const squash = Math.min(over / 120, 0.7);
  const speed = Math.min(Math.abs(velocity) / 1800, 1) * ctx.n("stretch");
  const length = Math.max(baseLength * (1 + speed) * (1 - squash), 10);
  const top = INSET + (track - baseLength) * progress;
  // Past an end the thumb stays pressed against that edge; inside the range the stretch trails the motion.
  const stretchY = offset > range ? baseLength - length : offset < 0 ? 0 : velocity > 0 ? baseLength - length : 0;
  const width = (visible ? 8 : 5) + (squash / 0.7) * 2;
  const shape = spring(0.3, 0.55);

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
        <div ref={sc.contentRef} style={{ padding: "14px 26px 14px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
          {Array.from({ length: 18 }, (_, i) => (
            <ScrollKitRow key={i} index={i + 1} lang={ctx.lang} style={{ flexShrink: 0 }} />
          ))}
        </div>
      </div>
      <motion.div
        initial={false}
        animate={{ opacity: visible ? 1 : 0 }}
        transition={visible ? spring(0.3, 0.8) : anim.easeInOut(0.35)}
        style={{ position: "absolute", right: 5, top: 0, width: 60, height: viewport, pointerEvents: "none" }}
      >
        {/* Only the shape springs; the thumb's position tracks the content exactly. */}
        <div style={{ position: "absolute", right: 0, top: 0, transform: `translateY(${top}px)` }}>
          <motion.div
            initial={false}
            animate={{ width, height: length, y: stretchY }}
            transition={shape}
            style={{ position: "absolute", right: 0, top: 0, borderRadius: 999, background: `linear-gradient(${Palette.sky}, ${Palette.violet})` }}
          />
        </div>
        {ctx.b("bubble") && (
          <div
            style={{
              position: "absolute",
              right: 16,
              top: top + baseLength / 2 - 10,
              padding: "4px 7px",
              borderRadius: 999,
              background: Palette.indigo,
              color: "#fff",
              fontSize: 11,
              lineHeight: "13px",
              fontWeight: 700,
              fontVariantNumeric: "tabular-nums",
            }}
          >
            {Math.round(progress * 100)}%
          </div>
        )}
      </motion.div>
    </div>
  );
}
