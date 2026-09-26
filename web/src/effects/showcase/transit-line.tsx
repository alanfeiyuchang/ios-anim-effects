/** showcase.transit-line · 地铁线路 (TravelTransitLine.swift) */
import { AnimatePresence, motion } from "motion/react";
import { TramFront } from "lucide-react";
import { useEffect, useState } from "react";
import { DemoHint, NumericText, anim, fonts, hex, pressHandlers, springAt, useAutoplay, useElapsed, useHaptics, useLatest, useTimeouts, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";

const ROW_H = 40;
const STATIONS = [
  { en: "Harbour Front", zh: "港湾前" },
  { en: "Old Market", zh: "老市场" },
  { en: "Central", zh: "中央站" },
  { en: "Museum Quarter", zh: "博物馆区" },
  { en: "North Park", zh: "北公园" },
];
const N = STATIONS.length;

export default function TransitLine({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const zh = ctx.lang === "zh";
  const travel = ctx.n("travel");
  const dwell = ctx.n("dwell");
  const [current, setCurrent] = useState(0);
  const [arrivals, setArrivals] = useState([0, 0, 0, 0, 0]);
  const [runID, setRunID] = useState(0);
  const currentRef = useLatest(current);
  const pulseRef = useLatest(ctx.b("pulse"));

  const arrive = (index: number, silent: boolean) => {
    currentRef.current = index;
    setCurrent(index);
    after(travel * 0.9, () => {
      if (pulseRef.current) setArrivals((a) => a.map((v, i) => (i === index ? v + 1 : v)));
      if (!silent) haptics.tap();
    });
  };
  const arriveRef = useLatest(arrive);

  const send = (index: number, silent = false) => {
    if (index === currentRef.current) return;
    arrive(index, silent);
    setRunID((r) => r + 1);
  };

  // The automatic loop: dwell, then move on (silently); restarted by every tap.
  useEffect(() => {
    let timer = 0;
    const tick = () => {
      arriveRef.current((currentRef.current + 1) % N, true);
      timer = window.setTimeout(tick, (travel + dwell) * 1000);
    };
    timer = window.setTimeout(tick, (travel + dwell) * 1000);
    return () => window.clearTimeout(timer);
  }, [runID, travel, dwell, arriveRef, currentRef]);

  useAutoplay(ctx.isPreview, () => send((currentRef.current + 2) % N, true), { every: 3.6, delay: 1.6 });

  const move = anim.easeInOut(travel);
  const minutes = (N - 1 - current) * 3;
  const travelled = ROW_H * current;

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(26), width: 290, padding: 18, display: "flex", flexDirection: "column", gap: 14, flexShrink: 0 }}>
          <div style={{ display: "flex", alignItems: "flex-end" }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
              <span style={signatureEyebrow()}>{zh ? "2 号线 · 北行" : "Line 2 · Northbound"}</span>
              <span style={{ position: "relative", height: 22 }}>
                <AnimatePresence initial={false}>
                  <motion.span
                    key={current}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={move}
                    style={{ position: "absolute", left: 0, top: 0, whiteSpace: "nowrap", fontFamily: fonts.rounded, fontSize: 17, fontWeight: 700, color: "#fff", lineHeight: "22px" }}
                  >
                    {zh ? STATIONS[current].zh : STATIONS[current].en}
                  </motion.span>
                </AnimatePresence>
              </span>
            </div>
            <div style={{ flex: 1 }} />
            <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 3 }}>
              <span style={signatureEyebrow()}>{zh ? "距终点" : "To terminus"}</span>
              <span style={{ display: "flex", alignItems: "baseline", gap: 3 }}>
                <span style={{ ...signatureNumber(20), color: Signature.accent }}>
                  <NumericText value={minutes} />
                </span>
                <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 600, color: Signature.textSecondary }}>{zh ? "分" : "min"}</span>
              </span>
            </div>
          </div>
          <div style={{ position: "relative" }}>
            {/* track */}
            <div style={{ position: "absolute", left: 9, top: ROW_H / 2, width: 4, height: ROW_H * (N - 1), borderRadius: 2, background: white(0.1) }} />
            <motion.div
              initial={false}
              animate={{ height: Math.max(travelled, 4) }}
              transition={move}
              style={{ position: "absolute", left: 9, top: ROW_H / 2, width: 4, borderRadius: 2, background: Signature.accentGradient, boxShadow: `0 0 8px rgb(255 138 31 / 0.6)` }}
            />
            <div style={{ display: "flex", flexDirection: "column" }}>
              {STATIONS.map((s, index) => (
                <Station
                  key={index}
                  label={zh ? s.zh : s.en}
                  zh={zh}
                  passed={index <= current}
                  isCurrent={index === current}
                  isNext={index === current + 1}
                  arrival={arrivals[index]}
                  transitionT={move}
                  onTap={() => send(index)}
                />
              ))}
            </div>
            {/* train */}
            <motion.div
              initial={false}
              animate={{ y: ROW_H / 2 - 8 + travelled }}
              transition={move}
              style={{ position: "absolute", left: 3, top: 0, width: 16, height: 16, borderRadius: "50%", background: Signature.accent, boxShadow: `0 0 16px rgb(255 138 31 / 0.9)`, display: "grid", placeItems: "center", pointerEvents: "none" }}
            >
              <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#fff" }} />
            </motion.div>
          </div>
          <SignatureRim radius={26} />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap a station to send the train" zh="点击站点让列车驶去" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Station({
  label,
  zh,
  passed,
  isCurrent,
  isNext,
  arrival,
  transitionT,
  onTap,
}: {
  label: string;
  zh: boolean;
  passed: boolean;
  isCurrent: boolean;
  isNext: boolean;
  arrival: number;
  transitionT: ReturnType<typeof anim.easeInOut>;
  onTap: () => void;
}) {
  const [pressed, setPressed] = useState(false);
  const cssT = `${(transitionT as { duration: number }).duration}s ease-in-out`;
  return (
    <div onClick={onTap} {...pressHandlers(setPressed)} style={{ position: "relative", height: ROW_H, display: "flex", alignItems: "center", gap: 14, cursor: "pointer" }}>
      <div style={{ position: "absolute", left: -8, right: -8, top: 0, bottom: 0, borderRadius: 10, background: white(pressed ? 0.07 : 0), transition: "background 0.15s ease-out" }} />
      <div style={{ width: 22, display: "grid", placeItems: "center", flexShrink: 0 }}>
        <Ring passed={passed} arrival={arrival} cssT={cssT} />
      </div>
      <span
        style={{
          position: "relative",
          fontFamily: fonts.rounded,
          fontSize: 14,
          fontWeight: isCurrent ? 700 : 500,
          color: passed ? "#fff" : Signature.textSecondary,
          transition: `color ${cssT}`,
          whiteSpace: "nowrap",
        }}
      >
        {label}
      </span>
      <span style={{ flex: 1 }} />
      <AnimatePresence initial={false}>
        {isNext && (
          <motion.span
            initial={{ opacity: 0, y: -14 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -14 }}
            transition={transitionT}
            style={{ display: "flex", alignItems: "center", gap: 4 }}
          >
            <TramFront size={12} strokeWidth={2.4} color={Signature.accent} />
            <span style={signatureEyebrow()}>{zh ? "下一站 · 3 分" : "Next · 3 min"}</span>
          </motion.span>
        )}
      </AnimatePresence>
    </div>
  );
}

/** Station ring with the arrival pop: 1 → 1.4 in 120 ms, then a spring back (keyframeAnimator). */
function Ring({ passed, arrival, cssT }: { passed: boolean; arrival: number; cssT: string }) {
  const t = useElapsed(arrival, 0.57, true);
  let scale = 1;
  if (t >= 0) {
    if (t < 0.12) {
      const p = t / 0.12;
      scale = 1 + 0.4 * (p * p * (3 - 2 * p));
    } else scale = 1.4 - 0.4 * springAt(t - 0.12, 0.35, 0.5);
  }
  return (
    <div
      style={{
        width: 14,
        height: 14,
        borderRadius: "50%",
        boxSizing: "border-box",
        border: `2px solid ${passed ? Signature.accent : white(0.25)}`,
        background: passed ? hex(Signature.accent, 0.35) : Signature.card,
        transition: `border-color ${cssT}, background-color ${cssT}`,
        transform: `scale(${scale})`,
      }}
    />
  );
}

