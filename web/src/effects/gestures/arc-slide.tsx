/** gestures.arc-slide · 弧形滑动解锁 (Gestures+ArcSlide.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { ChevronRight } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, SymbolBounce, anim, black, hex, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { useScript } from "./_a-common";

const ARC_START = 150;
const ARC_SWEEP = 240;
const R = 110;
const SIDE = 300;
const C = SIDE / 2;
const GRADIENT = [Palette.mint, Palette.sky, Palette.indigo];

const rad = (deg: number) => (deg * Math.PI) / 180;
const pt = (deg: number): [number, number] => [C + R * Math.cos(rad(deg)), C + R * Math.sin(rad(deg))];

function parse(c: string) {
  const n = parseInt(c.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
/** `AngularGradient(startAngle: 0°, endAngle: 240°)` rotated to the arc: colour at a fraction of the sweep. */
function gradientAt(f: number) {
  const stops = GRADIENT.map(parse);
  const x = Math.min(Math.max(f, 0), 1) * (stops.length - 1);
  const i = Math.min(Math.floor(x), stops.length - 2);
  const k = x - i;
  const c = stops[i].map((v, j) => Math.round(v + (stops[i + 1][j] - v) * k));
  return `rgb(${c[0]} ${c[1]} ${c[2]})`;
}

function arcPath(from: number, to: number) {
  const [x0, y0] = pt(from);
  const [x1, y1] = pt(to);
  return `M${x0} ${y0} A${R} ${R} 0 ${to - from > 180 ? 1 : 0} 1 ${x1} ${y1}`;
}

function LockGlyph({ open, size }: { open: boolean; size: number }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size}>
      <path d={open ? "M7.5 11V7a4.5 4.5 0 0 1 8.9-1" : "M7.5 11V7a4.5 4.5 0 0 1 9 0v4"} fill="none" stroke="currentColor" strokeWidth={2.4} strokeLinecap="round" />
      <rect x="4.5" y="10.5" width="15" height="11.5" rx="2.6" fill="currentColor" />
    </svg>
  );
}

