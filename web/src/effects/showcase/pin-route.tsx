/** showcase.pin-route · 图钉路线 (TravelPinRoute.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useId, useRef, useState } from "react";
import { DemoHint, NumericText, anim, delayed, fonts, localPoint, spring, useAutoplay, useHaptics, white, type DemoProps, type Point } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";

const MAP_W = 276;
const MAP_H = 228;
type Pin = { id: number; point: Point };

const DEMO_POINTS: Point[] = [
  { x: 140, y: 92 },
  { x: 228, y: 160 },
  { x: 116, y: 196 },
  { x: 214, y: 70 },
  { x: 62, y: 104 },
];

export default function PinRoute({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  const [pins, setPins] = useState<Pin[]>([
    { id: 0, point: { x: 64, y: 176 } },
    { id: 1, point: { x: 140, y: 92 } },
    { id: 2, point: { x: 228, y: 160 } },
  ]);
  const nextID = useRef(3);
  const sp = spring(0.5, 1 - ctx.n("bounce"));

  const drop = (point: Point) => {
    haptics.tap("medium");
    const limit = Math.max(ctx.i("maxPins"), 2);
    const id = nextID.current++;
    setPins((list) => {
      const next = [...list, { id, point }];
      while (next.length > limit) next.shift();
      return next;
    });
  };

  useAutoplay(ctx.isPreview, () => drop(DEMO_POINTS[nextID.current % DEMO_POINTS.length]), { every: 1.4 });

  let sum = 0;
  for (let i = 1; i < pins.length; i++) sum += Math.hypot(pins[i].point.x - pins[i - 1].point.x, pins[i].point.y - pins[i - 1].point.y);
  const totalKm = pins.length > 1 ? Math.floor(sum * 3.2) : 0;
  const latest = pins[pins.length - 1]?.id;

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(26), width: MAP_W + 28, padding: 14, display: "flex", flexDirection: "column", gap: 12, flexShrink: 0 }}>
          <div style={{ display: "flex", alignItems: "flex-end", padding: "0 4px" }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={signatureEyebrow()}>{zh ? "我的路线" : "My route"}</span>
              <span style={{ display: "inline-flex", gap: 4, fontFamily: fonts.rounded, fontSize: 17, fontWeight: 700, color: "#fff", lineHeight: "22px" }}>
                <NumericText value={pins.length} />
                <span>{zh ? "个站点" : "stops"}</span>
              </span>
            </div>
            <span style={{ flex: 1 }} />
            <span style={{ display: "inline-flex", alignItems: "baseline", gap: 3, paddingBottom: 1 }}>
              <span style={{ ...signatureNumber(24), color: "#fff" }}>
                <NumericText value={totalKm} text={totalKm.toLocaleString("en-US")} />
              </span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, color: Signature.textSecondary }}>km</span>
            </span>
          </div>
          <div
            onClick={(e) => drop(localPoint(e, e.currentTarget))}
            style={{ position: "relative", width: MAP_W, height: MAP_H, borderRadius: 20, overflow: "hidden", cursor: "crosshair" }}
          >
            <MapBackdrop />
            <AnimatePresence>
              {pins.slice(1).map((pin, k) => (
                <motion.div
                  key={pin.id}
                  exit={{ scale: 0.2, opacity: 0 }}
                  transition={sp}
                  style={{ position: "absolute", inset: 0, pointerEvents: "none", transformOrigin: `${pin.point.x}px ${pin.point.y}px` }}
                >
                  <Leg from={pins[k].point} to={pin.point} duration={ctx.n("routeTime")} />
                </motion.div>
              ))}
            </AnimatePresence>
            <AnimatePresence initial={false}>
              {pins.map((pin) => (
                <motion.div
                  key={pin.id}
                  initial={{ y: -90, opacity: 0 }}
                  animate={{ y: 0, opacity: 1, scale: 1 }}
                  exit={{ scale: 0.3, opacity: 0 }}
                  transition={sp}
                  style={{ position: "absolute", inset: 0, pointerEvents: "none" }}
                >
                  <Marker at={pin.point} isLatest={pin.id === latest} />
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
          <SignatureRim radius={26} />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap the map to drop pins" zh="点击地图放置图钉" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Leg({ from, to, duration }: { from: Point; to: Point; duration: number }) {
  const distance = Math.hypot(to.x - from.x, to.y - from.y);
  const cx = (from.x + to.x) / 2;
  const cy = (from.y + to.y) / 2 - distance * 0.25;
  const d = `M${from.x} ${from.y} Q${cx} ${cy} ${to.x} ${to.y}`;
  const maskId = `pin-leg${useId().replace(/:/g, "")}`;
  return (
    <svg width={MAP_W} height={MAP_H} style={{ position: "absolute", inset: 0, overflow: "visible", filter: `drop-shadow(0 0 4px rgb(255 138 31 / 0.6))` }}>
      <mask id={maskId} maskUnits="userSpaceOnUse" x={-20} y={-40} width={MAP_W + 40} height={MAP_H + 80}>
        <motion.path
          d={d}
          fill="none"
          stroke="#fff"
          strokeWidth={8}
          initial={{ pathLength: 0 }}
          animate={{ pathLength: 1 }}
          transition={delayed(anim.easeInOut(duration), 0.15)}
        />
      </mask>
      <path d={d} fill="none" stroke={Signature.accent} strokeWidth={3} strokeLinecap="round" strokeDasharray="6 5" mask={`url(#${maskId})`} />
    </svg>
  );
}

function Marker({ at, isLatest }: { at: Point; isLatest: boolean }) {
  return (
    <div style={{ position: "absolute", left: at.x, top: at.y, width: 0, height: 0 }}>
      <motion.div
        initial={{ scale: 0.4, opacity: 0.9 }}
        animate={{ scale: 3.2, opacity: 0 }}
        transition={delayed(anim.easeOut(0.9), 0.25)}
        style={{ position: "absolute", left: -9, top: -9, width: 18, height: 18, borderRadius: "50%", border: `2px solid ${Signature.accent}` }}
      />
      <div style={{ position: "absolute", left: -6, top: -2, width: 12, height: 4, borderRadius: "50%", background: "rgb(0 0 0 / 0.45)" }} />
      <svg
        width={24}
        height={24}
        viewBox="-12 -12 24 24"
        style={{ position: "absolute", left: -12, top: -12 - 16, filter: "drop-shadow(0 2px 4px rgb(0 0 0 / 0.4))", overflow: "visible" }}
      >
        <circle r={11} fill={isLatest ? Signature.accent : "#3A3F48"} style={{ transition: "fill 0.3s ease-in-out" }} />
        <circle cx={0} cy={-2.6} r={3.6} fill="#fff" />
        <path d="M-1 0 L1 0 L0.7 6 Q0 7 -0.7 6 Z" fill="#fff" />
      </svg>
    </div>
  );
}

function MapBackdrop() {
  const w = MAP_W;
  const h = MAP_H;
  const streets: string[] = [];
  for (let i = 1; i < 8; i++) {
    const x = (w * i) / 8 + (i % 3) * 5;
    streets.push(`M${x} 0 L${x - 18} ${h}`);
  }
  for (let i = 1; i < 6; i++) {
    const y = (h * i) / 6;
    streets.push(`M0 ${y} L${w} ${y + 10}`);
  }
  return (
    <svg width={w} height={h} style={{ position: "absolute", inset: 0 }}>
      <rect width={w} height={h} fill="#1E2126" />
      <path d={`M${w * 0.58} ${h} C${w * 0.68} ${h * 0.68} ${w * 0.84} ${h * 0.5} ${w} ${h * 0.4} L${w} ${h} Z`} fill="#173A48" />
      <rect x={w * 0.14} y={h * 0.12} width={w * 0.22} height={h * 0.2} rx={8} fill="#223127" />
      <path d={streets.join(" ")} stroke={white(0.07)} strokeWidth={1} fill="none" />
      <path d={`M0 ${h * 0.78} Q${w * 0.5} ${h * 0.62} ${w} ${h * 0.18}`} stroke={white(0.13)} strokeWidth={3} fill="none" />
    </svg>
  );
}
