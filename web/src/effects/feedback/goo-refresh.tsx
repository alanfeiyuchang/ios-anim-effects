/** feedback.goo-refresh · 黏滴下拉刷新 (Feedback+RefreshVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { RotateCw } from "lucide-react";
import { Palette, spring, type DemoProps } from "../../kit";
import { RefreshVarHost, VarSpinner } from "./refresh-vars";

const MAX_REACH = 46;

export default function GooRefresh({ ctx }: DemoProps) {
  const stretch = ctx.n("stretch");
  const fps = ctx.isPreview ? 30 : undefined;
  return (
    <RefreshVarHost
      ctx={ctx}
      indicator={({ progress, refreshing }) => {
        const p = Math.min(Math.max(progress, 0), 1);
        const snapped = refreshing || progress >= 1;
        const t = spring(0.35, 0.55);
        return (
          <AnimatePresence initial={false}>
            {snapped ? (
              <motion.div key="spin" initial={{ scale: 0.4, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.4, opacity: 0 }} transition={t} style={{ position: "absolute", left: 137, top: 22, width: 26, height: 26 }}>
                <VarSpinner color={Palette.indigo} fps={fps} />
              </motion.div>
            ) : (
              <motion.div key="drop" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={t} style={{ position: "absolute", left: 120, top: 8, width: 60, height: 110, opacity: p > 0.05 ? 1 : 0 }}>
                <Drop p={p} stretch={stretch} />
                <div style={{ position: "absolute", left: 0, right: 0, top: 20 - 5 * p, display: "flex", justifyContent: "center", color: "#fff" }}>
                  <RotateCw size={14} strokeWidth={3} style={{ transform: `rotate(${p * 270}deg)` }} />
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        );
      }}
    />
  );
}

function Drop({ p, stretch }: { p: number; stretch: number }) {
  const cx = 30;
  const r1 = 16 - 5 * p;
  const r2 = 16 - 11 * p;
  const y1 = 16;
  const y2 = y1 + Math.min(stretch, MAX_REACH) * p;
  const mid = (y1 + y2) / 2;
  const neck = `M${cx - r1} ${y1} Q${cx - r2 * 0.5} ${mid} ${cx - r2} ${y2} L${cx + r2} ${y2} Q${cx + r2 * 0.5} ${mid} ${cx + r1} ${y1} Z`;
  return (
    <svg width={60} height={110} style={{ position: "absolute", inset: 0 }}>
      <defs>
        <linearGradient id="goo-grad" gradientUnits="userSpaceOnUse" x1={0} y1={0} x2={60} y2={110}>
          <stop offset="0" stopColor={Palette.indigo} />
          <stop offset="1" stopColor={Palette.violet} />
        </linearGradient>
      </defs>
      <g fill="url(#goo-grad)">
        <circle cx={cx} cy={y1} r={r1} />
        <circle cx={cx} cy={y2} r={r2} />
        <path d={neck} />
      </g>
    </svg>
  );
}
