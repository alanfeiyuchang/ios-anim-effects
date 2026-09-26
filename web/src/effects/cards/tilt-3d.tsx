/** cards.tilt-3d · 3D 倾斜卡片 (Cards+Tilt3D.swift) */
import { animate, useMotionValue } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, black, clamp, spring, useClock, useHaptics, usePan, type DemoProps } from "../../kit";
import { CreditCard, Stage, persp, useMV } from "./shared";

const W = 250;
const H = 158;

export default function Tilt3D({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const tx = useMotionValue(0);
  const ty = useMotionValue(0);
  const lift = useMotionValue(0);
  const [touched, setTouched] = useState(false);
  const touchedRef = useRef(false);
  const touching = useRef(false);

  // Idle Lissajous drift until the first touch (full swing in previews, ~45 % on the detail stage).
  useClock(!touched, ctx.isPreview ? 30 : undefined);
  const sway = (t: number) => {
    const amount = ctx.isPreview ? 1 : 0.45;
    return { x: Math.sin(t * 1.3) * 0.85 * amount, y: Math.cos(t * 0.9) * 0.7 * amount };
  };

  const x = useMV(tx);
  const y = useMV(ty);
  const l = useMV(lift);
  const idle = sway(Date.now() / 1000);
  const tilt = touched ? { x, y } : idle;
  const lifted = touched ? l : ctx.isPreview ? 1 : 0;

  const pan = usePan({
    onChange: ({ location }) => {
      if (!touchedRef.current) {
        // Pick up from the idle pose instead of jumping.
        const s = sway(Date.now() / 1000);
        tx.set(s.x);
        ty.set(s.y);
        lift.set(ctx.isPreview ? 1 : 0);
        touchedRef.current = true;
        setTouched(true);
      }
      const nx = clamp((location.x / W - 0.5) * 2, -1, 1);
      const ny = clamp((location.y / H - 0.5) * 2, -1, 1);
      if (!touching.current) haptics.tap("soft");
      touching.current = true;
      const t = spring(ctx.n("follow"), 0.8);
      animate(tx, nx, t);
      animate(ty, ny, t);
      animate(lift, 1, t);
    },
    onEnd: () => {
      if (!touching.current) return;
      touching.current = false;
      const t = spring(ctx.n("response"), 0.6);
      animate(tx, 0, t);
      animate(ty, 0, t);
      animate(lift, 0, t);
    },
  });

  const maxAngle = ctx.n("angle");
  const glare = ctx.n("glare");
  const p = persp(W, H, 0.55);
  const shadowA = 0.2 + 0.12 * lifted;
  const shadowR = 16 + 10 * lifted;

  return (
    <Stage gap={28}>
      <div {...pan} style={{ ...pan.style, width: W, height: H, position: "relative", cursor: "grab" }}>
        <div style={{ position: "absolute", inset: 0, filter: `drop-shadow(${-tilt.x * 16}px ${16 - tilt.y * 8}px ${shadowR}px ${black(shadowA)})` }}>
          <div style={{ position: "absolute", inset: 0, transform: `scale(${1 + 0.04 * lifted})` }}>
            <div style={{ position: "absolute", inset: 0, transform: `${p} rotateY(${tilt.x * maxAngle}deg)` }}>
              <div style={{ position: "absolute", inset: 0, transform: `${p} rotateX(${-tilt.y * maxAngle}deg)` }}>
                <CreditCard
                  theme={0}
                  shift={{ x: -tilt.x * 14, y: -tilt.y * 10 }}
                  overlay={
                    <div
                      style={{
                        position: "absolute",
                        inset: 0,
                        mixBlendMode: "overlay",
                        pointerEvents: "none",
                        background: `radial-gradient(circle 190px at ${(0.5 + tilt.x * 0.5) * 100}% ${(0.5 + tilt.y * 0.5) * 100}%, rgb(255 255 255 / ${0.8 * glare}), rgb(255 255 255 / 0))`,
                      }}
                    />
                  }
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag across the card" zh="在卡片上拖动" />
    </Stage>
  );
}
