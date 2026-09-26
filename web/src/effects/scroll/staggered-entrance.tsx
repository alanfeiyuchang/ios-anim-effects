/** scroll.staggered-entrance · 错峰入场列表 (Scroll+StaggeredEntrance.swift) */
import { motion } from "motion/react";
import { useEffect, useState } from "react";
import { Palette, delayed, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { ROW_HEIGHT, ScrollKitRow, Sym, useScroller } from "./_kit";

const COUNT = 14;
const GAP = 10;
const TOP = 16;

export default function StaggeredEntrance({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [generation, setGeneration] = useState(0);
  const replay = () => setGeneration((g) => g + 1);
  // Rows already enter on appear, so no intro play replaying them a second time.
  useAutoplay(ctx.isPreview, replay, { every: 3.2, intro: false });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
      <List key={generation} ctx={ctx} />
      {!ctx.isPreview && (
        <button
          type="button"
          onClick={() => {
            haptics.tap();
            replay();
          }}
          style={{
            display: "flex",
            alignItems: "center",
            gap: 6,
            padding: "9px 16px",
            marginBottom: 12,
            borderRadius: 999,
            background: Palette.elevated,
            boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
            fontSize: 15,
            lineHeight: "20px",
            fontWeight: 600,
            flexShrink: 0,
          }}
        >
          <Sym name="arrow.clockwise" size={15} weight={600} />
          {ctx.t("Replay", "重播")}
        </button>
      )}
    </div>
  );
}

function List({ ctx }: DemoProps) {
  const sc = useScroller({ axis: "y" });
  // True once the first screenful has been laid out: rows scrolled into view later enter at once.
  const [settled, setSettled] = useState(false);
  useEffect(() => {
    const id = window.setTimeout(() => setSettled(true), 350);
    return () => window.clearTimeout(id);
  }, []);
  const viewport = sc.size.height;
  return (
    <div {...sc.props} style={{ ...sc.props.style, flex: 1, minHeight: 0, alignSelf: "stretch" }}>
      <div ref={sc.contentRef} style={{ padding: `${TOP}px 20px 14px`, display: "flex", flexDirection: "column", gap: GAP }}>
        {Array.from({ length: COUNT }, (_, i) => {
          // LazyVStack: a row is created (and appears) once it scrolls into the viewport.
          const inView = viewport > 0 && TOP + i * (ROW_HEIGHT + GAP) - sc.offset < viewport;
          return <Row key={i} index={i} ctx={ctx} inView={inView} delay={settled ? 0 : i * ctx.n("stagger")} />;
        })}
      </div>
    </div>
  );
}

function Row({ index, ctx, inView, delay }: { index: number; ctx: DemoProps["ctx"]; inView: boolean; delay: number }) {
  const [shown, setShown] = useState(false);
  const [startDelay, setStartDelay] = useState(0);
  useEffect(() => {
    if (inView && !shown) {
      setStartDelay(delay);
      setShown(true);
    }
  }, [inView, shown, delay]);
  const distance = ctx.n("distance");
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.96, filter: "blur(4.5px)", y: distance }}
      animate={shown ? { opacity: 1, scale: 1, filter: "blur(0px)", y: 0 } : undefined}
      transition={delayed(spring(ctx.n("response"), 0.82), startDelay)}
      style={{ flexShrink: 0 }}
    >
      <ScrollKitRow index={index} lang={ctx.lang} />
    </motion.div>
  );
}
