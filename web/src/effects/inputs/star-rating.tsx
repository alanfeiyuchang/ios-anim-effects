/** inputs.star-rating (Inputs+StarRating.swift) */
import { useId, useRef, useState } from "react";
import { DemoHint, Palette, alpha, clamp, demoCard, ease, mix, progress, springAt, textStyle, useAutoplay, useElapsed, useHaptics, usePan, type DemoProps } from "../../kit";
import { PushText, STAR_PATH } from "./_a-common";

const STAR = 36;
const SPACING = 12;
const PREVIEW = [4, 2, 5, 3, 1];
const CAPTIONS: [string, string][] = [
  ["Tap to rate", "点击评分"],
  ["Terrible", "很差"],
  ["Not great", "不太好"],
  ["Okay", "还行"],
  ["Good", "不错"],
  ["Amazing!", "太棒了！"],
];

/** Settling time of a SwiftUI `Spring(response:dampingRatio:)` (to within ~0.1 %). */
function settlingDuration(response: number, damping: number) {
  const w0 = (2 * Math.PI) / response;
  return Math.log(1000) / (Math.min(damping, 1) * w0);
}

export default function StarRating({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [state, setState] = useState({ rating: 0, previous: 0, changes: 0 });
  const ratingRef = useRef(0);
  const step = useRef(0);
  const { rating, previous, changes } = state;

  const setRating = (value: number) => {
    if (value === ratingRef.current) return;
    haptics.selection();
    const prev = ratingRef.current;
    ratingRef.current = value;
    setState((s) => ({ rating: value, previous: prev, changes: s.changes + 1 }));
  };

  const pan = usePan({
    onChange: ({ location }) => {
      const index = Math.floor((location.x + SPACING / 2) / (STAR + SPACING)) + 1;
      setRating(clamp(index, 1, 5));
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      setRating(PREVIEW[step.current % PREVIEW.length]);
      step.current += 1;
    },
    { every: 1.3, delay: 0.4 },
  );

  const stagger = ctx.n("stagger");
  const delayFor = (index: number) => (rating >= previous ? Math.max(index - previous, 0) * stagger : Math.max(previous - 1 - index, 0) * stagger);
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 316, padding: 18, display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12, alignSelf: "stretch" }}>
          <div style={{ width: 44, height: 44, borderRadius: 12, background: Palette.ocean, display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
            <svg width={24} height={18} viewBox="0 0 24 18" fill="currentColor">
              <path d="M8.2 1.4c.4-.6 1.2-.6 1.6 0l4.4 6.9 1.6-2.3c.4-.6 1.2-.6 1.6 0l6 9.6c.4.7-.1 1.5-.8 1.5H1.4c-.8 0-1.2-.8-.8-1.5Z" />
            </svg>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ ...textStyle.headline }}>{zh ? "这次入住体验如何？" : "How was your stay?"}</span>
            <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{zh ? "高山小屋 · 2 晚" : "Alpine Lodge · 2 nights"}</span>
          </div>
        </div>
        <div {...pan} style={{ ...pan.style, display: "flex", gap: SPACING, cursor: "pointer" }}>
          {Array.from({ length: 5 }, (_, index) => (
            <Star
              key={index}
              filled={index < rating}
              changed={index < rating !== index < previous}
              delay={delayFor(index)}
              pop={ctx.n("pop")}
              response={ctx.n("response")}
              damping={ctx.n("damping")}
              trigger={changes}
            />
          ))}
        </div>
        <PushText k={rating} height={20} style={{ alignSelf: "stretch" }}>
          <span style={{ ...textStyle.subheadline, fontWeight: 600, color: rating === 0 ? Palette.secondaryLabel : Palette.label }}>
            {zh ? CAPTIONS[rating][1] : CAPTIONS[rating][0]}
          </span>
        </PushText>
        <div
          style={{
            position: "relative",
            alignSelf: "stretch",
            height: 44,
            borderRadius: 22,
            display: "grid",
            placeItems: "center",
            ...textStyle.subheadline,
            fontWeight: 600,
            color: rating > 0 ? "#fff" : Palette.secondaryLabel,
            transition: "color 0.3s",
          }}
        >
          <div style={{ position: "absolute", inset: 0, borderRadius: 22, background: Palette.labelAlpha(0.06) }} />
          <div style={{ position: "absolute", inset: 0, borderRadius: 22, background: Palette.sunset, opacity: rating > 0 ? 1 : 0, transition: "opacity 0.3s" }} />
          <span style={{ position: "relative" }}>{zh ? "提交评价" : "Submit review"}</span>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap a star or drag across them" zh="点击星星，或横向拖过它们" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Star({
  filled,
  changed,
  delay,
  pop,
  response,
  damping,
  trigger,
}: {
  filled: boolean;
  changed: boolean;
  delay: number;
  pop: number;
  response: number;
  damping: number;
  trigger: number;
}) {
  const id = `a-star-${useId().replace(/:/g, "")}`;
  const lead = 0.001 + delay;
  const peak = changed ? (filled ? pop : 0.85) : 1;
  const settle = Math.max(settlingDuration(response, damping), 0.3);
  const total = lead + 0.12 + settle;
  // Keep the peak of the last change, so a re-render mid-animation doesn't change its shape.
  const peakRef = useRef({ trigger, peak });
  if (peakRef.current.trigger !== trigger) peakRef.current = { trigger, peak };
  const t = useElapsed(trigger, total, true);
  let scale = 1;
  const pk = peakRef.current.peak;
  if (t > lead && t < total) {
    scale = t < lead + 0.12 ? mix(1, pk, ease.inOut(progress(t, lead, 0.12))) : mix(pk, 1, springAt(t - lead - 0.12, response, damping));
  }
  return (
    <div
      style={{
        position: "relative",
        width: 46,
        height: 44,
        transform: `scale(${scale})`,
        filter: `drop-shadow(0 3px 8px ${alpha(Palette.amber, filled ? 0.35 : 0)})`,
        transition: `filter 0.15s ease-out ${filled ? delay : 0}s`,
      }}
    >
      <svg width={50} height={50} viewBox="0 0 24 24" style={{ position: "absolute", left: -2, top: -3.5 }}>
        <defs>
          <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor={Palette.amber} />
            <stop offset="1" stopColor={Palette.coral} />
          </linearGradient>
        </defs>
        <path d={STAR_PATH} style={{ fill: Palette.labelAlpha(0.14) }} />
        <path d={STAR_PATH} fill={`url(#${id})`} style={{ opacity: filled ? 1 : 0, transition: `opacity 0.15s ease-out ${delay}s` }} />
      </svg>
    </div>
  );
}
