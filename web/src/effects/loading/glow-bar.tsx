/** loading.glow-bar · 辉光进度条 (Loading+Progress.swift) */
import { CloudUpload } from "lucide-react";
import { useState } from "react";
import { DemoHint, NumericText, Palette, demoCard, useClock, useHaptics, type DemoProps } from "../../kit";
import { previewFps, primary, simulateProgress, useAnimatedNumber, useTask } from "./shared";

const WIDTH = 250;

export default function GlowBar({ ctx }: DemoProps) {
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
  const percent = Math.round(progress.target.current * 100);
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22, cursor: "pointer" }}
    >
      <div style={{ ...demoCard(), padding: 22 }}>
        <div style={{ width: WIDTH, display: "flex", flexDirection: "column", gap: 14 }}>
          <div style={{ display: "flex", alignItems: "baseline", fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>
            <span style={{ display: "flex", alignItems: "center", gap: 7 }}>
              <CloudUpload size={18} strokeWidth={2.2} />
              {ctx.t("Uploading", "正在上传")}
            </span>
            <span style={{ flex: 1 }} />
            <span style={{ color: Palette.secondaryLabel }}>
              <NumericText value={percent} text={`${percent}%`} />
            </span>
          </div>
          <Track progress={p} height={ctx.n("height")} glow={ctx.n("glow")} preview={ctx.isPreview} />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to restart" zh="点击重新开始" />
    </div>
  );
}

function Track({ progress, height, glow, preview }: { progress: number; height: number; glow: number; preview: boolean }) {
  useClock(true, previewFps(preview));
  const fill = Math.max(height, WIDTH * progress);
  const t = performance.now() / 1000;
  const x = ((t / 1.6) % 1) * 3 - 1;
  const a = (x - 0.5) * fill;
  const sheen = `linear-gradient(90deg, rgb(255 255 255 / 0) ${a}px, rgb(255 255 255 / 0.55) ${a + fill * 0.5}px, rgb(255 255 255 / 0) ${a + fill}px)`;
  return (
    <div style={{ position: "relative", width: WIDTH, height, opacity: progress > 0.001 ? 1 : 0.6 }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: height / 2, background: primary(0.08) }} />
      <div style={{ position: "absolute", left: 0, top: 0, width: fill, height, borderRadius: height / 2, background: Palette.aurora, filter: `blur(${glow}px)`, opacity: 0.75 }} />
      <div style={{ position: "absolute", left: 0, top: 0, width: fill, height, borderRadius: height / 2, background: `${sheen}, ${Palette.aurora}`, overflow: "hidden" }} />
    </div>
  );
}
