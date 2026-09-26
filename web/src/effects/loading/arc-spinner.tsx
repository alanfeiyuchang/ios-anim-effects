/** loading.arc-spinner · 呼吸弧线旋转器 (Loading+Spinners.swift) */
import { Palette, type DemoProps } from "../../kit";
import { GradientArc, TrimCircle, easeInOutCubic, previewFps, primary, usePhase } from "./shared";

const SIZE = 96;

function state(phase: number) {
  const local = ((phase % 5) + 5) % 5;
  const cycle = Math.floor(local);
  const u = local - cycle;
  const head = easeInOutCubic(u / 0.55);
  const tail = easeInOutCubic((u - 0.45) / 0.55);
  return { from: 0.8 * tail, to: 0.04 + 0.8 * head, rotation: cycle * 288 + (local / 5) * 720 };
}

export default function ArcSpinner({ ctx }: DemoProps) {
  const style = ctx.i("style");
  const colors =
    style === 1 ? [Palette.amber, Palette.coral, Palette.pink] : style === 2 ? [Palette.label, Palette.label] : [Palette.mint, Palette.sky, Palette.violet];
  const lineWidth = ctx.n("width");
  const period = ctx.n("period");
  const t = usePhase(1 / Math.max(period, 0.1), previewFps(ctx.isPreview));
  const s = state(t);
  const gradient = `linear-gradient(135deg, ${colors.join(", ")})`;
  const length = s.to - s.from;
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 28 }}>
      <div style={{ position: "relative", width: SIZE, height: SIZE }}>
        <TrimCircle size={SIZE} lineWidth={lineWidth} color={primary(0.08)} />
        <GradientArc
          size={SIZE}
          lineWidth={lineWidth * 1.6}
          from={s.from}
          to={s.to}
          background={gradient}
          rotate={s.rotation - 90}
          style={{ filter: `blur(${lineWidth * 1.5}px)`, opacity: 0.2 + (0.45 * length) / 0.84 }}
        />
        <GradientArc size={SIZE} lineWidth={lineWidth} from={s.from} to={s.to} background={gradient} rotate={s.rotation - 90} />
      </div>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{ctx.t("Preparing your library", "正在准备资源库")}</span>
        <span style={{ fontSize: 13, lineHeight: "18px", color: Palette.secondaryLabel }}>{ctx.t("This only takes a moment", "马上就好")}</span>
      </div>
    </div>
  );
}
