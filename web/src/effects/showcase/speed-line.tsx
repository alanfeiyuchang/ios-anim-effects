/** showcase.speed-line · 极速折线 (Sport+SpeedLine.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { Gauge, RotateCcw } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, anim, clamp, fonts, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { SportEyebrowRow, SportPress } from "./_a-sport";

const VALUES = [18, 24, 21, 29, 26, 35, 31, 39, 36, 44, 40, 50, 43, 47];
const MIN = 10;
const MAX = 54;
const W = 252;
const H = 104;
const PEAK = Math.max(...VALUES);

function pt(i: number) {
  return { x: (W * i) / (VALUES.length - 1), y: H * (1 - (VALUES[i] - MIN) / (MAX - MIN)) };
}
function ptAt(progress: number) {
  const f = clamp(progress) * (VALUES.length - 1);
  const i = Math.min(Math.floor(f), VALUES.length - 2);
  const r = f - i;
  const a = pt(i);
  const b = pt(i + 1);
  return { x: a.x + (b.x - a.x) * r, y: a.y + (b.y - a.y) * r };
}
function linePath(progress: number) {
  const p0 = pt(0);
  let d = `M${p0.x},${p0.y}`;
  const whole = Math.floor(clamp(progress) * (VALUES.length - 1));
  for (let i = 1; i <= whole; i++) {
    const p = pt(i);
    d += ` L${p.x},${p.y}`;
  }
  const e = ptAt(progress);
  return d + ` L${e.x},${e.y}`;
}

export default function SpeedLine({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const progressMV = useMotionValue(0);
  const dotMV = useMotionValue(0);
  const [progress, setProgress] = useState(0);
  const [dotP, setDotP] = useState(0);
  const [shown, setShown] = useState(0);
  const [scrub, setScrub] = useState<number | null>(null);
  const [runID, setRunID] = useState(0);
  const scrubRef = useRef<number | null>(null);
  const dotFree = useRef(true);

  useMotionValueEvent(progressMV, "change", (v) => {
    setProgress(v);
    if (dotFree.current) dotMV.set(v);
  });
  useMotionValueEvent(dotMV, "change", setDotP);

  const duration = ctx.n("duration");
  useEffect(() => {
    // play(): reset without animation, wait 250 ms, draw linearly while the readout steps up.
    let cancelled = false;
    const timers: number[] = [];
    progressMV.stop();
    dotMV.stop();
    dotFree.current = true;
    progressMV.set(0);
    dotMV.set(0);
    setShown(0);
    setScrub(null);
    scrubRef.current = null;
    let current = 0;
    const step = duration / (VALUES.length - 1);
    timers.push(
      window.setTimeout(() => {
        if (cancelled) return;
        animate(progressMV, 1, anim.linear(duration));
        VALUES.forEach((v, k) =>
          timers.push(
            window.setTimeout(() => {
              if (cancelled) return;
              if (v > current) {
                current = v;
                setShown(v);
              }
            }, k * step * 1000),
          ),
        );
      }, 250),
    );
    return () => {
      cancelled = true;
      timers.forEach(clearTimeout);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [runID]);

  useAutoplay(ctx.isPreview, () => setRunID((r) => r + 1), { every: 4.4, delay: 4.4, intro: false });

  const endScrub = useCallback(() => {
    if (scrubRef.current === null) return;
    scrubRef.current = null;
    setScrub(null);
    const target = progressMV.get();
    animate(dotMV, target, { ...spring(0.45, 0.8), onComplete: () => (dotFree.current = true) });
  }, [dotMV, progressMV]);

  const pan = usePan({
    onChange: ({ location }) => {
      const f = clamp(location.x / W);
      const index = Math.round(f * (VALUES.length - 1));
      if (progressMV.get() < 1) {
        progressMV.stop();
        progressMV.set(1);
        setShown(PEAK);
      }
      if (index !== scrubRef.current) {
        scrubRef.current = index;
        dotFree.current = false;
        setScrub(index);
        animate(dotMV, index / (VALUES.length - 1), anim.snappyD(0.22));
        haptics.selection();
      }
    },
    onEnd: endScrub,
  });

  const displayed = scrub !== null ? VALUES[scrub] : shown;
  const dot = ptAt(dotP);
  const end = ptAt(progress);
  const line = linePath(progress);
  const glow = ctx.n("glow");

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(), padding: 20, width: 292, display: "flex", flexDirection: "column", gap: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <SportEyebrowRow title={ctx.t("Top speed", "最高速度")} icon={<Gauge size={11} strokeWidth={2.6} />} />
            <SportPress scale={0.88} onClick={() => setRunID((r) => r + 1)}>
              <div style={{ width: 28, height: 28, borderRadius: "50%", background: white(0.07), display: "grid", placeItems: "center", color: Signature.textSecondary }}>
                <RotateCcw size={12} strokeWidth={3} />
              </div>
            </SportPress>
          </div>
          <div style={{ display: "flex", alignItems: "baseline", gap: 5 }}>
            <span style={{ ...signatureNumber(48), color: "#fff", lineHeight: "57px" }}>
              <NumericText value={displayed} />
            </span>
            <span style={{ fontFamily: fonts.rounded, fontSize: 14, fontWeight: 600, color: Signature.textSecondary }}>km/h</span>
            <span style={{ flex: 1 }} />
            <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 500, color: Signature.textSecondary }}>{ctx.t("Nordkette · today", "Nordkette · 今日")}</span>
          </div>
          <div {...pan} style={{ position: "relative", width: W, height: H, touchAction: "none", cursor: "crosshair" }}>
            {[0, 1, 2].map((k) => (
              <div key={k} style={{ position: "absolute", left: 0, right: 0, top: k * ((H - 1) / 2), height: 1, background: white(0.07) }} />
            ))}
            <svg width={W} height={H} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
              <defs>
                <linearGradient id="speed-area" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0" stopColor={Signature.accent} stopOpacity={0.32} />
                  <stop offset="1" stopColor={Signature.accent} stopOpacity={0} />
                </linearGradient>
                <linearGradient id="speed-stroke" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2={W} y2={H}>
                  <stop offset="0" stopColor={Signature.accentSoft} />
                  <stop offset="0.5" stopColor={Signature.accent} />
                  <stop offset="1" stopColor={Signature.accentHot} />
                </linearGradient>
              </defs>
              {ctx.b("area") && <path d={`${line} L${end.x},${H} L0,${H} Z`} fill="url(#speed-area)" />}
            </svg>
            <svg width={W} height={H} style={{ position: "absolute", inset: 0, overflow: "visible", filter: `drop-shadow(0 0 6px rgb(255 138 31 / 0.6))` }}>
              <path d={line} fill="none" stroke="url(#speed-stroke)" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            <div style={{ position: "absolute", left: dot.x - 10, top: dot.y - 10, width: 20, height: 20, borderRadius: "50%", background: "rgb(255 138 31 / 0.28)" }} />
            <div
              style={{
                position: "absolute",
                left: dot.x - 4.5,
                top: dot.y - 4.5,
                width: 9,
                height: 9,
                borderRadius: "50%",
                background: "#fff",
                boxShadow: glow > 0 ? `0 0 ${glow}px ${Signature.accent}` : undefined,
              }}
            />
            <AnimatePresence>{scrub !== null && <Tooltip key="tip" index={scrub} />}</AnimatePresence>
          </div>
          <SignatureRim />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Drag across the chart" zh="在图表上横向拖动" style={{ paddingBottom: 16 }} />
      </div>
    </SignatureStage>
  );
}

function Tooltip({ index }: { index: number }) {
  const p = pt(index);
  const t = anim.snappyD(0.22);
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, transition: spring(0.45, 0.8) }}
      transition={t}
      style={{ position: "absolute", inset: 0, pointerEvents: "none" }}
    >
      <motion.div initial={false} animate={{ x: p.x - 0.5 }} transition={t} style={{ position: "absolute", left: 0, top: 0, width: 1, height: H, background: white(0.28) }} />
      <motion.div
        initial={false}
        animate={{ x: clamp(p.x, 32, W - 32), y: Math.max(p.y - 24, 10) }}
        transition={t}
        style={{ position: "absolute", left: 0, top: 0, width: 0, height: 0 }}
      >
        <div
          style={{
            position: "absolute",
            transform: "translate(-50%, -50%)",
            whiteSpace: "nowrap",
            fontFamily: fonts.rounded,
            fontSize: 11,
            fontWeight: 700,
            fontVariantNumeric: "tabular-nums",
            color: "#000",
            padding: "4px 8px",
            borderRadius: 999,
            background: "#fff",
            boxShadow: "0 3px 6px rgb(0 0 0 / 0.4)",
            lineHeight: "13px",
          }}
        >
          {VALUES[index]} km/h
        </div>
      </motion.div>
    </motion.div>
  );
}
