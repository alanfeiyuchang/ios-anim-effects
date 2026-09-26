/** inputs.velocity-slider (Inputs+VelocitySlider.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform, type MotionValue } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, clamp, demoCard, fonts, spring, springDB, textStyle, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";

const WIDTH = 260;
const TARGETS = [0.82, 0.22, 0.64, 0.1, 0.5];

export default function VelocitySlider({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const value = useMotionValue(0.4);
  const tilt = useMotionValue(0);
  const raise = useMotionValue(0);
  const [shown, setShown] = useState(0.4);
  const [dragging, setDragging] = useState(false);
  const draggingRef = useRef(false);
  const settleTimer = useRef<() => void>(() => {});
  const step = useRef(0);
  useMotionValueEvent(value, "change", (v) => setShown(v));

  const setDrag = (on: boolean, t: ReturnType<typeof spring>) => {
    draggingRef.current = on;
    setDragging(on);
    animate(raise, on ? 1 : 0, t);
  };

  const settle = () => {
    const t = spring(0.5, ctx.n("damping"));
    animate(tilt, 0, t);
    setDrag(false, t);
  };

  const pan = usePan({
    onChange: ({ location, velocity }) => {
      const nv = clamp(location.x / WIDTH);
      if (Math.floor(nv * 10) !== Math.floor(value.get() * 10)) haptics.selection();
      value.jump(nv);
      setShown(nv);
      const swing = (-velocity.x / 40) * ctx.n("sensitivity");
      const t = spring(0.3, 0.5);
      if (!draggingRef.current) setDrag(true, t);
      animate(tilt, clamp(swing, -30, 30), t);
      settleTimer.current();
      settleTimer.current = after(0.08, () => animate(tilt, 0, spring(0.5, ctx.n("damping"))));
    },
    onEnd: () => {
      if (!draggingRef.current) return;
      settleTimer.current();
      settle();
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      const target = TARGETS[step.current % TARGETS.length];
      step.current += 1;
      const direction = target > value.get() ? 1 : -1;
      const t = spring(0.3, 0.5);
      setDrag(true, t);
      animate(tilt, -direction * 22 * clamp(ctx.n("sensitivity"), 0.2, 1.3), t);
      animate(value, target, springDB(0.7, 0));
      after(0.6, settle);
    },
    { every: 1.5, delay: 0.3 },
  );

  const x = useTransform(value, (v) => WIDTH * v);
  const fillW = useTransform(x, (v) => Math.max(8, v));
  const thumbX = useTransform(x, (v) => v - 14);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), padding: 18, display: "flex", flexDirection: "column", width: WIDTH + 36 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, ...textStyle.subheadline, fontWeight: 600 }}>
          <svg width={17} height={17} viewBox="0 0 24 24" style={{ color: Palette.blue }}>
            <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" strokeWidth={2.2} />
            <path d="M12 2a10 10 0 0 0 0 20Z" fill="currentColor" />
          </svg>
          <span>{ctx.t("Layer opacity", "图层不透明度")}</span>
        </div>
        <div {...pan} style={{ ...pan.style, position: "relative", width: WIDTH, height: 44, marginTop: 62, cursor: "pointer" }}>
          <div style={{ position: "absolute", left: 0, right: 0, top: 18, height: 8, borderRadius: 4, background: Palette.labelAlpha(0.1) }} />
          <motion.div style={{ position: "absolute", left: 0, top: 18, height: 8, borderRadius: 4, width: fillW, background: `linear-gradient(90deg, ${Palette.sky}, ${Palette.blue})` }} />
          <motion.div
            animate={{ scale: dragging ? 1.15 : 1 }}
            transition={dragging ? spring(0.3, 0.5) : spring(0.5, ctx.n("damping"))}
            style={{ position: "absolute", left: 0, top: 8, x: thumbX, width: 28, height: 28, borderRadius: "50%", background: "#fff", boxShadow: "0 2px 5px rgb(0 0 0 / 0.2)" }}
          />
          <Bubble x={x} tilt={tilt} raise={raise} percent={Math.round(shown * 100)} stretchOn={ctx.b("stretch")} />
        </div>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", width: WIDTH, height: 8, marginTop: 2 }}>
          {Array.from({ length: 11 }, (_, tick) => (
            <div
              key={tick}
              style={{
                width: 1.5,
                height: tick % 5 === 0 ? 8 : 4,
                borderRadius: 1,
                background: tick / 10 <= shown + 0.001 ? alpha(Palette.blue, 0.5) : Palette.labelAlpha(0.14),
              }}
            />
          ))}
        </div>
        <div style={{ display: "flex", justifyContent: "space-between", width: WIDTH, marginTop: 4, ...textStyle.caption2, fontWeight: 500, fontVariantNumeric: "tabular-nums", color: Palette.tertiaryLabel }}>
          <span>0%</span>
          <span>100%</span>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag fast, then stop" zh="快速拖动后停下" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Bubble({ x, tilt, raise, percent, stretchOn }: { x: MotionValue<number>; tilt: MotionValue<number>; raise: MotionValue<number>; percent: number; stretchOn: boolean }) {
  const bubbleX = useTransform(x, (v) => clamp(v, 22, WIDTH - 22));
  const shift = useTransform(() => clamp(x.get() - bubbleX.get(), -24, 24));
  const origin = useTransform(shift, (s) => `${(0.5 + s / 64) * 100}% 100%`);
  const left = useTransform(bubbleX, (b) => b - 32);
  const outerY = useTransform(raise, (r) => -10 * r);
  const outerScale = useTransform(raise, (r) => 0.85 + 0.15 * r);
  const stretch = useTransform(tilt, (t) => (stretchOn ? Math.min(Math.abs(t) / 30, 1) * 0.12 : 0));
  const sx = useTransform(stretch, (s) => 1 + s);
  const sy = useTransform(stretch, (s) => 1 - s * 0.6);
  // Bubble frame: 64 × 41 (34 body + 8 pointer − 1), centred 52 pt above the track's centre line.
  return (
    <motion.div
      style={{ position: "absolute", left, top: 22 - 52 - 20.5, width: 64, height: 41, y: outerY, scale: outerScale, transformOrigin: origin, filter: `drop-shadow(0 6px 10px ${alpha(Palette.blue, 0.3)})`, pointerEvents: "none" }}
    >
      <motion.div style={{ position: "absolute", inset: 0, rotate: tilt, transformOrigin: origin }}>
        <motion.div style={{ position: "absolute", inset: 0, scaleX: sx, scaleY: sy, transformOrigin: origin }}>
          <div
            style={{
              width: 64,
              height: 34,
              borderRadius: 11,
              background: Palette.blue,
              display: "grid",
              placeItems: "center",
              color: "#fff",
              fontFamily: fonts.rounded,
              fontSize: 16,
              fontWeight: 700,
              fontVariantNumeric: "tabular-nums",
            }}
          >
            {percent}%
          </div>
          <motion.svg width={14} height={8} style={{ position: "absolute", left: 25, top: 33, x: shift }}>
            <path d="M0 0 L14 0 L7 8 Z" fill={Palette.blue} />
          </motion.svg>
        </motion.div>
      </motion.div>
    </motion.div>
  );
}
