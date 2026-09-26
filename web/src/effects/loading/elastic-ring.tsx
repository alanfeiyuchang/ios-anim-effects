/** loading.elastic-ring · 弹性进度环 (Loading+RingVariations.swift) */
import { useState } from "react";
import { DemoHint, NumericText, Palette, alpha, fonts, spring, useHaptics, type DemoProps } from "../../kit";
import { popScale, ringVarSimulate } from "./bar-shared";
import { GradientArc, TrimCircle, angular, primary, useAnimatedNumber, useTask, useTriggerElapsed } from "./shared";

const SIZE = 170;

export default function ElasticRing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [run, setRun] = useState(0);
  const [steps, setSteps] = useState(0);
  const progress = useAnimatedNumber(0);
  const zh = ctx.lang === "zh";

  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    setSteps(0);
    await ringVarSimulate(task, ctx.n("speed"), () => progress.target.current, progress.to, spring(ctx.n("response"), ctx.n("damping")), () =>
      setSteps((s) => s + 1),
    );
    if (live) haptics.success();
    await task.sleep(1.8);
    if (ctx.isPreview) setRun((r) => r + 1);
  });

  const elapsed = useTriggerElapsed(steps, 0.8);
  const squash = popScale(elapsed, 0.97, 0.1);
  const bead = popScale(elapsed, 1.5, 0.1);
  const model = progress.target.current;
  const shown = Math.min(Math.max(progress.value, 0), 1);
  const percent = Math.round(Math.min(Math.max(model, 0), 1) * 100);
  const photos = Math.floor(model * 24);
  const beadVisible = model < 1 && progress.value > 0.005;
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: SIZE, height: SIZE }}>
        <div style={{ position: "absolute", inset: 0, transform: `scale(${squash})` }}>
          <TrimCircle size={SIZE} lineWidth={12} color={primary(0.08)} />
          <GradientArc size={SIZE} lineWidth={12} from={0} to={shown} background={angular([Palette.pink, Palette.coral, Palette.amber, Palette.pink])} rotate={-90} />
          <div
            style={{
              position: "absolute",
              inset: 0,
              transform: `rotate(${shown * 360}deg)`,
              opacity: beadVisible ? 1 : 0,
              transition: "opacity 0.3s ease-out",
            }}
          >
            <div
              style={{
                position: "absolute",
                left: SIZE / 2 - 10,
                top: SIZE / 2 - 85 - 10,
                width: 20,
                height: 20,
                borderRadius: "50%",
                background: "#fff",
                boxShadow: `0 0 5px ${alpha(Palette.coral, 0.5)}`,
                transform: `scale(${bead})`,
              }}
            />
          </div>
        </div>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", fontFamily: fonts.rounded, fontSize: 40, fontWeight: 700 }}>
          <NumericText value={percent} text={`${percent}%`} />
        </div>
      </div>
      <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, color: Palette.secondaryLabel }}>
        <NumericText value={photos} text={zh ? `已上传 ${photos} / 24 张照片` : `${photos} of 24 photos`} />
      </span>
      <DemoHint ctx={ctx} en="Tap to restart" zh="点击重新开始" />
    </div>
  );
}
