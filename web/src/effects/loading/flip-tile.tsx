/** loading.flip-tile · 弹簧翻转方块 (Loading+SpinnerVariations.swift) */
import { Palette, alpha, type DemoProps } from "../../kit";
import { SpinnerCaption, previewFps, primary, usePhase } from "./shared";

const COLORS = [Palette.indigo, Palette.violet, Palette.pink, Palette.amber];

/** A settle curve that overshoots once and lands exactly on 1 at u = 1. */
function settle(u: number, overshoot: number) {
  const x = Math.min(Math.max(u, 0), 1);
  const decay = -3 * Math.log(Math.max(overshoot, 0.005));
  const wobble = Math.exp(-decay * x) * Math.cos(3 * Math.PI * x);
  return 1 - wobble * (1 - x * x * x);
}

export default function FlipTile({ ctx }: DemoProps) {
  const zh = ctx.lang === "zh";
  const beat = Math.max(ctx.n("beat"), 0.2);
  const side = ctx.n("size");
  const t = usePhase(1 / beat, previewFps(ctx.isPreview));
  const index = Math.floor(t);
  const u = t - index;
  const angle = 180 * settle(u, ctx.n("overshoot"));
  const lift = Math.sin(Math.PI * Math.min(u * 1.6, 1));
  const color = COLORS[(index + (angle > 90 ? 1 : 0)) % COLORS.length];
  const rotate = index % 2 === 0 ? `rotateX(${angle}deg)` : `rotateY(${angle}deg)`;
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 26 }}>
      <div style={{ width: 140, height: 140, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        <div style={{ transform: `translateY(${-14 * lift}px) scale(${1 + 0.12 * lift})`, filter: `drop-shadow(0 8px 12px ${alpha(color, 0.35)})` }}>
          <div
            style={{
              width: side,
              height: side,
              borderRadius: side * 0.28,
              background: `radial-gradient(circle ${side * 0.72}px at 50% 50%, rgb(255 255 255 / 0.22), transparent), ${color}`,
              display: "grid",
              placeItems: "center",
              transform: `perspective(${side / 0.8}px) ${rotate}`,
            }}
          >
            <div style={{ width: side * 0.22, height: side * 0.22, borderRadius: "50%", background: "rgb(255 255 255 / 0.9)" }} />
          </div>
        </div>
        <div style={{ marginTop: 14, width: side * (0.9 - 0.3 * lift), height: 8, borderRadius: "50%", background: primary(0.14 - 0.08 * lift), filter: "blur(3px)", flexShrink: 0 }} />
      </div>
      <SpinnerCaption title={zh ? "正在搭建你的工作区" : "Building your workspace"} detail={zh ? "导入模板与成员…" : "Importing templates and members…"} />
    </div>
  );
}
