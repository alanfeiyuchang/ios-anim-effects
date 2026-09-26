/** inputs.jog-wheel (Inputs+JogWheel.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, clamp, fonts, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";

const SIZE = 220;

export default function JogWheel({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const rotationMV = useMotionValue(0);
  const [rotation, setRotation] = useState(0);
  useMotionValueEvent(rotationMV, "change", setRotation);
  const [spinning, setSpinningState] = useState(false);
  const spinningRef = useRef(false);
  const [spinSign, setSpinSign] = useState(1);
  const lastAngle = useRef<number | null>(null);
  const lastTime = useRef(0);
  const velocity = useRef(0);
  const generation = useRef(0);
  const step = useRef(0);
  const detent = ctx.n("detent");
  const setSpinning = (v: boolean) => {
    spinningRef.current = v;
    setSpinningState(v);
  };

  const coast = (extra: number) => {
    const capped = clamp(extra, -1080, 1080);
    if (Math.abs(capped) > 1) setSpinSign(capped > 0 ? 1 : -1);
    const duration = ctx.n("duration");
    animate(rotationMV, rotationMV.get() + capped, { type: "tween", duration, ease: [0.15, 0.7, 0.3, 1] });
    generation.current += 1;
    const current = generation.current;
    after(Math.abs(capped) > 1 ? duration : 0.1, () => {
      if (generation.current !== current || lastAngle.current !== null) return;
      setSpinning(false);
    });
  };

  const endSpin = () => {
    if (lastAngle.current === null) return;
    lastAngle.current = null;
    const idle = performance.now() / 1000 - lastTime.current > 0.08;
    coast((idle ? 0 : velocity.current) * ctx.n("coast"));
  };

  const pan = usePan({
    onChange: ({ location }) => {
      const dx = location.x - SIZE / 2;
      const dy = location.y - SIZE / 2;
      if (Math.hypot(dx, dy) <= 18) return;
      const angle = (Math.atan2(dy, dx) * 180) / Math.PI;
      const now = performance.now() / 1000;
      if (lastAngle.current !== null) {
        let delta = angle - lastAngle.current;
        if (delta > 180) delta -= 360;
        if (delta < -180) delta += 360;
        const dt = Math.max(now - lastTime.current, 0.001);
        velocity.current = velocity.current * 0.6 + (delta / dt) * 0.4;
        if (Math.abs(delta) > 0.5) setSpinSign(delta > 0 ? 1 : -1);
        const before = Math.floor(rotationMV.get() / detent);
        rotationMV.set(rotationMV.get() + delta);
        if (Math.floor(rotationMV.get() / detent) !== before) haptics.selection();
      } else {
        velocity.current = 0;
        generation.current += 1;
        rotationMV.stop();
      }
      lastAngle.current = angle;
      lastTime.current = now;
      if (!spinningRef.current) setSpinning(true);
    },
    onEnd: endSpin,
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      step.current += 1;
      setSpinning(true);
      coast((step.current % 2 === 0 ? -1 : 1) * 540);
    },
    { every: 2.2, delay: 0.3 },
  );

  const frames = Math.floor(rotation / detent);
  const total = Math.abs(frames);
  const seconds = Math.floor(total / 24);
  const p2 = (n: number) => String(n).padStart(2, "0");
  const timecode = `${frames < 0 ? "-" : ""}00:${p2(Math.floor(seconds / 60))}:${p2(seconds % 60)}:${p2(total % 24)}`;
  const light = ctx.scheme === "light";
  const disc = light
    ? "conic-gradient(from 90deg, #E4E6EC, #FFFFFF, #D4D7DF, #FFFFFF, #E4E6EC)"
    : "conic-gradient(from 90deg, #2A2C33, #3B3E47, #24262C, #3B3E47, #2A2C33)";
  // Blur arc: 28.8° trailing the well (SwiftUI trim starts at 3 o'clock; rotated so it sits behind the well).
  const arcStart = spinSign < 0 ? -90 + 1.2 : -90 - 30;
  const r = (SIZE * 0.66) / 2;
  const a0 = (arcStart * Math.PI) / 180;
  const a1 = ((arcStart + 28.8) * Math.PI) / 180;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18, transform: ctx.isPreview ? "scale(0.9)" : undefined }}>
        <div {...pan} style={{ ...pan.style, position: "relative", width: SIZE, height: SIZE, borderRadius: "50%", cursor: "grab" }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: disc, boxShadow: `0 10px 16px rgb(0 0 0 / ${light ? 0.18 : 0.5})` }} />
          <div style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }} />
          <div
            style={{
              position: "absolute",
              left: SIZE * 0.33,
              top: SIZE * 0.33,
              width: SIZE * 0.34,
              height: SIZE * 0.34,
              borderRadius: "50%",
              background: Palette.elevated,
              boxShadow: "0 2px 4px rgb(0 0 0 / 0.12)",
            }}
          />
          <div style={{ position: "absolute", inset: 0, transform: `rotate(${rotation}deg)` }}>
            {Array.from({ length: 36 }, (_, i) => (
              <div
                key={i}
                style={{
                  position: "absolute",
                  left: SIZE / 2 - 2.5,
                  top: 12 - 2.5,
                  width: 5,
                  height: 5,
                  borderRadius: "50%",
                  background: Palette.labelAlpha(0.14),
                  transformOrigin: `2.5px ${SIZE / 2 - 12 + 2.5}px`,
                  transform: `rotate(${i * 10}deg)`,
                }}
              />
            ))}
          </div>
          <div style={{ position: "absolute", inset: 0, transform: `rotate(${rotation}deg)` }}>
            <svg width={SIZE} height={SIZE} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
              <path
                d={`M${SIZE / 2 + r * Math.cos(a0)} ${SIZE / 2 + r * Math.sin(a0)} A${r} ${r} 0 0 1 ${SIZE / 2 + r * Math.cos(a1)} ${SIZE / 2 + r * Math.sin(a1)}`}
                fill="none"
                stroke={alpha(Palette.indigo, spinning ? 0.35 : 0)}
                strokeWidth={14}
                strokeLinecap="round"
                style={{ transition: "stroke 0.3s" }}
              />
            </svg>
            <div
              style={{
                position: "absolute",
                left: SIZE / 2 - 15,
                top: SIZE / 2 - SIZE * 0.33 - 15,
                width: 30,
                height: 30,
                borderRadius: "50%",
                background: "linear-gradient(rgb(0 0 0 / 0.18), rgb(255 255 255 / 0.2))",
                boxShadow: `inset 0 0 0 1px ${Palette.labelAlpha(0.1)}`,
              }}
            />
          </div>
        </div>
        <span style={{ fontFamily: fonts.mono, fontSize: 20, fontWeight: 600, lineHeight: "24px", color: spinning ? Palette.indigo : Palette.label }}>{timecode}</span>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Spin the wheel, then flick it" zh="转动轮盘，再甩一下试试" style={{ paddingBottom: 14 }} />
    </div>
  );
}
