/** inputs.dial-knob (Inputs+DialKnob.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, anim, clamp, fonts, rubberBand, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";

const KNOB = 170;
const PAD = 250;
const PREVIEW_STEPS = [7, 2, 9, 5, 10, 0];

export default function DialKnob({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const snaps = ctx.b("snap");
  const steps = Math.max(ctx.i("steps"), 2);
  const [index, setIndex] = useState(3);
  const [freeAngle, setFreeAngle] = useState(-81);
  const current = Math.min(index, steps - 1);
  const currentRef = useRef(current);
  currentRef.current = current;
  const lastRaw = useRef<number | null>(null);
  const atStop = useRef(false);
  const step = useRef(0);
  const tickAngle = (i: number) => -135 + (270 * i) / (steps - 1);

  const fraction = snaps ? current / (steps - 1) : clamp((freeAngle + 135) / 270);

  // Animated layers: base angle and arc fraction follow detents with `.snappy(duration:)`.
  const base = useMotionValue(snaps ? tickAngle(current) : freeAngle);
  const overshoot = useMotionValue(0);
  const arcFraction = useMotionValue(fraction);
  const rotate = useTransform(() => base.get() + overshoot.get());
  const [arcShown, setArcShown] = useState(fraction);
  useMotionValueEvent(arcFraction, "change", setArcShown);

  const previewAnim = useRef(false);
  useEffect(() => {
    if (snaps) {
      const t = anim.snappyD(ctx.n("response"));
      animate(base, tickAngle(current), t);
      animate(arcFraction, current / (steps - 1), t);
    } else if (previewAnim.current) {
      animate(base, freeAngle, anim.snappyD(0.3));
      arcFraction.jump(clamp((freeAngle + 135) / 270));
      setArcShown(clamp((freeAngle + 135) / 270));
    } else {
      base.jump(freeAngle);
      arcFraction.jump(clamp((freeAngle + 135) / 270));
      setArcShown(clamp((freeAngle + 135) / 270));
    }
    previewAnim.current = false;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [current, freeAngle, snaps, steps]);

  const endTurn = () => {
    if (lastRaw.current === null && !atStop.current && overshoot.get() === 0) return;
    lastRaw.current = null;
    atStop.current = false;
    animate(overshoot, 0, spring(0.35, 0.5));
  };

  const pan = usePan({
    onChange: ({ location }) => {
      const dx = location.x - PAD / 2;
      const dy = location.y - PAD / 2;
      if (Math.hypot(dx, dy) <= 14) return;
      const raw = (Math.atan2(dx, -dy) * 180) / Math.PI;
      if (lastRaw.current !== null && Math.abs(raw - lastRaw.current) > 180) return;
      lastRaw.current = raw;
      const angle = clamp(raw, -135, 135);
      setFreeAngle(angle);
      const beyond = raw - angle;
      overshoot.set(rubberBand(beyond, ctx.n("stretch")));
      const pinned = Math.abs(beyond) > 0.5;
      if (pinned && !atStop.current) haptics.tap("rigid");
      atStop.current = pinned;
      const newIndex = Math.round(((angle + 135) / 270) * (steps - 1));
      if (newIndex !== currentRef.current) {
        if (snaps) haptics.selection();
        setIndex(newIndex);
      }
    },
    onEnd: endTurn,
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      const target = PREVIEW_STEPS[step.current % PREVIEW_STEPS.length];
      step.current += 1;
      const next = Math.min(target, steps - 1);
      previewAnim.current = true;
      setIndex(next);
      setFreeAngle(tickAngle(next));
    },
    { every: 0.9, delay: 0.4 },
  );

  const lit = Math.round(fraction * (steps - 1));
  const light = ctx.scheme === "light";
  const R = (KNOB + 32) / 2;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div
        {...pan}
        style={{ ...pan.style, position: "relative", width: PAD, height: PAD, flexShrink: 0, transform: ctx.isPreview ? "scale(0.84)" : undefined, borderRadius: "50%", cursor: "grab" }}
      >
        {/* ticks */}
        {Array.from({ length: steps }, (_, i) => {
          const h = i === lit ? 14 : 9;
          return (
            <div
              key={i}
              style={{
                position: "absolute",
                left: PAD / 2 - 1.5,
                top: PAD / 2 - (KNOB / 2 + 30) - h / 2,
                width: 3,
                height: h,
                borderRadius: 1.5,
                background: i <= lit ? Palette.blue : Palette.labelAlpha(0.18),
                transformOrigin: `50% ${KNOB / 2 + 30 + h / 2}px`,
                transform: `rotate(${tickAngle(i)}deg)`,
                transition: "height 0.15s ease-out, top 0.15s ease-out, transform-origin 0.15s ease-out, background-color 0.15s ease-out",
              }}
            />
          );
        })}
        <Arc fraction={arcShown} r={R} />
        <Face light={light} />
        <motion.div style={{ position: "absolute", left: (PAD - KNOB) / 2, top: (PAD - KNOB) / 2, width: KNOB, height: KNOB, rotate, pointerEvents: "none" }}>
          <div style={{ position: "absolute", top: 16, left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 5 }}>
            <div style={{ width: 9, height: 9, borderRadius: "50%", background: Palette.sky, boxShadow: `0 0 5px ${alpha(Palette.sky, 0.9)}` }} />
            <div style={{ width: 2, height: 10, borderRadius: 1, background: Palette.labelAlpha(0.12) }} />
          </div>
        </motion.div>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", pointerEvents: "none" }}>
          <NumericText value={Math.round(fraction * 100)} style={{ fontFamily: fonts.rounded, fontSize: 30, fontWeight: 600, lineHeight: "36px" }} />
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag around the knob; push past the ends" zh="绕着旋钮拖动，试试顶到两端" style={{ paddingBottom: 16 }} />
    </div>
  );
}

