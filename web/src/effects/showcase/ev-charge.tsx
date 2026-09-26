/** showcase.ev-charge · 电车充电 (Life+EvCharge.swift) */
import { AnimatePresence, motion, useAnimationControls } from "motion/react";
import { CarFront, ChevronRight, Pause } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, anim, fonts, springDB, useAutoplay, useClock, useHaptics, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";
import { SportLiveDot, SportPress, sportHash } from "./_a-sport";

const BAR_W = 240;
const BAR_H = 34;

export default function EvCharge({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  const [percent, setPercent] = useState(62);
  const [power, setPower] = useState(152);
  const [paused, setPaused] = useState(false);
  const [charged, setCharged] = useState(false);
  const [flashes, setFlashes] = useState(0);
  const st = useRef({ percent: 62, charged: false });
  st.current = { percent, charged };

  const beat = ctx.n("beat");
  useEffect(() => {
    if (paused) return;
    let cancelled = false;
    let timer = 0;
    const loop = () => {
      timer = window.setTimeout(() => {
        if (cancelled) return;
        if (st.current.percent >= 100) {
          setCharged(true);
          setFlashes((f) => f + 1);
          timer = window.setTimeout(() => {
            if (cancelled) return;
            setCharged(false);
            setPercent(62);
            st.current.percent = 62;
            loop();
          }, 2000);
          return;
        }
        const jitter = Math.floor(sportHash(st.current.percent) * 8);
        setPercent((p) => p + 1);
        st.current.percent += 1;
        setPower(148 + jitter);
        loop();
      }, beat * 1000);
    };
    loop();
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [paused, beat]);

  const togglePause = () => {
    if (st.current.charged) return;
    haptics.tap("medium");
    setPaused((p) => !p);
  };
  useAutoplay(ctx.isPreview, togglePause, { every: 2.2, delay: 2.4, intro: false });

  const flash = useAnimationControls();
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    void flash.start({
      filter: ["brightness(1)", "brightness(1.5)", "brightness(1.05)", "brightness(1.4)", "brightness(1)"],
      transition: { duration: 0.73, times: [0, 0.08 / 0.73, 0.3 / 0.73, 0.38 / 0.73, 1], ease: ["linear", "easeInOut", "linear", "easeInOut"] },
    });
  }, [flashes, flash]);

  const smooth = springDB(0.3, 0);
  const minutesLeft = Math.max(0, Math.trunc(((100 - percent) * 2) / 3));
  const eyebrow = charged ? (zh ? "已充满 · 4 号桩" : "Charged · Bay 4") : paused ? (zh ? "已暂停 · 4 号桩" : "Paused · Bay 4") : zh ? "充电中 · 4 号桩" : "Charging · Bay 4";
  const stat = (value: number, unit: string, label: string) => (
    <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
      <span style={signatureEyebrow()}>{label}</span>
      <span style={{ display: "flex", alignItems: "baseline", gap: 3 }}>
        <span style={{ ...signatureNumber(18), color: "#fff", lineHeight: "22px" }}>
          <NumericText value={value} />
        </span>
        <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 600, color: Signature.textSecondary }}>{unit}</span>
      </span>
    </div>
  );

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <SportPress scale={0.98} dim={0.04} radius={26} onClick={togglePause}>
          <div style={{ ...signatureCard(), width: BAR_W + 44, padding: 18, display: "flex", flexDirection: "column", gap: 16, color: "#fff" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
              {paused ? (
                <span style={{ width: 24, height: 24, display: "grid", placeItems: "center", color: Signature.textSecondary }}>
                  <Pause size={12} fill="currentColor" strokeWidth={0} />
                </span>
              ) : (
                <SportLiveDot color={charged ? Signature.lime : Signature.accent} preview={ctx.isPreview} />
              )}
              <span style={{ position: "relative", height: 12, flex: 1 }}>
                <AnimatePresence initial={false}>
                  <motion.span key={eyebrow} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={smooth} style={{ ...signatureEyebrow(), position: "absolute", left: 0, top: 0, whiteSpace: "nowrap" }}>
                    {eyebrow}
                  </motion.span>
                </AnimatePresence>
              </span>
              <span style={{ color: Signature.accent, display: "grid" }}>
                <CarFront size={19} strokeWidth={2.4} />
              </span>
            </div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 2 }}>
              <motion.span initial={false} animate={{ color: charged ? Signature.lime : "#FFFFFF" }} transition={smooth} style={{ ...signatureNumber(46), lineHeight: "55px" }}>
                <NumericText value={percent} />
              </motion.span>
              <span style={{ ...signatureNumber(20), color: Signature.textSecondary }}>%</span>
            </div>
            <div style={{ display: "flex", gap: 22 }}>
              {stat(paused || charged ? 0 : power, "kW", zh ? "功率" : "Power")}
              {stat(minutesLeft, zh ? "分钟" : "min", zh ? "剩余" : "Left")}
              {stat(Math.trunc(((percent - 62) * 3) / 4) + 4, "kWh", zh ? "已充" : "Added")}
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 3 }}>
              <div style={{ position: "relative", width: BAR_W, height: BAR_H, borderRadius: 10, background: white(0.07) }}>
                <motion.div
                  initial={false}
                  animate={{ width: (BAR_W * percent) / 100, boxShadow: `0 0 8px ${charged ? "rgb(200 245 96 / 0.45)" : "rgb(255 138 31 / 0.45)"}` }}
                  transition={percent === 62 ? springDB(0.5, 0) : anim.easeOut(0.6)}
                  style={{ position: "absolute", left: 0, top: 0, height: BAR_H, borderRadius: 10, overflow: "hidden" }}
                >
                  <motion.div animate={flash} style={{ position: "absolute", left: 0, top: 0, width: BAR_W, height: BAR_H }}>
                    <motion.div
                      initial={false}
                      animate={{ opacity: paused ? 0.45 : 1 }}
                      transition={smooth}
                      style={{ position: "absolute", inset: 0 }}
                    >
                      <div style={{ position: "absolute", inset: 0, background: Signature.accentGradient }} />
                      <motion.div initial={false} animate={{ opacity: charged ? 1 : 0 }} transition={smooth} style={{ position: "absolute", inset: 0, background: Signature.lime }} />
                      {ctx.b("chevrons") && <Chevrons speed={ctx.n("flow")} running={!paused && !charged} preview={ctx.isPreview} />}
                    </motion.div>
                  </motion.div>
                </motion.div>
                <div style={{ position: "absolute", inset: 0, borderRadius: 10, boxShadow: `inset 0 0 0 1px ${Signature.hairline}`, pointerEvents: "none" }} />
              </div>
              <span style={{ width: 4, height: 12, borderRadius: 2, background: white(0.25) }} />
            </div>
            <SignatureRim />
          </div>
        </SportPress>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap the card to pause or resume" zh="点击卡片暂停或继续" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

/** A row of chevrons scrolling right forever; frozen (and resumed in place) when paused. */
function Chevrons({ speed, running, preview }: { speed: number; running: boolean; preview: boolean }) {
  const t = useClock(running, preview ? 30 : undefined);
  const spacing = 22;
  const shift = (t * speed) % spacing;
  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden", pointerEvents: "none" }}>
      <div style={{ position: "absolute", left: 0, top: 0, height: BAR_H, display: "flex", alignItems: "center", transform: `translateX(${shift - spacing}px)` }}>
        {Array.from({ length: 14 }, (_, i) => (
          <span key={i} style={{ width: spacing, display: "grid", placeItems: "center", color: white(0.35) }}>
            <ChevronRight size={14} strokeWidth={4} />
          </span>
        ))}
      </div>
    </div>
  );
}
