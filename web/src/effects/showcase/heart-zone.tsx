/** showcase.heart-zone · 心率区间 (Sport+HeartZone.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { Activity, Heart } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, SymbolBounce, anim, clamp, fonts, spring, useAutoplay, useHaptics, useLatest, useTimeouts, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { SportEyebrowRow, SportPress } from "./_a-sport";

const COLORS = ["rgb(255 255 255 / 0.75)", "#8FD3FF", Signature.lime, Signature.accent, Signature.accentHot];
const GLOWS = ["rgb(255 255 255 / 0.45)", "rgb(143 211 255 / 0.6)", "rgb(200 245 96 / 0.6)", "rgb(255 138 31 / 0.6)", "rgb(255 90 31 / 0.6)"];
const HALOS = ["rgb(255 255 255 / 0.26)", "rgb(143 211 255 / 0.35)", "rgb(200 245 96 / 0.35)", "rgb(255 138 31 / 0.35)", "rgb(255 90 31 / 0.35)"];
const NAMES: [string, string][] = [
  ["Warm-up", "热身"],
  ["Easy", "轻松"],
  ["Aerobic", "有氧"],
  ["Threshold", "乳酸阈"],
  ["Max", "极限"],
];
/** The gauge covers 50 %…100 % of max HR, one zone per 10 %. */
const fractionOf = (bpm: number, maxHR: number) => clamp((bpm / maxHR - 0.5) / 0.5);
const zoneOf = (bpm: number, maxHR: number) => Math.min(4, Math.floor(fractionOf(bpm, maxHR) * 5));

const C = 100;
const R = 92;
const pt = (deg: number) => [C + R * Math.cos((deg * Math.PI) / 180), C + R * Math.sin((deg * Math.PI) / 180)];
function arc(f0: number, f1: number) {
  const a0 = 135 + 360 * f0;
  const a1 = 135 + 360 * f1;
  const [x0, y0] = pt(a0);
  const [x1, y1] = pt(a1);
  return `M${x0},${y0} A${R},${R} 0 ${a1 - a0 > 180 ? 1 : 0} 1 ${x1},${y1}`;
}

