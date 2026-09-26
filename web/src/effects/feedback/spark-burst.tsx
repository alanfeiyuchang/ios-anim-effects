/** feedback.spark-burst · 火花迸发对勾 (Feedback+SuccessVariations.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, delayed, demoCard, fonts, spring, useAutoplay, useClock, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";

type Phase = "idle" | "paying" | "paid";
const SIZES: Record<Phase, [number, number]> = { idle: [200, 50], paying: [50, 50], paid: [88, 88] };
const SPARK_COLORS = [Palette.green, Palette.mint, Palette.amber];

export default function SparkBurst({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [phase, setPhaseState] = useState<Phase>("idle");
  const [t, setT] = useState<Transition>(anim.smoothD(0.35));
  const [bursts, setBursts] = useState(0);
  const phaseRef = useRef<Phase>("idle");
  const zh = ctx.lang === "zh";
  const paid = phase === "paid";
  const setPhase = (p: Phase, tr: Transition) => {
    phaseRef.current = p;
    setT(tr);
    setPhaseState(p);
  };

  const pay = (buzz = true) => {
    const p = phaseRef.current;
    if (p === "paying") return;
    if (p === "paid") {
      clearAll();
      setPhase("idle", anim.smoothD(0.35));
      return;
    }
    clearAll();
    if (buzz) haptics.tap("medium");
    setPhase("paying", spring(0.4, 0.85));
    after(0.7, () => {
      setPhase("paid", spring(0.45, ctx.n("damping")));
      setBursts((b) => b + 1);
      after(0.2, () => {
        if (buzz) haptics.success();
        if (!ctx.isPreview) return;
        after(2.4, () => setPhase("idle", anim.smoothD(0.35)));
      });
    });
  };

  useAutoplay(ctx.isPreview, () => pay(false), { every: 4.2, delay: 0.5 });

  const [w, h] = SIZES[phase];
  const count = Math.max(ctx.i("count"), 6);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ position: "relative", width: 260, height: 260, flexShrink: 0 }}>
        <motion.div
          initial={false}
          animate={{ scale: paid ? 0.6 : 1, opacity: paid ? 0 : 1 }}
          transition={anim.smoothD(0.35)}
          style={{ position: "absolute", left: 20, top: 70 - 56, width: 220, height: 120 }}
        >
          <div style={{ ...demoCard(22), width: 220, height: 120, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 6 }}>
            <span style={{ fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel }}>{zh ? "向 Mia 支付" : "Pay Mia"}</span>
            <span style={{ fontFamily: fonts.rounded, fontSize: 40, lineHeight: "48px", fontWeight: 700, fontVariantNumeric: "tabular-nums" }}>{zh ? "¥168.00" : "$24.00"}</span>
          </div>
        </motion.div>
        <motion.button
          type="button"
          onClick={() => pay()}
          initial={false}
          animate={{ y: paid ? -40 : 88 }}
          transition={spring(0.45, 0.78)}
          style={{ position: "absolute", left: 30, top: 86, width: 200, height: 88, display: "grid", placeItems: "center" }}
        >
          <Fountain trigger={bursts} count={count} power={ctx.n("reach")} />
          <motion.div
            initial={false}
            animate={{ width: w, height: h, boxShadow: `0 6px 14px ${alpha(paid ? Palette.green : Palette.indigo, 0.35)}` }}
            transition={t}
            style={{ gridArea: "1/1", position: "relative", borderRadius: 999, overflow: "hidden", background: Palette.primary }}
          >
            <motion.div initial={false} animate={{ opacity: paid ? 1 : 0 }} transition={t} style={{ position: "absolute", inset: 0, background: `linear-gradient(#4BE08F, ${Palette.green})` }} />
          </motion.div>
          <div style={{ gridArea: "1/1", position: "relative", display: "grid", placeItems: "center", color: "#fff" }}>
            <AnimatePresence initial={false}>
              {phase === "idle" && (
                <motion.span key="pay" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={t} style={{ gridArea: "1/1", fontSize: 17, fontWeight: 600 }}>
                  {zh ? "支付" : "Pay"}
                </motion.span>
              )}
              {phase === "paying" && (
                <motion.span key="spin" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={t} style={{ gridArea: "1/1", display: "grid" }}>
                  <ActivityIndicator />
                </motion.span>
              )}
            </AnimatePresence>
          </div>
          <svg width={36} height={28} viewBox="0 0 36 28" style={{ gridArea: "1/1", position: "relative", overflow: "visible" }}>
            <motion.path
              d={`M${36 * 0.04} ${28 * 0.55} L${36 * 0.37} ${28 - 28 * 0.04} L${36 - 36 * 0.03} ${28 * 0.06}`}
              fill="none"
              stroke="#fff"
              strokeWidth={6}
              strokeLinecap="round"
              strokeLinejoin="round"
              initial={false}
              animate={{ pathLength: paid ? 1 : 0, opacity: paid ? 1 : 0 }}
              transition={paid ? delayed(anim.easeOut(0.3), 0.2) : anim.easeIn(0.1)}
            />
          </svg>
        </motion.button>
      </div>
      <motion.div
        initial={false}
        animate={{ opacity: paid ? 1 : 0 }}
        transition={delayed(anim.easeOut(0.3), paid ? 0.3 : 0)}
        style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}
      >
        {zh ? "付款成功" : "Payment sent"}
      </motion.div>
      <DemoHint ctx={ctx} en="Tap Pay" zh="点击支付" />
    </div>
  );
}

function Fountain({ trigger, count, power }: { trigger: number; count: number; power: number }) {
  const e = useElapsed(trigger, 0.9, true);
  const s = e < 0 ? 0 : Math.min(e / 0.9, 1);
  const live = s > 0.001 && s < 0.999;
  return (
    <div style={{ gridArea: "1/1", position: "relative", width: 0, height: 0, opacity: live ? 1 : 0, pointerEvents: "none" }}>
      {Array.from({ length: count }, (_, i) => {
        const fan = count > 1 ? i / (count - 1) - 0.5 : 0;
        const angle = -Math.PI / 2 + fan * 2.3;
        const jitter = 0.72 + 0.28 * Math.abs(Math.sin(i * 12.9898));
        const speed = (150 + power * 2) * jitter;
        const x = Math.cos(angle) * (30 + speed * s);
        const y = Math.sin(angle) * (30 + speed * s) + 0.5 * 380 * s * s;
        const size = (i % 2 === 0 ? 7 : 5) * (1 - 0.6 * s);
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x - size / 2,
              top: y - size / 2,
              width: size,
              height: size,
              borderRadius: 1.5,
              background: SPARK_COLORS[i % 3],
              transform: `rotate(${s * 360 * (i % 2 === 0 ? 1 : -1)}deg)`,
              opacity: 1 - s * s,
            }}
          />
        );
      })}
    </div>
  );
}

/** UIActivityIndicatorView (`ProgressView()`): eight fading spokes stepping around. */
function ActivityIndicator() {
  const t = useClock(true);
  const head = Math.floor(t * 12) % 8;
  return (
    <svg width={20} height={20} viewBox="-10 -10 20 20">
      {Array.from({ length: 8 }, (_, i) => {
        const age = (head - i + 8) % 8;
        return <line key={i} x1={0} y1={-4.5} x2={0} y2={-8.5} stroke="#fff" strokeWidth={2.2} strokeLinecap="round" opacity={1 - age * 0.1} transform={`rotate(${i * 45})`} />;
      })}
    </svg>
  );
}
