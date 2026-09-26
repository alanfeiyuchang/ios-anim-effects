/** loading.ring-to-check · 进度环变对勾徽章 (Loading+RingVariations.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { File } from "lucide-react";
import { useState } from "react";
import { DemoHint, NumericText, Palette, anim, demoCard, fonts, spring, useHaptics, type DemoProps } from "../../kit";
import { ringVarSimulate } from "./bar-shared";
import { TrimCircle, primary, springSmooth, useAnimatedNumber, useTask } from "./shared";

type Phase = 0 | 1 | 2 | 3; // uploading, filled, checked, docked
const B = 140;

export default function RingToCheck({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [run, setRun] = useState(0);
  const [phase, setPhase] = useState<Phase>(0);
  const [t, setT] = useState<Transition>(springSmooth(0.5));
  const progress = useAnimatedNumber(0);
  const zh = ctx.lang === "zh";

  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    setT(springSmooth(0.5));
    setPhase(0);
    await ringVarSimulate(task, ctx.n("speed"), () => progress.target.current, progress.to);
    await task.sleep(0.2);
    setT(spring(0.4, 0.7));
    setPhase(1);
    await task.sleep(0.15);
    setT(anim.easeOut(0.35));
    setPhase(2);
    if (live) haptics.success();
    await task.sleep(ctx.n("hold"));
    if (ctx.b("dock")) {
      setT(springSmooth(0.55));
      setPhase(3);
    }
    await task.sleep(2.0);
    if (ctx.isPreview) setRun((r) => r + 1);
  });

  const filled = phase >= 1;
  const checked = phase >= 2;
  const docked = phase === 3;
  const percent = Math.round(progress.target.current * 100);
  const w = 52;
  const h = 40;
  const check = `M ${w * 0.04} ${h * 0.55} L ${w * 0.37} ${h - h * 0.04} L ${w - w * 0.03} ${h * 0.06}`;
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: 290, height: 170, display: "grid", placeItems: "center" }}>
        <AnimatePresence>
          {docked && (
            <motion.div
              key="row"
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: 20, opacity: 0 }}
              transition={t}
              style={{ gridArea: "1 / 1", ...demoCard(18), width: 270, height: 64, padding: "0 14px", display: "flex", alignItems: "center", gap: 12 }}
            >
              <div style={{ width: 32, height: 32 }} />
              <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
                <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>Report.pdf</span>
                <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{zh ? "已上传 · 2.4 MB" : "Uploaded · 2.4 MB"}</span>
              </div>
              <div style={{ flex: 1 }} />
              <File size={17} fill="currentColor" strokeWidth={1.4} color={Palette.secondaryLabel} />
            </motion.div>
          )}
        </AnimatePresence>
        <motion.div
          initial={false}
          animate={{ scale: docked ? 0.23 : 1, x: docked ? -108 : 0 }}
          transition={t}
          style={{ gridArea: "1 / 1", position: "relative", width: B, height: B }}
        >
          <TrimCircle size={B} lineWidth={10} color={primary(0.08)} />
          <svg width={B} height={B} style={{ position: "absolute", inset: 0, overflow: "visible", transform: "rotate(-90deg)" }}>
            {progress.value > 0.001 && (
              <circle cx={B / 2} cy={B / 2} r={B / 2} fill="none" stroke={Palette.sky} strokeWidth={10} strokeLinecap="round" pathLength={1} strokeDasharray={`${Math.min(progress.value, 1)} 2`} />
            )}
          </svg>
          <motion.div
            initial={false}
            animate={{ scale: filled ? 1.08 : 0.01, opacity: filled ? 1 : 0 }}
            transition={t}
            style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.green }}
          />
          <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
            <svg width={w} height={h} style={{ overflow: "visible" }}>
              <motion.path
                d={check}
                fill="none"
                stroke="#fff"
                strokeWidth={4}
                strokeLinecap="round"
                strokeLinejoin="round"
                initial={false}
                animate={{ pathLength: checked ? 1 : 0, opacity: checked ? 1 : 0 }}
                transition={{ pathLength: t, opacity: { duration: checked ? 0.05 : 0 } }}
              />
            </svg>
          </div>
          <AnimatePresence>
            {!filled && (
              <motion.div
                key="pct"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={t}
                style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", fontFamily: fonts.rounded, fontSize: 30, fontWeight: 700 }}
              >
                <NumericText value={percent} text={`${percent}%`} />
              </motion.div>
            )}
          </AnimatePresence>
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Tap to restart" zh="点击重新开始" />
    </div>
  );
}
