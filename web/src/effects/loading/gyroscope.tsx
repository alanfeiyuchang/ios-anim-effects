/** loading.gyroscope · 陀螺仪圆环 (Loading+SpinnerVariations.swift) */
import { useEffect, useState } from "react";
import { Palette, alpha, type DemoProps } from "../../kit";
import { SpinnerCaption, frac, previewFps, primary, usePhase } from "./shared";

const COLORS = [Palette.mint, Palette.sky, Palette.violet];
const PERIODS = [2.4, 3.2, 4.0];
const AXES = ["1, 0, 0", "0, 1, 0", "1, 1, 0.3"];

export default function Gyroscope({ ctx }: DemoProps) {
  const zh = ctx.lang === "zh";
  const speed = ctx.n("speed");
  const perspective = ctx.n("perspective");
  const t = usePhase(speed, previewFps(ctx.isPreview));
  const breath = 1 + 0.1 * Math.sin((2 * Math.PI * t) / 1.2);
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 20 }}>
      <div style={{ position: "relative", width: 150, height: 150 }}>
        {COLORS.map((color, i) => {
          const deg = frac(t / PERIODS[i]) * 360;
          // SwiftUI's rotation3DEffect perspective p ≈ a CSS perspective of (frame side / p).
          const persp = perspective > 0.001 ? `perspective(${120 / perspective}px) ` : "";
          return (
            <div
              key={i}
              style={{
                position: "absolute",
                left: 15,
                top: 15,
                width: 120,
                height: 120,
                borderRadius: "50%",
                boxShadow: `inset 0 0 0 1.25px ${color}, 0 0 0 1.25px ${color}`,
                transform: `${persp}rotate3d(${AXES[i]}, ${deg}deg)`,
              }}
            />
          );
        })}
        <div
          style={{
            position: "absolute",
            left: 75 - 11,
            top: 75 - 11,
            width: 22,
            height: 22,
            borderRadius: "50%",
            background: Palette.aurora,
            transform: `scale(${breath})`,
            boxShadow: `0 0 12px ${alpha(Palette.sky, ctx.b("glow") ? 0.7 : 0)}`,
          }}
        />
      </div>
      <SpinnerCaption title={zh ? "正在校准运动传感器" : "Calibrating motion sensors"} detail={zh ? "请将设备平放" : "Keep your device on a flat surface"} />
      <Readouts speed={speed} />
    </div>
  );
}

function Readouts({ speed }: { speed: number }) {
  const [now, setNow] = useState(() => Date.now() / 1000);
  useEffect(() => {
    const id = window.setInterval(() => setNow(Date.now() / 1000), 120);
    return () => clearInterval(id);
  }, []);
  const t = (now % 100000) * speed;
  const fmt = (v: number) => (v >= 0 ? "+" : "-") + Math.abs(v).toFixed(2);
  const item = (axis: string, value: number) => (
    <div key={axis} style={{ display: "flex", alignItems: "center", gap: 4, padding: "5px 8px", borderRadius: 999, background: primary(0.06) }}>
      <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 700, color: Palette.secondaryLabel }}>{axis}</span>
      <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, fontVariantNumeric: "tabular-nums" }}>{fmt(value)}</span>
    </div>
  );
  return (
    <div style={{ display: "flex", gap: 16 }}>
      {item("X", Math.sin(t * 1.3) * 0.42)}
      {item("Y", Math.cos(t * 0.9) * 0.37)}
      {item("Z", Math.sin(t * 0.7 + 1) * 0.12 + 0.98)}
    </div>
  );
}
