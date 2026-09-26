/** charts.bar-grow · 柱状图错峰生长 (Charts+BarGrow.swift) */
import { animate, motion, useMotionValue, useTransform, type MotionValue, type Transition } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, delayed, demoCard, fonts, spring, useAutoplay, useTimeouts, type DemoProps } from "../../kit";
import { randomInt, swiftCharts, useChartEntrance } from "./_shared";

const weekdaysEN = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const weekdaysZH = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
const barSeed = [46, 72, 58, 94, 67, 38, 81];

const CHART_W = 264;
const CHART_H = 190;
/** Plot height above the x-axis label row (measured from the app). */
const PLOT_H = 174;
const DOMAIN = 110;
const BAND = CHART_W / 7;
const BAR_W = BAND * 0.62;

export default function BarGrow({ ctx }: DemoProps) {
  const { after } = useTimeouts();
  const [values, setValues] = useState(barSeed);
  const [shown, setShown] = useState<boolean[]>(() => barSeed.map(() => false));
  const [total, setTotal] = useState(barSeed.reduce((a, b) => a + b, 0));
  const generation = useRef(0);
  // The animated bar value (what Swift Charts interpolates: `shown ? value : 0`).
  const m0 = useMotionValue(0), m1 = useMotionValue(0), m2 = useMotionValue(0), m3 = useMotionValue(0);
  const m4 = useMotionValue(0), m5 = useMotionValue(0), m6 = useMotionValue(0);
  const mvs = [m0, m1, m2, m3, m4, m5, m6];

  const play = () => {
    setShown(barSeed.map(() => false));
    mvs.forEach((mv) => animate(mv, 0, anim.easeIn(0.18)));
    generation.current += 1;
    const current = generation.current;
    after(0.22, () => {
      if (current !== generation.current) return;
      const next = Array.from({ length: 7 }, () => randomInt(28, 100));
      setValues(next);
      setTotal(next.reduce((a, b) => a + b, 0));
      setShown(next.map(() => true));
      const stagger = ctx.n("stagger");
      const sp = spring(ctx.n("response"), ctx.n("damping"));
      next.forEach((v, i) => animate(mvs[i], v, delayed(sp, i * stagger)));
    });
  };

  useChartEntrance(play);
  useAutoplay(ctx.isPreview, play, { every: 3.2, delay: 3.2, intro: false });

  const labels = ctx.lang === "zh" ? weekdaysZH : weekdaysEN;
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div onClick={play} style={{ ...demoCard(), width: 300, padding: 18, display: "flex", flexDirection: "column", gap: 14, cursor: "pointer" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("Weekly activity", "本周活跃")}</div>
          <NumericText value={total} style={{ fontFamily: fonts.rounded, fontSize: 28, lineHeight: "34px", fontWeight: 700 }} />
        </div>
        <div style={{ position: "relative", width: CHART_W, height: CHART_H }}>
          <svg width={CHART_W} height={PLOT_H} style={{ position: "absolute", left: 0, top: 0, overflow: "visible" }}>
            {[0, 25, 50, 75, 100].map((v) => {
              const y = PLOT_H * (1 - v / DOMAIN);
              return <line key={v} x1={0} x2={CHART_W} y1={y} y2={y} stroke={swiftCharts.grid} strokeWidth={0.5} strokeDasharray="3 4" />;
            })}
          </svg>
          {mvs.map((mv, i) => (
            <Bar key={i} index={i} mv={mv} value={values[i]} shown={shown[i]} appear={delayed(spring(ctx.n("response"), ctx.n("damping")), i * ctx.n("stagger"))} />
          ))}
          {labels.map((label, i) => (
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
                whiteSpace: "nowrap",
              }}
            >
              {label}
            </div>
          ))}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to replay" zh="点击重播" style={{ position: "absolute", left: 0, right: 0, bottom: 8 }} />
    </div>
  );
}

function Bar({ index, mv, value, shown, appear }: { index: number; mv: MotionValue<number>; value: number; shown: boolean; appear: Transition }) {
  const height = useTransform(mv, (v) => Math.max(0, (v / DOMAIN) * PLOT_H));
  const labelBottom = useTransform(height, (h) => CHART_H - PLOT_H + h + 4);
  const shownValue = shown ? value : 0;
  return (
    <>
      <motion.div
        style={{
          position: "absolute",
          left: index * BAND + (BAND - BAR_W) / 2,
          width: BAR_W,
          bottom: CHART_H - PLOT_H,
          height,
          borderRadius: 6,
          background: `linear-gradient(180deg, ${Palette.sky}, ${Palette.indigo})`,
        }}
      />
      <motion.div
        animate={{ opacity: shown ? 1 : 0 }}
        transition={shown ? appear : anim.easeIn(0.18)}
        style={{
          position: "absolute",
          left: index * BAND,
          width: BAND,
          bottom: labelBottom,
          display: "flex",
          justifyContent: "center",
          fontFamily: fonts.rounded,
          fontSize: 10,
          lineHeight: "12px",
          fontWeight: 600,
          color: Palette.secondaryLabel,
        }}
      >
        <NumericText value={shownValue} />
      </motion.div>
    </>
  );
}
