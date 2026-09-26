/** showcase.fresh-snow · 新雪柱状 (Sport+FreshSnow.swift) */
import { motion } from "motion/react";
import { RotateCw, Snowflake } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, anim, delayed, fonts, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { CanvasLayer, SportEyebrowRow, SportPress, sportHash } from "./_a-sport";

const PRESET = [0.32, 0.55, 0.22, 0.7, 0.48, 0.82, 1.0];
const STUBS = Array(7).fill(0.05) as number[];

export default function FreshSnow({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [bars, setBars] = useState<number[]>(STUBS);
  const [rising, setRising] = useState(false);
  const [total, setTotal] = useState(0);
  const [spin, setSpin] = useState(0);
  const [runID, setRunID] = useState(0);
  const totalRef = useRef(0);
  totalRef.current = total;

  useEffect(() => {
    let cancelled = false;
    const timers: number[] = [];
    const isFirst = runID === 0;
    const next = isFirst ? PRESET : PRESET.map(() => 0.18 + Math.random() * 0.82);
    const target = isFirst ? 46 : Math.round(next.reduce((a, b) => a + b, 0) * 10.5);
    const from = totalRef.current;
    timers.push(window.setTimeout(() => !cancelled && setSpin((s) => s + 360), 0));
    setRising(false);
    setBars(STUBS);
    timers.push(
      window.setTimeout(() => {
        if (cancelled) return;
        setRising(true);
        setBars(next);
        // Only user refreshes buzz; the arrival run and preview loops stay silent.
        if (!isFirst) haptics.tap("soft");
        for (let step = 1; step <= 10; step++) {
          timers.push(
            window.setTimeout(() => {
              if (!cancelled) setTotal(from + Math.trunc(((target - from) * step) / 10));
            }, (step - 1) * 45),
          );
        }
      }, 200),
    );
    return () => {
      cancelled = true;
      timers.forEach(clearTimeout);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [runID]);

  useAutoplay(ctx.isPreview, () => setRunID((r) => r + 1), { every: 3.4, delay: 3.4, intro: false });

  const zh = ctx.lang === "zh";
  const labels = zh ? ["一", "二", "三", "四", "五", "六", "日"] : ["M", "T", "W", "T", "F", "S", "S"];
  const count = ctx.i("snow");
  const stagger = ctx.n("stagger");
  const damping = ctx.n("damping");

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <SportPress scale={0.98} dim={0.04} radius={26} onClick={() => setRunID((r) => r + 1)}>
          <div style={{ ...signatureCard(), padding: 20, width: 292, display: "flex", flexDirection: "column", gap: 12, color: "#fff" }}>
            <div style={{ position: "absolute", inset: 0, borderRadius: 26, overflow: "hidden" }}>
              <CanvasLayer
                fps={ctx.isPreview ? 30 : undefined}
                draw={(g, t, w, h) => {
                  if (count <= 0) return;
                  for (let i = 0; i < count; i++) {
                    const seed = i * 3.17;
                    const speed = 8 + sportHash(seed + 1) * 16;
                    const r = 0.6 + sportHash(seed + 2) * 1.0;
                    const baseX = sportHash(seed + 3) * w;
                    const y = ((t * speed + sportHash(seed + 4) * h) % (h + 10)) - 5;
                    const x = baseX + Math.sin(t * 0.8 + seed) * 8;
                    g.fillStyle = white(0.25 + sportHash(seed + 5) * 0.45);
                    g.beginPath();
                    g.arc(x, y, r, 0, Math.PI * 2);
                    g.fill();
                  }
                }}
              />
            </div>
            <div style={{ position: "relative", display: "flex", alignItems: "center", gap: 8 }}>
              <SportEyebrowRow title={ctx.t("Fresh snow", "新雪")} icon={<Snowflake size={11} strokeWidth={2.6} />} />
              <div style={{ width: 28, height: 28, borderRadius: "50%", background: white(0.07), display: "grid", placeItems: "center", color: Signature.textSecondary }}>
                <motion.span animate={{ rotate: spin }} transition={anim.easeInOut(0.6)} style={{ display: "grid" }}>
                  <RotateCw size={12} strokeWidth={3} />
                </motion.span>
              </div>
            </div>
            <div style={{ position: "relative", display: "flex", flexDirection: "column", gap: 2 }}>
              <div style={{ display: "flex", alignItems: "baseline", gap: 4 }}>
                <span style={{ ...signatureNumber(50), color: "#fff", lineHeight: "60px" }}>
                  <NumericText value={total} />
                </span>
                <span style={{ fontFamily: fonts.rounded, fontSize: 13, fontWeight: 600, color: Signature.textSecondary }}>{ctx.t("cm fresh", "厘米新雪")}</span>
              </div>
              <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 500, color: Signature.textSecondary, lineHeight: "13px" }}>
                {ctx.t("Nordkette · last 7 days", "Nordkette · 近 7 天")}
              </span>
            </div>
            <div style={{ position: "relative", display: "flex", alignItems: "flex-end" }}>
              {bars.map((h, index) => {
                const today = index === 6;
                return (
                  <div key={index} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
                    <div style={{ height: 84, display: "flex", alignItems: "flex-end" }}>
                      <motion.div
                        initial={false}
                        animate={{ height: Math.max(8, 84 * h) }}
                        transition={rising ? delayed(spring(0.55, damping), index * stagger) : anim.easeIn(0.18)}
                        style={{
                          width: 24,
                          borderRadius: 8,
                          background: today ? Signature.accentGradient : white(0.16),
                          boxShadow: today ? `0 2px 8px rgb(255 138 31 / 0.5)` : undefined,
                        }}
                      />
                    </div>
                    <span style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 600, lineHeight: "12px", color: today ? Signature.accent : Signature.textSecondary }}>
                      {labels[index]}
                    </span>
                  </div>
                );
              })}
            </div>
            <SignatureRim />
          </div>
        </SportPress>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap the card to refresh" zh="点击卡片刷新" style={{ paddingBottom: 16 }} />
      </div>
    </SignatureStage>
  );
}
