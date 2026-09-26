/** showcase.flight-path · 航线飞行 (TravelFlightPath.swift) */
import { useEffect, useState } from "react";
import { DemoHint, fonts, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";

const S = 290;
const XS = [0.12, 0.3, 0.66, 0.84];
const YS = [0.84, 0.3, 0.98, 0.42];
function point(t: number) {
  const u = 1 - t;
  const w = [u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t];
  return { x: S * w.reduce((a, k, i) => a + k * XS[i], 0), y: S * w.reduce((a, k, i) => a + k * YS[i], 0) };
}
function angle(t: number) {
  const u = 1 - t;
  const d = [3 * u * u, 6 * u * t, 3 * t * t];
  const dx = d[0] * (XS[1] - XS[0]) + d[1] * (XS[2] - XS[1]) + d[2] * (XS[3] - XS[2]);
  const dy = d[0] * (YS[1] - YS[0]) + d[1] * (YS[2] - YS[1]) + d[2] * (YS[3] - YS[2]);
  return Math.atan2(dy * S, dx * S);
}
const ROUTE_D = Array.from({ length: 61 }, (_, i) => {
  const p = point(i / 60);
  return `${i === 0 ? "M" : "L"}${p.x.toFixed(2)},${p.y.toFixed(2)}`;
}).join(" ");

export default function FlightPath({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [launch, setLaunch] = useState(() => performance.now());
  const [running, setRunning] = useState(true);
  const duration = Math.max(ctx.n("duration"), 0.1);
  useEffect(() => {
    setRunning(true);
    const id = window.setTimeout(() => setRunning(false), (duration + 2.2) * 1000);
    return () => clearTimeout(id);
  }, [launch, duration]);
  useClock(running, ctx.isPreview ? 30 : undefined);
  useAutoplay(ctx.isPreview, () => setLaunch(performance.now()), { every: duration + 1.8, delay: 0.1, intro: false });

  const elapsed = (performance.now() - launch) / 1000;
  const t = Math.min(Math.max(elapsed / duration, 0), 1);
  const progress = t * t * (3 - 2 * t);
  const landing = elapsed - duration;
  const trailFade = landing <= 0 ? 1 : Math.max(0, 1 - landing / 0.8);
  const trail = ctx.n("trail");
  const zh = ctx.lang === "zh";

  const start = Math.max(0, progress - trail);
  const segments = [];
  if (progress > start && trailFade > 0) {
    for (let i = 0; i < 24; i++) {
      const a = point(start + ((progress - start) * i) / 24);
      const b = point(start + ((progress - start) * (i + 1)) / 24);
      const f = (i + 1) / 24;
      segments.push(<line key={i} x1={a.x} y1={a.y} x2={b.x} y2={b.y} stroke={Signature.accent} strokeOpacity={f * trailFade} strokeWidth={1 + 2.5 * f} strokeLinecap="round" />);
    }
  }

  const plane = point(progress);
  const heading = angle(Math.min(Math.max(progress, 0.001), 0.999));
  const planeOpacity = landing > 0.4 ? Math.max(0, 1 - (landing - 0.4) / 0.4) : 1;
  const origin = point(0);
  const dest = point(1);

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
        <div
          onClick={() => {
            haptics.tap("medium");
            setLaunch(performance.now());
          }}
          style={{ ...signatureCard(28), width: S, height: S, flexShrink: 0, cursor: "pointer" }}
        >
          <div style={{ position: "absolute", inset: 0, borderRadius: 28, overflow: "hidden" }}>
            <div style={{ position: "absolute", left: 0, top: 0, width: 520, height: S }}>
              <LandscapeArt seed={4} />
            </div>
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(rgb(0 0 0 / 0.6), transparent, rgb(0 0 0 / 0.35))" }} />
            <svg width={S} height={S} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
              <path d={ROUTE_D} fill="none" stroke="rgb(255 255 255 / 0.45)" strokeWidth={1.5} strokeLinecap="round" strokeDasharray="2 6" />
              {segments}
            </svg>
            <div style={{ position: "absolute", left: origin.x - 4, top: origin.y - 4, width: 8, height: 8, borderRadius: "50%", background: "#fff", boxShadow: "0 0 0 3px rgb(255 255 255 / 0.35)" }} />
            <Pin at={dest} landing={landing} bounce={ctx.n("bounce")} />
            <div
              style={{
                position: "absolute",
                left: plane.x - 13,
                top: plane.y - 13,
                width: 26,
                height: 26,
                opacity: planeOpacity,
                transform: `scale(${1 + 0.25 * Math.sin(progress * Math.PI)}) rotate(${heading}rad)`,
                filter: "drop-shadow(0 0 8px rgb(255 138 31 / 0.9))",
              }}
            >
              <svg width={26} height={26} viewBox="0 0 24 24">
                <path d="M21.5 12c0-.8-.7-1.4-1.5-1.4h-4.6L10.2 2.8H8.3l2.6 7.8H5.6L3.9 8.4H2.4l1 3.6-1 3.6h1.5l1.7-2.2h5.3l-2.6 7.8h1.9l5.2-7.8H20c.8 0 1.5-.6 1.5-1.4Z" fill="#fff" />
              </svg>
            </div>
            <div style={{ position: "absolute", left: 20, top: 20, display: "flex", flexDirection: "column", gap: 6 }}>
              <span style={signatureEyebrow()}>{zh ? "旅行 · 灵感" : "Travel · Inspire"}</span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 24, fontWeight: 700, color: "#fff", lineHeight: "29px", whiteSpace: "pre-line" }}>
                {zh ? "你的下一场冒险\n从这里出发" : "Your Next\nAdventure\nStarts Here"}
              </span>
            </div>
            <div
              style={{
                position: "absolute",
                right: 14,
                bottom: 14,
                display: "flex",
                alignItems: "center",
                gap: 6,
                padding: "6px 10px",
                borderRadius: 999,
                background: "rgb(0 0 0 / 0.35)",
              }}
            >
              <span style={signatureEyebrow()}>HGH → NCE</span>
              <span style={{ ...signatureNumber(13), color: "#fff" }}>{Math.trunc(progress * 9120).toLocaleString("en-US")} km</span>
            </div>
          </div>
          <SignatureRim radius={28} />
        </div>
        <DemoHint ctx={ctx} en="Tap the card to fly again" zh="点击卡片重新起飞" />
      </div>
    </SignatureStage>
  );
}

