/** text.count-up · 数值递增 (Text+CountUp.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { ArrowUpRight } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, demoCard, fonts, springDB, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { RollingText, randInt } from "./_text-kit";

/** "12480" → "12,480". */
function grouped(value: number) {
  const digits = String(Math.abs(value));
  let result = "";
  [...digits].forEach((ch, index) => {
    if (index > 0 && (digits.length - index) % 3 === 0) result += ",";
    result += ch;
  });
  return value < 0 ? "-" + result : result;
}

export default function CountUp({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [range, setRange] = useState({ from: 10_340, to: 12_480 });
  const [runs, setRuns] = useState(0);
  const shownMv = useMotionValue(12_480);
  const [shown, setShown] = useState(12_480);
  useMotionValueEvent(shownMv, "change", setShown);
  const rangeRef = useRef(range);
  const currency = ctx.lang === "zh" ? "¥" : "$";
  const duration = ctx.n("duration");
  const delta = Math.trunc(range.to - range.from);

  const countAnimation = () => {
    switch (ctx.i("curve")) {
      case 1:
        return anim.easeInOut(duration);
      case 2:
        return springDB(duration, 0.2);
      default:
        return anim.curve(0.16, 1, 0.3, 1, duration);
    }
  };

  const receive = () => {
    const start = rangeRef.current.to;
    const end = start + randInt(8, 42) * 50 + randInt(0, 9) * 10;
    let from = start;
    const to = end > 90_000 ? 12_480 : end;
    if (to < from) from = to - 2_140;
    rangeRef.current = { from, to };
    setRange({ from, to });
    setRuns((r) => r + 1);
    animate(shownMv, to, countAnimation());
    haptics.tap("light");
    after(duration, () => haptics.success());
  };
  useAutoplay(ctx.isPreview, receive, { every: Math.max(duration + 1.0, 2.0) });

  // Holds scale 1 while counting, then pops to 1.08 and springs back.
  const peak = ctx.b("pop") ? 1.08 : 1;
  const t = useElapsed(runs, duration + 0.62, true);
  const scale = t > duration ? popScale(t - duration, peak) : 1;

  const span = range.to - range.from;
  const progress = span > 0 ? Math.min(Math.max((shown - range.from) / span, 0), 1) : 1;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div onClick={receive} style={{ ...demoCard(), width: 290, padding: 20, display: "flex", flexDirection: "column", gap: 12, cursor: "pointer" }}>
        <div style={{ display: "flex", alignItems: "center" }}>
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("Revenue this month", "本月收入")}</span>
          <span style={{ flex: 1 }} />
          <span
            style={{
              display: "flex",
              alignItems: "center",
              gap: 3,
              height: 24,
              padding: "0 8px",
              borderRadius: 12,
              color: Palette.green,
              background: alpha(Palette.green, 0.14),
            }}
          >
            <ArrowUpRight size={11} strokeWidth={3.4} />
            <RollingText value={delta} text={"+" + currency + grouped(delta)} transition={anim.snappy} style={{ fontSize: 12, lineHeight: "16px", fontWeight: 700 }} />
          </span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10, transform: `scale(${scale})`, transformOrigin: "left center" }}>
          <div style={{ display: "flex", alignItems: "baseline", gap: 2, fontFamily: fonts.rounded }}>
            <span style={{ fontSize: 28, fontWeight: 700, color: Palette.secondaryLabel }}>{currency}</span>
            <span style={{ fontSize: 50, lineHeight: "60px", fontWeight: 800, fontVariantNumeric: "tabular-nums", color: Palette.label }}>{grouped(Math.round(shown))}</span>
          </div>
          <div style={{ position: "relative", width: 250, height: 5, borderRadius: 3, background: Palette.labelAlpha(0.08) }}>
            <div
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                height: 5,
                width: 250 * progress,
                borderRadius: 3,
                background: `linear-gradient(to right, ${Palette.mint}, ${Palette.green})`,
              }}
            />
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap the card" zh="点击卡片" />
    </div>
  );
}

/**
 * The keyframes after the hold: `SpringKeyframe(peak, duration: 0.12, spring: .snappy)` then
 * `SpringKeyframe(1, duration: 0.5, spring: .bouncy)`, velocity carried across (integrated).
 */
function popScale(t: number, peak: number) {
  let x = 1;
  let v = 0;
  const dt = 1 / 480;
  for (let time = 0; time < Math.min(t, 0.62); time += dt) {
    const [target, response, damping] = time < 0.12 ? [peak, 0.5, 0.85] : [1, 0.5, 0.7];
    const k = (2 * Math.PI / response) ** 2;
    const c = (4 * Math.PI * damping) / response;
    v += (-k * (x - target) - c * v) * dt;
    x += v * dt;
  }
  return t >= 0.62 ? 1 : x;
}
