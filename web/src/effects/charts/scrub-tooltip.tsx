/** charts.scrub-tooltip · 滑动查看数据提示 (Charts+Scrub.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useEffect, useId, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, clamp, demoCard, fonts, useAutoplay, useHaptics, usePan, useStageRuntime, useTimeouts, type DemoProps } from "../../kit";
import { swiftCharts } from "./_shared";

const scrubData = Array.from({ length: 24 }, (_, hour) => {
  const base = 42 + 26 * Math.sin(((hour - 7) / 24) * 2 * Math.PI) + 9 * Math.sin(hour * 1.3) + 5 * Math.cos(hour * 2.7);
  return Math.max(base, 8);
});

const CHART_W = 278;
const CHART_H = 170;
/** Plot height above the x-axis label row (y axis hidden). */
const PLOT_H = 154;
const DOMAIN = 95;
const px = (hour: number) => (hour / 23) * CHART_W;
const py = (value: number) => PLOT_H * (1 - value / DOMAIN);
const pad2 = (n: number) => String(n).padStart(2, "0");
const snappy = anim.snappyD(0.25);

type P = { x: number; y: number };

/** Swift Charts' `.catmullRom` (centripetal, like d3's curveCatmullRom). */
function catmullRom(pts: P[]): string {
  let d = `M${pts[0].x},${pts[0].y}`;
  const alpha = 0.5;
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] ?? pts[i];
    const p1 = pts[i];
    const p2 = pts[i + 1];
    const p3 = pts[i + 2] ?? p2;
    const l01 = Math.hypot(p1.x - p0.x, p1.y - p0.y);
    const l12 = Math.hypot(p2.x - p1.x, p2.y - p1.y);
    const l23 = Math.hypot(p3.x - p2.x, p3.y - p2.y);
    const l01a = l01 ** alpha, l01_2a = l01 ** (2 * alpha);
    const l12a = l12 ** alpha, l12_2a = l12 ** (2 * alpha);
    const l23a = l23 ** alpha, l23_2a = l23 ** (2 * alpha);
    let c1 = { ...p1 };
    let c2 = { ...p2 };
    if (l01a > 1e-9) {
      const a = 2 * l01_2a + 3 * l01a * l12a + l12_2a;
      const n = 3 * l01a * (l01a + l12a);
      c1 = { x: (p1.x * a - p0.x * l12_2a + p2.x * l01_2a) / n, y: (p1.y * a - p0.y * l12_2a + p2.y * l01_2a) / n };
    }
    if (l23a > 1e-9) {
      const b = 2 * l23_2a + 3 * l23a * l12a + l12_2a;
      const m = 3 * l23a * (l23a + l12a);
      c2 = { x: (p2.x * b + p1.x * l23_2a - p3.x * l12_2a) / m, y: (p2.y * b + p1.y * l23_2a - p3.y * l12_2a) / m };
    }
    d += ` C${c1.x},${c1.y} ${c2.x},${c2.y} ${p2.x},${p2.y}`;
  }
  return d;
}

function linePath(pts: P[], curve: number): string {
  if (curve === 1) return pts.map((p, i) => `${i ? "L" : "M"}${p.x},${p.y}`).join(" ");
  if (curve === 2) {
    // .stepCenter: the value changes halfway between two points.
    let d = `M${pts[0].x},${pts[0].y}`;
    for (let i = 1; i < pts.length; i++) {
      const mid = (pts[i - 1].x + pts[i].x) / 2;
      d += ` L${mid},${pts[i - 1].y} L${mid},${pts[i].y}`;
    }
    return `${d} L${pts[pts.length - 1].x},${pts[pts.length - 1].y}`;
  }
  return catmullRom(pts);
}

