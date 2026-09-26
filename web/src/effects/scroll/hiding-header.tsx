/** scroll.hiding-header · 滚动隐藏栏 (Scroll+HidingHeader.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { Palette, anim, black, delayed, glass, spring, useAutoplay, type DemoProps } from "../../kit";
import { ScrollKitIcon, ScrollKitRow, Sym, useScroller } from "./_kit";

const HEADER = 56;
const TARGETS = [260, 520, 420, 700, 560, 0];
const TABS = ["house.fill", "magnifyingglass", "plus.app.fill", "bell.fill", "person.crop.circle"];

export default function HidingHeader({ ctx }: DemoProps) {
  const [hidden, setHidden] = useState(false);
  const hiddenRef = useRef(false);
  // Offset where the current scroll direction started.
  const anchor = useRef(0);
  const step = useRef(0);
  const setHide = (h: boolean) => {
    hiddenRef.current = h;
    setHidden(h);
  };
  const track = (offset: number) => {
    const threshold = ctx.n("threshold");
    if (offset < 60) {
      if (hiddenRef.current) setHide(false);
      anchor.current = offset;
      return;
    }
    const delta = offset - anchor.current;
    if (delta > threshold) {
      if (!hiddenRef.current) setHide(true);
      anchor.current = offset;
    } else if (delta < -threshold) {
      if (hiddenRef.current) setHide(false);
      anchor.current = offset;
    } else if ((hiddenRef.current && delta > 0) || (!hiddenRef.current && delta < 0)) {
      // Keep the anchor at the extreme of the current direction.
      anchor.current = offset;
    }
  };
  const sc = useScroller({ axis: "y", onScroll: track });

  useAutoplay(
    ctx.isPreview,
    () => {
      const target = TARGETS[step.current % TARGETS.length];
      step.current += 1;
      sc.scrollTo(target, anim.smoothD(1.0));
    },
    { every: 1.4 },
  );

  const scrolled = sc.offset > 4;
  const t = spring(0.35, 0.82);

  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
      <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
        <div ref={sc.contentRef} style={{ padding: `${HEADER + 10}px 16px 90px`, display: "flex", flexDirection: "column", gap: 10 }}>
          {Array.from({ length: 16 }, (_, i) => (
            <ScrollKitRow key={i} index={i + 2} lang={ctx.lang} style={{ flexShrink: 0 }} />
          ))}
        </div>
      </div>
      <motion.div
        animate={{ y: hidden ? -HEADER - 12 : 0 }}
        transition={t}
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 0,
          height: HEADER,
          padding: "0 16px",
          display: "flex",
          alignItems: "center",
          gap: 10,
          pointerEvents: "none",
          ...glass("regular"),
        }}
      >
        <ScrollKitIcon index={6} size={30} circle />
        <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{ctx.t("Following", "关注")}</span>
        <span style={{ flex: 1 }} />
        {[ctx.t("All", "全部"), ctx.t("Photos", "照片")].map((label, i) => (
          <span
            key={i}
            style={{
              padding: "5px 10px",
              borderRadius: 999,
              fontSize: 12,
              lineHeight: "16px",
              fontWeight: 600,
              color: i === 0 ? "#fff" : Palette.label,
              background: i === 0 ? Palette.primary : Palette.labelAlpha(0.08),
            }}
          >
            {label}
          </span>
        ))}
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            bottom: 0,
            height: 0.5,
            background: Palette.labelAlpha(0.12),
            opacity: scrolled ? 1 : 0,
            transition: "opacity 0.2s ease-out",
          }}
        />
      </motion.div>
      <motion.div
        animate={{ y: hidden && ctx.b("tabBar") ? 90 : 0 }}
        transition={delayed(t, 0.05)}
        style={{
          position: "absolute",
          left: (340 - 260) / 2,
          bottom: 14,
          width: 260,
          height: 58,
          borderRadius: 29,
          display: "flex",
          alignItems: "center",
          pointerEvents: "none",
          ...glass("regular"),
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 6px 14px ${black(0.14)}`,
        }}
      >
        {TABS.map((name, i) => (
          <div key={i} style={{ flex: 1, display: "grid", placeItems: "center", color: i === 0 ? "#8575FF" : Palette.secondaryLabel }}>
            <Sym name={name} size={18} weight={600} />
          </div>
        ))}
      </motion.div>
    </div>
  );
}
