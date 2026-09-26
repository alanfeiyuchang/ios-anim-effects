/** inputs.emoji-face-rating (Inputs+EmojiFaceRating.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, clamp, demoCard, ease, mix, progress, spring, springAt, textStyle, useAutoplay, useElapsed, useHaptics, usePan, type DemoProps } from "../../kit";
import { PushText } from "./_a-common";

const WIDTH = 250;
const PREVIEW = [1, 0.25, 0.75, 0, 0.5];
const LABELS: [string, string][] = [
  ["Awful", "很差"],
  ["Meh", "一般"],
  ["Okay", "还行"],
  ["Good", "不错"],
  ["Great!", "很棒！"],
];
const levelOf = (m: number) => clamp(Math.round(m * 4), 0, 4);

export default function EmojiFaceRating({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const moodMV = useMotionValue(0.5);
  const [mood, setMood] = useState(0.5);
  useMotionValueEvent(moodMV, "change", setMood);
  const step = useRef(0);
  const level = levelOf(mood);
  const t = spring(ctx.n("response"), ctx.n("damping"));

  const snap = () => {
    if (!ctx.b("snap")) return;
    animate(moodMV, levelOf(moodMV.get()) / 4, t);
  };

  const pan = usePan({
    onChange: ({ location }) => {
      const before = levelOf(moodMV.get());
      moodMV.stop();
      moodMV.set(clamp(location.x / WIDTH));
      if (levelOf(moodMV.get()) !== before) haptics.selection();
    },
    onEnd: snap,
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      animate(moodMV, PREVIEW[step.current % PREVIEW.length], t);
      step.current += 1;
    },
    { every: 1.3, delay: 0.3 },
  );

  // Hop on every level change: cubic up 6 pt in 100 ms, bouncy spring back over 350 ms.
  const e = useElapsed(level, 0.45, true);
  let hop = 0;
  if (e >= 0 && e < 0.45) hop = e < 0.1 ? -6 * ease.inOut(progress(e, 0, 0.1)) : mix(-6, 0, springAt(e - 0.1, 0.35, 0.7));
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), width: WIDTH + 40, padding: 20, display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
        <div style={{ transform: `translateY(${hop}px)` }}>
          <Face mood={mood} />
        </div>
        <PushText k={level} height={24} style={{ alignSelf: "stretch" }}>
          <span style={{ ...textStyle.headline }}>{zh ? LABELS[level][1] : LABELS[level][0]}</span>
        </PushText>
        <div {...pan} style={{ ...pan.style, position: "relative", width: WIDTH, height: 36, cursor: "pointer" }}>
          <div
            style={{
              position: "absolute",
              left: 0,
              right: 0,
              top: 14,
              height: 8,
              borderRadius: 4,
              opacity: 0.8,
              background: `linear-gradient(90deg, ${Palette.coral}, ${Palette.amber}, ${Palette.mint})`,
            }}
          />
          {Array.from({ length: 5 }, (_, i) => (
            <div key={i} style={{ position: "absolute", left: (WIDTH * i) / 4 - 2, top: 16, width: 4, height: 4, borderRadius: 2, background: "rgb(255 255 255 / 0.9)" }} />
          ))}
          <div
            style={{
              position: "absolute",
              left: WIDTH * mood - 14,
              top: 4,
              width: 28,
              height: 28,
              borderRadius: "50%",
              background: "#fff",
              boxShadow: "0 2px 5px rgb(0 0 0 / 0.2)",
            }}
          />
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag the slider" zh="拖动滑块" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Face({ mood }: { mood: number }) {
  const low = Math.max(0, 1 - mood * 2);
  const high = Math.max(0, mood * 2 - 1);
  const tilt = -Math.max(0, 0.5 - mood) * 40;
  const eyeH = Math.max(16 - Math.max(0, mood - 0.6) * 22, 5);
  const ink = "rgb(0 0 0 / 0.72)";
  // Mouth: 56 × 22 frame, quad curve whose edges and control point follow the mood.
  const curve = mood * 2 - 1;
  const edgeY = 11 - curve * 22 * 0.25;
  const controlY = 11 + curve * 22 * 1.1;
  const eye = (t: number) => (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
      <div style={{ width: 18, height: 4, borderRadius: 2, background: ink, transform: `rotate(${t}deg)` }} />
      <div style={{ width: 11, height: eyeH, borderRadius: 5.5, background: ink }} />
    </div>
  );
  return (
    <div style={{ position: "relative", width: 120, height: 120, borderRadius: "50%", boxShadow: `0 8px 14px ${alpha(Palette.amber, 0.35)}` }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.amber }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.coral, opacity: low }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.mint, opacity: high }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: "linear-gradient(rgb(255 255 255 / 0.3), transparent 50%)" }} />
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14, transform: "translateY(6px)" }}>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 30 }}>
          {eye(tilt)}
          {eye(-tilt)}
        </div>
        <svg width={56} height={22} style={{ overflow: "visible" }}>
          <path d={`M0 ${edgeY} Q28 ${controlY} 56 ${edgeY}`} fill="none" stroke={ink} strokeWidth={5} strokeLinecap="round" />
        </svg>
      </div>
    </div>
  );
}
