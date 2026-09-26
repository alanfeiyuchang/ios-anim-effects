/** loading.square-grid · 形变方格 (Loading+Ambient.swift) */
import { motion } from "motion/react";
import { useId } from "react";
import { Palette, type DemoProps } from "../../kit";
import { previewFps, usePhase } from "./shared";

const CELL = 26;
const GAP = 8;
const SIDE = CELL * 3 + GAP * 2;

export default function SquareGrid({ ctx }: DemoProps) {
  const id = useId().replace(/:/g, "");
  const period = ctx.n("period");
  const stagger = ctx.n("stagger");
  const minScale = ctx.n("minScale");
  const t = usePhase(1 / Math.max(period, 0.1), previewFps(ctx.isPreview));
  const tiles = [];
  for (let row = 0; row < 3; row++) {
    for (let column = 0; column < 3; column++) {
      const phase = (t - ((row + column) * stagger) / Math.max(period, 0.1)) * 2 * Math.PI;
      const m = 0.5 - 0.5 * Math.cos(phase);
      const radius = 6 + (CELL / 2 - 6) * (1 - m);
      const scale = minScale + (1 - minScale) * m;
      const cx = column * (CELL + GAP) + CELL / 2;
      const cy = row * (CELL + GAP) + CELL / 2;
      tiles.push(
        <rect
          key={`${row}-${column}`}
          x={-CELL / 2}
          y={-CELL / 2}
          width={CELL}
          height={CELL}
          rx={radius}
          transform={`translate(${cx} ${cy}) rotate(${(1 - m) * 90}) scale(${scale})`}
        />,
      );
    }
  }
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ position: "relative", width: SIDE, height: SIDE }}>
        <motion.div
          animate={{ opacity: [0.25, 0.45] }}
          transition={{ duration: 1.6, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
          style={{ position: "absolute", left: SIDE / 2 - 85, top: SIDE / 2 - 85, width: 170, height: 170, borderRadius: "50%", background: Palette.aurora, filter: "blur(44px)" }}
        />
        <svg width={SIDE} height={SIDE} viewBox={`0 0 ${SIDE} ${SIDE}`} style={{ position: "absolute", inset: 0, overflow: "visible", transform: "scale(1.55)" }}>
          <defs>
            <linearGradient id={`g${id}`} x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Palette.mint} />
              <stop offset="0.5" stopColor={Palette.sky} />
              <stop offset="1" stopColor={Palette.violet} />
            </linearGradient>
            <clipPath id={`c${id}`}>{tiles}</clipPath>
          </defs>
          <rect width={SIDE} height={SIDE} fill={`url(#g${id})`} clipPath={`url(#c${id})`} />
        </svg>
      </div>
    </div>
  );
}
