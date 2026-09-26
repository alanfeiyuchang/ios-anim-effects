/** loading.liquid-fill · 液体填充 (Loading+Progress.swift) */
import { useId, useState } from "react";
import { DemoHint, Palette, alpha, fonts, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { previewFps, useAnimatedNumber, usePhase } from "./shared";

const LEVELS = [0.28, 0.64, 0.9, 0.46];
const SIZE = 180;

function wave(level: number, phase: number, amplitude: number, frequency: number) {
  const baseY = SIZE - SIZE * level;
  let d = `M 0 ${SIZE}`;
  for (let i = 0; i <= 48; i++) {
    const rel = i / 48;
    d += ` L ${(SIZE * rel).toFixed(2)} ${(baseY + amplitude * Math.sin(rel * 2 * Math.PI * frequency + phase)).toFixed(2)}`;
  }
  return `${d} L ${SIZE} ${SIZE} Z`;
}

export default function LiquidFill({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [step, setStep] = useState(1);
  const level = useAnimatedNumber(LEVELS[1]);
  const time = usePhase(ctx.n("speed"), previewFps(ctx.isPreview));
  const id = useId().replace(/:/g, "");

  const advance = () => {
    const next = step + 1;
    setStep(next);
    level.to(LEVELS[next % LEVELS.length], spring(1.1, 0.7));
    haptics.tap("soft");
  };
  useAutoplay(ctx.isPreview, advance, { every: 2.4 });

  const amplitude = ctx.n("amplitude");
  const l = level.value;
  const front = wave(l, time * 2.3, amplitude, 1.1);
  const back = wave(l, -time * 1.7 + 1.8, amplitude * 0.8, 0.8);
  const percent = Math.round(Math.min(Math.max(l, 0), 1) * 100);
  const label = (color: string) => (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", color, fontFamily: fonts.rounded, fontWeight: 700 }}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 1 }}>
        <span style={{ fontSize: 42, fontVariantNumeric: "tabular-nums" }}>{percent}</span>
        <span style={{ fontSize: 20 }}>%</span>
      </div>
    </div>
  );

  return (
    <div
      onClick={advance}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 20, cursor: "pointer" }}
    >
      <div style={{ position: "relative", padding: 6 }}>
        <div style={{ position: "relative", width: SIZE, height: SIZE, borderRadius: "50%", overflow: "hidden", background: alpha(Palette.sky, 0.1) }}>
          <svg width={SIZE} height={SIZE} style={{ position: "absolute", inset: 0 }}>
            <defs>
              <linearGradient id={`w${id}`} x1="0" y1="0" x2="0" y2={SIZE} gradientUnits="userSpaceOnUse">
                <stop offset="0" stopColor={Palette.sky} />
                <stop offset="1" stopColor={Palette.blue} />
              </linearGradient>
            </defs>
            <path d={back} fill={alpha(Palette.sky, 0.45)} />
            <path d={front} fill={`url(#w${id})`} />
          </svg>
          {label(Palette.blue)}
          <div style={{ position: "absolute", inset: 0, clipPath: `path("${front}")` }}>{label("#fff")}</div>
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: `inset 0 0 0 1.25px ${alpha(Palette.sky, 0.55)}, 0 0 0 1.25px ${alpha(Palette.sky, 0.55)}` }} />
      </div>
      <DemoHint ctx={ctx} en="Tap to change the level" zh="点击改变液位" />
    </div>
  );
}