export default function HeartZone({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [bpm, setBpm] = useState(128);
  const [sprinting, setSprinting] = useState(false);
  const [beats, setBeats] = useState(0);
  const haloMV = useMotionValue(0);
  const [halo, setHalo] = useState(0);
  useMotionValueEvent(haloMV, "change", setHalo);
  const maxHR = Math.max(ctx.n("maxHR"), 120);
  const bpmRef = useLatest(bpm);

  const indicator = useMotionValue(fractionOf(128, maxHR));
  const [indicatorF, setIndicatorF] = useState(indicator.get());
  useMotionValueEvent(indicator, "change", setIndicatorF);
  const response = ctx.n("response");
  useEffect(() => {
    animate(indicator, fractionOf(bpm, maxHR), spring(response, 0.7));
  }, [bpm, maxHR, response, indicator]);

  // drift(): every 650 ms step toward 66 % (cruise) or 93 % (sprint) of max HR, with jitter.
  useEffect(() => {
    const step = () =>
      setBpm((b) => {
        const target = Math.trunc(maxHR * (sprinting ? 0.93 : 0.66));
        const gap = target - b;
        const size = Math.max(1, Math.min(Math.trunc(Math.abs(gap) / 3), 9));
        const move = gap === 0 ? 0 : gap > 0 ? size : -size;
        return b + move + (Math.floor(Math.random() * 3) - 1);
      });
    step();
    const id = window.setInterval(step, 650);
    return () => window.clearInterval(id);
  }, [sprinting, maxHR]);

  // beat(): bounce the heart and swell the halo at the real tempo.
  const beatTimer = useRef(0);
  useEffect(() => {
    let cancelled = false;
    const beat = () => {
      if (cancelled) return;
      setBeats((b) => b + 1);
      haloMV.stop();
      haloMV.set(1);
      window.setTimeout(() => !cancelled && animate(haloMV, 0, anim.easeOut(0.45)), 20);
      const interval = 60 / Math.max(bpmRef.current, 40);
      beatTimer.current = window.setTimeout(beat, (0.02 + Math.max(0.25, interval - 0.02)) * 1000);
    };
    beat();
    return () => {
      cancelled = true;
      window.clearTimeout(beatTimer.current);
    };
  }, [haloMV, bpmRef]);

  const toggleSprint = () => {
    setSprinting((s) => !s);
    haptics.tap("medium");
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (ctx.isPreview) toggleSprint();
      else {
        // Detail intro: sprint, then recover so the stage isn't left pinned in the red zone.
        clearAll();
        setSprinting(true);
        after(3.2, () => setSprinting(false));
      }
    },
    { every: 4.5, delay: 1.5 },
  );

  const zone = zoneOf(bpm, maxHR);
  const zh = ctx.lang === "zh";
  const name = NAMES[zone][zh ? 1 : 0];
  const label = zh ? `${zone + 1} 区 · ${name}` : `Zone ${zone + 1} · ${name}`;
  const haloOn = ctx.b("halo") ? halo : 0;
  const t3 = anim.easeInOut(0.3);
  const angle = 135 + 270 * indicatorF;

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <SportPress
          scale={0.98}
          dim={0.04}
          radius={26}
          onClick={() => {
            clearAll();
            toggleSprint();
          }}
        >
          <div style={{ ...signatureCard(), padding: 20, width: 280, display: "flex", flexDirection: "column", alignItems: "center", gap: 6, color: "#fff" }}>
            <SportEyebrowRow
              title={ctx.t("Heart rate", "心率")}
              icon={<Activity size={11} strokeWidth={2.6} />}
              trailing={sprinting ? ctx.t("Sprint", "冲刺") : ctx.t("Cruise", "巡航")}
              style={{ alignSelf: "stretch" }}
            />
            <div style={{ position: "relative", width: 200, height: 200 }}>
              <svg width={200} height={200} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
                {COLORS.map((color, index) => {
                  const active = index === zone;
                  return (
                    <motion.path
                      key={index}
                      d={arc((0.75 * index) / 5 + 0.006, (0.75 * (index + 1)) / 5 - 0.006)}
                      fill="none"
                      stroke={color}
                      strokeLinecap="round"
                      initial={false}
                      animate={{ strokeWidth: active ? 12 : 10, opacity: active ? 1 : 0.3, filter: `drop-shadow(0 0 ${active ? 8 : 0}px ${active ? GLOWS[index] : "transparent"})` }}
                      transition={t3}
                    />
                  );
                })}
              </svg>
              <div style={{ position: "absolute", left: C - 7, top: C - 7, width: 14, height: 14, transform: `rotate(${angle}deg) translateX(${R}px)` }}>
                <div style={{ width: 14, height: 14, borderRadius: "50%", background: "#fff", boxShadow: `inset 0 0 0 3px ${Signature.ink}, 0 0 4px rgb(0 0 0 / 0.5)` }} />
              </div>
              <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2 }}>
                <div style={{ position: "relative", width: 26, height: 22, display: "grid", placeItems: "center" }}>
                  <div
                    style={{
                      position: "absolute",
                      left: 0,
                      top: -2,
                      width: 26,
                      height: 26,
                      borderRadius: "50%",
                      background: HALOS[zone],
                      transform: `scale(${1 + 0.4 * (1 - haloOn)})`,
                      opacity: haloOn * 0.8,
                      filter: "blur(4px)",
                    }}
                  />
                  <SymbolBounce trigger={beats}>
                    <motion.span initial={false} animate={{ color: COLORS[zone] }} transition={t3} style={{ display: "grid" }}>
                      <Heart size={20} fill="currentColor" strokeWidth={0} />
                    </motion.span>
                  </SymbolBounce>
                </div>
                <span style={{ ...signatureNumber(46), color: "#fff", lineHeight: "55px" }}>
                  <NumericText value={bpm} />
                </span>
                <motion.span
                  initial={false}
                  animate={{ color: COLORS[zone] }}
                  transition={t3}
                  style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 600, lineHeight: "13px" }}
                >
                  {label}
                </motion.span>
              </div>
            </div>
            <SignatureRim />
          </div>
        </SportPress>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap to sprint / recover" zh="点击冲刺或恢复" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}
