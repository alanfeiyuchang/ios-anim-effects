/** scroll.pill-header · 悬浮胶囊头部 (Scroll+PillHeader.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useRef, useState } from "react";
import { Palette, anim, black, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { ScrollKitArt, ScrollKitIcon, Sym, useScroller } from "./_kit";

export default function PillHeader({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [floating, setFloating] = useState(false);
  const floatingRef = useRef(false);
  const down = useRef(false);
  const scripted = useRef(false);
  const sc = useScroller({
    axis: "y",
    onScroll: (o) => {
      const next = o > 40;
      if (next === floatingRef.current) return;
      floatingRef.current = next;
      if (next && !ctx.isPreview && !scripted.current) haptics.tap("soft");
      setFloating(next);
    },
    onPhase: (p) => {
      if (p === "interacting") scripted.current = false;
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      scripted.current = true;
      down.current = !down.current;
      sc.scrollTo(down.current ? 260 : 0, anim.smoothD(1.1));
    },
    { every: 1.8 },
  );

  const t = spring(0.45, ctx.n("damping"));
  const inset = floating ? ctx.n("inset") : 0;

  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
      <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
        <div ref={sc.contentRef} style={{ padding: "76px 16px 20px", display: "flex", flexDirection: "column", gap: 12 }}>
          {Array.from({ length: 5 }, (_, i) => (
            <div key={i} style={{ position: "relative", height: 150, borderRadius: 22, overflow: "hidden", flexShrink: 0 }}>
              <ScrollKitArt index={i + 5} lang={ctx.lang} />
            </div>
          ))}
        </div>
      </div>
      <motion.div
        initial={false}
        animate={{
          left: inset,
          right: inset,
          top: floating ? 10 : 0,
          height: floating ? 46 : 64,
          borderRadius: floating ? 23 : 0,
          paddingLeft: floating ? 12 : 16,
          paddingRight: floating ? 12 : 16,
          boxShadow: floating
            ? `inset 0 0 0 1px ${Palette.labelAlpha(0.08)}, 0 6px 16px ${black(0.16)}`
            : `inset 0 0 0 1px ${Palette.labelAlpha(0)}, 0 6px 16px ${black(0)}`,
        }}
        transition={t}
        style={{ position: "absolute", display: "flex", alignItems: "center", gap: 10, pointerEvents: "none", ...glass("regular") }}
      >
        <motion.span
          initial={false}
          animate={{ scale: floating ? 0.8 : 1 }}
          transition={t}
          style={{ fontSize: 22, lineHeight: "28px", fontWeight: 700, whiteSpace: "nowrap", transformOrigin: "0% 50%" }}
        >
          {ctx.t("Discover", "发现")}
        </motion.span>
        <span style={{ flex: 1 }} />
        {/* matchedGeometryEffect: the search field folds into a round button. */}
        <motion.div
          initial={false}
          animate={{
            width: floating ? 30 : 118,
            height: floating ? 30 : 32,
            borderRadius: floating ? 15 : 16,
            paddingLeft: floating ? 0 : 10,
            background: floating ? Palette.labelAlpha(0.08) : Palette.labelAlpha(0.07),
          }}
          transition={t}
          style={{
            position: "relative",
            display: "flex",
            alignItems: "center",
            justifyContent: floating ? "center" : "flex-start",
            gap: 6,
            overflow: "hidden",
            flexShrink: 0,
            color: floating ? Palette.label : Palette.secondaryLabel,
            fontSize: 13,
          }}
        >
          <Sym name="magnifyingglass" size={floating ? 14 : 13} weight={floating ? 600 : 400} />
          <AnimatePresence initial={false}>
            {!floating && (
              <motion.span key="label" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, transition: { duration: 0.1 } }} style={{ whiteSpace: "nowrap" }}>
                {ctx.t("Search", "搜索")}
              </motion.span>
            )}
          </AnimatePresence>
        </motion.div>
        <motion.div initial={false} animate={{ width: floating ? 30 : 34, height: floating ? 30 : 34 }} transition={t} style={{ flexShrink: 0, display: "grid", placeItems: "center" }}>
          <motion.div initial={false} animate={{ scale: floating ? 30 / 34 : 1 }} transition={t}>
            <ScrollKitIcon index={4} size={34} circle />
          </motion.div>
        </motion.div>
      </motion.div>
    </div>
  );
}
