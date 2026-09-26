/** charts.activity-rings · 健身圆环 (Charts+ActivityRings.swift) */
import { ArrowRight, ArrowUp, ChevronsRight, type LucideIcon } from "lucide-react";
import { DemoHint, Palette, anim, delayed, fonts, hex, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { randomIn, useAnimatedNumbers, useChartEntrance } from "./_shared";

const ringStyles: { en: string; zh: string; icon: LucideIcon; start: string; end: string }[] = [
  { en: "Move", zh: "活动", icon: ArrowRight, start: "#E0004B", end: "#FF4F9A" },
  { en: "Exercise", zh: "锻炼", icon: ChevronsRight, start: "#6BD100", end: "#C6FF3D" },
  { en: "Stand", zh: "站立", icon: ArrowUp, start: "#00B4D8", end: "#3DF2F2" },
];
const OUTER = 210;

export default function ActivityRings({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const progress = useAnimatedNumbers(3, 0);
  const thickness = ctx.n("thickness");

  const play = (haptic = true) => {
    [0, 1, 2].forEach((i) => progress.to(i, 0, anim.easeIn(0.25)));
    const targets = [randomIn(0.7, 1.35), randomIn(0.55, 1.2), randomIn(0.4, 1.0)];
    const sp = spring(ctx.n("response"), 0.82);
    const stagger = ctx.n("stagger");
    after(0.28, () => {
      targets.forEach((t, i) => progress.to(i, t, delayed(sp, i * stagger)));
      if (haptic) haptics.tap("soft");
    });
  };

  useChartEntrance(() => play(false));
  useAutoplay(ctx.isPreview, () => play(), { every: 3.6, delay: 3.6, intro: false });

  const frame = OUTER + thickness;
  return (
    <div
      onClick={() => play()}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: frame, height: frame, flexShrink: 0 }}>
        {ringStyles.map((style, index) => (
          <Ring key={index} progress={progress.get(index)} style={style} lineWidth={thickness} diameter={OUTER - index * 2 * (thickness + 4)} frame={frame} />
        ))}
      </div>
      <div style={{ display: "flex", gap: 18 }}>
        {ringStyles.map((style, index) => (
          <div key={index} style={{ width: 70, display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}>
            <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t(style.en, style.zh)}</span>
            <span style={{ fontFamily: fonts.rounded, fontSize: 17, lineHeight: "22px", fontWeight: 700, fontVariantNumeric: "tabular-nums", color: style.start }}>
              {Math.round(Math.max(progress.get(index), 0) * 100)}%
            </span>
          </div>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap to replay" zh="点击重播" />
    </div>
  );
}

/** Clip path of the annulus (full ring) or a butt-ended arc from 12 o'clock clockwise over `turn` (0…1). */
function bandPath(c: number, r: number, half: number, turn: number): string {
  const ro = r + half;
  const ri = r - half;
  if (turn >= 0.9999) {
    return `M ${c} ${c - ro} A ${ro} ${ro} 0 1 1 ${c} ${c + ro} A ${ro} ${ro} 0 1 1 ${c} ${c - ro} Z M ${c} ${c - ri} A ${ri} ${ri} 0 1 0 ${c} ${c + ri} A ${ri} ${ri} 0 1 0 ${c} ${c - ri} Z`;
  }
  const a = turn * 2 * Math.PI;
  const large = turn > 0.5 ? 1 : 0;
  const ox = c + ro * Math.sin(a), oy = c - ro * Math.cos(a);
  const ix = c + ri * Math.sin(a), iy = c - ri * Math.cos(a);
  return `M ${c} ${c - ro} A ${ro} ${ro} 0 ${large} 1 ${ox} ${oy} L ${ix} ${iy} A ${ri} ${ri} 0 ${large} 0 ${c} ${c - ri} Z`;
}

function Ring({ progress, style, lineWidth, diameter, frame }: { progress: number; style: (typeof ringStyles)[number]; lineWidth: number; diameter: number; frame: number }) {
  const p = Math.max(progress, 0);
  const c = frame / 2;
  const r = diameter / 2;
  const Icon = style.icon;
  const over = p > 1;
  const gradient = over
    ? `conic-gradient(from ${360 * (p - 1)}deg at ${c}px ${c}px, ${style.start}, ${style.end})`
    : `conic-gradient(from 0deg at ${c}px ${c}px, ${style.start} 0deg, ${style.end} ${Math.max(360 * p, 1)}deg, ${style.end} 360deg)`;
  const endAngle = 2 * Math.PI * p;
  // The end cap casts its shadow along the direction of travel, fading in near 100%.
  const shade = Math.min(Math.max((p - 0.85) / 0.15, 0), 1);
  const tangent = { x: Math.cos(endAngle), y: Math.sin(endAngle) };
  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <svg width={frame} height={frame} style={{ position: "absolute", inset: 0 }}>
        <circle cx={c} cy={c} r={r} fill="none" stroke={hex(style.start, 0.2)} strokeWidth={lineWidth} />
      </svg>
      {p > 0 && (
        <div style={{ position: "absolute", inset: 0, background: gradient, clipPath: `path(${over ? "evenodd, " : ""}"${bandPath(c, r, lineWidth / 2, Math.min(p, 1))}")` }} />
      )}
      {p > 0.01 && p <= 1 && (
        <div style={{ position: "absolute", left: c - lineWidth / 2, top: c - r - lineWidth / 2, width: lineWidth, height: lineWidth, borderRadius: "50%", background: style.start }} />
      )}
      {p > 0.01 && (
        <div
          style={{
            position: "absolute",
            left: c + r * Math.sin(endAngle) - lineWidth / 2,
            top: c - r * Math.cos(endAngle) - lineWidth / 2,
            width: lineWidth,
            height: lineWidth,
            borderRadius: "50%",
            background: style.end,
            boxShadow: `${(tangent.x * 3).toFixed(2)}px ${(tangent.y * 3).toFixed(2)}px 7px rgb(0 0 0 / ${0.45 * shade})`,
          }}
        />
      )}
      <div
        style={{
          position: "absolute",
          left: c - lineWidth / 2,
          top: c - r - lineWidth / 2,
          width: lineWidth,
          height: lineWidth,
          display: "grid",
          placeItems: "center",
          color: p > 0.01 ? "#000" : style.start,
        }}
      >
        <Icon size={lineWidth * 0.62} strokeWidth={3.6} />
      </div>
    </div>
  );
}
