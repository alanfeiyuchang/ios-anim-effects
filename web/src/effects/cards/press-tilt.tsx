/** cards.press-tilt · 按压倾斜 (Cards+PressTilt.swift) */
import { animate, useMotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, black, clamp, mix, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { CreditCard, Stage, persp, useMV } from "./shared";

const W = 250;
const H = 158;
const PREVIEW_POINTS = [
  { x: 0.85, y: -0.7 },
  { x: -0.8, y: 0.6 },
  { x: 0.1, y: 0.9 },
  { x: -0.6, y: -0.8 },
];

export default function PressTilt({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const pxMV = useMotionValue(0);
  const pyMV = useMotionValue(0);
  const prMV = useMotionValue(0);
  const [dent, setDent] = useState({ x: 0.5, y: 0.5 });
  const held = useRef(false);
  const step = useRef(0);
  const script = useRef(0);
  useEffect(() => () => window.clearTimeout(script.current), []);

  const pressDown = (point: { x: number; y: number }) => {
    setDent({ x: (point.x + 1) / 2, y: (point.y + 1) / 2 });
    const t = spring(0.18, 0.86);
    animate(pxMV, point.x, t);
    animate(pyMV, point.y, t);
    animate(prMV, 1, t);
  };
  const release = () => {
    const t = spring(ctx.n("response"), ctx.n("wobble"));
    animate(pxMV, 0, t);
    animate(pyMV, 0, t);
    animate(prMV, 0, t);
  };

  const pan = usePan({
    onChange: ({ location }) => {
      if (!held.current) {
        held.current = true;
        window.clearTimeout(script.current);
        haptics.tap("soft");
      }
      pressDown({ x: clamp((location.x / W - 0.5) * 2, -1, 1), y: clamp((location.y / H - 0.5) * 2, -1, 1) });
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      release();
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (held.current) return;
      const point = PREVIEW_POINTS[step.current % PREVIEW_POINTS.length];
      step.current += 1;
      pressDown(point);
      window.clearTimeout(script.current);
      script.current = window.setTimeout(release, 300);
    },
    { every: 1.5 },
  );

  const x = useMV(pxMV);
  const y = useMV(pyMV);
  const pr = useMV(prMV);
  const depth = ctx.n("depth");
  const p = persp(W, H, 0.5);

  return (
    <Stage gap={30}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: W, height: H, cursor: "pointer" }}>
        <div
          style={{
            position: "absolute",
            inset: 0,
            filter: `drop-shadow(${-x * 8}px ${mix(14, 5, pr)}px ${Math.max(0, mix(18, 8, pr))}px ${black(mix(0.24, 0.16, pr))})`,
          }}
        >
          <div style={{ position: "absolute", inset: 0, transform: `scale(${mix(1, 0.965, pr)})` }}>
            <div style={{ position: "absolute", inset: 0, transform: `${p} rotateY(${x * depth}deg)` }}>
              <div style={{ position: "absolute", inset: 0, transform: `${p} rotateX(${-y * depth}deg)` }}>
                <CreditCard
                  theme={3}
                  last4="2046"
                  overlay={
                    <div
                      style={{
                        position: "absolute",
                        inset: 0,
                        pointerEvents: "none",
                        opacity: clamp(pr, 0, 1),
                        background: `radial-gradient(circle 110px at ${dent.x * 100}% ${dent.y * 100}%, ${black(0.3)}, transparent)`,
                      }}
                    />
                  }
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Press anywhere on the card" zh="按压卡片任意位置" />
    </Stage>
  );
}
