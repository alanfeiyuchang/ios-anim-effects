/** inputs.wheel-picker (Inputs+WheelPicker.swift) */
import { animate } from "motion/react";
import { AlarmClock } from "lucide-react";
import { forwardRef, useImperativeHandle, useLayoutEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, clamp, demoCard, fonts, springDB, textStyle, useAutoplay, useHaptics, type DemoProps } from "../../kit";

const NOW = 22 * 60 + 35;
const TIMES: [number, number][] = [
  [6, 45],
  [9, 10],
  [7, 30],
  [5, 55],
];
const ROW = 36;
const H = 190;
const W = 76;

interface WheelHandle {
  scrollTo(value: number, animated: boolean): void;
}
interface Style {
  tilt: number;
  fade: number;
  shrink: number;
}

export default function WheelPicker({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [hour, setHour] = useState(7);
  const [minute, setMinute] = useState(25);
  const quietUntil = useRef(performance.now() + 600);
  const hourWheel = useRef<WheelHandle>(null);
  const minuteWheel = useRef<WheelHandle>(null);
  const step = useRef(0);
  const style: Style = { tilt: ctx.n("tilt"), fade: ctx.n("fade"), shrink: ctx.n("shrink") };

  const onUserChange = (set: (v: number) => void) => (v: number) => {
    set(v);
    if (performance.now() >= quietUntil.current) haptics.selection();
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const [h, m] = TIMES[step.current % TIMES.length];
      step.current += 1;
      quietUntil.current = performance.now() + 1100;
      hourWheel.current?.scrollTo(h, true);
      minuteWheel.current?.scrollTo(m, true);
    },
    { every: 1.6, delay: 0.6 },
  );

  const minutesUntil = (hour * 60 + minute - NOW + 1440) % 1440;
  const hh = Math.floor(minutesUntil / 60);
  const mm = minutesUntil % 60;
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 290, padding: 18, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <AlarmClock size={18} strokeWidth={2.2} style={{ color: Palette.coral }} />
          <span style={{ ...textStyle.headline }}>{zh ? "起床闹钟" : "Wake-up"}</span>
          <div style={{ flex: 1 }} />
          <NumericText
            value={minutesUntil}
            text={zh ? `${hh} 小时 ${mm} 分钟后响铃` : `Rings in ${hh} h ${mm} min`}
            style={{ ...textStyle.caption, fontWeight: 600, color: Palette.secondaryLabel }}
          />
        </div>
        <div style={{ position: "relative", height: H, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ position: "absolute", left: 0, right: 0, top: H / 2 - 19, height: 38, borderRadius: 12, background: Palette.labelAlpha(0.07) }} />
          <div style={{ position: "relative", display: "flex", alignItems: "center", gap: 4 }}>
            <Wheel ref={hourWheel} count={24} initial={7} style={style} onChange={onUserChange(setHour)} />
            <span style={{ fontFamily: fonts.rounded, fontSize: 26, fontWeight: 600, transform: "translateY(-2px)" }}>:</span>
            <Wheel ref={minuteWheel} count={60} initial={25} style={style} onChange={onUserChange(setMinute)} />
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Flick either wheel" zh="上下拨动任一滚轮" style={{ paddingBottom: 16 }} />
    </div>
  );
}

const Wheel = forwardRef<WheelHandle, { count: number; initial: number; style: Style; onChange: (v: number) => void }>(function Wheel(
  { count, initial, style, onChange },
  ref,
) {
  const el = useRef<HTMLDivElement>(null);
  const [top, setTop] = useState(initial * ROW);
  const [snapping, setSnapping] = useState(true);
  const current = useRef(initial);
  const anim = useRef<{ stop(): void } | null>(null);

  useLayoutEffect(() => {
    if (el.current) el.current.scrollTop = initial * ROW;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useImperativeHandle(ref, () => ({
    scrollTo(value, animated) {
      const node = el.current;
      if (!node) return;
      anim.current?.stop();
      if (!animated) {
        node.scrollTop = value * ROW;
        return;
      }
      setSnapping(false);
      anim.current = animate(node.scrollTop, value * ROW, {
        ...springDB(0.8, 0),
        restDelta: 0.5,
        restSpeed: 5,
        onUpdate: (v) => {
          node.scrollTop = v;
        },
        onComplete: () => setSnapping(true),
      });
    },
  }));

  const onScroll = () => {
    const node = el.current;
    if (!node) return;
    setTop(node.scrollTop);
    const v = clamp(Math.round(node.scrollTop / ROW), 0, count - 1);
    if (v !== current.current) {
      current.current = v;
      onChange(v);
    }
  };

  const mask = "linear-gradient(transparent 0%, #000 28%, #000 72%, transparent 100%)";
  const pad = (H - ROW) / 2;
  return (
    <div
      ref={el}
      onScroll={onScroll}
      onPointerDown={() => {
        anim.current?.stop();
        setSnapping(true);
      }}
      onWheel={() => {
        anim.current?.stop();
        setSnapping(true);
      }}
      onTouchStart={() => {
        anim.current?.stop();
        setSnapping(true);
      }}
      style={{
        width: W,
        height: H,
        overflowY: "auto",
        touchAction: "pan-y",
        scrollbarWidth: "none",
        scrollSnapType: snapping ? "y mandatory" : "none",
        WebkitMaskImage: mask,
        maskImage: mask,
        overscrollBehavior: "contain",
      }}
    >
      <div style={{ paddingTop: pad, paddingBottom: pad }}>
        {Array.from({ length: count }, (_, v) => {
          const center = pad + v * ROW + ROW / 2 - top;
          // scrollTransition measures against the content-margin band (one row tall), so neighbours are already at ±1.
          const phase = clamp((center - H / 2) / ROW, -1, 1);
          return (
            <div key={v} style={{ height: ROW, scrollSnapAlign: "center", perspective: W / 0.5 }}>
              <div
                style={{
                  width: W,
                  height: ROW,
                  display: "grid",
                  placeItems: "center",
                  fontFamily: fonts.rounded,
                  fontSize: 26,
                  fontWeight: 600,
                  fontVariantNumeric: "tabular-nums",
                  transform: `rotateX(${-phase * style.tilt}deg) scale(${1 - Math.abs(phase) * style.shrink})`,
                  opacity: 1 - Math.abs(phase) * style.fade,
                }}
              >
                {String(v).padStart(2, "0")}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
});
