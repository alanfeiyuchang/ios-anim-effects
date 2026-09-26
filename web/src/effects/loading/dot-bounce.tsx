/** loading.dot-bounce · 三点跳动 (Loading+Spinners.swift) */
import { motion } from "motion/react";
import { Palette, black, type DemoProps } from "../../kit";
import { frac, previewFps, usePhase } from "./shared";

const COLORS = [Palette.indigo, Palette.violet, Palette.pink];

export default function DotBounce({ ctx }: DemoProps) {
  const row = <Row size={ctx.n("size")} speed={ctx.n("speed")} height={ctx.n("height")} preview={ctx.isPreview} />;
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      {ctx.b("bubble") ? <ChatThread zh={ctx.lang === "zh"}>{row}</ChatThread> : <div style={{ transform: "scale(1.6)" }}>{row}</div>}
    </div>
  );
}

function ChatThread({ zh, children }: { zh: boolean; children: React.ReactNode }) {
  return (
    <div style={{ width: 290, display: "flex", flexDirection: "column", alignItems: "stretch", gap: 14 }}>
      <div style={{ display: "flex", justifyContent: "flex-end" }}>
        <div
          style={{
            fontSize: 15,
            lineHeight: "20px",
            color: "#fff",
            padding: "10px 14px",
            background: Palette.primary,
            borderRadius: "20px 20px 6px 20px",
          }}
        >
          {zh ? "今晚的发布会你来吗？" : "Coming to the launch tonight?"}
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "flex-end", gap: 8 }}>
        <div
          style={{
            width: 30,
            height: 30,
            borderRadius: "50%",
            background: `linear-gradient(${Palette.pink}, ${Palette.coral})`,
            display: "grid",
            placeItems: "center",
            fontSize: 11,
            fontWeight: 700,
            color: "#fff",
            flexShrink: 0,
          }}
        >
          MJ
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 6 }}>
          <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 500, color: Palette.secondaryLabel, paddingLeft: 6 }}>
            {zh ? "米娅正在输入…" : "Mia is typing…"}
          </span>
          <motion.div
            animate={{ scale: [1, 1.03] }}
            transition={{ duration: 1.1, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
            style={{
              transformOrigin: "0% 100%",
              padding: "14px 18px",
              background: Palette.elevated,
              borderRadius: "22px 22px 22px 6px",
              boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 6px 12px ${black(0.1)}`,
            }}
          >
            {children}
          </motion.div>
        </div>
      </div>
    </div>
  );
}

function Row({ size, speed, height, preview }: { size: number; speed: number; height: number; preview: boolean }) {
  const t = usePhase(speed, previewFps(preview));
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: size * 0.55, height: size + height }}>
      {COLORS.map((color, index) => {
        const phase = frac(t - index * 0.14);
        const lift = phase < 0.5 ? Math.sin((phase / 0.5) * Math.PI) : 0;
        return (
          <div
            key={index}
            style={{
              width: size,
              height: size,
              borderRadius: "50%",
              background: color,
              opacity: 0.5 + 0.5 * lift,
              transform: `translateY(${-height * lift}px) scale(${0.85 + 0.15 * lift})`,
            }}
          />
        );
      })}
    </div>
  );
}