export default function ScrubTooltip({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const uid = useId().replace(/:/g, "");
  const { reduceMotion } = useStageRuntime();
  const { after, clearAll } = useTimeouts();
  const [selected, setSelectedState] = useState<number | null>(null);
  const [lastShown, setLastShown] = useState(0);
  const selectedRef = useRef<number | null>(null);
  const engaged = useRef(false);
  const selX = useMotionValue(0);
  const selY = useMotionValue(0);
  const tipRef = useRef<HTMLDivElement>(null);
  const tipX = useTransform(selX, (x) => {
    const w = tipRef.current?.offsetWidth ?? 50;
    return clamp(x - w / 2, 0, CHART_W - w);
  });

  const setSelected = (hour: number | null) => {
    const previous = selectedRef.current;
    if (hour === previous) return;
    selectedRef.current = hour;
    setSelectedState(hour);
    if (hour !== null) {
      setLastShown(hour);
      if (previous === null) {
        selX.jump(px(hour));
        selY.jump(py(scrubData[hour]));
      } else {
        animate(selX, px(hour), snappy);
        animate(selY, py(scrubData[hour]), snappy);
      }
      // Only a real finger ticks: the arrival sweep and previews stay silent.
      if (engaged.current) haptics.selection();
    }
  };

  const advance = () => {
    const next = (selectedRef.current ?? -1) + 1;
    setSelected(next < scrubData.length ? next : null);
  };

  // Detail arrival: glide the cursor once across the day, then clear it.
  useEffect(() => {
    if (ctx.isPreview || reduceMotion) return;
    let t = 0.7;
    for (let hour = 0; hour < scrubData.length; hour++) {
      after(t, () => setSelected(hour));
      t += 0.04;
    }
    after(t + 0.35, () => setSelected(null));
    return clearAll;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useAutoplay(ctx.isPreview, advance, { every: 0.32, delay: 0.5, intro: false });

  const endScrub = () => {
    if (!engaged.current) return;
    engaged.current = false;
    setSelected(null);
  };

  const pan = usePan(
    {
      onChange: ({ translation, location }) => {
        if (!engaged.current) {
          if (!(Math.abs(translation.x) > Math.abs(translation.y))) return;
          engaged.current = true;
          clearAll();
        }
        setSelected(clamp(Math.round((location.x / CHART_W) * 23), 0, 23));
      },
      onEnd: endScrub,
    },
    8,
  );

  const pts = scrubData.map((v, i) => ({ x: px(i), y: py(v) }));
  const curve = ctx.i("curve");
  const line = linePath(pts, curve);
  const area = `${line} L${CHART_W},${PLOT_H} L0,${PLOT_H} Z`;

  const value = selected !== null ? scrubData[selected] : scrubData[scrubData.length - 1];
  const label = selected !== null ? `${pad2(selected)}:00` : ctx.t("Now", "当前");
  const bpm = Math.round(value) + 40;
  const on = selected !== null;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ ...demoCard(), width: 310, padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel }}>
            {ctx.t(`Heart rate · ${label}`, `心率 · ${label}`)}
          </div>
          <div style={{ display: "flex", alignItems: "baseline", gap: 4 }}>
            <NumericText value={bpm} style={{ fontFamily: fonts.rounded, fontSize: 30, lineHeight: "36px", fontWeight: 700 }} />
            <span style={{ fontSize: 12, fontWeight: 700, color: Palette.pink }}>BPM</span>
          </div>
        </div>
        <div {...pan} style={{ ...pan.style, position: "relative", width: CHART_W, height: CHART_H, cursor: "ew-resize" }}>
          <svg width={CHART_W} height={PLOT_H} style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }}>
            <defs>
              <linearGradient id={`${uid}a`} x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor={Palette.blue} stopOpacity={0.32} />
                <stop offset="1" stopColor={Palette.blue} stopOpacity={0} />
              </linearGradient>
            </defs>
            {ctx.b("area") && <path d={area} fill={`url(#${uid}a)`} />}
            <path d={line} fill="none" stroke={Palette.blue} strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          <motion.div
            initial={false}
            animate={{ opacity: on ? 1 : 0 }}
            transition={snappy}
            style={{ position: "absolute", inset: 0, pointerEvents: "none" }}
          >
            <motion.div style={{ position: "absolute", top: 0, left: -0.5, x: selX, width: 1, height: PLOT_H }}>
              <svg width={1} height={PLOT_H} style={{ overflow: "visible" }}>
                <line x1={0.5} x2={0.5} y1={0} y2={PLOT_H} stroke={Palette.labelAlpha(0.3)} strokeWidth={1} strokeDasharray="3 3" />
              </svg>
            </motion.div>
            <motion.div ref={tipRef} style={{ position: "absolute", bottom: CHART_H + 4, left: 0, x: tipX }}>
              <Tooltip hour={lastShown} value={scrubData[lastShown] + 40} />
            </motion.div>
            <motion.div
              style={{
                position: "absolute",
                left: -5.5,
                top: -5.5,
                x: selX,
                y: selY,
                width: 11,
                height: 11,
                borderRadius: "50%",
                background: Palette.blue,
                boxShadow: `inset 0 0 0 2.5px #fff, 0 0 8px rgb(79 124 255 / 0.5)`,
              }}
            />
          </motion.div>
          {[0, 6, 12, 18].map((hour) => (
            <div
              key={hour}
              style={{
                position: "absolute",
                left: px(hour) + 4,
                top: PLOT_H + 3,
                fontSize: swiftCharts.labelSize,
                lineHeight: "13px",
                color: swiftCharts.labelColor,
                whiteSpace: "nowrap",
                pointerEvents: "none",
              }}
            >
              {pad2(hour)}:00
            </div>
          ))}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag across the chart" zh="在图表上左右滑动" style={{ position: "absolute", left: 0, right: 0, bottom: 8 }} />
    </div>
  );
}

function Tooltip({ hour, value }: { hour: number; value: number }) {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 1,
        padding: "5px 10px",
        borderRadius: 10,
        background: "color-mix(in srgb, var(--ml-background) 82%, transparent)",
        backdropFilter: "blur(24px) saturate(1.8)",
        WebkitBackdropFilter: "blur(24px) saturate(1.8)",
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 3px 12px rgb(0 0 0 / 0.12)`,
        whiteSpace: "nowrap",
      }}
    >
      <span style={{ fontSize: 10, lineHeight: "12px", fontWeight: 600, color: Palette.secondaryLabel }}>{pad2(hour)}:00</span>
      <span style={{ fontFamily: fonts.rounded, fontSize: 14, lineHeight: "17px", fontWeight: 700, fontVariantNumeric: "tabular-nums" }}>{Math.round(value)}</span>
    </div>
  );
}
