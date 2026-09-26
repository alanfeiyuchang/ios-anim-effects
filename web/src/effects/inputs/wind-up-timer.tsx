/** inputs.wind-up-timer (Inputs+WindUpTimer.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, clamp, fonts, springDB, useAutoplay, useElapsed, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";
import { useAutoMute } from "./_a-common";

const SIZE = 210;

export default function WindUpTimer({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const { wrap, muted } = useAutoMute();
  const angleMV = useMotionValue(0);
  const [angle, setAngle] = useState(0);
  useMotionValueEvent(angleMV, "change", setAngle);
  const [rings, setRings] = useState(0);
  const running = useRef(false);
  const runID = useRef(0);
  const lastTouch = useRef<number | null>(null);
  const lastNotch = useRef(0);
  const grabbed = useRef(false);
  const rate = 6 * Math.max(ctx.n("speed"), 1);
  const notchDeg = 6 * Math.max(ctx.n("notch"), 1);

  const setImmediately = (v: number) => {
    angleMV.stop();
    angleMV.set(v);
  };

  const run = (silent: boolean) => {
    const a = angleMV.get();
    if (a <= 0.5) return;
    runID.current += 1;
    const id = runID.current;
    const duration = a / rate;
    running.current = true;
    animate(angleMV, 0, { type: "tween", ease: "linear", duration });
    after(duration, () => {
      if (id !== runID.current) return;
      running.current = false;
      lastNotch.current = 0;
      setRings((r) => r + 1);
      if (!silent) haptics.success();
    });
  };

  const freeze = () => {
    if (!running.current) return;
    running.current = false;
    runID.current += 1;
    setImmediately(angleMV.get());
  };

  const endWind = () => {
    if (!grabbed.current) return;
    grabbed.current = false;
    lastTouch.current = null;
    setImmediately(clamp(Math.round(angleMV.get() / notchDeg) * notchDeg, 0, 360));
    run(false);
  };

  const pan = usePan({
    onChange: ({ location }) => {
      grabbed.current = true;
      freeze();
      const dx = location.x - SIZE / 2;
      const dy = location.y - SIZE / 2;
      if (Math.hypot(dx, dy) <= 16) return;
      const touch = (Math.atan2(dy, dx) * 180) / Math.PI;
      if (lastTouch.current !== null) {
        let delta = touch - lastTouch.current;
        if (delta > 180) delta -= 360;
        if (delta < -180) delta += 360;
        const free = clamp(angleMV.get() + delta, 0, 360);
        setImmediately(free);
        const notch = Math.floor(free / notchDeg);
        if (notch !== lastNotch.current) {
          lastNotch.current = notch;
          haptics.selection();
        }
      }
      lastTouch.current = touch;
    },
    onEnd: endWind,
  });

  useAutoplay(
    ctx.isPreview,
    wrap(() => {
      if (running.current) return;
      animate(angleMV, 90, springDB(0.6, 0));
      const silent = muted();
      after(0.75, () => run(silent));
    }),
    { every: 5.0, delay: 0.3 },
  );

  // Ring wobble: ±shake decaying over ~0.5 s, then a smooth settle.
  const shake = ctx.n("shake");
  const e = useElapsed(rings, 0.6, true);
  const keys = [0, shake, -shake * 0.8, shake * 0.55, -shake * 0.35, shake * 0.15, 0];
  const times = [0, 0.06, 0.16, 0.26, 0.36, 0.46, 0.6];
  let wobble = 0;
  if (e >= 0 && e < 0.6) {
    const k = times.findIndex((t) => t > e) - 1;
    const p = (e - times[k]) / (times[k + 1] - times[k]);
    const s = p * p * (3 - 2 * p);
    wobble = keys[k] + (keys[k + 1] - keys[k]) * s;
  }
  // Index flare: up in 0.12 s, hold 0.25 s, fade over 0.6 s.
  const f = useElapsed(rings, 0.97, true);
  let flare = 0;
  if (f >= 0 && f < 0.97) flare = f < 0.12 ? f / 0.12 : f < 0.37 ? 1 : 1 - (f - 0.37) / 0.6;
  const rest = Math.max(0, 1 - angle / 6) * 0.35;
  const seconds = Math.ceil(angle / 6 - 1e-9);
  const R = SIZE / 2 - 22;
  const wedgeEnd = ((-90 + angle) * Math.PI) / 180;
  const wedge =
    angle > 0.1
      ? angle >= 359.9
        ? `M${SIZE / 2} ${SIZE / 2 - R} A${R} ${R} 0 1 1 ${SIZE / 2 - 0.01} ${SIZE / 2 - R} Z`
        : `M${SIZE / 2} ${SIZE / 2} L${SIZE / 2} ${SIZE / 2 - R} A${R} ${R} 0 ${angle > 180 ? 1 : 0} 1 ${SIZE / 2 + R * Math.cos(wedgeEnd)} ${SIZE / 2 + R * Math.sin(wedgeEnd)} Z`
      : "";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <motion.div
        {...pan}
        style={{
          ...pan.style,
          position: "relative",
          width: SIZE,
          height: SIZE,
          borderRadius: "50%",
          flexShrink: 0,
          cursor: "grab",
          transform: `${ctx.isPreview ? "scale(0.92) " : ""}rotate(${wobble}deg)`,
        }}
      >
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.elevated, boxShadow: "0 10px 16px rgb(0 0 0 / 0.16)" }} />
        <svg width={SIZE} height={SIZE} style={{ position: "absolute", inset: 0 }}>
          {wedge && <path d={wedge} fill={alpha(Palette.coral, 0.85)} />}
        </svg>
        <div style={{ position: "absolute", inset: 0, transform: `rotate(${angle}deg)` }}>
          {Array.from({ length: 12 }, (_, i) => (
            <div key={i} style={{ position: "absolute", inset: 0, paddingTop: 6, display: "flex", flexDirection: "column", alignItems: "center", gap: 3, transform: `rotate(${i * -30}deg)` }}>
              <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, lineHeight: "14px", color: Palette.secondaryLabel }}>{i * 5}</span>
              <div style={{ width: 2, height: 6, borderRadius: 1, background: Palette.labelAlpha(0.35) }} />
            </div>
          ))}
        </div>
        <div style={{ position: "absolute", left: SIZE / 2 - 35, top: SIZE / 2 - 35, width: 70, height: 70, borderRadius: "50%", background: Palette.elevated, boxShadow: "0 2px 5px rgb(0 0 0 / 0.12)" }} />
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", fontFamily: fonts.rounded, fontSize: 18, fontWeight: 700, fontVariantNumeric: "tabular-nums" }}>
          0:{String(seconds).padStart(2, "0")}
        </div>
        <svg
          width={14}
          height={12}
          style={{
            position: "absolute",
            left: SIZE / 2 - 7,
            top: -8,
            overflow: "visible",
            transformOrigin: "50% 0%",
            transform: `scale(${1 + 0.2 * flare})`,
            filter: `drop-shadow(0 0 ${(6 + 8 * flare) / 2}px ${alpha(Palette.red, Math.min(rest + 0.65 * flare, 1))})`,
          }}
        >
          <path d="M0 0 L14 0 L7 12 Z" fill={Palette.red} />
        </svg>
      </motion.div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Twist clockwise to wind, then let go" zh="顺时针拧动上发条，然后松手" style={{ paddingBottom: 14 }} />
    </div>
  );
}
