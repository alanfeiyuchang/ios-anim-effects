/** cards.tear-off · 撕页日历 (Cards+TearOff.swift) */
import { animate, useMotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, black, fonts, mix, rubberBand, spring, useAutoplay, useHaptics, usePan, type DemoContext, type DemoProps } from "../../kit";
import { Stage, persp, useMV } from "./shared";

const WEEKDAYS: [string, string][] = [
  ["Sunday", "星期日"], ["Monday", "星期一"], ["Tuesday", "星期二"], ["Wednesday", "星期三"],
  ["Thursday", "星期四"], ["Friday", "星期五"], ["Saturday", "星期六"],
];

export default function TearOff({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [day, setDay] = useState(23);
  const pullMV = useMotionValue(0);
  const fallMV = useMotionValue(0);
  const falling = useRef(false);
  const [isFalling, setIsFalling] = useState(false);
  const held = useRef(false);
  const script = useRef(0);
  useEffect(() => () => window.clearTimeout(script.current), []);

  const tear = () => {
    haptics.tap("rigid");
    falling.current = true;
    setIsFalling(true);
    animate(fallMV, 1, anim.easeIn(0.55));
    window.setTimeout(() => {
      setDay((d) => (d >= 30 ? 1 : d + 1));
      pullMV.jump(0);
      fallMV.jump(0);
      falling.current = false;
      setIsFalling(false);
    }, 580);
  };

  // Down only: an upward swipe never starts the pull.
  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (falling.current) return;
        if (!held.current) {
          if (translation.y <= 0) return;
          held.current = true;
          window.clearTimeout(script.current);
        }
        pullMV.jump(Math.max(translation.y, 0));
      },
      onEnd: () => {
        if (!held.current) return;
        held.current = false;
        if (falling.current) return;
        if (pullMV.get() > ctx.n("threshold")) tear();
        else animate(pullMV, 0, spring(0.4, 0.6));
      },
    },
    8,
  );

  useAutoplay(
    ctx.isPreview,
    () => {
      if (falling.current || held.current) return;
      animate(pullMV, 120, spring(0.5, 0.8));
      window.clearTimeout(script.current);
      script.current = window.setTimeout(tear, 600);
    },
    { every: 1.8 },
  );

  const pull = useMV(pullMV);
  const f = useMV(fallMV);
  const progress = Math.min(pull / 180, 1);
  const bend = mix(progress * ctx.n("bend"), 70, f);
  const twist = mix(progress * 6, 25, f);
  const stretch = mix(1 + progress * 0.1, 1, f);
  const follow = rubberBand(pull, 70);

  return (
    <Stage gap={22}>
      <div style={{ position: "relative", width: 200, height: 232, flexShrink: 0 }}>
        <div style={{ position: "absolute", left: 0, top: 0 }}>
          <Sheet day={day + 1} shade={0} ctx={ctx} />
        </div>
        <div
          {...(isFalling ? {} : pan)}
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            width: 200,
            height: 232,
            touchAction: "none",
            cursor: "grab",
            opacity: 1 - f,
            transformOrigin: "0 0",
            transform: `translateY(${420 * f}px) rotate(${twist}deg)`,
          }}
        >
          <div style={{ transformOrigin: "50% 0", transform: `${persp(200, 232, 0.5)} rotateX(${bend}deg)` }}>
            <div style={{ transformOrigin: "50% 0", transform: `scaleY(${stretch}) translateY(${follow}px)` }}>
              <Sheet day={day} shade={progress} ctx={ctx} />
            </div>
          </div>
        </div>
        <Binding />
      </div>
      <DemoHint ctx={ctx} en="Pull the page down to tear it off" zh="向下拉动纸页将其撕下" />
    </Stage>
  );
}

function Sheet({ day, shade, ctx }: { day: number; shade: number; ctx: DemoContext }) {
  const wd = WEEKDAYS[(day + 1) % 7];
  return (
    <div style={{ paddingTop: 12 }}>
      <div
        style={{
          position: "relative",
          width: 200,
          height: 220,
          paddingTop: 16,
          borderRadius: 16,
          background: Palette.elevated,
          boxShadow: `0 6px 10px ${black(0.12)}`,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 2,
        }}
      >
        <span style={{ fontSize: 13, lineHeight: "16px", fontWeight: 800, letterSpacing: 2, color: Palette.red }}>{ctx.t("SEPTEMBER", "九月")}</span>
        <span style={{ fontFamily: fonts.rounded, fontSize: 88, lineHeight: "105px", fontWeight: 700, fontVariantNumeric: "tabular-nums", color: Palette.label }}>{day}</span>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t(wd[0], wd[1])}</span>
        <div style={{ position: "absolute", inset: 0, borderRadius: 16, background: `linear-gradient(transparent 50%, ${black(0.28 * shade)})`, pointerEvents: "none" }} />
        <div style={{ position: "absolute", inset: 0, borderRadius: 16, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
    </div>
  );
}

function Binding() {
  return (
    <div
      style={{
        position: "absolute",
        left: -4,
        top: 0,
        width: 208,
        height: 26,
        borderRadius: 8,
        background: "linear-gradient(#3A3F55, #1B1D2B)",
        boxShadow: `0 2px 4px ${black(0.2)}`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 22,
        pointerEvents: "none",
      }}
    >
      {Array.from({ length: 6 }, (_, i) => (
        <div key={i} style={{ width: 7, height: 7, borderRadius: "50%", background: black(0.55) }} />
      ))}
    </div>
  );
}
