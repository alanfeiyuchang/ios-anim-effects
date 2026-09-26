/** showcase.lift-status · 缆车实时状态 (Sport+LiftStatus.swift) */
import { motion } from "motion/react";
import { TramFront } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, anim, fonts, useAutoplay, useHaptics, useLatest, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { SportLiveDot } from "./_a-sport";

type Lift = { id: number; name: string; status: number; wait: number };
const INITIAL: Lift[] = [
  { id: 0, name: "Hungerburg", status: 0, wait: 4 },
  { id: 1, name: "Seegrube", status: 0, wait: 9 },
  { id: 2, name: "Hafelekar", status: 1, wait: 15 },
  { id: 3, name: "Frau Hitt", status: 2, wait: 0 },
];
const randInt = (lo: number, hi: number) => lo + Math.floor(Math.random() * (hi - lo + 1));

export default function LiftStatus({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [lifts, setLifts] = useState(INITIAL);
  const [flash, setFlash] = useState<number | null>(null);
  const flashTimer = useRef(0);
  const demoStep = useRef(0);
  const flashOn = ctx.b("flash");
  const flashOnRef = useLatest(flashOn);

  const pulseRow = (id: number) => {
    if (!flashOnRef.current) return;
    setFlash(id);
    window.clearTimeout(flashTimer.current);
    flashTimer.current = window.setTimeout(() => setFlash((f) => (f === id ? null : f)), 220);
  };
  useEffect(() => () => window.clearTimeout(flashTimer.current), []);

  const cycle = (id: number) => {
    setLifts((ls) =>
      ls.map((l) => {
        if (l.id !== id) return l;
        const status = (l.status + 1) % 3;
        return { ...l, status, wait: status === 2 ? 0 : randInt(2, 18) };
      }),
    );
    pulseRow(id);
    haptics.tap("light");
  };

  const interval = Math.max(ctx.n("interval"), 0.5);
  useEffect(() => {
    const timer = window.setInterval(() => {
      const index = randInt(0, INITIAL.length - 1);
      setLifts((ls) =>
        ls.map((l, k) => {
          if (k !== index) return l;
          const status = Math.random() < 0.2 ? (l.status + 1) % 3 : l.status;
          return { ...l, status, wait: status === 2 ? 0 : Math.max(1, l.wait + randInt(-4, 5)) };
        }),
      );
      pulseRow(index);
    }, interval * 1000);
    return () => window.clearInterval(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [interval, flashOn]);

  useAutoplay(
    ctx.isPreview,
    () => {
      cycle(demoStep.current % INITIAL.length);
      demoStep.current += 1;
    },
    { every: 2.6, delay: 1.2 },
  );

  const open = 10 + lifts.filter((l) => l.status === 0).length;
  const zh = ctx.lang === "zh";

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(), padding: 18, width: 300, display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ display: "flex", alignItems: "center" }}>
            <span style={{ fontFamily: fonts.rounded, fontSize: 20, fontWeight: 600, color: "#fff", lineHeight: "24px" }}>{ctx.t("Lifts", "缆车")}</span>
            <span style={{ flex: 1 }} />
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 6,
                padding: "5px 10px 5px 6px",
                borderRadius: 999,
                background: white(0.07),
                boxShadow: `inset 0 0 0 1px ${Signature.hairline}`,
              }}
            >
              <span style={{ position: "relative", width: 12, height: 12, flexShrink: 0 }}>
                <span style={{ position: "absolute", left: -3, top: -3 }}>
                  <SportLiveDot color={Signature.accentHot} size={6} period={Math.max(ctx.n("pulse"), 0.3)} preview={ctx.isPreview} />
                </span>
              </span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 800, letterSpacing: 1, color: Signature.accentHot, lineHeight: "12px" }}>LIVE</span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 700, fontVariantNumeric: "tabular-nums", color: "#fff", lineHeight: "13px", display: "inline-flex" }}>
                <NumericText value={open} />
                /14
              </span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 500, color: Signature.textSecondary, lineHeight: "12px" }}>{zh ? "开放" : "open"}</span>
            </div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            {lifts.map((lift) => (
              <Row key={lift.id} lift={lift} highlighted={flash === lift.id} zh={zh} onTap={() => cycle(lift.id)} />
            ))}
          </div>
          <SignatureRim />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap a lift to change its status" zh="点击缆车切换状态" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Row({ lift, highlighted, zh, onTap }: { lift: Lift; highlighted: boolean; zh: boolean; onTap: () => void }) {
  const color = lift.status === 0 ? Signature.lime : lift.status === 1 ? Signature.accent : "#FFFFFF";
  const colorAlpha = lift.status === 2 ? 0.4 : 1;
  const text = lift.status === 0 ? (zh ? "开放" : "Open") : lift.status === 1 ? (zh ? "暂停" : "Hold") : zh ? "关闭" : "Closed";
  const chipT = anim.snappyD(0.35);
  const rgb = (a: number) => {
    const n = parseInt(color.slice(1), 16);
    return `rgb(${(n >> 16) & 255} ${(n >> 8) & 255} ${n & 255} / ${a})`;
  };
  return (
    <motion.div
      onClick={onTap}
      initial={false}
      animate={{ backgroundColor: highlighted ? "rgb(255 138 31 / 0.14)" : "rgb(255 138 31 / 0)" }}
      transition={highlighted ? anim.easeOut(0.12) : anim.easeOut(0.6)}
      style={{ display: "flex", alignItems: "center", gap: 8, padding: "6px 8px", borderRadius: 12, cursor: "pointer" }}
    >
      <span style={{ width: 30, height: 30, borderRadius: 9, background: white(0.06), display: "grid", placeItems: "center", color: white(0.8), flexShrink: 0 }}>
        <TramFront size={14} strokeWidth={2.4} />
      </span>
      <span style={{ fontFamily: fonts.rounded, fontSize: 13, fontWeight: 600, color: "#fff", whiteSpace: "nowrap", lineHeight: "16px" }}>{lift.name}</span>
      <span style={{ flex: 1, minWidth: 4 }} />
      <motion.span
        initial={false}
        animate={{ color: rgb(colorAlpha), backgroundColor: rgb(0.16 * colorAlpha) }}
        transition={chipT}
        style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 700, padding: "4px 8px", borderRadius: 999, lineHeight: "12px" }}
      >
        {text}
      </motion.span>
      <span style={{ width: 46, display: "flex", justifyContent: "flex-end", alignItems: "baseline", gap: 2, flexShrink: 0 }}>
        <span style={{ ...signatureNumber(15), color: "#fff" }}>{lift.status === 2 ? "—" : <NumericText value={lift.wait} />}</span>
        <span style={{ fontFamily: fonts.rounded, fontSize: 9, fontWeight: 500, color: Signature.textSecondary }}>{zh ? "分" : "min"}</span>
      </span>
    </motion.div>
  );
}