/** Circle.trim(0, 0.75·fraction) rotated 135°, stroked with an angular sky → blue gradient (4 pt, round caps). */
function Arc({ fraction, r }: { fraction: number; r: number }) {
  const sweep = 270 * clamp(fraction);
  const c = PAD / 2;
  const pt = (deg: number) => {
    // SwiftUI angle 0 = 3 o'clock, clockwise; the trim starts at 135°.
    const a = ((135 + deg) * Math.PI) / 180;
    return [c + r * Math.cos(a), c + r * Math.sin(a)];
  };
  const segs = Math.max(1, Math.ceil(sweep / 4));
  const mixColor = (t: number) => {
    const a = [0x3a, 0xc4, 0xff];
    const b = [0x4f, 0x7c, 0xff];
    return `rgb(${a.map((v, i) => Math.round(v + (b[i] - v) * t)).join(" ")})`;
  };
  if (sweep <= 0.01) {
    const [x, y] = pt(0);
    return (
      <svg width={PAD} height={PAD} style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <circle cx={x} cy={y} r={2} fill={mixColor(0)} />
      </svg>
    );
  }
  return (
    <svg width={PAD} height={PAD} style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      {Array.from({ length: segs }, (_, i) => {
        const a0 = (sweep * i) / segs;
        const a1 = Math.min(sweep, (sweep * (i + 1)) / segs + 0.6);
        const [x0, y0] = pt(a0);
        const [x1, y1] = pt(a1);
        return <path key={i} d={`M${x0} ${y0} A${r} ${r} 0 0 1 ${x1} ${y1}`} stroke={mixColor(((a0 + a1) / 2) / 270)} strokeWidth={4} fill="none" strokeLinecap={i === 0 || i === segs - 1 ? "round" : "butt"} />;
      })}
    </svg>
  );
}

function Face({ light }: { light: boolean }) {
  const o = (PAD - KNOB) / 2;
  return (
    <div style={{ position: "absolute", left: o, top: o, width: KNOB, height: KNOB, pointerEvents: "none" }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: "50%",
          background: light ? "linear-gradient(135deg, #FFFFFF, #DADDE6)" : "linear-gradient(135deg, #3A3D48, #1B1D24)",
          boxShadow: `6px 12px 18px rgb(0 0 0 / ${light ? 0.18 : 0.5})`,
        }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: "50%",
          background: `linear-gradient(135deg, rgb(255 255 255 / ${light ? 0.9 : 0.18}), rgb(0 0 0 / ${light ? 0.08 : 0.4}))`,
          WebkitMaskImage: `radial-gradient(circle, transparent ${KNOB / 2 - 2.5}px, #000 ${KNOB / 2 - 2}px)`,
          maskImage: `radial-gradient(circle, transparent ${KNOB / 2 - 2.5}px, #000 ${KNOB / 2 - 2}px)`,
        }}
      />
      <div
        style={{
          position: "absolute",
          inset: 22,
          borderRadius: "50%",
          background: light ? "linear-gradient(135deg, #E9EBF1, #FFFFFF)" : "linear-gradient(135deg, #22242C, #33363F)",
        }}
      />
    </div>
  );
}
