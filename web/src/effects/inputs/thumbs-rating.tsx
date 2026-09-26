/** inputs.thumbs-rating (Inputs+ThumbsRating.swift) */
import { motion } from "motion/react";
import { ThumbsDown, ThumbsUp } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, demoCard, ease, fonts, mix, progress, spring, springAt, textStyle, useAutoplay, useElapsed, useHaptics, type DemoProps } from "../../kit";

const SCRIPT = [1, -1, -1, 1, 1];

export default function ThumbsRating({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [choice, setChoice] = useState(0);
  const choiceRef = useRef(0);
  const [upTrigger, setUp] = useState(0);
  const [downTrigger, setDown] = useState(0);
  const step = useRef(0);

  const choose = (direction: number) => {
    const next = choiceRef.current === direction ? 0 : direction;
    choiceRef.current = next;
    setChoice(next);
    if (next !== direction) return;
    haptics.tap("medium");
    if (direction === 1) setUp((u) => u + 1);
    else setDown((d) => d + 1);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      choose(SCRIPT[step.current % SCRIPT.length]);
      step.current += 1;
    },
    { every: 1.2, delay: 0.4 },
  );

  const common = { flick: ctx.n("flick"), pop: ctx.n("pop"), particles: ctx.b("particles"), ink: ctx.scheme === "dark" ? "255 255 255" : "0 0 0" };
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), width: 300, padding: 20, display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
          <span style={{ ...textStyle.headline }}>{zh ? "这篇内容有帮助吗？" : "Was this helpful?"}</span>
          <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{zh ? "设置面容 ID" : "Setting up Face ID"}</span>
        </div>
        <div style={{ display: "flex", gap: 14 }}>
          <ThumbButton {...common} direction={1} selected={choice === 1} count={128 + (choice === 1 ? 1 : 0)} tint={Palette.indigo} trigger={upTrigger} onClick={() => choose(1)} />
          <ThumbButton {...common} direction={-1} selected={choice === -1} count={9 + (choice === -1 ? 1 : 0)} tint={Palette.coral} trigger={downTrigger} onClick={() => choose(-1)} />
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap thumbs up or down" zh="点击点赞或点踩" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function ThumbButton({
  direction,
  selected,
  count,
  tint,
  trigger,
  flick,
  pop,
  particles,
  onClick,
  ink,
}: {
  ink: string;
  direction: number;
  selected: boolean;
  count: number;
  tint: string;
  trigger: number;
  flick: number;
  pop: number;
  particles: boolean;
  onClick: () => void;
}) {
  const t = spring(0.35, 0.65);
  const sign = direction > 0 ? -1 : 1;
  const e = useElapsed(trigger, 0.6, true);
  let angle = 0;
  let scale = 1;
  let burst = 0;
  if (e >= 0 && e < 0.6) {
    if (e < 0.09) {
      angle = mix(0, -sign * 10, ease.inOut(progress(e, 0, 0.09)));
      scale = mix(1, 0.9, ease.inOut(progress(e, 0, 0.09)));
    } else if (e < 0.19) {
      angle = mix(-sign * 10, sign * flick, ease.inOut(progress(e, 0.09, 0.1)));
    } else angle = mix(sign * flick, 0, springAt(e - 0.19, 0.4, 0.7));
    if (e >= 0.09 && e < 0.21) scale = mix(0.9, pop, ease.inOut(progress(e, 0.09, 0.12)));
    else if (e >= 0.21) scale = mix(pop, 1, springAt(e - 0.21, 0.38, 0.7));
    if (e >= 0.12) burst = e < 0.13 ? 0.02 * progress(e, 0.12, 0.01) : mix(0.02, 1, ease.inOut(progress(e, 0.13, 0.45)));
  }
  const Icon = direction > 0 ? ThumbsUp : ThumbsDown;
  return (
    <motion.button
      type="button"
      onClick={onClick}
      initial={false}
      animate={{
        scale: selected ? 1 : 0.96,
        backgroundColor: selected ? alpha(tint, 0.14) : `rgb(${ink} / 0.05)`,
        boxShadow: `inset 0 0 0 ${selected ? 1.5 : 1}px ${selected ? alpha(tint, 0.5) : `rgb(${ink} / 0.08)`}`,
      }}
      transition={t}
      style={{ height: 64, padding: "0 20px", borderRadius: 32, display: "flex", alignItems: "center", gap: 8 }}
    >
      <div style={{ position: "relative", width: 30, height: 30, display: "grid", placeItems: "center" }}>
        {particles &&
          Array.from({ length: 8 }, (_, i) => {
            const a = (i / 8) * 2 * Math.PI;
            return (
              <div
                key={i}
                style={{
                  position: "absolute",
                  left: 12.5,
                  top: 12.5,
                  width: 5,
                  height: 5,
                  borderRadius: "50%",
                  background: tint,
                  transform: `translate(${Math.cos(a) * 26 * burst}px, ${Math.sin(a) * 26 * burst}px)`,
                  opacity: burst > 0 && burst < 1 ? 1 - burst : 0,
                }}
              />
            );
          })}
        <div style={{ display: "grid", color: selected ? tint : Palette.secondaryLabel, transform: `rotate(${angle}deg) scale(${scale})`, transformOrigin: "50% 100%" }}>
          <Icon size={26} strokeWidth={2.2} fill={selected ? "currentColor" : "none"} />
        </div>
      </div>
      <NumericText value={count} style={{ fontFamily: fonts.rounded, ...textStyle.headline, color: selected ? tint : Palette.secondaryLabel }} />
    </motion.button>
  );
}
