/** loading.tooltip-bar · 摆动气泡进度条 (Loading+BarVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Check, Film } from "lucide-react";
import { useState } from "react";
import { DemoHint, NumericText, Palette, cubicBezier, demoCard, mix, spring, springAt, useHaptics, type DemoProps } from "../../kit";
import { barVarSimulate } from "./bar-shared";
import { primary, useAnimatedNumber, useTask, useTriggerElapsed } from "./shared";

const W = 250;
/** The ZStack is as tall as its tallest fixed child (the 30 pt bubble + its 8 pt caret), and the
 *  capsules stretch to it, while the row only takes its 6 pt frame in the card's layout. */
const BAR_H = 38;
const cubic = cubicBezier(0.42, 0, 0.58, 1);

export default function TooltipBar({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [run, setRun] = useState(0);
  const [steps, setSteps] = useState(0);
  const progress = useAnimatedNumber(0);
  const zh = ctx.lang === "zh";

  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    setSteps(0);
    await barVarSimulate(task, ctx.n("speed"), () => progress.target.current, progress.to, () => setSteps((s) => s + 1));
    if (live) haptics.success();
    await task.sleep(1.6);
    if (ctx.isPreview) setRun((r) => r + 1);
  });

  const model = progress.target.current;
  const done = model >= 1;
  const x = W * Math.min(Math.max(progress.value, 0), 1);
  const bx = Math.min(Math.max(x, 18), W - 18);
  const caretShift = x - bx;
  const swing = ctx.n("swing");
  const t = useTriggerElapsed(steps, 0.85);
  let angle = 0;
  if (t >= 0) {
    if (t < 0.12) angle = mix(0, -swing, cubic(t / 0.12));
    else if (t < 0.32) angle = mix(-swing, swing * 0.5, cubic((t - 0.12) / 0.2));
    else angle = mix(swing * 0.5, 0, springAt(t - 0.32, 0.5, 0.7));
  }
  const percent = Math.round(model * 100);
  const fill = done ? Palette.successStrong : Palette.indigo;

  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ ...demoCard(), padding: 18 }}>
        <div style={{ width: W, display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ height: 110, borderRadius: 14, background: Palette.sunset, display: "grid", placeItems: "center", color: "rgb(255 255 255 / 0.9)" }}>
            <Film size={38} strokeWidth={2.2} />
          </div>
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, paddingBottom: 40 }}>{zh ? "正在导出 · 4K 60fps" : "Exporting · 4K 60fps"}</span>
          <div style={{ position: "relative", width: W, height: 6 }}>
            <div style={{ position: "absolute", left: 0, top: 3 - BAR_H / 2, width: W, height: BAR_H, borderRadius: BAR_H / 2, background: primary(0.08) }} />
            <div style={{ position: "absolute", left: 0, top: 3 - BAR_H / 2, width: Math.max(6, x), height: BAR_H, borderRadius: BAR_H / 2, background: Palette.sunset }} />
            <div style={{ position: "absolute", left: x - 8, top: 3 - 8, width: 16, height: 16, borderRadius: "50%", background: "#fff", boxShadow: "0 1px 3px rgb(0 0 0 / 0.25)" }} />
            <div
              style={{
                position: "absolute",
                left: bx - 27,
                top: 3 - BAR_H / 2 - 30,
                width: 54,
                height: BAR_H,
                transformOrigin: `${(0.5 + caretShift / 54) * 100}% 100%`,
                transform: `rotate(${angle}deg)`,
              }}
            >
              <motion.div
                initial={false}
                animate={{ scale: done ? 1.15 : 1 }}
                transition={spring(0.4, 0.55)}
                style={{ transformOrigin: `${(0.5 + caretShift / 54) * 100}% 100%`, display: "flex", flexDirection: "column", alignItems: "center" }}
              >
                <div style={{ position: "relative", width: 54, height: 30, borderRadius: 10, background: fill, color: "#fff", display: "grid", placeItems: "center", fontSize: 12, fontWeight: 700 }}>
                  <AnimatePresence initial={false}>
                    {done ? (
                      <motion.span key="check" initial={{ scale: 0, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0, opacity: 0 }} style={{ position: "absolute", display: "grid" }}>
                        <Check size={14} strokeWidth={4} />
                      </motion.span>
                    ) : (
                      <motion.span key="pct" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} style={{ position: "absolute" }}>
                        <NumericText value={percent} text={`${percent}%`} />
                      </motion.span>
                    )}
                  </AnimatePresence>
                </div>
                <svg width={10} height={8} viewBox="0 0 10 8" style={{ transform: `translate(${caretShift}px, -3px)` }}>
                  <path d="M1 0.5 H9 L5.6 7 Q5 8 4.4 7 Z" fill={fill} />
                </svg>
              </motion.div>
            </div>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to restart" zh="点击重新开始" />
    </div>
  );
}
