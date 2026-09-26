/** cards.turn-swipe · 旋转门滑卡 (Cards+TurnSwipe.swift) */
import { animate, useMotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, black, clamp, mix, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { DeckFace, Stage, persp, predictEnd, useMV } from "./shared";

export default function TurnSwipe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [order, setOrder] = useState([2, 3, 4, 5, 0]);
  const dragMV = useMotionValue(0);
  /** Outgoing card's angle once thrown, and the throw's progress for the cards behind. */
  const thrownMV = useMotionValue(0);
  const throwP = useMotionValue(0);
  const incomingMV = useMotionValue(0);
  const [thrownDir, setThrownDir] = useState<number | null>(null);
  const thrownRef = useRef<number | null>(null);
  const held = useRef(false);
  const autoDirection = useRef(1);
  const script = useRef(0);
  useEffect(() => () => window.clearTimeout(script.current), []);

  const threshold = Math.max(ctx.n("threshold"), 1);
  const maxAngle = ctx.n("maxAngle");

  const throwCard = (direction: number) => {
    haptics.tap("medium");
    const start = clamp((dragMV.get() / threshold) * maxAngle, -89, 89);
    thrownMV.jump(start);
    throwP.jump(0);
    thrownRef.current = direction;
    setThrownDir(direction);
    const t = spring(0.42, 0.88);
    animate(thrownMV, direction * 90, t);
    animate(throwP, 1, t);
    animate(dragMV, direction * ctx.n("threshold"), t);
    window.setTimeout(() => {
      setOrder((o) => [...o.slice(1), o[0]]);
      thrownRef.current = null;
      setThrownDir(null);
      dragMV.jump(0);
      thrownMV.jump(0);
      throwP.jump(0);
      incomingMV.jump(-direction * 25);
      window.setTimeout(() => animate(incomingMV, 0, spring(0.55, 0.7)), 0);
    }, 340);
  };

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (thrownRef.current !== null) return;
        if (!held.current) {
          held.current = true;
          window.clearTimeout(script.current);
        }
        dragMV.jump(translation.x);
      },
      onEnd: ({ translation, velocity }) => {
        if (!held.current) return;
        held.current = false;
        if (thrownRef.current !== null) return;
        const predicted = predictEnd(translation.x, velocity.x);
        if (Math.abs(translation.x) > ctx.n("threshold") || Math.abs(predicted) > ctx.n("threshold") * 2) {
          throwCard(predicted >= 0 ? 1 : -1);
          return;
        }
        animate(dragMV, 0, spring(0.45, 0.7));
      },
    },
    10,
  );

  useAutoplay(
    ctx.isPreview,
    () => {
      if (held.current || thrownRef.current !== null) return;
      autoDirection.current = -autoDirection.current;
      const direction = autoDirection.current;
      animate(dragMV, direction * 70, spring(0.45, 0.8));
      window.clearTimeout(script.current);
      script.current = window.setTimeout(() => throwCard(direction), 550);
    },
    { every: 1.7 },
  );

  const drag = useMV(dragMV);
  const thrown = useMV(thrownMV);
  const p = useMV(throwP);
  const incoming = useMV(incomingMV);
  const progress = Math.min(Math.abs(drag) / threshold, 1);
  const perspective = persp(190, 240, ctx.n("perspective"));

  return (
    <Stage gap={18}>
      <div style={{ position: "relative", width: 190, height: 270, flexShrink: 0 }}>
        {order.map((id, depth) => {
          const isTop = depth === 0;
          let angle = 0;
          let scale = 1;
          let y = 0;
          if (isTop) {
            angle = (thrownDir !== null ? thrown : clamp((drag / threshold) * maxAngle, -89, 89)) + incoming;
            scale = 1 - (Math.abs(incoming) / 25) * 0.08;
          } else if (depth === 1 && thrownDir !== null) {
            // The card behind already takes the incoming pre-turn (25° the other way, 92 %).
            angle = -(thrownDir >= 0 ? 1 : -1) * 25 * p;
            scale = mix(0.94, 0.92, p);
            y = mix(16, 0, p);
          } else {
            const slot = Math.max(depth - (thrownDir !== null ? p : 0), 0);
            scale = 1 - slot * 0.06;
            y = slot * 16;
          }
          const edge = Math.abs(Math.sin((angle * Math.PI) / 180));
          return (
            <div
              key={id}
              {...(isTop ? pan : {})}
              style={{
                position: "absolute",
                left: 0,
                top: 15,
                zIndex: order.length - depth,
                opacity: depth < 3 ? 1 : depth === 3 ? progress : 0,
                pointerEvents: isTop ? "auto" : "none",
                touchAction: "none",
                cursor: isTop ? "grab" : undefined,
                filter: `drop-shadow(0 8px 14px ${black(0.16)})`,
                transform: `translate(${isTop ? drag * 0.55 : 0}px, ${y}px) scale(${scale})`,
              }}
            >
              <div style={{ transform: `${perspective} rotateY(${angle}deg)` }}>
                <DeckFace index={id} ctx={ctx}>
                  <div style={{ position: "absolute", inset: 0, background: black(0.45 * edge) }} />
                </DeckFace>
              </div>
            </div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Swipe the card left or right" zh="左右滑动卡片" />
    </Stage>
  );
}
