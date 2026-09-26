/** loading.orbit-dots · 轨道圆点 (Loading+Spinners.swift) */
import { Palette, alpha, type DemoProps } from "../../kit";
import { easeInOutCubic, frac, previewFps, primary, usePhase } from "./shared";

const PALETTE = [Palette.mint, Palette.sky, Palette.blue, Palette.indigo, Palette.violet, Palette.pink, Palette.coral, Palette.amber];
const DOT = 14;

export default function OrbitDots({ ctx }: DemoProps) {
  const count = Math.max(ctx.i("count"), 1);
  const period = ctx.n("period");
  const radius = ctx.n("radius");
  const multicolor = ctx.b("color");
  const t = usePhase(1 / Math.max(period, 0.1), previewFps(ctx.isPreview));
  const lap = frac(t);
  const box = radius * 2 + DOT;
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ position: "relative", width: box, height: box, transform: "scale(1.8)" }}>
        <div
          style={{
            position: "absolute",
            left: DOT / 2,
            top: DOT / 2,
            width: radius * 2,
            height: radius * 2,
            borderRadius: "50%",
            boxShadow: `inset 0 0 0 0.75px ${primary(0.06)}, 0 0 0 0.75px ${primary(0.06)}`,
          }}
        />
        <div
          style={{
            position: "absolute",
            left: box / 2 - 8,
            top: box / 2 - 8,
            width: 16,
            height: 16,
            borderRadius: "50%",
            background: multicolor ? Palette.aurora : primary(0.8),
            transform: `scale(${0.85 + 0.15 * Math.cos(lap * 2 * Math.PI)})`,
            boxShadow: `0 0 6px ${multicolor ? alpha(Palette.sky, 0.35) : primary(0.35)}`,
          }}
        />
        {Array.from({ length: count }, (_, index) => {
          const color = multicolor ? PALETTE[index % PALETTE.length] : Palette.label;
          const angle = easeInOutCubic(frac(t - index * 0.075)) * 360;
          return (
            <div
              key={index}
              style={{ position: "absolute", left: box / 2 - DOT / 2, top: box / 2 - DOT / 2, width: DOT, height: DOT, transform: `rotate(${angle}deg) translateY(${-radius}px) scale(${1 - index * 0.065})` }}
            >
              <div
                style={{
                  width: DOT,
                  height: DOT,
                  borderRadius: "50%",
                  background: color,
                  boxShadow: `0 0 4px ${multicolor ? alpha(color, 0.45) : primary(0.45)}`,
                }}
              />
            </div>
          );
        })}
      </div>
    </div>
  );
}
