/** loading.audio-wave · 音频波形条 (Loading+Ambient.swift) */
import { motion } from "motion/react";
import { useEffect, useState } from "react";
import { Palette, demoCard, type DemoProps } from "../../kit";
import { previewFps, usePhase } from "./shared";

const BAR = 7;
const GAP = 6;

function level(t: number, index: number, count: number) {
  const envelope = 0.3 + 0.7 * Math.sin((Math.PI * (index + 0.5)) / count);
  const wave = 0.5 + 0.28 * Math.sin(t * 5.1 + index * 0.8) + 0.22 * Math.sin(t * 7.7 - index * 1.3);
  return Math.min(Math.max(envelope * wave, 0.05), 1);
}

export default function AudioWave({ ctx }: DemoProps) {
  const zh = ctx.lang === "zh";
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ ...demoCard(26), width: 292, padding: "20px 22px", display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <Header zh={zh} />
        <div style={{ height: 110, display: "grid", placeItems: "center" }}>
          <Bars count={Math.max(ctx.i("count"), 1)} speed={ctx.n("speed")} maxHeight={ctx.n("height")} centered={ctx.b("mirror")} preview={ctx.isPreview} />
        </div>
        <div style={{ fontSize: 13, lineHeight: "18px", color: Palette.secondaryLabel, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis", maxWidth: "100%" }}>
          {zh ? "“把明早的站会改到十点……”" : "“Move tomorrow's standup to ten…”"}
        </div>
      </div>
    </div>
  );
}

function Header({ zh }: { zh: boolean }) {
  const [seconds, setSeconds] = useState(0);
  useEffect(() => {
    const start = performance.now();
    const id = window.setInterval(() => setSeconds(Math.floor((performance.now() - start) / 1000)), 250);
    return () => clearInterval(id);
  }, []);
  const total = seconds % 600;
  return (
    <div style={{ alignSelf: "stretch", display: "flex", alignItems: "center", gap: 8 }}>
      <motion.div
        animate={{ opacity: [1, 0.35] }}
        transition={{ duration: 0.8, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
        style={{ width: 8, height: 8, borderRadius: "50%", background: Palette.red }}
      />
      <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "正在聆听…" : "Listening…"}</span>
      <div style={{ flex: 1, minWidth: 8 }} />
      <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>
        {Math.floor(total / 60)}:{String(total % 60).padStart(2, "0")}
      </span>
    </div>
  );
}

function Bars({ count, speed, maxHeight, centered, preview }: { count: number; speed: number; maxHeight: number; centered: boolean; preview: boolean }) {
  const t = usePhase(speed, previewFps(preview));
  const total = count * BAR + Math.max(count - 1, 0) * GAP;
  return (
    <div style={{ position: "relative", width: total, height: maxHeight }}>
      {Array.from({ length: count }, (_, index) => {
        const h = Math.max(BAR, maxHeight * level(t, index, count));
        const y = centered ? (maxHeight - h) / 2 : maxHeight - h;
        return (
          <div
            key={index}
            style={{
              position: "absolute",
              left: index * (BAR + GAP),
              top: y,
              width: BAR,
              height: h,
              borderRadius: BAR / 2,
              background: `linear-gradient(${Palette.violet}, ${Palette.sky}, ${Palette.mint})`,
              backgroundSize: `${BAR}px ${maxHeight}px`,
              backgroundPosition: `0 ${-y}px`,
            }}
          />
        );
      })}
    </div>
  );
}
