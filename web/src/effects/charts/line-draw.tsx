/** charts.line-draw · 折线绘制与面积渐显 (Charts+LineDraw.swift) */
import { useId, useRef, useState } from "react";
import { DemoHint, Palette, anim, clamp, demoCard, fonts, useAutoplay, useTimeouts, type DemoProps } from "../../kit";
import { useAnimatedNumbers, useChartEntrance } from "./_shared";

const W = 290;
const H = 170;
const INSET = 14;

type P = { x: number; y: number };

function points(values: number[]): P[] {
  const step = W / (values.length - 1);
  return values.map((v, i) => ({ x: i * step, y: INSET + (1 - v) * (H - INSET * 2) }));
}

/** Catmull-Rom → Bézier controls, with mirrored phantom end points so x stays linear in t. */
function controls(pts: P[], i: number): [P, P] {
  const p1 = pts[i];
  const p2 = pts[i + 1];
  const p0 = i > 0 ? pts[i - 1] : { x: 2 * p1.x - p2.x, y: 2 * p1.y - p2.y };
  const p3 = i + 2 < pts.length ? pts[i + 2] : { x: 2 * p2.x - p1.x, y: 2 * p2.y - p1.y };
  return [
    { x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6 },
    { x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6 },
  ];
}

function linePath(pts: P[], smooth: boolean): string {
  let d = `M${pts[0].x},${pts[0].y}`;
  for (let i = 0; i < pts.length - 1; i++) {
    if (smooth) {
      const [c1, c2] = controls(pts, i);
      d += ` C${c1.x},${c1.y} ${c2.x},${c2.y} ${pts[i + 1].x},${pts[i + 1].y}`;
    } else d += ` L${pts[i + 1].x},${pts[i + 1].y}`;
  }
  return d;
}

function yAt(x: number, pts: P[], smooth: boolean): number {
  const step = pts[1].x - pts[0].x;
  const i = Math.min(Math.max(Math.floor(x / step), 0), pts.length - 2);
  const t = clamp((x - pts[i].x) / step);
  const a = pts[i].y;
  const d = pts[i + 1].y;
  if (!smooth) return a + (d - a) * t;
  const [c1, c2] = controls(pts, i);
  const mt = 1 - t;
  return mt * mt * mt * a + 3 * mt * mt * t * c1.y + 3 * mt * t * t * c2.y + t * t * t * d;
}

const datasets = [
  [0.22, 0.35, 0.3, 0.52, 0.46, 0.68, 0.6, 0.82, 0.9],
  [0.55, 0.42, 0.6, 0.38, 0.5, 0.72, 0.66, 0.58, 0.86],
  [0.15, 0.28, 0.5, 0.44, 0.7, 0.62, 0.78, 0.74, 0.95],
];

export default function LineDraw({ ctx }: DemoProps) {
  const { after } = useTimeouts();
  const progress = useAnimatedNumbers(1, 0);
  const [dataset, setDataset] = useState(0);
  const generation = useRef(0);

  const draw = () => progress.to(0, 1, anim.curve(0.65, 0, 0.35, 1, ctx.n("duration")));
  const replay = () => {
    progress.to(0, 0, anim.easeIn(0.25));
    generation.current += 1;
    const current = generation.current;
    after(0.3, () => {
      if (current !== generation.current) return;
      setDataset((d) => d + 1);
      draw();
    });
  };

  useChartEntrance(draw);
  useAutoplay(ctx.isPreview, replay, { every: ctx.n("duration") + 1.6, delay: ctx.n("duration") + 1.2, intro: false });

  const monthLabels = ctx.lang === "zh" ? ["1月", "3月", "5月", "7月", "9月"] : ["Jan", "Mar", "May", "Jul", "Sep"];
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div onClick={replay} style={{ ...demoCard(), padding: 16, display: "flex", flexDirection: "column", gap: 12, cursor: "pointer" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("Revenue", "营收")}</div>
          <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{ctx.t("Last 9 months", "近 9 个月")}</div>
        </div>
        <LineChartCanvas progress={progress.get(0)} values={datasets[dataset % datasets.length]} smooth={ctx.b("smooth")} showArea={ctx.b("area")} />
        <div style={{ position: "relative", width: W, height: 12, marginTop: -6 }}>
          {monthLabels.map((label, index) => (
            <div
              key={index}
              style={{
                position: "absolute",
                left: clamp(((W / 8) * index * 2), 12, W - 12) - 20,
                top: 0,
                width: 40,
                height: 12,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                whiteSpace: "nowrap",
                fontSize: 9,
                fontWeight: 600,
                color: Palette.secondaryLabel,
              }}
            >
              {label}
            </div>
          ))}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to redraw" zh="点击重新绘制" style={{ position: "absolute", left: 0, right: 0, bottom: 8 }} />
    </div>
  );
}

