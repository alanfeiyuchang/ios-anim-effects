/** gestures.coil-spring · 弹簧秤 (Gestures+CoilSpring.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, fonts, rubberBand, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";

const CEILING_Y = -140;
const REST = 130;
const C = 160; // centre of the 320 × 320 frame
const GRAY = "142 142 147";

function coilPath(length: number, turns = 9, diameter = 44) {
  const lead = 12;
  const tx = C;
  const ty = C + CEILING_Y;
  const usable = Math.max(length - lead * 2, 8);
  const ratio = Math.sqrt(REST / Math.max(length, 1));
  const width = diameter * Math.min(Math.max(ratio, 0.75), 1.2);
  const segments = turns * 2;
  const pitch = usable / segments;
  let d = `M ${tx} ${ty} L ${tx} ${ty + lead}`;
  for (let i = 0; i < segments; i++) {
    const side = i % 2 === 0 ? 1 : -1;
    d += ` L ${tx + (side * width) / 2} ${ty + lead + pitch * (i + 0.5)}`;
  }
  d += ` L ${tx} ${ty + lead + usable} L ${tx} ${ty + length}`;
  return d;
}

export default function CoilSpring({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const stretch = useMotionValue(0);
  const d = useTransform(stretch, (s) => coilPath(REST + s));
  const weightY = useTransform(stretch, (s) => CEILING_Y + REST + s + 28);
  const [dragging, setDragging] = useState(false);
  const held = useRef(false);
  const script = useRef<number | null>(null);
  useEffect(() => () => {
    if (script.current) window.clearTimeout(script.current);
  }, []);

  const release = (haptic: boolean) => {
    const pulled = Math.abs(stretch.get());
    animate(stretch, 0, { type: "spring", mass: ctx.n("mass"), stiffness: ctx.n("stiffness"), damping: ctx.n("damping"), restDelta: 0.01, restSpeed: 0.01 });
    setDragging(false);
    if (haptic && pulled > 20) haptics.tap(pulled > 70 ? "rigid" : "light");
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!held.current) {
        held.current = true;
        if (script.current) window.clearTimeout(script.current);
        script.current = null;
        setDragging(true);
      }
      const dy = translation.y;
      stretch.stop();
      stretch.set(dy >= 0 ? rubberBand(dy, 110, 0.8) : rubberBand(dy, 90, 0.8));
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      release(true);
    },
  });

  const simulate = () => {
    if (held.current) return;
    animate(stretch, 70 + Math.random() * 30, anim.easeInOut(0.55));
    setDragging(true);
    if (script.current) window.clearTimeout(script.current);
    script.current = window.setTimeout(() => {
      script.current = null;
      release(false);
    }, 700);
  };
  useAutoplay(ctx.isPreview, simulate, { every: 3.6, delay: 0.4 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ position: "relative", width: 320, height: 320 }}>
        {/* Ruler */}
        <div style={{ position: "absolute", left: C + 130 - 8, top: C - 243 / 2, width: 16, display: "flex", flexDirection: "column", gap: 9, alignItems: "flex-end" }}>
          {Array.from({ length: 24 }, (_, i) => (
            <div key={i} style={{ width: i % 4 === 0 ? 16 : 9, height: 1.5, borderRadius: 1, background: Palette.labelAlpha(i % 4 === 0 ? 0.35 : 0.15) }} />
          ))}
        </div>
        {/* Ceiling */}
        <div style={{ position: "absolute", left: C - 60, top: C + CEILING_Y - 4 - 4, width: 120, height: 8, borderRadius: 4, background: Palette.labelAlpha(0.7) }} />
        <svg width={320} height={320} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
          <defs>
            <linearGradient id="coil-grad" gradientUnits="userSpaceOnUse" x1={0} y1={0} x2={320} y2={0}>
              <stop offset={0} stopColor={`rgb(${GRAY} / 0.95)`} />
              <stop offset={1} stopColor={`rgb(${GRAY} / 0.55)`} />
            </linearGradient>
          </defs>
          <motion.path d={d} stroke="url(#coil-grad)" strokeWidth={3} strokeLinecap="round" strokeLinejoin="round" fill="none" />
        </svg>
        {/* Weight */}
        <motion.div {...pan} style={{ position: "absolute", left: C - 32, top: C - 28, width: 64, height: 56, y: weightY, touchAction: "none", cursor: "grab" }}>
          <motion.div
            initial={false}
            animate={{
              scale: dragging ? 1.05 : 1,
              boxShadow: dragging ? `0 10px 16px ${alpha(Palette.indigo, 0.35)}` : `0 6px 10px ${alpha(Palette.indigo, 0.35)}`,
            }}
            transition={dragging ? spring(0.25, 0.7) : spring(0.3, 0.7)}
            style={{
              position: "relative",
              width: 64,
              height: 56,
              borderRadius: 16,
              background: Palette.primary,
              display: "grid",
              placeItems: "center",
              fontFamily: fonts.rounded,
              fontSize: 15,
              fontWeight: 700,
              color: "#fff",
            }}
          >
            1 kg
            <div style={{ position: "absolute", left: 25, top: -9, width: 14, height: 14, borderRadius: "50%", border: `3px solid rgb(${GRAY})` }} />
          </motion.div>
        </motion.div>
        {/* Pointer */}
        <motion.div style={{ position: "absolute", left: C + 110 - 5, top: C - 5, width: 10, height: 10, y: weightY, color: Palette.violet, pointerEvents: "none" }}>
          <svg viewBox="0 0 10 10" width={10} height={10}>
            <path d="M1.6 1.2 Q1.6 0.4 2.4 0.8 L9 4.4 Q9.8 5 9 5.6 L2.4 9.2 Q1.6 9.6 1.6 8.8 Z" fill="currentColor" />
          </svg>
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Pull the weight down and let go" zh="把砝码往下拉再松手" style={{ position: "absolute", left: 0, right: 0, bottom: 4 }} />
    </div>
  );
}
