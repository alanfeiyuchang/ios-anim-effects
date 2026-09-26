/** loading.segment-bar · LED 分段进度条 (Loading+BarVariations.swift) */
import { motion } from "motion/react";
import { HardDrive } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, demoCard, spring, useHaptics, type DemoProps } from "../../kit";
import { BarVarHeader, barVarSimulate, stopColor } from "./bar-shared";
import { primary, useTask } from "./shared";

const STOPS = [0x21d4a8, 0x3ac4ff, 0x6e7bff];

export default function SegmentBar({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [progress, setProgress] = useState(0);
  const [run, setRun] = useState(0);
  const [flash, setFlash] = useState<null | "in" | "out">(null);
  const model = useRef(0);
  const count = Math.max(ctx.i("count"), 2);
  const lit = Math.floor(progress * count);
  const zh = ctx.lang === "zh";

  // One tick per newly lit cell, 30 ms apart; only a run the user restarted ticks.
  const lastLit = useRef(lit);
  useEffect(() => {
    const old = lastLit.current;
    lastLit.current = lit;
    if (!(lit > old && !ctx.isPreview && run > 0)) return;
    const ids: number[] = [];
    for (let k = 0; k < lit - old; k++) ids.push(window.setTimeout(() => haptics.selection(), k * 30));
    return () => ids.forEach(clearTimeout);
  }, [lit, ctx.isPreview, run, haptics]);

  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    setFlash(null);
    await barVarSimulate(
      task,
      ctx.n("speed"),
      () => model.current,
      (v) => {
        model.current = v;
        setProgress(v);
      },
    );
    await task.sleep(0.4);
    setFlash("in");
    if (live) haptics.success();
    await task.sleep(0.35);
    setFlash("out");
    await task.sleep(1.2);
    if (ctx.isPreview) setRun((r) => r + 1);
  });

  const flashing = flash === "in";
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 20, cursor: "pointer" }}
    >
      <div style={{ ...demoCard(), padding: 20 }}>
        <div style={{ width: 262, display: "flex", flexDirection: "column", gap: 16 }}>
          <BarVarHeader icon={HardDrive} title={zh ? "正在备份" : "Backing up"} value={progress} done={progress >= 1} />
          <div style={{ display: "flex", alignItems: "center", gap: 3, height: 24 }}>
            {Array.from({ length: count }, (_, index) => {
              const on = index < lit;
              const head = on && index === lit - 1;
              const color = stopColor(STOPS, index / Math.max(count - 1, 1));
              const glow = stopColor(STOPS, index / Math.max(count - 1, 1), head ? 0.7 : 0);
              return (
                <motion.div
                  key={index}
                  initial={false}
                  animate={{ height: on ? 24 : 13 }}
                  transition={spring(0.32, ctx.n("damping"))}
                  style={{ flex: 1, position: "relative", borderRadius: 3, boxShadow: `0 0 6px ${glow}`, background: on ? color : primary(0.08) }}
                >
                  <div
                    style={{
                      position: "absolute",
                      inset: 0,
                      borderRadius: 3,
                      background: Palette.green,
                      opacity: flashing ? 1 : 0,
                      transition: flashing ? "opacity 0.25s cubic-bezier(0,0,0.58,1)" : "opacity 0.4s cubic-bezier(0.42,0,1,1)",
                    }}
                  />
                </motion.div>
              );
            })}
          </div>
          <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>iPhone · 12.4 GB</span>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to restart" zh="点击重新开始" />
    </div>
  );
}
