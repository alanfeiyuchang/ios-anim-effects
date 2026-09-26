/** loading.gooey-orbit · 黏滴轨道 (Loading+SpinnerVariations.swift) */
import { motion } from "motion/react";
import { useId } from "react";
import { Palette, type DemoProps } from "../../kit";
import { SpinnerCaption, previewFps, primary, usePhase } from "./shared";

const SIZE = 150;

function blobs(t: number, period: number, count: number) {
  const c = SIZE / 2;
  const reach = period / 2;
  const breath = Math.cos((2 * Math.PI * t) / reach);
  const core = 26 * (1 + 0.06 * breath);
  const list = [{ x: c, y: c, r: core }];
  const spin = (2 * Math.PI * t) / period;
  for (let i = 0; i < count; i++) {
    const share = i / count;
    const swing = 0.5 - 0.5 * Math.cos(2 * Math.PI * (t / reach + share));
    const distance = 8 + 32 * swing;
    const angle = spin + share * 2 * Math.PI;
    list.push({ x: c + distance * Math.cos(angle), y: c + distance * Math.sin(angle), r: 11 });
  }
  return list;
}

export default function GooeyOrbit({ ctx }: DemoProps) {
  const zh = ctx.lang === "zh";
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <Orbit period={ctx.n("period")} goo={ctx.n("goo")} count={Math.max(ctx.i("count"), 1)} preview={ctx.isPreview} />
      <SpinnerCaption title={zh ? "正在查找附近设备" : "Looking for nearby devices"} detail={zh ? "请保持设备解锁并靠近" : "Keep devices unlocked and close by"} />
      <div style={{ display: "flex", gap: 12 }}>
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            initial={{ opacity: 1 }}
            animate={{ opacity: 0.45 }}
            transition={{ duration: 0.9, ease: [0.42, 0, 0.58, 1], delay: i * 0.2, repeat: Infinity, repeatType: "reverse", repeatDelay: i * 0.2 }}
            style={{ width: 30, height: 30, borderRadius: "50%", background: primary(0.1) }}
          />
        ))}
      </div>
    </div>
  );
}

/** Canvas + `.blur(goo)` + `.alphaThreshold(0.5)` = metaballs: an SVG blur + discrete alpha filter. */
function Orbit({ period, goo, count, preview }: { period: number; goo: number; count: number; preview: boolean }) {
  const id = useId().replace(/:/g, "");
  const t = usePhase(1 / Math.max(period, 0.1), previewFps(preview)) * period;
  return (
    <svg width={SIZE} height={SIZE} viewBox={`0 0 ${SIZE} ${SIZE}`} style={{ overflow: "visible" }}>
      <defs>
        <linearGradient id={`g${id}`} gradientUnits="userSpaceOnUse" x1={0} y1={0} x2={SIZE} y2={SIZE}>
          <stop offset="0" stopColor={Palette.mint} />
          <stop offset="0.5" stopColor={Palette.sky} />
          <stop offset="1" stopColor={Palette.violet} />
        </linearGradient>
        <filter id={`f${id}`} filterUnits="userSpaceOnUse" x={-20} y={-20} width={SIZE + 40} height={SIZE + 40} colorInterpolationFilters="sRGB">
          {/* GraphicsContext .blur(radius:) reads as a Gaussian of σ ≈ radius / 2 here: with σ = radius the 22 pt drops would vanish under the 50 % threshold instead of snapping free as the app shows. */}
          <feGaussianBlur in="SourceGraphic" stdDeviation={goo / 2} result="b" />
          <feComponentTransfer in="b" result="t">
            <feFuncA type="discrete" tableValues="0 1" />
          </feComponentTransfer>
          <feFlood floodColor="#fff" result="w" />
          <feComposite in="w" in2="t" operator="in" result="mask" />
          <feGaussianBlur in="mask" stdDeviation={0.6} />
        </filter>
        <mask id={`m${id}`} maskUnits="userSpaceOnUse" x={-20} y={-20} width={SIZE + 40} height={SIZE + 40}>
          <g filter={`url(#f${id})`}>
            {blobs(t, period, count).map((b, i) => (
              <circle key={i} cx={b.x} cy={b.y} r={b.r} fill="#fff" />
            ))}
          </g>
        </mask>
      </defs>
      <rect width={SIZE} height={SIZE} fill={`url(#g${id})`} mask={`url(#m${id})`} />
    </svg>
  );
}
