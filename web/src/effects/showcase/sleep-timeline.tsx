/** showcase.sleep-timeline · 睡眠时间线 (Life+SleepTimeline.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent, type Transition } from "motion/react";
import { BedDouble, RotateCcw } from "lucide-react";
import { useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { DemoHint, NumericText, anim, clamp, delayed, fonts, spring, springDB, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { SportEyebrowRow, SportPress } from "./_a-sport";

const STAGES = [
  { en: "Awake", zh: "清醒", color: Signature.accent, rgb: "255 138 31" },
  { en: "REM", zh: "快速眼动", color: "#5AC8FA", rgb: "90 200 250" },
  { en: "Core", zh: "核心", color: "#4F7CFF", rgb: "79 124 255" },
  { en: "Deep", zh: "深睡", color: "#8A5CFF", rgb: "138 92 255" },
];
/** Minutes after 23:10; the night lasts 462 min (until 06:52). */
const TOTAL = 462;
const START_CLOCK = 23 * 60 + 10;
const BLOCKS: [number, number, number][] = [
  [2, 0, 18], [3, 18, 62], [2, 62, 98], [1, 98, 120], [2, 120, 160], [3, 160, 190], [2, 190, 232], [1, 232, 262],
  [0, 262, 268], [2, 268, 318], [1, 318, 352], [2, 352, 392], [3, 392, 404], [2, 404, 430], [1, 430, 456], [0, 456, 462],
];
const W = 264;
const H = 108;
const LANE = H / 4;
const PREVIEW_SCRUBS: (number | null)[] = [0.12, 0.3, 0.55, null, 0.87, null];

const minutesIn = (s: number) => BLOCKS.filter((b) => b[0] === s).reduce((a, b) => a + b[2] - b[1], 0);
const stageAt = (m: number) => BLOCKS.find((b) => m >= b[1] && m < b[2])?.[0] ?? 0;
const clock = (m: number) => {
  const v = (START_CLOCK + Math.floor(m)) % 1440;
  return `${String(Math.floor(v / 60)).padStart(2, "0")}:${String(v % 60).padStart(2, "0")}`;
};
const duration = (minutes: number, zh: boolean) => {
  const m = Math.round(minutes);
  if (zh) return m >= 60 ? `${Math.floor(m / 60)} 小时 ${m % 60} 分` : `${m} 分`;
  return m >= 60 ? `${Math.floor(m / 60)}h ${m % 60}m` : `${m}m`;
};
const CONNECTORS = BLOCKS.slice(1)
  .map((b, i) => {
    const x = (W * b[1]) / TOTAL;
    return `M${x},${LANE * (BLOCKS[i][0] + 0.5)} L${x},${LANE * (b[0] + 0.5)}`;
  })
  .join(" ");

