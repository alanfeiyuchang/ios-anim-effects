/** showcase.date-range · 日期区间 (TravelDateRange.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, anim, delayed, fonts, hex, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";

/** July 6, 2026 is a Monday. */
const FIRST_DAY = 6;
const CELL = 38;
const ROW_GAP = 6;
const PRESETS: [number, number][] = [
  [1, 4],
  [3, 9],
  [8, 12],
  [0, 2],
  [2, 5],
];

const cellPos = (index: number) => ({ x: (index % 7) * CELL, y: Math.floor(index / 7) * (CELL + ROW_GAP) });

export default function DateRange({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  const [start, setStart] = useState(2);
  const [end, setEnd] = useState(5);
  const [pickingEnd, setPickingEnd] = useState(false);
  const demoStep = useRef(0);
  const sp = spring(ctx.n("response"), ctx.n("damping"));
  const bandT = delayed(sp, ctx.n("lag"));
  const nights = Math.max(end - start, 0);
  const rate = zh ? 1280 : 186;
  const total = nights * rate;

  useAutoplay(
    ctx.isPreview,
    () => {
      const [s, e] = PRESETS[demoStep.current % PRESETS.length];
      demoStep.current += 1;
      setStart(s);
      setEnd(e);
    },
    { every: 1.6 },
  );

  const tap = (index: number) => {
    haptics.selection();
    if (pickingEnd && index > start) {
      setEnd(index);
      setPickingEnd(false);
    } else {
      setStart(index);
      setEnd(index);
      setPickingEnd(true);
    }
  };

  const role = (index: number) => (index === start ? "start" : index === end ? "end" : index > start && index < end ? "inside" : "idle");
  const names = zh ? ["一", "二", "三", "四", "五", "六", "日"] : ["M", "T", "W", "T", "F", "S", "S"];
  const s = cellPos(start);
  const e = cellPos(end);

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(26), width: 7 * CELL + 32, padding: 16, display: "flex", flexDirection: "column", gap: 12, flexShrink: 0 }}>
          {/* header */}
          <div style={{ display: "flex", alignItems: "center" }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={signatureEyebrow()}>{zh ? "2026 年 7 月" : "July 2026"}</span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 15, fontWeight: 700, color: "#fff", lineHeight: "19px" }}>{zh ? "蔚蓝海岸 · 海景房" : "Azure Coast · Sea view"}</span>
            </div>
            <div style={{ flex: 1 }} />
            <span style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 600, color: Signature.accent, padding: "4px 8px", borderRadius: 99, background: hex(Signature.accent, 0.14), lineHeight: "12px" }}>
              {pickingEnd ? (zh ? "选择退房" : "Pick check-out") : zh ? "选择入住" : "Pick check-in"}
            </span>
          </div>
          {/* weekdays */}
          <div style={{ display: "flex" }}>
            {names.map((n, i) => (
              <span key={i} style={{ width: CELL, textAlign: "center", fontFamily: fonts.rounded, fontSize: 10, fontWeight: 700, color: Signature.textSecondary, lineHeight: "12px" }}>
                {n}
              </span>
            ))}
          </div>
          {/* grid */}
          <div style={{ position: "relative", width: 7 * CELL, height: CELL * 2 + ROW_GAP }}>
            {[0, 1].map((week) => (
              <Band key={week} week={week} start={start} end={end} transition={bandT} />
            ))}
            {/* endpoints (matchedGeometryEffect "start" / "end") */}
            <motion.div initial={false} animate={{ x: s.x, y: s.y }} transition={sp} style={endpointStyle} />
            <AnimatePresence initial={false}>
              {end !== start && (
                <motion.div
                  key="end"
                  initial={{ opacity: 0, x: e.x, y: e.y }}
                  animate={{ opacity: 1, x: e.x, y: e.y }}
                  exit={{ opacity: 0 }}
                  transition={sp}
                  style={endpointStyle}
                />
              )}
            </AnimatePresence>
            {Array.from({ length: 14 }, (_, index) => {
              const r = role(index);
              const p = cellPos(index);
              return (
                <div
                  key={index}
                  onClick={() => tap(index)}
                  style={{
                    position: "absolute",
                    left: p.x,
                    top: p.y,
                    width: CELL,
                    height: CELL,
                    display: "grid",
                    placeItems: "center",
                    cursor: "pointer",
                    fontFamily: fonts.rounded,
                    fontSize: 14,
                    fontWeight: r === "idle" ? 500 : 700,
                    fontVariantNumeric: "tabular-nums",
                    color: r === "start" || r === "end" ? "#000" : r === "inside" ? "#fff" : white(0.62),
                    transition: "color 0.3s",
                  }}
                >
                  {FIRST_DAY + index}
                </div>
              );
            })}
          </div>
          {/* footer */}
          <div style={{ display: "flex", alignItems: "center" }}>
            <div style={{ display: "flex", flexDirection: "column" }}>
              <span style={{ display: "flex", fontFamily: fonts.rounded, fontSize: 11, fontWeight: 500, color: Signature.textSecondary, lineHeight: "14px" }}>
                <NumericText value={nights} />
                <span style={{ whiteSpace: "pre" }}>{zh ? ` 晚 · ¥${rate.toLocaleString("en-US")}/晚` : ` nights · $${rate}/night`}</span>
              </span>
              <span style={{ display: "flex", alignItems: "baseline", gap: 2, color: "#fff" }}>
                <span style={signatureNumber(15)}>{zh ? "¥" : "$"}</span>
                <span style={signatureNumber(28)}>
                  <NumericText value={total} text={total.toLocaleString("en-US")} />
                </span>
              </span>
            </div>
            <div style={{ flex: 1 }} />
            <span
              style={{
                height: 38,
                padding: "0 18px",
                borderRadius: 19,
                display: "grid",
                placeItems: "center",
                fontFamily: fonts.rounded,
                fontSize: 14,
                fontWeight: 700,
                color: nights > 0 ? "#000" : Signature.textSecondary,
                background: nights > 0 ? Signature.accentGradient : white(0.08),
                transition: "color 0.25s ease-in-out, background 0.25s ease-in-out",
              }}
            >
              {zh ? "预订" : "Reserve"}
            </span>
          </div>
          <SignatureRim radius={26} />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap a check-in day, then a check-out day" zh="先点入住日，再点退房日" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

