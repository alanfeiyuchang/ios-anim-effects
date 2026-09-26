/** navigation.number-pager · 滚动页码计数 (Navigation+NumberPager.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Binoculars, ChevronLeft, ChevronRight, Leaf, MoonStar, Mountain, Snowflake, Sunrise, Tent, Waves, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, fonts, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { colorGradient, useHorizontalDrag } from "./groupB-kit";

const SYMBOLS: [LucideIcon, boolean][] = [
  [Mountain, true],
  [Sunrise, false],
  [Leaf, true],
  [Snowflake, false],
  [Waves, false],
  [Tent, true],
  [Binoculars, true],
  [MoonStar, true],
];
const COLORS = [Palette.indigo, Palette.amber, Palette.green, Palette.sky, Palette.blue, Palette.coral, Palette.mint, Palette.violet];
const COUNT = 8;
const pad2 = (n: number) => String(n).padStart(2, "0");

export default function NumberPager({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [page, setPage] = useState(0);
  const [forward, setForward] = useState(true);
  const pageRef = useRef(0);
  const springT = spring(ctx.n("response"), ctx.n("damping"));

  const go = (step: number) => {
    const target = pageRef.current + step;
    if (target < 0 || target >= COUNT || step === 0) return;
    haptics.selection();
    pageRef.current = target;
    setForward(step > 0);
    setPage(target);
  };

  useAutoplay(ctx.isPreview, () => go(pageRef.current === COUNT - 1 ? -(COUNT - 1) : 1), { every: 1.2 });

  // The card never follows the finger, so a cancelled swipe (`null`) has nothing to undo.
  const drag = useHorizontalDrag(
    {
      onEnd: (value) => {
        if (!value) return;
        if (value.translation.x < -30) go(1);
        if (value.translation.x > 30) go(-1);
      },
    },
    12,
  );

  const [Icon, filled] = SYMBOLS[page];
  const segment = (270 + 4) / COUNT;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <motion.div
        {...drag}
        initial={false}
        animate={{ boxShadow: `0 8px 16px ${alpha(COLORS[page], 0.3)}` }}
        transition={springT}
        style={{ ...drag.style, position: "relative", width: 270, height: 180, borderRadius: 26, flexShrink: 0, cursor: "grab" }}
      >
        <div style={{ position: "absolute", inset: 0, borderRadius: 26, overflow: "hidden" }}>
          <AnimatePresence initial={false} custom={forward}>
            <motion.div
              key={page}
              custom={forward}
              variants={{
                // `.push(from:)` insertion; the old card recedes (opacity + scale 0.92).
                enter: (fwd: boolean) => ({ x: fwd ? 270 : -270, opacity: 0.5, scale: 1 }),
                center: { x: 0, opacity: 1, scale: 1 },
                exit: { x: 0, opacity: 0, scale: 0.92 },
              }}
              initial="enter"
              animate="center"
              exit="exit"
              transition={springT}
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: 26,
                background: colorGradient(COLORS[page]),
                display: "grid",
                placeItems: "center",
                color: "rgb(255 255 255 / 0.9)",
              }}
            >
              <Icon size={70} strokeWidth={filled ? 1.4 : 2.2} fill={filled ? "currentColor" : "none"} />
            </motion.div>
          </AnimatePresence>
        </div>
      </motion.div>
      <div style={{ width: 270, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 6, height: 40 }}>
          <NumericText
            value={page + 1}
            text={pad2(page + 1)}
            style={{ fontFamily: fonts.rounded, fontSize: 40, lineHeight: "40px", fontWeight: 700, height: 40, alignItems: "flex-end" }}
          />
          <span
            style={{
              fontFamily: fonts.rounded,
              fontSize: 15,
              lineHeight: "15px",
              fontWeight: 600,
              fontVariantNumeric: "tabular-nums",
              color: Palette.secondaryLabel,
              marginBottom: 4,
            }}
          >
            / {pad2(COUNT)}
          </span>
          <div style={{ flex: 1 }} />
          <div style={{ display: "flex", gap: 6, marginBottom: 5 }}>
            <Arrow icon={ChevronLeft} enabled={page > 0} onTap={() => go(-1)} />
            <Arrow icon={ChevronRight} enabled={page < COUNT - 1} onTap={() => go(1)} />
          </div>
        </div>
        {ctx.b("track") && (
          <div style={{ position: "relative", width: 270, height: 4 }}>
            <div style={{ position: "absolute", inset: 0, display: "flex", gap: 4 }}>
              {Array.from({ length: COUNT }, (_, i) => (
                <div key={i} style={{ flex: 1, borderRadius: 2, background: Palette.labelAlpha(0.1) }} />
              ))}
            </div>
            <motion.div
              initial={false}
              animate={{ width: segment * (page + 1) - 4 }}
              transition={springT}
              style={{ position: "absolute", left: 0, top: 0, height: 4, borderRadius: 2, background: Palette.primary }}
            />
          </div>
        )}
      </div>
      <DemoHint ctx={ctx} en="Swipe the card or tap the arrows" zh="左右滑动卡片或点击箭头" />
    </div>
  );
}

function Arrow({ icon: Icon, enabled, onTap }: { icon: LucideIcon; enabled: boolean; onTap: () => void }) {
  return (
    <button
      type="button"
      disabled={!enabled}
      onClick={onTap}
      style={{
        width: 38,
        height: 38,
        borderRadius: "50%",
        background: Palette.surface,
        display: "grid",
        placeItems: "center",
        color: enabled ? Palette.label : Palette.secondaryLabel,
        opacity: enabled ? 1 : 0.5,
        cursor: enabled ? "pointer" : "default",
      }}
    >
      <Icon size={17} strokeWidth={3} />
    </button>
  );
}
