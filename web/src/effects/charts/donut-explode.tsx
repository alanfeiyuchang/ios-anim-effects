/** charts.donut-explode · 环形图展开与弹出 (Charts+Donut.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useId, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, delayed, fonts, localPoint, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { useAnimatedNumbers, useChartEntrance } from "./_shared";

const slices = [
  { en: "Design", zh: "设计", value: 34, color: Palette.indigo, rgb: "110,123,255" },
  { en: "Engineering", zh: "研发", value: 24, color: Palette.pink, rgb: "255,95,162" },
  { en: "Marketing", zh: "市场", value: 18, color: Palette.amber, rgb: "255,194,71" },
  { en: "Support", zh: "支持", value: 14, color: Palette.mint, rgb: "33,212,168" },
  { en: "Other", zh: "其他", value: 10, color: Palette.sky, rgb: "58,196,255" },
];
const total = slices.reduce((a, s) => a + s.value, 0);
const DIAMETER = 190;
const SIDE = 250;
const C = SIDE / 2;

function bounds(index: number) {
  let start = 0;
  for (let i = 0; i < index; i++) start += slices[i].value / total;
  return { start, end: start + slices[index].value / total };
}

const selectSpring = spring(0.38, 0.72);

export default function DonutExplode({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const uid = useId().replace(/:/g, "");
  const grow = useAnimatedNumbers(slices.length, 0);
  const intro = useAnimatedNumbers(1, 0);
  const [selected, setSelected] = useState<number | null>(null);
  const selectedRef = useRef<number | null>(null);
  const autoStep = useRef(0);

  const select = (index: number | null) => {
    if (index !== selectedRef.current) haptics.selection();
    selectedRef.current = index;
    setSelected(index);
  };

  const sweepIn = () => {
    intro.to(0, 1, spring(0.9, 0.85));
    slices.forEach((_, i) => grow.to(i, 1, delayed(spring(ctx.n("response"), 0.8), i * ctx.n("stagger"))));
  };

  const cycle = () => {
    autoStep.current += 1;
    const step = autoStep.current % (slices.length + 1);
    select(step < slices.length ? step : null);
  };

  useChartEntrance(sweepIn);
  useAutoplay(ctx.isPreview, cycle, { every: 1.5, delay: 1.6, intro: false });

  const lineWidth = ctx.n("thickness");
  const handleTap = (e: React.PointerEvent<HTMLDivElement>) => {
    const p = localPoint(e, e.currentTarget);
    const dx = p.x - C;
    const dy = p.y - C;
    const radius = Math.hypot(dx, dy);
    if (!(radius > DIAMETER / 2 - lineWidth && radius < DIAMETER / 2 + lineWidth + 16)) {
      select(null);
      return;
    }
    let fraction = (Math.atan2(dy, dx) + Math.PI / 2) / (2 * Math.PI);
    if (fraction < 0) fraction += 1;
    const hit = slices.findIndex((_, i) => {
      const r = bounds(i);
      return fraction >= r.start && fraction < r.end;
    });
    const h = hit < 0 ? null : hit;
    select(h === selectedRef.current ? null : h);
  };

  const rotation = -90 - 60 * (1 - intro.get(0));
  const number = selected !== null ? (slices[selected].value / total) * 100 : total;
  const suffix = selected === null ? "k" : "%";
  const name = selected !== null ? ctx.t(slices[selected].en, slices[selected].zh) : ctx.t("Total budget", "总预算");

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10 }}>
      <div onPointerUp={handleTap} style={{ position: "relative", width: SIDE, height: SIDE, cursor: "pointer" }}>
        <svg width={SIDE} height={SIDE} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <defs>
            {slices.map((s, i) => (
              <linearGradient key={i} id={`${uid}g${i}`} x1="0" y1={C - DIAMETER / 2} x2="0" y2={C + DIAMETER / 2} gradientUnits="userSpaceOnUse">
                <stop offset="0" stopColor={`color-mix(in srgb, ${s.color} 82%, white)`} />
                <stop offset="1" stopColor={s.color} />
              </linearGradient>
            ))}
          </defs>
          {slices.map((s, index) => {
            const range = bounds(index);
            const gap = (lineWidth / 2 + 3) / (Math.PI * DIAMETER);
            const from = range.start + gap;
            const full = Math.max(range.end - gap - from, 0.001);
            const g = grow.get(index);
            const isSelected = selected === index;
            const mid = ((range.start + range.end) / 2) * 2 * Math.PI - Math.PI / 2;
            const distance = isSelected ? ctx.n("explode") : 0;
            const dimmed = selected !== null && !isSelected;
            return (
              <motion.g
                key={index}
                initial={false}
                animate={{
                  x: Math.cos(mid) * distance,
                  y: Math.sin(mid) * distance,
                  opacity: dimmed ? 0.35 : 1,
                  filter: `drop-shadow(0px 6px 12px rgba(${s.rgb},${isSelected ? 0.45 : 0}))`,
                }}
                transition={selectSpring}
              >
                <g transform={`rotate(${rotation} ${C} ${C})`} opacity={g > 0.001 ? 1 : 0}>
                  <motion.circle
                    cx={C}
                    cy={C}
                    r={DIAMETER / 2}
                    fill="none"
                    stroke={`url(#${uid}g${index})`}
                    strokeLinecap="round"
                    pathLength={1}
                    strokeDasharray={`${full * g} 2`}
                    strokeDashoffset={-from}
                    initial={false}
                    animate={{ strokeWidth: isSelected ? lineWidth + 8 : lineWidth }}
                    transition={selectSpring}
                  />
                </g>
              </motion.g>
            );
          })}
        </svg>
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2, pointerEvents: "none" }}>
          <NumericText
            value={Math.round(number)}
            text={`${Math.round(number)}${suffix}`}
            style={{ fontFamily: fonts.rounded, fontSize: 30, lineHeight: "36px", fontWeight: 700 }}
          />
          <div style={{ position: "relative", height: 16, display: "grid", placeItems: "center" }}>
            <AnimatePresence initial={false} mode="popLayout">
              <motion.div
                key={name}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={selectSpring}
                style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel, whiteSpace: "nowrap" }}
              >
                {name}
              </motion.div>
            </AnimatePresence>
          </div>
        </div>
      </div>
      <div style={{ width: 300, display: "grid", gridTemplateColumns: "repeat(3, 1fr)", columnGap: 6, rowGap: 6 }}>
        {slices.map((s, index) => (
          <motion.button
            key={index}
            type="button"
            onClick={() => select(selected === index ? null : index)}
            initial={false}
            animate={{ opacity: selected === null || selected === index ? 1 : 0.4 }}
            transition={selectSpring}
            style={{ display: "flex", alignItems: "center", gap: 5, fontSize: 11, lineHeight: "13px", fontWeight: 600, justifySelf: "start", whiteSpace: "nowrap" }}
          >
            <span style={{ width: 8, height: 8, borderRadius: "50%", background: s.color, flexShrink: 0 }} />
            <span style={{ color: Palette.label }}>{ctx.t(s.en, s.zh)}</span>
            <span style={{ color: Palette.secondaryLabel, fontVariantNumeric: "tabular-nums" }}>{Math.round((s.value / total) * 100)}%</span>
          </motion.button>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap a segment" zh="点击某一分段" />
    </div>
  );
}