const endpointStyle: React.CSSProperties = {
  position: "absolute",
  left: 2,
  top: 2,
  width: CELL - 4,
  height: CELL - 4,
  borderRadius: "50%",
  background: Signature.accentGradient,
  boxShadow: `0 0 12px rgb(255 138 31 / 0.5)`,
  pointerEvents: "none",
};

/** One week's band; ends that continue into the other week are squared off. */
function Band({ week, start, end, transition }: { week: number; start: number; end: number; transition: ReturnType<typeof spring> }) {
  const lo = Math.max(start, week * 7);
  const hi = Math.min(end, week * 7 + 6);
  const full = (CELL - 4) / 2;
  const continuesIn = start < week * 7;
  const continuesOut = end > week * 7 + 6;
  const top = week * (CELL + ROW_GAP) + 2;
  return (
    <AnimatePresence initial={false}>
      {lo <= hi && (
        <motion.div
          key="band"
          initial={{ opacity: 0 }}
          animate={{
            opacity: 1,
            x: (lo - week * 7) * CELL,
            width: (hi - lo + 1) * CELL,
            borderTopLeftRadius: continuesIn ? 3 : full,
            borderBottomLeftRadius: continuesIn ? 3 : full,
            borderTopRightRadius: continuesOut ? 3 : full,
            borderBottomRightRadius: continuesOut ? 3 : full,
          }}
          exit={{ opacity: 0 }}
          transition={{ ...transition, opacity: anim.easeInOut(0.25) }}
          style={{ position: "absolute", left: 0, top, height: CELL - 4, background: hex(Signature.accent, 0.2), x: (lo - week * 7) * CELL, width: (hi - lo + 1) * CELL }}
        />
      )}
    </AnimatePresence>
  );
}
