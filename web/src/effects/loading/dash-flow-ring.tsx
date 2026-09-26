/** loading.dash-flow-ring · 流动虚线环 (Loading+RingVariations.swift) */
import { useId, useState } from "react";
import { DemoHint, NumericText, Palette, useClock, useHaptics, type DemoProps } from "../../kit";
import { popScale, ringVarSimulate } from "./bar-shared";
import { TrimCircle, arcPath, previewFps, primary, useAnimatedNumber, useTask, useTriggerElapsed } from "./shared";

const S = 160;
const R = S / 2;

export default function DashFlowRing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const id = useId().replace(/:/g, "");
  const [run, setRun] = useState(0);
  const [done, setDone] = useState(false);
  const [pops, setPops] = useState(0);
  const progress = useAnimatedNumber(0);
  const zh = ctx.lang === "zh";

  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    setDone(false);
    await ringVarSimulate(task, ctx.n("speed"), () => progress.target.current, progress.to);
    await task.sleep(0.3);
    setDone(true);
    setPops((p) => p + 1);
    if (live) haptics.success();
    await task.sleep(1.8);
    if (ctx.isPreview) setRun((r) => r + 1);
  });

  useClock(!done, previewFps(ctx.isPreview));
  const t = performance.now() / 1000;
  const dash = ctx.n("dash");
  const period = dash + 14;
  const phase = -((t * ctx.n("flow")) % period);
  const p = Math.min(Math.max(progress.value, 0), 1);
  const d = p > 0.001 ? arcPath(R, R, R, 0, p) : "";
  const scale = popScale(useTriggerElapsed(pops, 0.7), 1.08, 0.15);
  const mb = progress.target.current * 8;
  const fade = "opacity 0.35s cubic-bezier(0.42,0,0.58,1)";
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: S, height: S }}>
        <TrimCircle size={S} lineWidth={7} color={primary(0.08)} />
        <svg width={S} height={S} style={{ position: "absolute", inset: 0, overflow: "visible", transform: "rotate(-90deg)" }}>
          <defs>
            <linearGradient id={`d${id}`} gradientUnits="userSpaceOnUse" x1={0} y1={0} x2={0} y2={S}>
              <stop offset="0" stopColor={Palette.sky} />
              <stop offset="1" stopColor={Palette.violet} />
            </linearGradient>
          </defs>
          {d && (
            <path d={d} fill="none" stroke={`url(#d${id})`} strokeWidth={7} strokeLinecap="round" strokeDasharray={`${dash} 14`} strokeDashoffset={phase} style={{ opacity: done ? 0 : 1, transition: fade }} />
          )}
          {d && <path d={d} fill="none" stroke={Palette.violet} strokeWidth={7} strokeLinecap="round" style={{ opacity: done ? 1 : 0, transition: fade }} />}
        </svg>
        <div
          style={{
            position: "absolute",
            left: R - 32,
            top: R - 32,
            width: 64,
            height: 64,
            borderRadius: "50%",
            background: `linear-gradient(${Palette.pink}, ${Palette.violet})`,
            display: "grid",
            placeItems: "center",
            color: "#fff",
            fontSize: 20,
            fontWeight: 700,
            transform: `scale(${scale})`,
          }}
        >
          MJ
        </div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3 }}>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>Keynote_Final.mov</span>
        <span style={{ fontSize: 12, lineHeight: "16px", fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>
          <NumericText value={mb} text={zh ? `${mb.toFixed(1)} / 8.0 MB · 来自 Mia` : `${mb.toFixed(1)} of 8.0 MB · from Mia`} />
        </span>
      </div>
      <DemoHint ctx={ctx} en="Tap to restart" zh="点击重新开始" />
    </div>
  );
}
