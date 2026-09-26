/** charts.heatmap-cascade · 热力图涟漪揭示 (Charts+Heatmap.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, clamp, delayed, demoCard, fonts, hex, localPoint, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { randomInt, useChartEntrance } from "./_shared";

const COLUMNS = 14;
const ROWS = 7;

function randomLevels(): number[] {
  return Array.from({ length: COLUMNS * ROWS }, () => {
    const r = Math.random();
    if (r < 0.28) return 0;
    if (r < 0.55) return 1;
    if (r < 0.75) return 2;
    if (r < 0.9) return 3;
    return 4;
  });
}
const heatTotal = (levels: number[]) => levels.reduce((a, l) => a + l * 7, 0) + 120;

function color(level: number): string {
  switch (level) {
    case 0:
      return Palette.labelAlpha(0.07);
    case 1:
      return hex(Palette.mint, 0.3);
    case 2:
      return hex(Palette.mint, 0.55);
    case 3:
      return hex(Palette.mint, 0.8);
    default:
      return Palette.mint;
  }
}

export default function HeatmapCascade({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [levels, setLevels] = useState(randomLevels);
  const [revealed, setRevealed] = useState(false);
  const [origin, setOrigin] = useState({ column: 0, row: 0 });
  const [total, setTotal] = useState(() => heatTotal(levels));
  const generation = useRef(0);

  const ripple = (column: number, row: number, refresh: boolean) => {
    setOrigin({ column, row });
    setRevealed(false);
    generation.current += 1;
    const current = generation.current;
    if (refresh) haptics.tap("light");
    after(0.22, () => {
      if (current !== generation.current) return;
      if (refresh) {
        const next = randomLevels();
        setLevels(next);
        setTotal(heatTotal(next));
      } else setTotal(heatTotal(levels));
      setRevealed(true);
    });
  };

  useChartEntrance(() => ripple(0, 0, false));
  useAutoplay(ctx.isPreview, () => ripple(randomInt(0, COLUMNS - 1), randomInt(0, ROWS - 1), true), { every: 3.0, delay: 2.6, intro: false });

  const onTap = (e: React.MouseEvent<HTMLDivElement>) => {
    const p = localPoint(e, e.currentTarget);
    // The hit area extends 8 pt around the grid; map to the nearest cell on the 20 pt pitch.
    const x = p.x - 8;
    const y = p.y - 8;
    const column = clamp(Math.floor((x + 2) / 20), 0, COLUMNS - 1);
    const row = clamp(Math.floor((y + 2) / 20), 0, ROWS - 1);
    ripple(column, row, true);
  };

  const radius = ctx.i("shape") === 1 ? 8 : 4;
  const reveal = spring(ctx.n("response"), ctx.n("damping"));
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ ...demoCard(), padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
          <NumericText value={total} style={{ fontFamily: fonts.rounded, fontSize: 24, lineHeight: "29px", fontWeight: 700 }} />
          <span style={{ fontSize: 12, fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("contributions", "次提交")}</span>
        </div>
        <div onClick={onTap} style={{ margin: -8, padding: 8, cursor: "pointer" }}>
          <div style={{ display: "grid", gridTemplateColumns: `repeat(${COLUMNS}, 16px)`, gap: 4 }}>
            {levels.map((level, i) => {
              const column = i % COLUMNS;
              const row = Math.floor(i / COLUMNS);
              const dx = column - origin.column;
              const dy = row - origin.row;
              const delay = Math.sqrt(dx * dx + dy * dy) * ctx.n("stagger");
              const isOrigin = dx === 0 && dy === 0;
              return (
                <motion.div
                  key={i}
                  initial={{ scale: 0.3, opacity: 0, boxShadow: "0 0 12px rgba(33,212,168,0)" }}
                  animate={{
                    scale: revealed ? 1 : 0.3,
                    opacity: revealed ? 1 : 0,
                    boxShadow: `0 0 12px rgba(33,212,168,${isOrigin && revealed ? 0.8 : 0})`,
                  }}
                  transition={revealed ? delayed(reveal, delay) : anim.easeOut(0.18)}
                  style={{ width: 16, height: 16, borderRadius: radius, background: color(level) }}
                />
              );
            })}
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap any cell" zh="点击任意格子" style={{ position: "absolute", left: 0, right: 0, bottom: 8 }} />
    </div>
  );
}
