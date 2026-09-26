/** inputs.drum-slider (Inputs+DrumSlider.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, clamp, demoCard, fonts, spring, textStyle, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";

const RADIUS = 150;
const LO = 40;
const HI = 120;
const TARGETS = [82, 57, 74, 63, 91];

export default function DrumSlider({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const mv = useMotionValue(68);
  const [value, setValue] = useState(68);
  useMotionValueEvent(mv, "change", setValue);
  const startValue = useRef(68);
  const dragging = useRef(false);
  const step = useRef(0);
  const degreesPerTick = ctx.n("curve");
  const pointsPerTick = RADIUS * Math.sin((degreesPerTick * Math.PI) / 180);

  const settleTo = (target: number, response: number) => animate(mv, target, spring(response, ctx.n("damping")));

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!dragging.current) {
        dragging.current = true;
        mv.stop();
        startValue.current = mv.get();
      }
      const nv = clamp(startValue.current - translation.x / pointsPerTick, LO, HI);
      if (Math.round(nv) !== Math.round(mv.get())) haptics.selection();
      mv.set(nv);
    },
    onEnd: ({ translation, velocity }) => {
      dragging.current = false;
      // DragGesture.predictedEndTranslation ≈ translation + velocity × 0.25 s.
      const travel = ctx.b("momentum") ? translation.x + velocity.x * 0.25 : translation.x;
      settleTo(clamp(Math.round(startValue.current - travel / pointsPerTick), LO, HI), 0.7);
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      settleTo(TARGETS[step.current % TARGETS.length], 0.9);
      step.current += 1;
    },
    { every: 1.9, delay: 0.3 },
  );

  const span = 88 / degreesPerTick;
  const lo = clamp(Math.floor(value - span), LO, HI);
  const hi = clamp(Math.ceil(value + span), LO, HI);
  const ticks: number[] = [];
  for (let i = lo; i <= hi; i++) ticks.push(i);
  const mask = "linear-gradient(90deg, transparent 0%, #000 22%, #000 78%, transparent 100%)";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), padding: "18px 0", display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
        <span style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("Target weight", "目标体重")}</span>
        <div {...pan} style={{ ...pan.style, width: 300, height: 130, display: "flex", flexDirection: "column", alignItems: "center", gap: 10, cursor: "grab" }}>
          <div style={{ display: "flex", alignItems: "baseline", gap: 4, fontFamily: fonts.rounded }}>
            <span style={{ fontSize: 40, fontWeight: 700, lineHeight: "48px", fontVariantNumeric: "tabular-nums" }}>{Math.round(value)}</span>
            <span style={{ fontSize: 17, fontWeight: 600, color: Palette.secondaryLabel }}>kg</span>
          </div>
          <div style={{ position: "relative", width: 300, height: 62, WebkitMaskImage: mask, maskImage: mask }}>
            {ticks.map((index) => {
              const theta = ((index - value) * degreesPerTick * Math.PI) / 180;
              const facing = Math.max(Math.cos(theta), 0);
              const x = RADIUS * Math.sin(theta);
              const major = index % 5 === 0;
              const labelled = index % 10 === 0;
              return (
                <div
                  key={index}
                  style={{
                    position: "absolute",
                    left: 150 - 20,
                    top: 5,
                    width: 40,
                    height: 52,
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    gap: 4,
                    transform: `translateX(${x}px) scaleX(${Math.max(facing, 0.05)})`,
                    opacity: facing * facing,
                  }}
                >
                  <div style={{ width: major ? 2.5 : 1.5, height: major ? 30 : 18, borderRadius: 2, background: Palette.labelAlpha(major ? 0.7 : 0.35), flexShrink: 0 }} />
                  <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, lineHeight: "14px", fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel, opacity: labelled ? 1 : 0 }}>
                    {index}
                  </span>
                </div>
              );
            })}
            <div style={{ position: "absolute", left: 148.5, top: 5, width: 3, height: 52, borderRadius: 1.5, background: Palette.coral, boxShadow: `0 0 4px ${alpha(Palette.coral, 0.5)}` }} />
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag or fling the ruler" zh="拖动或甩动刻度尺" style={{ paddingBottom: 18 }} />
    </div>
  );
}
