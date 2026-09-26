/** showcase.altitude-ruler · 海拔刻度尺 (Sport+AltitudeRuler.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, clamp, fonts, rubberBand, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { MountainGlyph, SportEyebrowRow } from "./_a-sport";

const BASE = 800;
const STEP = 10;
const TICKS = 221; // 800 … 3,000 m
const MAX_INDEX = TICKS - 1;
const RW = 260;
const RH = 76;

const valueAt = (p: number) => BASE + clamp(Math.round(p), 0, TICKS - 1) * STEP;

export default function AltitudeRuler({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const pos = useMotionValue(145);
  const [position, setPosition] = useState(145);
  useMotionValueEvent(pos, "change", setPosition);
  const dragStart = useRef<number | null>(null);
  const lastIndex = useRef(145);
  const spacing = Math.max(ctx.n("spacing"), 4);

  const settle = (target: number) => {
    animate(pos, target, spring(0.55, ctx.n("damping")));
    lastIndex.current = Math.trunc(target);
  };

  const pan = usePan({
    onStart: () => {
      pos.stop();
      dragStart.current = pos.get();
    },
    onChange: ({ translation }) => {
      const start = dragStart.current ?? pos.get();
      let p = start - translation.x / spacing;
      if (p < 0) p = rubberBand(p * spacing, 40) / spacing;
      else if (p > MAX_INDEX) p = MAX_INDEX + rubberBand((p - MAX_INDEX) * spacing, 40) / spacing;
      pos.set(p);
      const index = clamp(Math.round(p), 0, TICKS - 1);
      if (index !== lastIndex.current) {
        lastIndex.current = index;
        haptics.selection();
      }
    },
    onEnd: ({ translation, velocity }) => {
      const start = dragStart.current ?? pos.get();
      dragStart.current = null;
      const current = pos.get();
      const predicted = start - (translation.x + velocity.x * 0.25) / spacing;
      const target = clamp(Math.round(current + (predicted - current) * ctx.n("momentum")), 0, MAX_INDEX);
      settle(target);
      haptics.tap("soft");
    },
  });

  useAutoplay(ctx.isPreview, () => settle(30 + Math.floor(Math.random() * 171)), { every: 2.0, delay: 0.6 });

  const value = valueAt(position);
  const mid = RW / 2;
  const offset = -position * spacing;
  const first = Math.max(0, Math.floor((-offset - mid) / spacing));
  const last = Math.min(TICKS - 1, Math.ceil((-offset + mid) / spacing));
  const ticks = [];
  for (let i = first; i <= last; i++) {
    const x = mid + i * spacing + offset;
    const major = i % 10 === 0;
    const medium = i % 5 === 0;
    const h = major ? 34 : medium ? 22 : 13;
    const fade = Math.max(0.08, 1 - (Math.abs(x - mid) / mid) * 0.95);
    ticks.push(
      <g key={i}>
        <rect x={x - 1} y={12} width={2} height={h} rx={1} fill="#fff" fillOpacity={fade * (major ? 0.95 : 0.45)} />
        {major && (
          <text
            x={x}
            y={RH - 10}
            textAnchor="middle"
            dominantBaseline="central"
            fill="#fff"
            fillOpacity={fade * 0.7}
            style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 600 }}
          >
            {BASE + i * STEP}
          </text>
        )}
      </g>,
    );
  }

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(), padding: 20, width: 300, display: "flex", flexDirection: "column", gap: 14 }}>
          <SportEyebrowRow title={ctx.t("Drop-in altitude", "起滑海拔")} icon={<MountainGlyph />} trailing="Nordkette" />
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <div style={{ display: "flex", alignItems: "baseline", gap: 4 }}>
              <span style={{ ...signatureNumber(46), color: "#fff", lineHeight: "55px" }}>
                <NumericText value={value} text={value.toLocaleString("en-US")} />
              </span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 15, fontWeight: 600, color: Signature.textSecondary }}>m</span>
            </div>
            <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 500, fontVariantNumeric: "tabular-nums", color: Signature.textSecondary, lineHeight: "13px" }}>
              +{(value - 860).toLocaleString("en-US")} m {ctx.t("above base", "高于山脚")}
            </span>
          </div>
          <div {...pan} style={{ position: "relative", width: RW, height: RH, touchAction: "none", cursor: "grab" }}>
            <svg width={RW} height={RH} style={{ position: "absolute", inset: 0 }}>
              {ticks}
            </svg>
            <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", pointerEvents: "none" }}>
              <svg width={9} height={8} viewBox="0 0 9 8">
                <path d="M1.2 0.5 H7.8 Q9 0.5 8.3 1.6 L5.2 7 Q4.5 8 3.8 7 L0.7 1.6 Q0 0.5 1.2 0.5 Z" fill={Signature.accent} />
              </svg>
              <div style={{ width: 3, height: 48, borderRadius: 1.5, background: Signature.accentGradient, boxShadow: `0 0 6px rgb(255 138 31 / 0.9)` }} />
            </div>
          </div>
          <SignatureRim />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Drag or flick the ruler" zh="拖动或快速拨动刻度尺" style={{ paddingBottom: 16 }} />
      </div>
    </SignatureStage>
  );
}
