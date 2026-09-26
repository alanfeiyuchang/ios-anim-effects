/** buttons.neon-breath · 霓虹呼吸 (Buttons+NeonBreath.swift) */
import { useEffect, useState } from "react";
import { DemoHint, black, fonts, hex, useClock, useHaptics, white, type DemoProps } from "../../kit";
import { lin, track, useKeyframes, wallSeconds } from "./_b-kit";

const NEON = hex(0x3cf2ff);
const neonA = (a: number) => hex(0x3cf2ff, a);

export default function NeonBreath({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [flickers, setFlickers] = useState(0);
  useClock(true, ctx.isPreview ? 30 : undefined);

  const period = Math.max(ctx.n("period"), 0.2);
  const breath = (Math.sin((wallSeconds() / period) * 2 * Math.PI) + 1) / 2;
  const bloom = ctx.n("bloom");
  const glow = 4 + (bloom - 4) * breath;

  // A failing-tube stutter every few seconds while idle; silent, unlike the tap.
  const idle = ctx.b("flicker");
  useEffect(() => {
    if (!idle) return;
    let timer = 0;
    const loop = () => {
      timer = window.setTimeout(() => {
        setFlickers((f) => f + 1);
        loop();
      }, (2.8 + Math.random() * 2.7) * 1000);
    };
    loop();
    return () => window.clearTimeout(timer);
  }, [idle]);

  const ft = useKeyframes(flickers, 0.35);
  const flicker = ft < 0 ? 1 : track(ft, [lin(0.35, 0.05), lin(1, 0.06), lin(0.6, 0.08), lin(1, 0.16)], 1);

  // `.brightness(0.25 · breath)` adds to every channel.
  const add = 0.25 * breath * 255;
  const bright = `rgb(${Math.min(60 + add, 255)} ${Math.min(242 + add, 255)} 255)`;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div
        style={{
          position: "relative",
          padding: "58px 36px 34px",
          borderRadius: 28,
          overflow: "hidden",
          background: `linear-gradient(${hex(0x161824)}, ${hex(0x06070b)})`,
          boxShadow: `0 10px 20px ${black(0.3)}`,
          flexShrink: 0,
        }}
      >
        <div style={{ position: "absolute", inset: 0, borderRadius: 28, boxShadow: `inset 0 0 0 1px ${white(0.08)}`, pointerEvents: "none" }} />
        <div
          style={{
            position: "absolute",
            left: 18,
            top: 18,
            fontFamily: fonts.rounded,
            fontSize: 10,
            fontWeight: 700,
            letterSpacing: 1.4,
            textTransform: "uppercase",
            color: white(0.4),
            lineHeight: "12px",
          }}
        >
          {ctx.t("Open late", "营业至深夜")}
        </div>
        <div
          onClick={() => {
            setFlickers((f) => f + 1);
            haptics.tap();
          }}
          style={{ position: "relative", display: "flex", flexDirection: "column", alignItems: "center", gap: 14, opacity: flicker, cursor: "pointer" }}
        >
          <div style={{ position: "relative", width: 210, height: 62 }}>
            {/* Coloured wash spilling onto the wall, breathing with the tube. */}
            <div
              style={{
                position: "absolute",
                left: 105 - 160,
                top: 31 - 120,
                width: 320,
                height: 240,
                background: `radial-gradient(170px circle at 50% 50%, ${neonA(0.1 + 0.1 * breath)}, transparent)`,
                pointerEvents: "none",
              }}
            />
            <div style={{ position: "absolute", inset: 0, borderRadius: 31, background: hex(0x0a0b12) }} />
            <div
              style={{
                position: "absolute",
                inset: 0,
                display: "grid",
                placeItems: "center",
                fontFamily: fonts.rounded,
                fontSize: 20,
                fontWeight: 600,
                letterSpacing: 4,
                paddingLeft: 4,
                color: NEON,
                textShadow: `0 0 ${glow * 0.35}px ${neonA(0.9)}`,
              }}
            >
              {ctx.t("ENTER", "进入夜场")}
            </div>
            <div
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: 31,
                border: `2px solid ${bright}`,
                filter: `drop-shadow(0 0 ${glow * 0.25}px ${NEON}) drop-shadow(0 0 ${glow}px ${neonA(0.7)})`,
              }}
            />
          </div>
          <div style={{ width: 180, height: 14, borderRadius: 7, background: NEON, filter: "blur(16px)", opacity: 0.15 + 0.25 * breath }} />
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap to flicker" zh="点击让它闪烁" style={{ paddingBottom: 18 }} />
    </div>
  );
}
