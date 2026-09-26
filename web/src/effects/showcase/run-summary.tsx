/** showcase.run-summary · 今日滑雪总结 (Sport+RunSummary.swift) */
import { motion, type Transition } from "motion/react";
import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { DemoHint, NumericText, anim, delayed, fonts, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";
import { SportPress } from "./_a-sport";

type Motion = { assembled: boolean; stagger: number; response: number; damping: number };
const animationFor = (m: Motion, index: number): Transition =>
  m.assembled ? delayed(spring(m.response, m.damping), index * m.stagger) : anim.easeIn(0.2);
/** When a tile's spring has mostly settled, so its number starts counting as it lands. */
const landingDelay = (m: Motion, index: number) => index * m.stagger + m.response * 0.35;

const BARS = [0.35, 0.6, 0.45, 0.8, 0.55, 1.0, 0.7, 0.5, 0.85, 0.65];

export default function RunSummary({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [assembled, setAssembled] = useState(false);
  const [runID, setRunID] = useState(0);
  const assembledRef = useRef(false);

  useEffect(() => {
    const silent = runID === 0;
    let wait = 150;
    if (assembledRef.current) {
      assembledRef.current = false;
      setAssembled(false);
      wait = 320;
    }
    const id = window.setTimeout(() => {
      assembledRef.current = true;
      setAssembled(true);
      if (!silent) haptics.tap("soft");
    }, wait);
    return () => clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [runID]);

  useAutoplay(ctx.isPreview, () => setRunID((r) => r + 1), { every: 3.8, delay: 3.8, intro: false });

  const m: Motion = { assembled, stagger: ctx.n("stagger"), response: ctx.n("response"), damping: ctx.n("damping") };
  const on = assembled;

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <SportPress scale={0.98} dim={0.04} radius={20} onClick={() => setRunID((r) => r + 1)}>
          <div style={{ width: 298, display: "flex", flexDirection: "column", gap: 8, color: "#fff" }}>
            <Entrance index={0} m={m} style={{ display: "flex", alignItems: "center" }}>
              <span style={signatureEyebrow()}>{ctx.t("Today · Nordkette", "今日 · Nordkette")}</span>
              <span style={{ flex: 1 }} />
              <span style={{ fontFamily: fonts.rounded, fontSize: 9, fontWeight: 800, color: "#000", padding: "2px 6px", borderRadius: 999, background: Signature.lime, lineHeight: "11px" }}>PR</span>
            </Entrance>
            <div style={{ display: "flex", gap: 8 }}>
              <Entrance index={1} m={m} style={{ width: 196, flexShrink: 0 }}>
                <Tile style={{ display: "flex", alignItems: "flex-end", gap: 10 }}>
                  <div style={{ display: "flex", flexDirection: "column", height: "100%", justifyContent: "space-between" }}>
                    <span style={signatureEyebrow()}>{ctx.t("Distance", "距离")}</span>
                    <div style={{ display: "flex", alignItems: "baseline", gap: 3 }}>
                      <span style={{ ...signatureNumber(30), color: "#fff", lineHeight: "36px" }}>
                        <CountUp target={on ? 24.6 : 0} decimals={1} delay={landingDelay(m, 1)} />
                      </span>
                      <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 600, color: Signature.textSecondary }}>km</span>
                    </div>
                  </div>
                  <span style={{ flex: 1 }} />
                  <div style={{ height: 44, display: "flex", alignItems: "flex-end", gap: 2 }}>
                    {BARS.map((b, i) => (
                      <motion.div
                        key={i}
                        initial={false}
                        animate={{ height: on ? 44 * b : 3 }}
                        transition={delayed(spring(0.45, 0.6), on ? m.stagger + 0.15 + i * 0.025 : 0)}
                        style={{ width: 4, borderRadius: 2, background: i === 5 ? Signature.accentGradient : white(0.2) }}
                      />
                    ))}
                  </div>
                </Tile>
              </Entrance>
              <Stat title={ctx.t("Runs", "趟数")} value={on ? 14 : 0} unit="" accent={false} m={m} index={2} />
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <Stat title={ctx.t("Vertical", "落差")} value={on ? 3120 : 0} unit="m" accent={false} m={m} index={3} />
              <Stat title={ctx.t("Top", "最高速")} value={on ? 50 : 0} unit="km/h" accent m={m} index={4} />
              <Stat title={ctx.t("Minutes", "分钟")} value={on ? 222 : 0} unit="" accent={false} m={m} index={5} />
            </div>
          </div>
        </SportPress>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap to rebuild" zh="点击重新组装" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Entrance({ index, m, style, children }: { index: number; m: Motion; style?: CSSProperties; children: ReactNode }) {
  const on = m.assembled;
  return (
    <motion.div
      initial={false}
      animate={{ opacity: on ? 1 : 0, scale: on ? 1 : 0.82, y: on ? 0 : 26, filter: `blur(${on ? 0 : 8}px)` }}
      transition={animationFor(m, index)}
      style={style}
    >
      {children}
    </motion.div>
  );
}

function Tile({ children, style }: { children: ReactNode; style?: CSSProperties }) {
  return (
    <div style={{ ...signatureCard(20), padding: 12, height: 86, ...style }}>
      {children}
      <SignatureRim radius={20} />
    </div>
  );
}

function Stat({ title, value, unit, accent, m, index }: { title: string; value: number; unit: string; accent: boolean; m: Motion; index: number }) {
  return (
    <Entrance index={index} m={m} style={{ flex: 1, minWidth: 0 }}>
      <Tile style={{ display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
        <span style={{ ...signatureEyebrow(), whiteSpace: "nowrap", overflow: "hidden" }}>{title}</span>
        <div style={{ display: "flex", alignItems: "baseline", gap: 2 }}>
          <span style={{ ...signatureNumber(22), color: accent ? Signature.accent : "#fff", lineHeight: "26px" }}>
            <CountUp target={value} decimals={0} delay={landingDelay(m, index)} />
          </span>
          {unit && <span style={{ fontFamily: fonts.rounded, fontSize: 9, fontWeight: 600, color: Signature.textSecondary }}>{unit}</span>}
        </div>
      </Tile>
    </Entrance>
  );
}

/** A numeral that really counts: after `delay` it steps from 0 to `target` in 12 eased increments. */
function CountUp({ target, decimals, delay }: { target: number; decimals: number; delay: number }) {
  const [shown, setShown] = useState(0);
  const delayRef = useRef(delay);
  delayRef.current = delay;
  useEffect(() => {
    if (target <= 0) {
      setShown(0);
      return;
    }
    const timers: number[] = [];
    for (let step = 1; step <= 12; step++) {
      const t = step / 12;
      const eased = 1 - Math.pow(1 - t, 3);
      timers.push(window.setTimeout(() => setShown(target * eased), (delayRef.current + (step - 1) * 0.04) * 1000));
    }
    return () => timers.forEach(clearTimeout);
  }, [target]);
  const text = decimals === 0 ? String(Math.round(shown)) : shown.toFixed(decimals);
  return <NumericText value={shown} text={text} />;
}