export default function ArcSlide({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const relockTask = useScript();
  const progress = useMotionValue(0);
  const [p, setP] = useState(0);
  useMotionValueEvent(progress, "change", setP);
  /** The state value (what SwiftUI's body reads) for the ticks. */
  const [pState, setPState] = useState(0);
  const [unlocked, setUnlocked] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [pulseID, setPulseID] = useState(0);
  const st = useRef({ dragStart: null as number | null, unlocked: false, relockPending: false });
  const s = st.current;
  const detents = Math.max(ctx.i("detents"), 2);

  const setProgress = (v: number, t?: ReturnType<typeof spring>) => {
    setPState(v);
    if (t) animate(progress, v, t);
    else {
      progress.stop();
      progress.set(v);
    }
  };

  const relock = () => {
    s.relockPending = false;
    s.unlocked = false;
    setUnlocked(false);
    setDragging(false);
    setProgress(0, spring(0.6, 0.85));
  };

  const unlock = (haptic: boolean) => {
    if (s.unlocked) return;
    s.unlocked = true;
    setUnlocked(true);
    setProgress(1, spring(0.35, 0.7));
    setPulseID((n) => n + 1);
    if (haptic) haptics.success();
    relockTask.cancel();
    relockTask.after(1.6, () => {
      if (s.dragStart !== null) {
        s.relockPending = true;
        return;
      }
      relock();
    });
  };

  const tick = (from: number, to: number) => {
    const slots = detents + 1;
    if (Math.floor(from * slots) !== Math.floor(to * slots)) haptics.selection();
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (s.unlocked) return;
      if (s.dragStart === null) {
        s.dragStart = progress.get();
        script.cancel();
        progress.stop();
        setDragging(true);
      }
      const startRadians = rad(ARC_START + ARC_SWEEP * s.dragStart);
      const dx = R * Math.cos(startRadians) + translation.x;
      const dy = R * Math.sin(startRadians) + translation.y;
      let relative = ((Math.atan2(dy, dx) * 180) / Math.PI - ARC_START) % 360;
      if (relative < 0) relative += 360;
      if (relative > ARC_SWEEP) relative = relative > (ARC_SWEEP + 360) / 2 ? 0 : ARC_SWEEP;
      const next = relative / ARC_SWEEP;
      const cur = progress.get();
      if (Math.abs(next - cur) >= 0.3) return;
      tick(cur, next);
      setProgress(next);
      if (next >= 0.995) unlock(true);
    },
    onEnd: () => {
      if (s.dragStart === null) return;
      s.dragStart = null;
      setDragging(false);
      if (s.relockPending) {
        relock();
        return;
      }
      if (s.unlocked) return;
      setProgress(0, spring(0.6, ctx.n("damping")));
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (s.unlocked || s.dragStart !== null) return;
      setProgress(0.96, anim.easeInOut(1.1));
      setDragging(true);
      script.cancel();
      script.after(1.15, () => unlock(false));
    },
    { every: 3.6, delay: 0.6 },
  );

  // Filled arc: short segments sampling the angular gradient, round caps at both ends.
  const end = ARC_START + ARC_SWEEP * Math.max(p, 0);
  const segments = [];
  if (p > 0.001) {
    const n = Math.max(1, Math.ceil(p * 80));
    for (let i = 0; i < n; i++) {
      const f0 = (p * i) / n;
      const f1 = Math.min((p * (i + 1)) / n + 0.004, p);
      segments.push(
        <path key={i} d={arcPath(ARC_START + ARC_SWEEP * f0, ARC_START + ARC_SWEEP * f1)} stroke={unlocked ? Palette.green : gradientAt((f0 + f1) / 2)} />,
      );
    }
  }
  const [sx, sy] = pt(ARC_START);
  const [ex, ey] = pt(end);
  const knobPos = useTransform(progress, (v) => {
    const [x, y] = pt(ARC_START + ARC_SWEEP * v);
    return `translate(${x - 20}px, ${y - 20}px)`;
  });

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ position: "relative", width: SIDE, height: SIDE }}>
        <svg width={SIDE} height={SIDE} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <path d={arcPath(ARC_START, ARC_START + ARC_SWEEP)} fill="none" stroke={Palette.labelAlpha(0.08)} strokeWidth={14} strokeLinecap="round" />
          {p > 0.001 && (
            <g fill="none" strokeWidth={14}>
              <circle cx={sx} cy={sy} r={7} fill={unlocked ? Palette.green : gradientAt(0)} stroke="none" />
              {segments}
              <circle cx={ex} cy={ey} r={7} fill={unlocked ? Palette.green : gradientAt(p)} stroke="none" />
            </g>
          )}
        </svg>
        {Array.from({ length: detents }, (_, index) => {
          const fraction = (index + 1) / (detents + 1);
          const lit = pState >= fraction;
          return (
            <div key={index} style={{ position: "absolute", left: C, top: C, width: 0, height: 0, transform: `rotate(${ARC_START + ARC_SWEEP * fraction}deg)` }}>
              <motion.div
                initial={false}
                animate={{ width: lit ? 9 : 6, backgroundColor: lit ? "rgb(255 255 255)" : Palette.labelAlpha(0.25) }}
                transition={spring(0.25, 0.6)}
                style={{ position: "absolute", left: R, top: -1.5, height: 3, borderRadius: 1.5, x: "-50%" }}
              />
            </div>
          );
        })}
        {unlocked && (
          <motion.div
            key={pulseID}
            initial={{ scale: 0.95, borderColor: hex(Palette.green, 0.6) }}
            animate={{ scale: 1.18, borderColor: hex(Palette.green, 0) }}
            transition={anim.easeOut(0.7)}
            style={{ position: "absolute", left: C - R - 15, top: C - R - 15, width: R * 2 + 30, height: R * 2 + 30, borderRadius: "50%", border: "3px solid" }}
          />
        )}
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 8, pointerEvents: "none" }}>
          <SymbolBounce trigger={unlocked}>
            <span style={{ position: "relative", display: "grid", width: 44, height: 44, placeItems: "center" }}>
              <AnimatePresence mode="popLayout" initial={false}>
                <motion.span
                  key={unlocked ? "open" : "closed"}
                  initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                  animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                  exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                  transition={anim.snappyD(0.3)}
                  style={{ display: "grid", color: unlocked ? Palette.green : Palette.labelAlpha(0.7) }}
                >
                  <LockGlyph open={unlocked} size={44} />
                </motion.span>
              </AnimatePresence>
            </span>
          </SymbolBounce>
          <span style={{ position: "relative", display: "grid", fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>
            <AnimatePresence initial={false}>
              <motion.span
                key={unlocked ? "u" : "l"}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={spring(0.35, 0.7)}
                style={{ gridArea: "1 / 1", whiteSpace: "nowrap", textAlign: "center" }}
              >
                {unlocked ? ctx.t("Unlocked", "已解锁") : ctx.t("Slide to unlock", "滑动解锁")}
              </motion.span>
            </AnimatePresence>
          </span>
        </div>
        <motion.div {...pan} style={{ ...pan.style, position: "absolute", left: 0, top: 0, width: 40, height: 40, transform: knobPos, cursor: "grab" }}>
          <motion.div
            initial={false}
            animate={{ scale: dragging ? 1.12 : 1, boxShadow: `0 3px ${dragging ? 10 : 6}px ${black(0.2)}` }}
            transition={spring(0.25, 0.7)}
            style={{ width: 40, height: 40, borderRadius: "50%", background: "#fff", display: "grid", placeItems: "center", color: Palette.indigo }}
          >
            <ChevronRight size={17} strokeWidth={3.6} />
          </motion.div>
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Drag the knob around the arc" zh="沿弧线拖动滑块" style={{ position: "absolute", left: 0, right: 0, bottom: 4 }} />
    </div>
  );
}
