/** loading.candy-stripes · 糖果条纹进度条 (Loading+BarVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Sparkles } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, anim, demoCard, spring, useClock, useHaptics, type DemoProps } from "../../kit";
import { barVarSimulate } from "./bar-shared";
import { previewFps, primary, useAnimatedNumber, useTask } from "./shared";

const W = 250;
const SPACING = 16;

function stepText(p: number, zh: boolean) {
  if (p >= 1) return zh ? "安装完成" : "Installed";
  if (p < 0.3) return zh ? "正在验证…" : "Verifying…";
  if (p < 0.8) return zh ? "正在移动文件…" : "Moving files…";
  return zh ? "正在清理…" : "Cleaning up…";
}

export default function CandyStripes({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [run, setRun] = useState(0);
  const [pulse, setPulse] = useState(false);
  const [pulseT, setPulseT] = useState(spring(0.25, 0.5));
  const progress = useAnimatedNumber(0);
  const zh = ctx.lang === "zh";

  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    setPulse(false);
    await barVarSimulate(task, ctx.n("speed"), () => progress.target.current, progress.to);
    await task.sleep(0.3);
    setPulseT(spring(0.25, 0.5));
    setPulse(true);
    if (live) haptics.success();
    await task.sleep(0.25);
    setPulseT(spring(0.4, 0.7));
    setPulse(false);
    await task.sleep(1.6);
    if (ctx.isPreview) setRun((r) => r + 1);
  });

  const model = progress.target.current;
  const done = model >= 1;
  const height = ctx.n("height");
  const fillWidth = Math.max(height, W * Math.min(Math.max(progress.value, 0), 1));
  const text = stepText(model, zh);

  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ ...demoCard(), padding: 20 }}>
        <div style={{ width: W, display: "flex", flexDirection: "column", gap: 16 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 11, background: Palette.primary, display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
              <Sparkles size={21} fill="currentColor" strokeWidth={1.6} />
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "正在安装 Motion Pro" : "Installing Motion Pro"}</span>
              <span style={{ display: "grid", fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>
                <AnimatePresence initial={false}>
                  <motion.span key={text} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={anim.easeInOut(0.25)} style={{ gridArea: "1 / 1" }}>
                    {text}
                  </motion.span>
                </AnimatePresence>
              </span>
            </div>
          </div>
          <motion.div initial={false} animate={{ scaleY: pulse ? 1.08 : 1 }} transition={pulseT} style={{ position: "relative", width: W, height }}>
            <div style={{ position: "absolute", inset: 0, borderRadius: height / 2, background: primary(0.08) }} />
            <div style={{ position: "absolute", left: 0, top: 0, width: fillWidth, height, borderRadius: height / 2, overflow: "hidden", background: Palette.primary }}>
              <Stripes done={done} march={Math.max(ctx.n("march"), 0.1)} fps={previewFps(ctx.isPreview)} />
              <div style={{ position: "absolute", inset: 0, background: Palette.green, opacity: done ? 1 : 0, transition: "opacity 0.4s cubic-bezier(0.42,0,0.58,1)" }} />
            </div>
          </motion.div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to restart" zh="点击重新开始" />
    </div>
  );
}

/** Diagonal 8 pt stripes every 16 pt (each leaning one bar-height to the right), marching one period per `march` s. */
function Stripes({ done, march, fps }: { done: boolean; march: number; fps?: number }) {
  useClock(!done, fps);
  const t = performance.now() / 1000;
  const phase = (t / march) % 1;
  const period = SPACING / Math.SQRT2;
  return (
    <div
      style={{
        position: "absolute",
        left: -SPACING * 2,
        top: 0,
        bottom: 0,
        width: W + SPACING * 4,
        opacity: done ? 0 : 1,
        transition: "opacity 0.4s cubic-bezier(0.42,0,0.58,1)",
        background: `repeating-linear-gradient(135deg, rgb(255 255 255 / 0.22) 0 ${period / 2}px, transparent ${period / 2}px ${period}px)`,
        transform: `translateX(${phase * SPACING}px)`,
      }}
    />
  );
}
