/** icons.radar-ping · 雷达搜寻 (Icons+RadarPing.swift) */
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, useClock, useHaptics, type DemoProps } from "../../kit";
import { Glyph, sym, type GlyphDef } from "./_icons-kit";

const SIZE = 250;
const BLIPS = [
  { bearing: 28, distance: 0.62 },
  { bearing: 102, distance: 0.84 },
  { bearing: 168, distance: 0.48 },
  { bearing: 236, distance: 0.76 },
  { bearing: 312, distance: 0.55 },
];
const SWEEP_DURATION = 0.8;
const RING_DURATION = 1.2;
const LOCATION_FILL: GlyphDef = [{ d: "M3 11 22 2 13 21 11 13Z", sw: 1.4 }];
const frac = (v: number) => v - Math.floor(v);

export default function RadarPing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const time = useClock(true, ctx.isPreview ? 30 : undefined);
  const [pingTime, setPingTime] = useState(-Infinity);

  // Cycles carried over from earlier periods, so moving a period slider does not make the beam or rings jump.
  const sweep = Math.max(ctx.n("sweep"), 0.2);
  const rings = Math.max(ctx.n("rings"), 0.2);
  const carry = useRef({ sweep, rings, beamShift: 0, ringShift: 0 });
  const c = carry.current;
  if (c.sweep !== sweep) {
    c.beamShift += time * (1 / c.sweep - 1 / sweep);
    c.sweep = sweep;
  }
  if (c.rings !== rings) {
    c.ringShift += time * (1 / c.rings - 1 / rings);
    c.rings = rings;
  }
  const decay = Math.max(ctx.n("decay"), 0.05);
  const beamAngle = (at: number) => frac(at / sweep + c.beamShift) * 360;

  const ping = () => {
    if (ctx.isPreview) return;
    haptics.tap("medium");
    setPingTime(time);
  };

  const elapsed = time - pingTime;
  const pulseActive = Number.isFinite(pingTime) && elapsed >= 0 && elapsed < Math.max(SWEEP_DURATION, RING_DURATION) + 2;
  const fromAngle = pulseActive ? beamAngle(pingTime) : 0;
  const beam = beamAngle(time);
  const breath = Math.sin((time / rings + c.ringShift) * 2 * Math.PI * 3);
  const kick = pulseActive && elapsed < 0.4 ? Math.sin((Math.PI * elapsed) / 0.4) : 0;
  const pingPhase = pulseActive ? elapsed / RING_DURATION : 1;
  const sweepP = pulseActive && elapsed < SWEEP_DURATION ? elapsed / SWEEP_DURATION : null;
  const sweepOpacity = sweepP === null ? 0 : 1 - sweepP * sweepP;
  const pulseAngle = fromAngle + 360 * Math.min(Math.max(elapsed / SWEEP_DURATION, 0), 1);

  const pulseFlare = (bearing: number) => {
    if (!pulseActive) return 0;
    let ahead = (bearing - fromAngle) % 360;
    if (ahead < 0) ahead += 360;
    const since = elapsed - (ahead / 360) * SWEEP_DURATION;
    if (since < 0) return 0;
    return Math.max(0, 1 - since / decay);
  };

  const ring = (phase: number, from: number, color: string, opacity: number, width: number, key: string) => {
    const eased = 1 - Math.pow(1 - phase, 3);
    const d = from + (SIZE - from) * eased;
    return (
      <div
        key={key}
        style={{
          position: "absolute",
          left: SIZE / 2 - d / 2,
          top: SIZE / 2 - d / 2,
          width: d,
          height: d,
          borderRadius: "50%",
          boxShadow: `0 0 0 ${width / 2}px ${alpha(color, opacity)}, inset 0 0 0 ${width / 2}px ${alpha(color, opacity)}`,
        }}
      />
    );
  };

  const beamView = (angle: number, opacity: number, key: string) => (
    <div
      key={key}
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: "50%",
        opacity,
        transform: `rotate(${angle}deg)`,
        background: `conic-gradient(from 90deg, ${alpha(Palette.sky, 0)} 0%, ${alpha(Palette.sky, 0)} ${(1 - 70 / 360) * 100}%, ${alpha(Palette.sky, 0.45)} 99.5%, ${alpha(Palette.sky, 0)} 100%)`,
      }}
    />
  );

  const gridCircle = (inset: number, opacity: number) => (
    <div style={{ position: "absolute", inset, borderRadius: "50%", boxShadow: `inset 0 0 0 1px ${alpha(Palette.sky, opacity)}` }} />
  );

  const coreScale = 1 + 0.04 * breath + 0.1 * kick;
  const pingP = Math.min(Math.max(pingPhase, 0), 1);

  return (
    <div
      onClick={ping}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: SIZE, height: SIZE }}>
        {gridCircle(-0.5, 0.18)}
        {gridCircle(SIZE * 0.17 - 0.5, 0.14)}
        {gridCircle(SIZE * 0.34 - 0.5, 0.1)}
        <div style={{ position: "absolute", left: SIZE / 2 - 0.5, top: 0, width: 1, height: SIZE, background: alpha(Palette.sky, 0.1) }} />
        <div style={{ position: "absolute", top: SIZE / 2 - 0.5, left: 0, height: 1, width: SIZE, background: alpha(Palette.sky, 0.1) }} />
        {[0, 1, 2].map((i) => {
          const phase = frac(time / rings + c.ringShift + i / 3);
          return ring(phase, 36, Palette.sky, 0.45 * (1 - phase), 2, `r${i}`);
        })}
        {ring(pingP, 58, Palette.mint, 0.85 * (1 - pingP), 3 + 3 * (1 - pingP), "ping")}
        {beamView(beam, 1, "beam")}
        {beamView(pulseActive ? pulseAngle : beam, sweepOpacity, "sweep")}
        {BLIPS.map((b, i) => {
          let behind = beam - b.bearing;
          if (behind < 0) behind += 360;
          const idle = Math.max(0, 1 - ((behind / 360) * sweep) / decay);
          const flare = Math.max(idle, pulseFlare(b.bearing));
          const rad = (b.bearing * Math.PI) / 180;
          const r = (SIZE / 2) * b.distance;
          return (
            <div
              key={i}
              style={{
                position: "absolute",
                left: SIZE / 2 - 4 + r * Math.cos(rad),
                top: SIZE / 2 - 4 + r * Math.sin(rad),
                width: 8,
                height: 8,
                borderRadius: "50%",
                background: Palette.mint,
                transform: `scale(${1 + 0.5 * flare})`,
                boxShadow: `0 0 6px ${alpha(Palette.mint, flare)}`,
                opacity: 0.35 + 0.65 * flare,
              }}
            />
          );
        })}
        <div
          style={{
            position: "absolute",
            left: SIZE / 2 - 29,
            top: SIZE / 2 - 29,
            width: 58,
            height: 58,
            borderRadius: "50%",
            background: Palette.ocean,
            boxShadow: `inset 0 0 0 1px rgb(255 255 255 / 0.35), 0 4px 12px ${alpha(Palette.blue, 0.45)}`,
            transform: `scale(${coreScale})`,
            display: "grid",
            placeItems: "center",
            color: "#fff",
          }}
        >
          <Glyph def={LOCATION_FILL} size={sym(22)} />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to send a ping" zh="点击发出一次探测" />
    </div>
  );
}