export default function SleepTimeline({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  const revealMV = useMotionValue(0);
  const [reveal, setReveal] = useState(0);
  useMotionValueEvent(revealMV, "change", setReveal);
  const [counted, setCounted] = useState(0);
  const [scrub, setScrub] = useState<number | null>(null);
  const [scrubT, setScrubT] = useState<Transition>({ duration: 0 });
  const scrubRef = useRef<number | null>(null);
  const [sweeping, setSweeping] = useState(false);
  const [legendShown, setLegendShown] = useState(false);
  const [runID, setRunID] = useState(0);
  const step = useRef(0);

  useEffect(() => {
    let cancelled = false;
    const timers: number[] = [];
    revealMV.stop();
    revealMV.set(0);
    setCounted(0);
    setScrub(null);
    scrubRef.current = null;
    setSweeping(false);
    setLegendShown(false);
    const d = ctx.n("duration");
    timers.push(
      window.setTimeout(() => {
        if (cancelled) return;
        setSweeping(true);
        animate(revealMV, 1, anim.easeInOut(d));
        for (let i = 1; i <= 14; i++) {
          timers.push(
            window.setTimeout(() => {
              if (cancelled) return;
              const t = i / 14;
              setCounted(TOTAL * (1 - Math.pow(1 - t, 3)));
              if (i === 8) setLegendShown(true);
            }, (i - 1) * (d / 14) * 1000),
          );
        }
        timers.push(window.setTimeout(() => !cancelled && setSweeping(false), d * 1000));
      }, 250),
    );
    return () => {
      cancelled = true;
      timers.forEach(clearTimeout);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [runID]);

  useAutoplay(
    ctx.isPreview,
    () => {
      const next = PREVIEW_SCRUBS[step.current % PREVIEW_SCRUBS.length];
      step.current += 1;
      setScrubT(springDB(0.5, 0));
      scrubRef.current = next;
      setScrub(next);
    },
    { every: 1.1, delay: 2.0, intro: false },
  );

  const focus = scrub === null ? null : stageAt(scrub * TOTAL);
  const pan = usePan({
    onChange: ({ location }) => {
      const f = clamp(location.x / W, 0, 0.999);
      const before = scrubRef.current === null ? null : stageAt(scrubRef.current * TOTAL);
      setScrubT({ duration: 0 });
      scrubRef.current = f;
      setScrub(f);
      if (stageAt(f * TOTAL) !== before) haptics.selection();
    },
    onEnd: () => {
      scrubRef.current = null;
      setScrub(null);
    },
  });

  const dimT = spring(ctx.n("response"), 0.8);
  const dim = ctx.n("dim");
  const revealW = W * reveal * 1.1;

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(), width: 300, padding: 18, display: "flex", flexDirection: "column", gap: 12, flexShrink: 0 }}>
          <div style={{ display: "flex", alignItems: "flex-start" }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 4, flex: 1 }}>
              <SportEyebrowRow title={ctx.t("Sleep · last night", "睡眠 · 昨晚")} icon={<BedDouble size={11} strokeWidth={2.6} />} />
              <span style={{ ...signatureNumber(26), color: "#fff", lineHeight: "31px" }}>
                <NumericText value={counted} text={duration(counted, zh)} />
              </span>
            </div>
            <SportPress scale={0.88} dim={0.05} onClick={() => { haptics.tap(); setRunID((r) => r + 1); }}>
              <span style={{ width: 28, height: 28, borderRadius: "50%", background: white(0.07), display: "grid", placeItems: "center", color: Signature.textSecondary }}>
                <RotateCcw size={11} strokeWidth={3} />
              </span>
            </SportPress>
          </div>
          <div style={{ paddingTop: 22, display: "flex", flexDirection: "column", gap: 4 }}>
            <div {...pan} style={{ position: "relative", width: W, height: H, touchAction: "none", cursor: "crosshair" }}>
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  WebkitMaskImage: `linear-gradient(90deg, #000 ${revealW * 0.9}px, transparent ${revealW}px)`,
                  maskImage: `linear-gradient(90deg, #000 ${revealW * 0.9}px, transparent ${revealW}px)`,
                }}
              >
                {STAGES.map((_, s) => (
                  <div key={s} style={{ position: "absolute", left: 0, top: LANE * (s + 0.5), width: W, height: 1, background: white(0.04) }} />
                ))}
                <svg width={W} height={H} style={{ position: "absolute", inset: 0 }}>
                  <path d={CONNECTORS} stroke={white(0.22)} strokeWidth={1} fill="none" />
                </svg>
                {BLOCKS.map(([s, a, b], i) => {
                  const dimmed = focus !== null && focus !== s;
                  const st = STAGES[s];
                  return (
                    <motion.div
                      key={i}
                      initial={false}
                      animate={{ opacity: dimmed ? 1 - dim : 1, boxShadow: `0 0 4px rgb(${st.rgb} / ${dimmed ? 0 : 0.45})` }}
                      transition={dimT}
                      style={{
                        position: "absolute",
                        left: (W * a) / TOTAL,
                        top: LANE * (s + 0.2),
                        width: Math.max((W * (b - a)) / TOTAL, 3),
                        height: LANE * 0.6,
                        borderRadius: 4,
                        background: `linear-gradient(rgb(255 255 255 / 0.18), rgb(255 255 255 / 0)), ${st.color}`,
                      }}
                    />
                  );
                })}
              </div>
              <motion.div
                initial={false}
                animate={{ opacity: sweeping ? 0.7 : 0 }}
                transition={anim.easeOut(sweeping ? 0.12 : 0.25)}
                style={{ position: "absolute", left: W * reveal - 1, top: 0, width: 2, height: H, borderRadius: 1, background: "#fff", boxShadow: "0 0 6px rgb(255 255 255 / 0.8)", pointerEvents: "none" }}
              />
              <AnimatePresence>
                {scrub !== null && focus !== null && (
                  <motion.div
                    key="cursor"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={anim.easeOut(0.2)}
                    style={{ position: "absolute", inset: 0, pointerEvents: "none" }}
                  >
                    <motion.div initial={false} animate={{ x: W * scrub }} transition={scrubT} style={{ position: "absolute", left: 0, top: -3, width: 1, height: H + 6, background: white(0.85) }} />
                    <motion.div
                      initial={false}
                      animate={{ x: Math.min(Math.max(W * scrub - 55, -4), W - 106) }}
                      transition={scrubT}
                      style={{ position: "absolute", left: 0, top: -24, width: 110, display: "flex", justifyContent: "center" }}
                    >
                      <span
                        style={{
                          whiteSpace: "nowrap",
                          fontFamily: fonts.rounded,
                          fontSize: 10,
                          fontWeight: 700,
                          fontVariantNumeric: "tabular-nums",
                          color: "#000",
                          padding: "3px 7px",
                          borderRadius: 99,
                          background: STAGES[focus].color,
                          lineHeight: "12px",
                        }}
                      >
                        {clock(scrub * TOTAL)} · {zh ? STAGES[focus].zh : STAGES[focus].en}
                      </span>
                    </motion.div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
            <div style={{ display: "flex", fontFamily: fonts.rounded, fontSize: 10, fontWeight: 600, fontVariantNumeric: "tabular-nums", color: Signature.textSecondary, lineHeight: "12px" }}>
              <span>23:10</span>
              <span style={{ flex: 1 }} />
              <span>03:00</span>
              <span style={{ flex: 1 }} />
              <span>06:52</span>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            {STAGES.map((st, s) => {
              const minutes = minutesIn(s);
              const lit = focus === null || focus === s;
              return (
                <motion.div
                  key={s}
                  initial={false}
                  animate={{ opacity: lit ? 1 : 0.45 }}
                  transition={anim.easeOut(0.2)}
                  style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 4 }}
                >
                  <span style={{ display: "flex", alignItems: "center", gap: 4, fontFamily: fonts.rounded, fontSize: 9, fontWeight: 700, color: Signature.textSecondary, lineHeight: "11px", whiteSpace: "nowrap" }}>
                    <span style={{ width: 6, height: 6, borderRadius: "50%", background: st.color, flexShrink: 0 }} />
                    {zh ? st.zh : st.en}
                  </span>
                  <FitText size={12} style={{ fontFamily: fonts.rounded, fontWeight: 600, fontVariantNumeric: "tabular-nums", color: "#fff", lineHeight: "14px" }}>
                    {duration(minutes, zh)}
                  </FitText>
                  <div style={{ position: "relative", height: 3, borderRadius: 2, background: white(0.08) }}>
                    <motion.div
                      initial={false}
                      animate={{ scaleX: legendShown ? (minutes / TOTAL) * 1.6 : 0.001 }}
                      transition={legendShown ? delayed(spring(0.5, 0.8), s * 0.06) : { duration: 0 }}
                      style={{ position: "absolute", inset: 0, borderRadius: 2, background: st.color, transformOrigin: "0% 50%" }}
                    />
                  </div>
                </motion.div>
              );
            })}
          </div>
          <SignatureRim />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Drag across the chart" zh="在图上横向拖动" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

/** `.lineLimit(1).minimumScaleFactor(0.7)`: shrinks the font until the text fits its column. */
function FitText({ size, style, children }: { size: number; style?: CSSProperties; children: ReactNode }) {
  const box = useRef<HTMLSpanElement>(null);
  const text = useRef<HTMLSpanElement>(null);
  const [scale, setScale] = useState(1);
  useLayoutEffect(() => {
    if (!box.current || !text.current) return;
    const natural = text.current.offsetWidth / scale;
    const fit = box.current.clientWidth / Math.max(natural, 1);
    const next = Math.max(0.7, Math.min(1, fit));
    if (Math.abs(next - scale) > 0.01) setScale(next);
  });
  return (
    <span ref={box} style={{ display: "block", width: "100%", overflow: "hidden", whiteSpace: "nowrap" }}>
      <span ref={text} style={{ ...style, fontSize: size * scale, display: "inline-block" }}>
        {children}
      </span>
    </span>
  );
}
