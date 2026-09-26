/** charts.gauge-needle · 弹簧仪表指针 (Charts+Gauge.swift) */
import { DemoHint, Palette, clamp, fonts, localPoint, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { randomIn, useAnimatedNumbers, useChartEntrance } from "./_shared";

const SIZE = { w: 280, h: 210 };
const CX = 140;
const CY = 140;
const R = 110;
const LINE = 18;

/**
 * Outline of a round-capped stroke along the circle from SwiftUI angle `a0` to `a1` (degrees,
 * 0 = 3 o'clock, clockwise), used to clip a conic gradient (`AngularGradient`) to the arc.
 */
function arcBand(a0: number, a1: number, r: number, half: number): string {
  const rad = (d: number) => (d * Math.PI) / 180;
  const pt = (rr: number, d: number) => `${CX + rr * Math.cos(rad(d))} ${CY + rr * Math.sin(rad(d))}`;
  const large = a1 - a0 > 180 ? 1 : 0;
  return [
    `M ${pt(r + half, a0)}`,
    `A ${r + half} ${r + half} 0 ${large} 1 ${pt(r + half, a1)}`,
    `A ${half} ${half} 0 0 1 ${pt(r - half, a1)}`,
    `A ${r - half} ${r - half} 0 ${large} 0 ${pt(r - half, a0)}`,
    `A ${half} ${half} 0 0 1 ${pt(r + half, a0)}`,
    "Z",
  ].join(" ");
}

export default function GaugeNeedle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const anim = useAnimatedNumbers(1, 0);

  const set = (next: number, haptic = true) => {
    anim.to(0, next, spring(ctx.n("response"), ctx.n("damping")));
    if (haptic) haptics.tap("rigid");
  };

  useChartEntrance(() => set(0.74, false));
  useAutoplay(ctx.isPreview, () => set(randomIn(0.15, 0.95)), { every: 2.0, delay: 1.8, intro: false });

  const aim = (e: React.MouseEvent<HTMLDivElement>) => {
    const p = localPoint(e, e.currentTarget);
    const dx = p.x - CX;
    const dy = Math.min(p.y - CY, 0);
    // Angle from the left end (180°) across the top to the right end (360°).
    let degrees = (Math.atan2(dy, dx) * 180) / Math.PI;
    if (degrees > 0) degrees = dx < 0 ? -180 : 0;
    set(clamp((degrees + 180) / 180));
  };

  const value = anim.get(0);
  const clamped = clamp(value);
  const needle = Math.min(Math.max(-90 + 180 * value, -100), 100);
  const end = 180 + 180 * Math.max(clamped, 0.002);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div onClick={aim} style={{ position: "relative", width: SIZE.w, height: SIZE.h, cursor: "pointer", flexShrink: 0 }}>
        <svg width={SIZE.w} height={SIZE.h} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <path d={`M ${CX - R} ${CY} A ${R} ${R} 0 0 1 ${CX + R} ${CY}`} fill="none" stroke={Palette.labelAlpha(0.08)} strokeWidth={LINE} strokeLinecap="round" />
        </svg>
        <div
          style={{
            position: "absolute",
            inset: 0,
            background: `conic-gradient(from 270deg at ${CX}px ${CY}px, ${Palette.mint} 0deg, ${Palette.amber} 90deg, ${Palette.red} 180deg, ${Palette.red} 270deg, ${Palette.mint} 270deg)`,
            clipPath: `path("${arcBand(180, end, R, LINE / 2)}")`,
          }}
        />
        {ctx.b("ticks") &&
          Array.from({ length: 11 }, (_, index) => {
            const major = index % 5 === 0;
            const h = major ? 10 : 6;
            return (
              <div
                key={index}
                style={{
                  position: "absolute",
                  left: CX - 1,
                  top: CY - h / 2,
                  width: 2,
                  height: h,
                  borderRadius: 1,
                  background: Palette.labelAlpha(major ? 0.45 : 0.2),
                  transformOrigin: `1px ${h / 2}px`,
                  transform: `rotate(${-90 + index * 18}deg) translateY(${-(R - 24)}px)`,
                }}
              />
            );
          })}
        <div
          style={{
            position: "absolute",
            left: CX - 2,
            top: CY - (R - 20),
            width: 4,
            height: R - 20,
            borderRadius: 2,
            background: Palette.label,
            transformOrigin: `2px ${R - 20}px`,
            transform: `rotate(${needle}deg)`,
            boxShadow: "0 2px 6px rgb(0 0 0 / 0.2)",
          }}
        />
        <div style={{ position: "absolute", left: CX - 8, top: CY - 8, width: 16, height: 16, borderRadius: "50%", background: Palette.label, display: "grid", placeItems: "center" }}>
          <div style={{ width: 6, height: 6, borderRadius: "50%", background: Palette.surface }} />
        </div>
        <div style={{ position: "absolute", left: 0, right: 0, top: CY + 46, height: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ display: "flex", alignItems: "baseline", gap: 4 }}>
            <span style={{ fontFamily: fonts.rounded, fontSize: 34, lineHeight: "41px", fontWeight: 700, fontVariantNumeric: "tabular-nums" }}>
              {Math.round(Math.max(value, 0) * 1000)}
            </span>
            <span style={{ fontSize: 12, fontWeight: 600, color: Palette.secondaryLabel }}>Mbps</span>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap anywhere on the dial" zh="点击表盘任意位置" />
    </div>
  );
}