function LineChartCanvas({ progress, values, smooth, showArea }: { progress: number; values: number[]; smooth: boolean; showArea: boolean }) {
  const uid = useId().replace(/:/g, "");
  const pts = points(values);
  const p = clamp(progress);
  const tipX = p * W;
  const tipY = yAt(tipX, pts, smooth);
  const line = linePath(pts, smooth);
  const area = `${line} L${pts[pts.length - 1].x},${H} L${pts[0].x},${H} Z`;

  const normalized = 1 - (tipY - INSET) / (H - INSET * 2);
  const value = 8 + normalized * 18;
  // Keep the value pill (~52 pt wide) inside the chart so it never spills past the card edge.
  const pillHalf = 26;
  const pillShift = Math.max(0, pillHalf - tipX) + Math.min(0, W - pillHalf - tipX);

  return (
    <div style={{ position: "relative", width: W, height: H }}>
      {/* Four guides from the top (26k) to the bottom (8k), each labeled just above its line. */}
      {[0, 1, 2, 3].map((index) => {
        const y = INSET + index * ((H - INSET * 2 - 4) / 3 + 1);
        return (
          <div key={index} style={{ position: "absolute", left: 0, right: 0, top: y, height: 1, background: Palette.labelAlpha(0.07) }}>
            <span
              style={{
                position: "absolute",
                right: 0,
                bottom: 2,
                fontFamily: fonts.rounded,
                fontSize: 9,
                lineHeight: "11px",
                fontWeight: 600,
                fontVariantNumeric: "tabular-nums",
                color: Palette.tertiaryLabel,
              }}
            >
              ${26 - index * 6}k
            </span>
          </div>
        );
      })}
      <svg width={W} height={H} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        <defs>
          <linearGradient id={`${uid}a`} x1="0" y1="0" x2="0" y2={H} gradientUnits="userSpaceOnUse">
            <stop offset="0" stopColor={Palette.indigo} stopOpacity={0.35} />
            <stop offset="1" stopColor={Palette.indigo} stopOpacity={0} />
          </linearGradient>
          <linearGradient id={`${uid}l`} x1="0" y1="0" x2={W} y2="0" gradientUnits="userSpaceOnUse">
            <stop offset="0" stopColor={Palette.indigo} />
            <stop offset="0.5" stopColor={Palette.violet} />
            <stop offset="1" stopColor={Palette.pink} />
          </linearGradient>
          <clipPath id={`${uid}c`}>
            <rect x={0} y={-20} width={tipX} height={H + 40} />
          </clipPath>
        </defs>
        <g clipPath={`url(#${uid}c)`}>
          {showArea && <path d={area} fill={`url(#${uid}a)`} />}
          <path d={line} fill="none" stroke={`url(#${uid}l)`} strokeWidth={3} strokeLinecap="round" strokeLinejoin="round" />
        </g>
      </svg>
      <div style={{ position: "absolute", left: tipX, top: tipY, width: 0, height: 0, opacity: p > 0.01 ? 1 : 0 }}>
        <div style={{ position: "absolute", left: -13, top: -13, width: 26, height: 26, borderRadius: "50%", background: "rgb(164 107 255 / 0.25)" }} />
        <div style={{ position: "absolute", left: -5, top: -5, width: 10, height: 10, borderRadius: "50%", background: Palette.violet, boxShadow: "inset 0 0 0 2px #fff" }} />
        <div
          style={{
            position: "absolute",
            left: pillShift,
            top: -22,
            transform: "translate(-50%, -50%)",
            padding: "3px 6px",
            borderRadius: 999,
            background: Palette.violet,
            color: "#fff",
            whiteSpace: "nowrap",
            fontFamily: fonts.rounded,
            fontSize: 10,
            lineHeight: "12px",
            fontWeight: 700,
            fontVariantNumeric: "tabular-nums",
          }}
        >
          ${value.toFixed(1)}k
        </div>
      </div>
    </div>
  );
}
