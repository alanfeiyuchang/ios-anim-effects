/** text.neon-sign · 霓虹灯牌 (Text+NeonSign.swift) */
import { useState } from "react";
import { DemoHint, Palette, alpha, black, fonts, useAutoplay, useClock, useHaptics, white, type DemoProps } from "../../kit";
import { chars } from "./_text-kit";

/** (end time, brightness) segments of the power-on stutter. */
const FLICKER: [number, number][] = [
  [0.08, 0],
  [0.12, 0.9],
  [0.2, 0.1],
  [0.24, 1],
  [0.34, 0.25],
  [0.38, 0.8],
  [0.46, 0.15],
];
function neonLevel(t: number) {
  if (t < 0) return 0;
  for (const [end, level] of FLICKER) if (t < end) return level;
  return 1;
}
const secs = () => performance.now() / 1000;

export default function NeonSign({ ctx }: DemoProps) {
  const haptics = useHaptics();
  useClock(true, ctx.isPreview ? 30 : undefined);
  const [poweredAt, setPoweredAt] = useState(-Infinity);
  const now = secs();
  const since = now - poweredAt;
  const clock = Date.now() / 1000;
  const zh = ctx.lang === "zh";
  const stagger = ctx.n("stagger");
  const glow = ctx.n("glow");
  const faulty = ctx.b("faulty");

  const repower = () => {
    haptics.tap("rigid");
    setPoweredAt(secs());
  };
  useAutoplay(ctx.isPreview, repower, { every: 4.0, delay: 0.2 });

  const level = (index: number, lead: number, faultyLine: boolean) => {
    const local = since - lead - index * stagger;
    const base = neonLevel(local);
    if (!faulty || !faultyLine || index !== 1 || local <= 0.6) return base;
    const cycle = clock % 1.4;
    if (cycle < 0.05) return 0.2;
    if (cycle > 0.09 && cycle < 0.12) return 0.35;
    return base;
  };

  const line = (list: string[], color: string, size: number, lead: number) => (
    <div style={{ display: "flex", gap: 1, whiteSpace: "pre" }}>
      {list.map((ch, index) => {
        const l = level(index, lead, lead === 0);
        return (
          <span key={index} style={{ position: "relative", fontFamily: fonts.rounded, fontSize: size, fontWeight: 600, lineHeight: `${Math.round(size * 1.2)}px` }}>
            <span style={{ color: alpha(color, 0.18) }}>{ch}</span>
            <span
              style={{
                position: "absolute",
                inset: 0,
                color: white(0.9),
                opacity: l,
                // Each SwiftUI `.shadow` also shadows the ones before it: a chained filter compounds the same way.
                filter: `drop-shadow(0 0 ${4 * glow}px ${color}) drop-shadow(0 0 ${12 * glow}px ${alpha(color, 0.8)}) drop-shadow(0 0 ${28 * glow}px ${alpha(color, 0.5)})`,
              }}
            >
              {ch}
            </span>
          </span>
        );
      })}
    </div>
  );

  const bloom = neonLevel(since - 0.1);
  return (
    <div onClick={repower} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16, cursor: "pointer" }}>
      <div style={{ borderRadius: 26, boxShadow: `0 10px 18px ${black(0.3)}` }}>
        <div
          style={{
            position: "relative",
            overflow: "hidden",
            borderRadius: 26,
            padding: "24px 26px",
            background: `radial-gradient(circle 170px at center, ${alpha(Palette.pink, 0.28 * bloom)} 10px, transparent 170px), rgb(15 15 15)`,
            boxShadow: `inset 0 0 0 1px ${white(0.07)}`,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 10,
          }}
        >
          {line(chars(ctx.t("OPEN", "深夜食堂")), Palette.pink, zh ? 50 : 70, 0)}
          {line(chars(ctx.t("late night noodles", "营业至凌晨三点")), Palette.sky, 20, 0.25)}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to flip the switch" zh="点击开关电源" />
    </div>
  );
}
