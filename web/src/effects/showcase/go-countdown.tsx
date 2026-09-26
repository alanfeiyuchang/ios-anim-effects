/** showcase.go-countdown · 出发倒计时 (Sport+Countdown.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent, type Transition } from "motion/react";
import { Flag, Play } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, anim, fonts, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { SportEyebrowRow, SportPress } from "./_a-sport";

const SIZE = 170;
const R = SIZE / 2; // SwiftUI `stroke` straddles the circle of the 170 frame

export default function GoCountdown({ ctx }: DemoProps) {
  const haptics = useHaptics();
  /** null = idle, > 0 = counting, 0 = GO. */
  const [count, setCount] = useState<number | null>(null);
  const [labelT, setLabelT] = useState<Transition>(spring(0.35, 0.6));
  const ringMV = useMotionValue(1);
  const [ring, setRing] = useState(1);
  useMotionValueEvent(ringMV, "change", setRing);
  const [wave, setWave] = useState(0);
  const countRef = useRef<number | null>(null);
  const [run, setRun] = useState<{ id: number; silent: boolean }>({ id: 0, silent: false });

  const start = (silent: boolean) => {
    if (countRef.current !== null) return;
    countRef.current = -1;
    setRun((r) => ({ id: r.id + 1, silent }));
  };

  useEffect(() => {
    if (run.id === 0) return;
    const step = ctx.n("step");
    const from = Math.max(ctx.i("from"), 1);
    const muted = run.silent;
    let cancelled = false;
    const timers: number[] = [];
    const at = (s: number, fn: () => void) => timers.push(window.setTimeout(() => !cancelled && fn(), s * 1000));
    for (let k = 0; k < from; k++) {
      const n = from - k;
      at(k * step, () => {
        ringMV.stop();
        ringMV.set(1);
        setLabelT(spring(0.35, 0.6));
        countRef.current = n;
        setCount(n);
        if (!muted) haptics.tap("medium");
      });
      at(k * step + 0.04, () => animate(ringMV, 0, anim.linear(step - 0.04)));
    }
    const goAt = from * step;
    at(goAt, () => {
      setLabelT(spring(0.4, 0.55));
      countRef.current = 0;
      setCount(0);
      animate(ringMV, 1, spring(0.4, 0.55));
      if (ctx.b("shockwave")) setWave((w) => w + 1);
      if (!muted) haptics.success();
    });
    at(goAt + (ctx.b("shockwave") ? 0.03 : 0) + 1.6, () => {
      setLabelT(spring(0.5, 0.85));
      countRef.current = null;
      setCount(null);
    });
    return () => {
      cancelled = true;
      timers.forEach(clearTimeout);
      if (countRef.current !== null) countRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [run]);

  useAutoplay(ctx.isPreview, () => start(true), { every: ctx.i("from") * ctx.n("step") + 3.0, delay: 0.6 });

  const isGo = count === 0;
  const c = 2 * Math.PI * R;
  const glow = isGo ? "rgb(200 245 96 / 0.6)" : "rgb(255 138 31 / 0.6)";

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <SportPress scale={0.98} dim={0.04} radius={26} onClick={() => start(false)}>
          <div style={{ ...signatureCard(), padding: 20, width: 272, display: "flex", flexDirection: "column", alignItems: "center", gap: 16, color: "#fff" }}>
            <SportEyebrowRow title={ctx.t("Start gate", "出发门")} icon={<Flag size={11} strokeWidth={2.6} />} trailing="Nordkette" style={{ alignSelf: "stretch" }} />
            <div style={{ position: "relative", width: SIZE, height: SIZE }}>
              <svg width={SIZE} height={SIZE} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
                <circle cx={SIZE / 2} cy={SIZE / 2} r={R} fill="none" stroke={white(0.07)} strokeWidth={10} />
              </svg>
              <svg width={SIZE} height={SIZE} style={{ position: "absolute", inset: 0, overflow: "visible", transform: "rotate(-90deg)", filter: `drop-shadow(0 0 10px ${glow})` }}>
                <defs>
                  <linearGradient id="countdown-ring" x1="0" y1="0" x2="1" y2="1">
                    <stop offset="0" stopColor={Signature.accentSoft} />
                    <stop offset="0.5" stopColor={Signature.accent} />
                    <stop offset="1" stopColor={Signature.accentHot} />
                  </linearGradient>
                </defs>
                {ring > 0.0005 && (
                  <circle
                    cx={SIZE / 2}
                    cy={SIZE / 2}
                    r={R}
                    fill="none"
                    stroke={isGo ? Signature.lime : "url(#countdown-ring)"}
                    strokeWidth={10}
                    strokeLinecap="round"
                    strokeDasharray={`${Math.min(ring, 1) * c} ${c}`}
                  />
                )}
              </svg>
              {wave > 0 && <Shockwave key={wave} />}
              <AnimatePresence custom={labelT}>
                {count !== null ? (
                  <motion.div
                    key={count}
                    custom={labelT}
                    variants={{
                      hidden: { scale: 1.8, opacity: 0 },
                      shown: (t: Transition) => ({ scale: 1, opacity: 1, transition: t }),
                      gone: (t: Transition) => ({ scale: 0.4, opacity: 0, transition: t }),
                    }}
                    initial="hidden"
                    animate="shown"
                    exit="gone"
                    style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}
                  >
                    <span style={{ ...signatureNumber(isGo ? 58 : 76), color: count === 0 ? Signature.lime : "#fff" }}>{count === 0 ? "GO" : count}</span>
                  </motion.div>
                ) : (
                  <motion.div
                    key="idle"
                    custom={labelT}
                    variants={{
                      hidden: { scale: 0.8, opacity: 0 },
                      shown: (t: Transition) => ({ scale: 1, opacity: 1, transition: t }),
                      gone: (t: Transition) => ({ scale: 0.8, opacity: 0, transition: t }),
                    }}
                    initial={false}
                    animate="shown"
                    exit="gone"
                    style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 6 }}
                  >
                    <span style={{ color: Signature.accent, display: "grid" }}>
                      <Play size={22} fill="currentColor" strokeWidth={0} />
                    </span>
                    <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, color: Signature.textSecondary, lineHeight: "14px" }}>{ctx.t("Tap to start", "点击开始")}</span>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
            <SignatureRim />
          </div>
        </SportPress>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap the card to start the countdown" zh="点击卡片开始倒计时" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Shockwave() {
  const [fired, setFired] = useState(false);
  useEffect(() => {
    const id = window.setTimeout(() => setFired(true), 30);
    return () => clearTimeout(id);
  }, []);
  return (
    <motion.div
      initial={{ scale: 1, opacity: 0.9 }}
      animate={fired ? { scale: 1.9, opacity: 0 } : undefined}
      transition={anim.easeOut(0.9)}
      style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: `inset 0 0 0 1.5px ${Signature.accent}, 0 0 0 1.5px ${Signature.accent}`, pointerEvents: "none" }}
    />
  );
}
