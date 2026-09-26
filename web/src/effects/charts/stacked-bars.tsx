/** charts.stacked-bars · 堆叠柱重新堆叠 (Charts+StackedBars.swift) */
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, delayed, demoCard, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { swiftCharts, useAnimatedNumbers, useChartEntrance } from "./_shared";

const series = [
  { en: "Subscriptions", zh: "订阅", color: Palette.indigo },
  { en: "In-app", zh: "应用内购", color: Palette.pink },
  { en: "Ads", zh: "广告", color: Palette.amber },
];

/** Revenue in $k per month (rows) and series (columns). */
const stackData = [
  [8.2, 4.1, 2.0],
  [9.0, 4.6, 2.4],
  [10.1, 4.2, 2.9],
  [11.4, 5.3, 2.6],
  [12.2, 6.0, 3.1],
  [13.5, 6.4, 3.4],
];
const monthsEN = ["Apr", "May", "Jun", "Jul", "Aug", "Sep"];
const monthsZH = ["4月", "5月", "6月", "7月", "8月", "9月"];

const CHART_W = 274;
const CHART_H = 170;
/** Plot area (measured from the app): trailing y labels take 28 pt, the x label row 18 pt. */
const PLOT_W = 246;
const PLOT_H = 152;
const DOMAIN = 25;
const BAND = PLOT_W / stackData.length;
const BAR_W = BAND * 0.58;

export default function StackedBars({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [visible, setVisible] = useState([true, true, true]);
  const [grown, setGrown] = useState(stackData.map(() => 0));
  const grow = useAnimatedNumbers(stackData.length, 0);
  const vis = useAnimatedNumbers(series.length, 1);
  const riseGeneration = useRef(0);
  const autoIndex = useRef(0);
  const visibleRef = useRef(visible);
  visibleRef.current = visible;

  const sp = () => spring(ctx.n("response"), ctx.n("damping"));

  const setVisibility = (index: number, on: boolean) => {
    const next = [...visibleRef.current];
    next[index] = on;
    visibleRef.current = next;
    setVisible(next);
    vis.to(index, on ? 1 : 0, sp());
  };

  const toggle = (index: number) => {
    const current = visibleRef.current;
    // Keep at least one series visible so the chart never empties.
    if (current[index] && current.filter(Boolean).length <= 1) {
      haptics.error();
      return;
    }
    haptics.selection();
    setVisibility(index, !current[index]);
  };

  const staggerRise = () => {
    setGrown(stackData.map(() => 1));
    stackData.forEach((_, m) => grow.to(m, 1, delayed(sp(), m * ctx.n("stagger"))));
  };

  const rise = () => {
    riseGeneration.current += 1;
    staggerRise();
  };

  const replayRise = () => {
    riseGeneration.current += 1;
    const generation = riseGeneration.current;
    setGrown(stackData.map(() => 0));
    stackData.forEach((_, m) => grow.to(m, 0, anim.easeIn(0.18)));
    after(0.2, () => {
      if (generation !== riseGeneration.current) return;
      staggerRise();
    });
  };

  const toggleAndRestore = () => {
    const index = autoIndex.current % series.length;
    autoIndex.current += 1;
    setVisibility(index, false);
    after(1.1, () => setVisibility(index, true));
  };

  useChartEntrance(rise);
  useAutoplay(ctx.isPreview, toggleAndRestore, { every: 2.4, delay: 1.2, intro: false });

  // The header reads the model (final) values, rolling with a numeric transition like the app.
  let total = 0;
  stackData.forEach((row, m) => row.forEach((v, s) => visible[s] && (total += v * grown[m])));
  const months = ctx.lang === "zh" ? monthsZH : monthsEN;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ ...demoCard(), width: 310, padding: 18, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel }}>
            {ctx.t("Revenue by channel · 6 months", "各渠道营收 · 近 6 个月")}
          </div>
          <NumericText value={total} text={`$${total.toFixed(1)}k`} style={{ fontFamily: fonts.rounded, fontSize: 26, lineHeight: "31px", fontWeight: 700 }} />
        </div>
        <div onClick={replayRise} style={{ position: "relative", width: CHART_W, height: CHART_H, cursor: "pointer" }}>
          <svg width={CHART_W} height={CHART_H} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
            {/* x axis: gridlines and ticks on the band edges, running down through the label row */}
            {Array.from({ length: stackData.length + 1 }, (_, i) => (
              <line key={`x${i}`} x1={i * BAND} x2={i * BAND} y1={0} y2={CHART_H} stroke={swiftCharts.grid} strokeWidth={0.5} strokeDasharray="2 2" />
            ))}
            {[0, 5, 10, 15, 20, 25].map((v) => {
              const y = PLOT_H * (1 - v / DOMAIN);
              return (
                <g key={v}>
                  <line x1={0} x2={PLOT_W} y1={y} y2={y} stroke={swiftCharts.grid} strokeWidth={0.5} strokeDasharray="3 4" />
                  <text
                    x={PLOT_W + 4}
                    y={y}
                    dominantBaseline="central"
                    fill={Palette.secondaryLabel}
                    style={{ fontFamily: fonts.rounded, fontSize: 9, fontWeight: 600, fontVariantNumeric: "tabular-nums" }}
                  >
                    ${v}k
                  </text>
                </g>
              );
            })}
          </svg>
          {stackData.map((row, m) => {
            const g = grow.get(m);
            const heights = row.map((v, s) => Math.max(0, ((v * g * vis.get(s)) / DOMAIN) * PLOT_H));
            const stack = heights.reduce((a, b) => a + b, 0);
            let base = 0;
            return (
              <div
                key={m}
                style={{
                  position: "absolute",
                  left: m * BAND + (BAND - BAR_W) / 2,
                  width: BAR_W,
                  top: PLOT_H - stack,
                  height: stack,
                  borderRadius: 3,
                  overflow: "hidden",
                }}
              >
                {heights.map((h, s) => {
                  const bottom = base;
                  base += h;
                  return <div key={s} style={{ position: "absolute", left: 0, right: 0, bottom, height: h, background: series[s].color }} />;
                })}
              </div>
            );
          })}
          {months.map((label, i) => (
            <div
              key={i}
              style={{
                position: "absolute",
                left: i * BAND,
                width: BAND,
                top: PLOT_H + 3,
                textAlign: "center",
                fontSize: swiftCharts.labelSize,
                lineHeight: "13px",
                color: swiftCharts.labelColor,
              }}
            >
              {label}
            </div>
          ))}
        </div>
        <div style={{ display: "flex", gap: 6 }}>
          {series.map((s, index) => (
            <button
              key={index}
              type="button"
              onClick={() => toggle(index)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 5,
                padding: "6px 10px",
                borderRadius: 999,
                background: Palette.labelAlpha(visible[index] ? 0.07 : 0.03),
                opacity: visible[index] ? 1 : 0.45,
                transition: "opacity 0.3s, background 0.3s",
              }}
            >
              <span style={{ width: 8, height: 8, borderRadius: "50%", background: s.color }} />
              <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, whiteSpace: "nowrap", textDecoration: visible[index] ? "none" : "line-through" }}>
                {ctx.t(s.en, s.zh)}
              </span>
            </button>
          ))}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap a legend chip to toggle it" zh="点击图例开关系列" style={{ position: "absolute", left: 0, right: 0, bottom: 8 }} />
    </div>
  );
}
