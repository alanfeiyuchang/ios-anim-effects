/** showcase.slide-to-start · 滑动开始 (Sport+SlideToStart.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { ArrowRight, Check, ChevronsRight, MountainSnow, Square } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import {
  DemoHint,
  SymbolBounce,
  anim,
  clamp,
  fonts,
  rubberBand,
  spring,
  useAutoplay,
  useClock,
  useHaptics,
  usePan,
  white,
  type DemoProps,
} from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";

const TRACK_W = 272;
const TRACK_H = 64;
const KNOB = 52;
const INSET = (TRACK_H - KNOB) / 2;
const MAX_X = TRACK_W - KNOB - INSET * 2;

export default function SlideToStart({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const dragX = useMotionValue(0);
  const progress = useTransform(dragX, (x) => clamp(x / MAX_X));
  const [completed, setCompleted] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [startDate, setStartDate] = useState(() => Date.now());
  const lastTick = useRef(0);
  const dragStart = useRef<number | null>(null);
  const sim = useRef(0);
  const completedRef = useRef(false);
  completedRef.current = completed;

  const cancelSimulation = () => {
    sim.current += 1;
  };
  useEffect(() => cancelSimulation, []);

  const springBack = (silent = false) => {
    animate(dragX, 0, spring(0.5, ctx.n("damping")));
    lastTick.current = 0;
    if (!silent) haptics.tap("soft");
  };

  const complete = (silent = false) => {
    animate(dragX, MAX_X, spring(0.35, 0.8));
    setCompleted(true);
    completedRef.current = true;
    if (!silent) haptics.success();
    const run = sim.current;
    window.setTimeout(() => {
      if (!completedRef.current || run !== sim.current) return;
      setStartDate(Date.now());
      setExpanded(true);
    }, 700);
  };

  const reset = (silent = false) => {
    animate(dragX, 0, spring(0.5, 0.82));
    setExpanded(false);
    setCompleted(false);
    completedRef.current = false;
    lastTick.current = 0;
    if (!silent) haptics.tap("medium");
  };

  const pan = usePan({
    onStart: () => {
      cancelSimulation();
      setDragging(true);
    },
    onChange: ({ translation }) => {
      if (completedRef.current) return;
      const start = dragStart.current ?? clamp(dragX.get(), 0, MAX_X);
      if (dragStart.current === null) dragStart.current = start;
      const raw = start + translation.x;
      dragX.set(raw < 0 ? rubberBand(raw, 24) : raw > MAX_X ? MAX_X + rubberBand(raw - MAX_X, 16) : raw);
      const tick = Math.floor(progress.get() * Math.max(ctx.i("ticks"), 1));
      if (tick !== lastTick.current) {
        lastTick.current = tick;
        haptics.selection();
      }
    },
    onEnd: ({ translation }) => {
      setDragging(false);
      dragStart.current = null;
      if (expanded) {
        if (Math.abs(translation.x) < 10) reset();
        return;
      }
      if (completedRef.current) return;
      if (progress.get() >= ctx.n("threshold")) complete();
      else springBack();
    },
  });

  // Scripted drag (preview loop / detail intro); a real touch cancels it.
  const simulate = () => {
    cancelSimulation();
    const run = sim.current;
    const at = (seconds: number, fn: () => void) => window.setTimeout(() => run === sim.current && fn(), seconds * 1000);
    reset(true);
    at(0.7, () => animate(dragX, MAX_X * 0.45, anim.easeInOut(0.55)));
    at(1.35, () => animate(dragX, 0, spring(0.5, ctx.n("damping"))));
    at(2.25, () => animate(dragX, MAX_X, anim.easeIn(0.7)));
    at(2.95, () => complete(true));
  };
  useAutoplay(ctx.isPreview, simulate, { every: 6.5, delay: 0.5 });

  const fillWidth = useTransform(dragX, (x) => Math.max(TRACK_H + x, 44));
  const fillOpacity = useTransform(progress, (p) => 0.35 + 0.65 * p);
  const labelOpacity = useTransform(progress, (p) => Math.max(0, 1 - p * 1.6));
  const knobX = useTransform(dragX, (x) => INSET + x);

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(26), padding: 18, width: TRACK_W + 36, display: "flex", flexDirection: "column", gap: 18 }}>
          <Header expanded={expanded} zh={ctx.lang === "zh"} />
          <motion.div
            animate={{ scale: expanded ? 1.03 : 1 }}
            transition={spring(0.55, 0.78)}
            style={{ position: "relative", width: TRACK_W, height: TRACK_H }}
          >
            <div style={{ position: "absolute", inset: 0, borderRadius: TRACK_H / 2, background: white(0.06), boxShadow: `inset 0 0 0 1px ${Signature.hairline}` }} />
            <motion.div
              animate={expanded ? { width: TRACK_W, opacity: 1 } : undefined}
              transition={spring(0.55, 0.78)}
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                height: TRACK_H,
                borderRadius: TRACK_H / 2,
                background: Signature.accentGradient,
                width: expanded ? undefined : fillWidth,
                opacity: expanded ? undefined : fillOpacity,
              }}
            />
            <motion.div
              style={{ position: "absolute", inset: 0, paddingLeft: KNOB, display: "flex", alignItems: "center", justifyContent: "center", opacity: expanded ? 0 : labelOpacity }}
            >
              <ShimmerLabel text={ctx.t("Start Run", "开始滑行")} fps={ctx.isPreview ? 30 : undefined} />
            </motion.div>
            <motion.div
              animate={{ opacity: expanded ? 1 : 0, x: expanded ? 0 : -16 }}
              transition={spring(0.55, 0.78)}
              style={{ position: "absolute", inset: 0, paddingLeft: 20, paddingRight: KNOB + INSET * 2, display: "flex", alignItems: "center" }}
            >
              {expanded && <Running startDate={startDate} zh={ctx.lang === "zh"} />}
            </motion.div>
            <motion.div
              {...pan}
              style={{ position: "absolute", top: INSET, left: 0, x: knobX, width: KNOB, height: KNOB, touchAction: "none", cursor: "grab" }}
            >
              <motion.div
                animate={{ scale: dragging && !completed ? 1.07 : expanded ? 0.86 : 1 }}
                transition={spring(0.3, 0.6)}
                style={{ width: KNOB, height: KNOB, borderRadius: "50%", background: "#fff", display: "grid", placeItems: "center", color: Signature.accentHot, boxShadow: `0 4px 8px rgb(0 0 0 / 0.35)` }}
              >
                <motion.span key={expanded ? "stop" : completed ? "check" : "arrow"} initial={{ scale: 0.5, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={anim.snappyD(0.3)} style={{ display: "grid" }}>
                  {expanded ? <Square size={16} fill="currentColor" strokeWidth={0} /> : completed ? <Check size={20} strokeWidth={3.2} /> : <ArrowRight size={20} strokeWidth={3} />}
                </motion.span>
              </motion.div>
            </motion.div>
          </motion.div>
          <SignatureRim radius={26} />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Drag the knob to the end" zh="把圆钮拖到最右端" style={{ paddingBottom: 16 }} />
      </div>
    </SignatureStage>
  );
}

function Header({ expanded, zh }: { expanded: boolean; zh: boolean }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
        <motion.div key={expanded ? "run" : "ready"} initial={{ opacity: 0 }} animate={{ opacity: 1 }} style={signatureEyebrow()}>
          {expanded ? (zh ? "滑行中" : "On the run") : zh ? "准备出发" : "Ready to ride"}
        </motion.div>
        <div style={{ display: "flex", gap: 6, fontFamily: fonts.rounded, fontSize: 20, fontWeight: 600, color: "#fff", lineHeight: "24px" }}>
          <span>Nordkette</span>
          <span style={{ color: Signature.textSecondary }}>·</span>
          <span style={{ color: Signature.accent }}>46 cm</span>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <SymbolBounce trigger={expanded}>
        <div style={{ width: 42, height: 42, borderRadius: "50%", background: white(0.08), display: "grid", placeItems: "center", color: "#fff" }}>
          <MountainSnow size={19} strokeWidth={2.2} />
        </div>
      </SymbolBounce>
    </div>
  );
}

function Running({ startDate, zh }: { startDate: number; zh: boolean }) {
  useClock(true, 4);
  const seconds = Math.max(0, Math.floor((Date.now() - startDate) / 1000));
  const text = `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
      <LiveDot />
      <div style={{ display: "flex", flexDirection: "column" }}>
        <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 700, color: white(0.85) }}>{zh ? "已开始滑行" : "Run started"}</span>
        <span style={{ ...signatureNumber(20), color: "#fff" }}>{text}</span>
      </div>
    </div>
  );
}

function LiveDot() {
  return (
    <span style={{ position: "relative", width: 7, height: 7 }}>
      <motion.span
        animate={{ scale: [1, 2.6], opacity: [0.6, 0] }}
        transition={{ duration: 1.2, repeat: Infinity, ease: "easeOut" }}
        style={{ position: "absolute", inset: 0, borderRadius: "50%", background: "#fff" }}
      />
      <span style={{ position: "absolute", inset: 0, borderRadius: "50%", background: "#fff" }} />
    </span>
  );
}

/** Label with a soft highlight sweeping across it, like the classic slide-to-unlock. */
function ShimmerLabel({ text, fps }: { text: string; fps?: number }) {
  const t = useClock(true, fps);
  const phase = (t % 2.2) / 2.2;
  const label = (color: string) => (
    <span style={{ display: "inline-flex", alignItems: "center", gap: 6, fontFamily: fonts.rounded, fontSize: 16, fontWeight: 600, color, whiteSpace: "nowrap" }}>
      {text}
      <ChevronsRight size={17} strokeWidth={2.6} />
    </span>
  );
  // The highlight is a 56 pt window sliding from −120 to +120 around the label's centre.
  const x = phase * 240 - 120;
  return (
    <span style={{ position: "relative", display: "inline-block" }}>
      {label(Signature.textSecondary)}
      <span
        style={{
          position: "absolute",
          inset: 0,
          WebkitMaskImage: `linear-gradient(90deg, transparent calc(50% + ${x - 28}px), #000 calc(50% + ${x}px), transparent calc(50% + ${x + 28}px))`,
          maskImage: `linear-gradient(90deg, transparent calc(50% + ${x - 28}px), #000 calc(50% + ${x}px), transparent calc(50% + ${x + 28}px))`,
        }}
      >
        {label("#fff")}
      </span>
    </span>
  );
}
