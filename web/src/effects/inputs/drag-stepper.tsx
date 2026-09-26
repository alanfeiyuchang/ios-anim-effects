/** inputs.drag-stepper (Inputs+DragStepper.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, anim, clamp, fonts, rubberBand, spring, textStyle, useAutoplay, useHaptics, usePan, useSilently, useTimeouts, type DemoProps } from "../../kit";

const MIN = 0;
const MAX = 20;
const LIMIT = 90;

export default function DragStepper({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const silently = useSilently();
  const { after } = useTimeouts();
  const [value, setValueState] = useState(3);
  const valueRef = useRef(3);
  const offset = useMotionValue(0);
  const [off, setOff] = useState(0);
  useMotionValueEvent(offset, "change", setOff);
  const engaged = useRef(0);
  const repeat = useRef(0);
  const step = useRef(0);
  const threshold = ctx.n("threshold");

  useEffect(() => () => window.clearInterval(repeat.current), []);

  const change = (delta: number) => {
    const target = clamp(valueRef.current + delta, MIN, MAX);
    if (target === valueRef.current) {
      haptics.tap("rigid");
      return false;
    }
    haptics.tap("medium");
    valueRef.current = target;
    setValueState(target);
    return target !== MIN && target !== MAX;
  };

  const stopRepeat = () => {
    window.clearInterval(repeat.current);
    repeat.current = 0;
  };
  const startRepeating = (side: number) => {
    if (!change(side)) return;
    repeat.current = window.setInterval(() => {
      if (!change(side)) stopRepeat();
    }, 350);
  };

  const release = () => {
    if (engaged.current === 0 && offset.get() === 0 && !repeat.current) return;
    stopRepeat();
    engaged.current = 0;
    animate(offset, 0, spring(ctx.n("response"), ctx.n("damping")));
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      offset.set(rubberBand(translation.x, LIMIT, 1));
      const o = offset.get();
      const side = o >= threshold ? 1 : o <= -threshold ? -1 : 0;
      if (side !== engaged.current) {
        engaged.current = side;
        stopRepeat();
        if (side !== 0) startRepeating(side);
      }
    },
    onEnd: release,
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      step.current += 1;
      const side = Math.floor(step.current / 3) % 2 === 0 ? 1 : -1;
      animate(offset, side * (threshold + 8), anim.easeOut(0.22));
      after(0.24, () => {
        silently(() => change(side));
        after(0.2, release);
      });
    },
    { every: 1.3, delay: 0.3 },
  );

  const progress = Math.min(Math.abs(off) / threshold, 1);
  const stretch = 1 + Math.min(Math.abs(off) / LIMIT, 1) * 0.12;
  const zh = ctx.lang === "zh";

  const chevron = (side: number) => {
    const active = side < 0 ? off < 0 : off > 0;
    const amount = active ? progress : 0;
    return (
      <span
        style={{
          display: "grid",
          color: active && progress >= 1 ? Palette.indigo : Palette.secondaryLabel,
          opacity: 0.35 + amount * 0.65,
          transform: `translateX(${side * amount * 8}px)`,
        }}
      >
        {side < 0 ? <ChevronLeft size={19} strokeWidth={3} /> : <ChevronRight size={19} strokeWidth={3} />}
      </span>
    );
  };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
      <div style={{ flex: 1 }} />
      <span style={{ ...textStyle.headline }}>{zh ? "票数" : "Tickets"}</span>
      <div style={{ position: "relative", width: 230, height: 64, flexShrink: 0 }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: 32, background: Palette.labelAlpha(0.06), boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }} />
        <div style={{ position: "absolute", inset: 0, padding: "0 18px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          {chevron(-1)}
          {chevron(1)}
        </div>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
          <motion.div
            {...pan}
            style={{
              ...pan.style,
              x: offset,
              width: 56,
              height: 56,
              borderRadius: "50%",
              background: Palette.primary,
              boxShadow: `0 4px 8px ${alpha(Palette.indigo, 0.35)}`,
              display: "grid",
              placeItems: "center",
              color: "#fff",
              cursor: "grab",
              scaleX: stretch,
              scaleY: 2 - stretch,
              transformOrigin: off >= 0 ? "0% 50%" : "100% 50%",
            }}
          >
            <NumericText value={value} style={{ fontFamily: fonts.rounded, fontSize: 24, fontWeight: 700, lineHeight: "30px" }} />
          </motion.div>
        </div>
      </div>
      <NumericText
        value={value}
        text={zh ? `合计 ¥${value * 80}` : `Total $${value * 12}`}
        style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.secondaryLabel }}
      />
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag the number left or right" zh="左右拖动数字" style={{ paddingBottom: 18 }} />
    </div>
  );
}
