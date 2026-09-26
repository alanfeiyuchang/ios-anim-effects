/** loading.progress-ring · 渐变进度环 (Loading+Progress.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { DemoHint, NumericText, Palette, alpha, fonts, useHaptics, type DemoProps } from "../../kit";
import { GradientArc, TrimCircle, angular, primary, simulateProgress, useAnimatedNumber, useTask } from "./shared";

const SIZE = 170;
const COLORS = [Palette.mint, Palette.sky, Palette.blue, Palette.violet];

export default function ProgressRing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [run, setRun] = useState(0);
  const progress = useAnimatedNumber(0);

  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    await simulateProgress(task, ctx.n("speed"), progress);
    if (live) haptics.success();
    await task.sleep(1.4);
    if (ctx.isPreview) setRun((r) => r + 1);
  });

  const p = progress.value;
  const done = progress.target.current >= 1;
  const percent = Math.round(progress.target.current * 100);
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: SIZE, height: SIZE }}>
        <Ring progress={p} lineWidth={ctx.n("width")} glow={ctx.b("glow")} />
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2 }}>
          <div style={{ display: "flex", alignItems: "baseline", gap: 1, fontFamily: fonts.rounded }}>
            <span style={{ fontSize: 44, lineHeight: "52px", fontWeight: 700 }}>
              <NumericText value={percent} />
            </span>
            <span style={{ fontSize: 20, fontWeight: 600, color: Palette.secondaryLabel }}>%</span>
          </div>
          <div style={{ display: "grid", fontSize: 13, lineHeight: "18px", fontWeight: 500 }}>
            <AnimatePresence initial={false}>
              <motion.span
                key={done ? "done" : "sync"}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.35 }}
                style={{ gridArea: "1 / 1", textAlign: "center", color: done ? Palette.green : Palette.secondaryLabel }}
              >
                {done ? ctx.t("Complete", "已完成") : ctx.t("Syncing", "同步中")}
              </motion.span>
            </AnimatePresence>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to restart" zh="点击重新开始" />
    </div>
  );
}

function Ring({ progress, lineWidth, glow }: { progress: number; lineWidth: number; glow: boolean }) {
  const clamped = Math.min(Math.max(progress, 0), 1);
  const sweep = Math.max(clamped, 0.002) * 360;
  const r = SIZE / 2;
  const visible = clamped > 0.001 ? 1 : 0;
  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <TrimCircle size={SIZE} lineWidth={lineWidth} color={primary(0.08)} />
      <GradientArc
        size={SIZE}
        lineWidth={lineWidth}
        from={0}
        to={clamped}
        cap="butt"
        background={angular(COLORS, 0, sweep)}
        rotate={-90}
        style={{ filter: `drop-shadow(0 0 ${lineWidth * 0.9}px ${alpha(Palette.sky, glow ? 0.55 : 0)})` }}
      />
      <div style={{ position: "absolute", left: r - lineWidth / 2, top: -lineWidth / 2, width: lineWidth, height: lineWidth, borderRadius: "50%", background: COLORS[0], opacity: visible }} />
      <div style={{ position: "absolute", inset: 0, transform: `rotate(${sweep}deg)`, opacity: visible }}>
        <div
          style={{
            position: "absolute",
            left: r - lineWidth / 2,
            top: -lineWidth / 2,
            width: lineWidth,
            height: lineWidth,
            borderRadius: "50%",
            background: COLORS[3],
            display: "grid",
            placeItems: "center",
          }}
        >
          <div style={{ width: lineWidth * 0.5, height: lineWidth * 0.5, borderRadius: "50%", background: "#fff", boxShadow: "0 0 2px rgb(0 0 0 / 0.25)" }} />
        </div>
      </div>
    </div>
  );
}
