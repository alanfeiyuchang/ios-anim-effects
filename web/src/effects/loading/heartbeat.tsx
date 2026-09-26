/** loading.heartbeat · 心电脉冲 (Loading+Heartbeat.swift) */
import { Heart } from "lucide-react";
import { useEffect, useRef } from "react";
import { Palette, alpha, demoCard, type DemoProps } from "../../kit";
import { frac, previewFps, usePhase } from "./shared";

const W = 260;
const H = 90;

/** One heartbeat on u ∈ [0, 1): P bump, QRS complex around 0.3, T wave. */
function pqrst(u: number) {
  if (u > 0.1 && u < 0.2) return 0.1 * Math.sin(((u - 0.1) / 0.1) * Math.PI);
  if (u >= 0.26 && u < 0.29) return (-0.12 * (u - 0.26)) / 0.03;
  if (u >= 0.29 && u < 0.32) return -0.12 + (1.22 * (u - 0.29)) / 0.03;
  if (u >= 0.32 && u < 0.35) return 1.1 - (1.4 * (u - 0.32)) / 0.03;
  if (u >= 0.35 && u < 0.38) return -0.3 + (0.3 * (u - 0.35)) / 0.03;
  if (u > 0.48 && u < 0.66) return 0.2 * Math.sin(((u - 0.48) / 0.18) * Math.PI);
  return 0;
}
const traceY = (time: number, beats: number) => H * 0.68 - pqrst(frac(time * beats)) * H * 0.62;

export default function Heartbeat({ ctx }: DemoProps) {
  const zh = ctx.lang === "zh";
  const bpm = Math.max(ctx.n("bpm"), 20);
  const beats = Math.max(ctx.n("beats"), 0.5);
  const beatTime = 60 / bpm;
  const sweep = beatTime * beats;
  const written = usePhase(1 / sweep, previewFps(ctx.isPreview));
  const headBeat = frac(written * beats);
  const sinceR = Math.max((((headBeat - 0.32 + 1) % 1) * beatTime), 0);
  const pop = sinceR < 0.3 ? Math.sin((sinceR / 0.3) * Math.PI) * 0.25 : 0;
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ ...demoCard(), padding: 18, display: "flex", flexDirection: "column", gap: 14 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div
            style={{
              width: 30,
              display: "grid",
              placeItems: "center",
              color: Palette.red,
              transform: `scale(${1 + pop})`,
              filter: `drop-shadow(0 0 8px ${alpha(Palette.red, Math.min(pop * 2, 1))})`,
            }}
          >
            <Heart size={24} fill="currentColor" strokeWidth={0} />
          </div>
          <div style={{ display: "flex", flexDirection: "column" }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "正在测量心率" : "Measuring heart rate"}</span>
            <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>
              {Math.round(bpm)} BPM
            </span>
          </div>
        </div>
        <Strip written={written} beats={beats} grid={ctx.b("grid")} />
        <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{zh ? "请保持手指贴合传感器" : "Keep your finger on the sensor"}</span>
      </div>
    </div>
  );
}

function Strip({ written, beats, grid }: { written: number; beats: number; grid: boolean }) {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const dpr = Math.max(window.devicePixelRatio || 1, 2);
    if (canvas.width !== W * dpr) {
      canvas.width = W * dpr;
      canvas.height = H * dpr;
    }
    const g = canvas.getContext("2d");
    if (!g) return;
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.clearRect(0, 0, W, H);
    const labelRGB = getComputedStyle(canvas).getPropertyValue("--ml-label-rgb").trim() || "255 255 255";
    if (grid) {
      g.beginPath();
      for (let x = 0; x <= W; x += 13) {
        g.moveTo(x, 0);
        g.lineTo(x, H);
      }
      for (let y = 0; y <= H; y += 13) {
        g.moveTo(0, y);
        g.lineTo(W, y);
      }
      g.strokeStyle = `rgb(${labelRGB} / 0.06)`;
      g.lineWidth = 0.5;
      g.stroke();
    }
    const head = frac(written);
    const sweepStart = Math.floor(written);
    const headX = W * head;
    g.lineWidth = 2.2;
    g.lineCap = "round";
    g.lineJoin = "round";
    let prev: { x: number; y: number } | null = null;
    for (let i = 0; i <= W / 2; i++) {
      const x = i * 2;
      const fx = x / W;
      const time = fx <= head ? sweepStart + fx : sweepStart - 1 + fx;
      const p = { x, y: traceY(time, beats) };
      let behind = headX - x;
      if (behind < 0) behind += W;
      const age = behind / W;
      if (prev && age < 0.94) {
        g.beginPath();
        g.moveTo(prev.x, prev.y);
        g.lineTo(p.x, p.y);
        g.strokeStyle = alpha(Palette.red, 1 - age);
        g.stroke();
      }
      prev = p;
    }
    const headY = traceY(written, beats);
    g.fillStyle = alpha(Palette.red, 0.2);
    g.beginPath();
    g.arc(headX, headY, 7.5, 0, Math.PI * 2);
    g.fill();
    g.fillStyle = Palette.red;
    g.beginPath();
    g.arc(headX, headY, 3.5, 0, Math.PI * 2);
    g.fill();
  });
  return <canvas ref={ref} style={{ width: W, height: H, display: "block" }} />;
}