function Pin({ at, landing, bounce }: { at: { x: number; y: number }; landing: number; bounce: number }) {
  const FALL = 0.28;
  let drop = -70;
  if (landing >= 0) {
    if (landing < FALL) {
      const k = landing / FALL;
      drop = -70 * (1 - k * k);
    } else {
      const s = landing - FALL;
      drop = -Math.abs(Math.sin(s * 14)) * 18 * bounce * Math.exp(-s * 5);
    }
  }
  const ripple = Math.max(0, landing - FALL);
  return (
    <div style={{ position: "absolute", left: at.x, top: at.y, width: 0, height: 0, pointerEvents: "none" }}>
      <div
        style={{
          position: "absolute",
          left: -8,
          top: -8,
          width: 16,
          height: 16,
          borderRadius: "50%",
          boxShadow: `inset 0 0 0 1.5px ${Signature.accent}`,
          transform: `scale(${1 + ripple * 4})`,
          opacity: landing < FALL ? 0 : Math.max(0, 1 - ripple / 0.9),
        }}
      />
      <div style={{ position: "absolute", left: -7, top: -2.5, width: 14, height: 5, borderRadius: "50%", background: "rgb(0 0 0 / 0.4)", opacity: landing < 0 ? 0 : 1 }} />
      <div
        style={{
          position: "absolute",
          left: -8,
          top: -13 - 15 + drop,
          width: 16,
          height: 26,
          opacity: landing < 0 ? 0 : Math.min(1, landing / 0.12),
          filter: "drop-shadow(0 0 6px rgb(255 138 31 / 0.6))",
        }}
      >
        <svg width={16} height={26} viewBox="0 0 16 26">
          <defs>
            <linearGradient id="flight-pin" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Signature.accentSoft} />
              <stop offset="0.5" stopColor={Signature.accent} />
              <stop offset="1" stopColor={Signature.accentHot} />
            </linearGradient>
          </defs>
          <circle cx={8} cy={8} r={7} fill="url(#flight-pin)" />
          <rect x={6.6} y={13} width={2.8} height={12} rx={1.4} fill="url(#flight-pin)" />
        </svg>
      </div>
    </div>
  );
}
