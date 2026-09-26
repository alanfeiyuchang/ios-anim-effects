/** loading.infinity-comet · 无限彗星 (Loading+SpinnerVariations.swift) */
import { Smartphone, Watch } from "lucide-react";
import { Palette, alpha, type DemoProps } from "../../kit";
import { SpinnerCaption, frac, previewFps, primary, usePhase } from "./shared";

const W = 176;
const H = 72;

/** Faster through the crossing, slower through the loops. */
const warp = (u: number) => u - 0.05 * Math.sin(4 * Math.PI * u);

function point(u: number) {
  const theta = warp(u) * 2 * Math.PI;
  const s = Math.sin(theta);
  const c = Math.cos(theta);
  const denom = 1 + s * s;
  return { x: W / 2 + (c / denom) * (W / 2 - 8), y: H / 2 + ((s * c) / denom) * (H - 16) };
}

/** Sky → violet → pink, interpolated continuously along the tail. */
function tailColor(f: number, opacity: number) {
  const stops = [0x3ac4ff, 0xa46bff, 0xff5fa2];
  const u = Math.min(Math.max(f, 0), 1) * (stops.length - 1);
  const i = Math.min(Math.floor(u), stops.length - 2);
  const t = u - i;
  const ch = (v: number, s: number) => (v >> s) & 0xff;
  const mixc = (s: number) => Math.round(ch(stops[i], s) + (ch(stops[i + 1], s) - ch(stops[i], s)) * t);
  return `rgb(${mixc(16)} ${mixc(8)} ${mixc(0)} / ${opacity})`;
}

let trackPath = "";
for (let step = 0; step <= 120; step++) {
  const p = point(step / 120);
  trackPath += `${step === 0 ? "M" : "L"} ${p.x.toFixed(2)} ${p.y.toFixed(2)} `;
}

export default function InfinityComet({ ctx }: DemoProps) {
  const zh = ctx.lang === "zh";
  const period = Math.max(ctx.n("period"), 0.3);
  const phase = frac(usePhase(1 / period, previewFps(ctx.isPreview)));
  const side = Math.cos(warp(phase) * 2 * Math.PI);
  const trail = Math.max(ctx.i("trail"), 2);
  const glow = ctx.b("glow");
  const head = point(phase);
  const dots = [];
  for (let i = trail - 1; i >= 0; i--) {
    const f = i / trail;
    const p = point(frac(phase - f * 0.35));
    const r = 4.5 * (1 - 0.85 * f);
    dots.push(<circle key={i} cx={p.x} cy={p.y} r={r} fill={tailColor(f, 1 - f)} />);
  }
  const device = (Icon: typeof Smartphone, lit: boolean) => (
    <div
      style={{
        width: 34,
        display: "grid",
        placeItems: "center",
        color: lit ? Palette.sky : Palette.secondaryLabel,
        filter: `drop-shadow(0 0 8px ${alpha(Palette.sky, lit ? 0.6 : 0)})`,
        transition: "color 0.3s ease-out, filter 0.3s ease-out",
      }}
    >
      <Icon size={30} strokeWidth={1.6} />
    </div>
  );
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 26 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        {device(Smartphone, side < -0.6)}
        <div style={{ position: "relative", width: W, height: H }}>
          <svg width={W} height={H} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
            <path d={trackPath} fill="none" stroke={primary(0.08)} strokeWidth={3} />
            {dots}
          </svg>
          {glow && (
            <div style={{ position: "absolute", left: head.x - 10, top: head.y - 10, width: 20, height: 20, borderRadius: "50%", background: alpha(Palette.sky, 0.8), filter: "blur(8px)" }} />
          )}
          <div style={{ position: "absolute", left: head.x - 4.5, top: head.y - 4.5, width: 9, height: 9, borderRadius: "50%", background: glow ? "#fff" : Palette.sky }} />
        </div>
        {device(Watch, side > 0.6)}
      </div>
      <SpinnerCaption title={zh ? "正在配对…" : "Pairing…"} detail={zh ? "请让手表靠近 iPhone" : "Hold your watch near your iPhone"} />
    </div>
  );
}
