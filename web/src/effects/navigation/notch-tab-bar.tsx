/** navigation.notch-tab-bar · 凹槽标签栏 (Navigation+NotchTabBar.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, black, delayed, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { NavigationScreenPlaceholder } from "./shared";
import { BOUNCY, Glyph, cubicKF, springKF, track, useSince, type GlyphName } from "./groupB-kit";

const SYMBOLS: GlyphName[] = ["house.fill", "chart.bar.fill", "bell.fill", "person.fill"];
const BAR_W = 312;
const INSET = 20;
const BAR_H = 64;
const SLOT = (BAR_W - INSET * 2) / SYMBOLS.length;
const centerX = (index: number) => INSET + (index + 0.5) * SLOT;

/** `NotchBarShape.path(in:)` for a 312 × 64 rect. */
function notchPath(notchX: number, depth: number): string {
  const corner = 16;
  const half = 76 / 2;
  const x = Math.min(Math.max(notchX, corner + half), BAR_W - corner - half);
  const w = BAR_W;
  const h = BAR_H;
  return [
    `M0 ${corner}`,
    `Q0 0 ${corner} 0`,
    `L${x - half} 0`,
    `C${x - half * 0.45} 0 ${x - half * 0.62} ${depth} ${x} ${depth}`,
    `C${x + half * 0.62} ${depth} ${x + half * 0.45} 0 ${x + half} 0`,
    `L${w - corner} 0`,
    `Q${w} 0 ${w} ${corner}`,
    `L${w} ${h - corner}`,
    `Q${w} ${h} ${w - corner} ${h}`,
    `L${corner} ${h}`,
    `Q0 ${h} 0 ${h - corner}`,
    "Z",
  ].join(" ");
}

const DIP = [cubicKF(6, 0.14), springKF(0, 0.4, BOUNCY)];

export default function NotchTabBar({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [selected, setSelected] = useState(0);
  const [moves, setMoves] = useState(0);
  const movesRef = useRef(0);
  const selectedRef = useRef(0);
  /** True while an autoplay action runs (Swift reads `Haptics.isMuted` at that moment). */
  const simulated = useRef(false);
  const notchMV = useMotionValue(centerX(0));
  const [notchX, setNotchX] = useState(centerX(0));
  useMotionValueEvent(notchMV, "change", setNotchX);
  const response = ctx.n("response");
  const depth = ctx.n("depth");

  const select = (index: number) => {
    if (index === selectedRef.current) return;
    movesRef.current += 1;
    const current = movesRef.current;
    setMoves(current);
    // The haptic lands with the bubble (~80% of the spring response), not on touch-down.
    const live = !ctx.isPreview && !simulated.current;
    if (live) {
      after(response * 0.8, () => {
        if (movesRef.current === current) haptics.tap("medium");
      });
    }
    selectedRef.current = index;
    setSelected(index);
    const notchAnimation = ctx.b("lag") ? delayed(spring(response * 1.3, 0.78), 0.05) : spring(response, 0.7);
    animate(notchMV, centerX(index), notchAnimation);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      simulated.current = true;
      try {
        select((selectedRef.current + 1) % SYMBOLS.length);
      } finally {
        simulated.current = false;
      }
    },
    { every: 1.2 },
  );

  const dipT = useSince(moves, 0.54);
  const dip = track(dipT, 0, DIP);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 24 }}>
      {ctx.isPreview && (
        <div style={{ paddingTop: 20 }}>
          <NavigationScreenPlaceholder />
        </div>
      )}
      <div style={{ flex: 1, minHeight: 0 }} />
      <div style={{ position: "relative", width: BAR_W, height: BAR_H, flexShrink: 0 }}>
        <svg
          width={BAR_W}
          height={BAR_H}
          viewBox={`0 0 ${BAR_W} ${BAR_H}`}
          style={{ position: "absolute", inset: 0, overflow: "visible", filter: `drop-shadow(0 6px 8px ${black(0.14)})` }}
        >
          <path d={notchPath(notchX, depth)} style={{ fill: Palette.elevated }} />
        </svg>
        <div style={{ position: "absolute", left: INSET, top: 0, width: BAR_W - INSET * 2, height: BAR_H, display: "flex" }}>
          {SYMBOLS.map((symbol, index) => {
            const isSelected = index === selected;
            return (
              <div
                key={symbol}
                onClick={() => select(index)}
                style={{ flex: 1, height: "100%", display: "grid", placeItems: "center", cursor: "pointer" }}
              >
                <motion.div
                  initial={false}
                  animate={{ opacity: isSelected ? 0 : 1, y: isSelected ? 14 : 0 }}
                  transition={anim.easeInOut(0.25)}
                  style={{ color: Palette.secondaryLabel }}
                >
                  <Glyph name={symbol} size={21} />
                </motion.div>
              </div>
            );
          })}
        </div>
        <motion.div
          initial={false}
          animate={{ x: centerX(selected) - 27 }}
          transition={spring(response, 0.7)}
          style={{ position: "absolute", left: 0, top: -27 - 4, width: 54, height: 54, pointerEvents: "none" }}
        >
          <div
            style={{
              width: 54,
              height: 54,
              transform: `translateY(${dip}px)`,
              borderRadius: "50%",
              background: Palette.primary,
              boxShadow: `0 5px 10px ${alpha(Palette.indigo, 0.4)}`,
              display: "grid",
              placeItems: "center",
              color: "#fff",
            }}
          >
            <AnimatePresence mode="popLayout" initial={false}>
              <motion.div
                key={selected}
                initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                transition={anim.snappy}
                style={{ gridArea: "1 / 1" }}
              >
                <Glyph name={SYMBOLS[selected]} size={22} />
              </motion.div>
            </AnimatePresence>
          </div>
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Tap a tab" zh="点击任一标签" style={{ paddingBottom: 12 }} />
    </div>
  );
}

