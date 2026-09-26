/** cards.toss-swipe · 抛掷卡片 (Cards+TossSwipe.swift) */
import { animate, useMotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, anim, black, clamp, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { DeckFace, Stage, predictEnd, useMV } from "./shared";

const W = 180;
const H = 230;
const restAngle = (id: number) => ((id * 5) % 9) - 4;

export default function TossSwipe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [order, setOrder] = useState([4, 0, 1, 2, 3, 5]);
  const orderRef = useRef(order);
  orderRef.current = order;
  const dx = useMotionValue(0);
  const dy = useMotionValue(0);
  const gx = useMotionValue(0.5);
  const gy = useMotionValue(0.5);
  const sx = useMotionValue(0);
  const sy = useMotionValue(0);
  const tossX = useMotionValue(0);
  const tossY = useMotionValue(0);
  const tossSpin = useMotionValue(0);
  const lift = useMotionValue(1);
  const [tossing, setTossing] = useState(false);
  const tossingRef = useRef(false);
  const held = useRef(false);
  const autoDirection = useRef(1);
  const timers = useRef<number[]>([]);
  const later = (s: number, fn: () => void) => timers.current.push(window.setTimeout(fn, s * 1000));
  const cancelSequence = () => {
    timers.current.forEach((id) => window.clearTimeout(id));
    timers.current = [];
  };
  useEffect(() => cancelSequence, []);

  /** Moves the rotation anchor to the grab point without a visible hop. */
  const pickUp = (px: number, py: number) => {
    const theta = (restAngle(orderRef.current[0]) * Math.PI) / 180;
    const ddx = (px - 0.5) * W;
    const ddy = (py - 0.5) * H;
    gx.jump(px);
    gy.jump(py);
    sx.jump(ddx * Math.cos(theta) - ddy * Math.sin(theta) - ddx);
    sy.jump(ddx * Math.sin(theta) + ddy * Math.cos(theta) - ddy);
  };

  const putDown = () => {
    const t = spring(0.45, 0.65);
    [dx, dy, sx, sy].forEach((mv) => animate(mv, 0, t));
    animate(gx, 0.5, t);
    animate(gy, 0.5, t);
    animate(lift, 1, t);
  };

  const land = () => {
    setOrder((o) => [...o.slice(1), o[0]]);
    [dx, dy, tossX, tossY, tossSpin, sx, sy].forEach((mv) => mv.jump(0));
    gx.jump(0.5);
    gy.jump(0.5);
    tossingRef.current = false;
    setTossing(false);
    lift.jump(1);
    animate(lift, 1.03, spring(0.4, 0.7));
  };

  const toss = (direction: number) => {
    tossingRef.current = true;
    setTossing(true);
    haptics.tap("medium");
    animate(tossX, direction * 240, anim.easeOut(0.75));
    animate(tossSpin, direction * ctx.n("spin"), anim.easeOut(0.75));
    animate(tossY, -ctx.n("lift"), anim.easeOut(0.2));
    later(0.2, () => {
      animate(tossY, 460, anim.easeIn(0.55));
      later(0.58, () => {
        land();
        later(0.22, () => animate(lift, 1, spring(0.45, 0.7)));
      });
    });
  };

  const pan = usePan(
    {
      onChange: ({ translation, start }) => {
        if (!held.current) {
          held.current = true;
          cancelSequence();
          pickUp(clamp(start.x / W), clamp(start.y / H));
        }
        const t = spring(0.2, 0.8);
        animate(dx, translation.x, t);
        animate(dy, translation.y, t);
        animate(lift, 1.03, t);
      },
      onEnd: ({ translation, velocity }) => {
        if (!held.current) return;
        held.current = false;
        if (Math.hypot(translation.x, translation.y) > ctx.n("threshold")) toss(predictEnd(translation.x, velocity.x) >= 0 ? 1 : -1);
        else putDown();
      },
    },
    10,
  );

  useAutoplay(
    ctx.isPreview,
    () => {
      if (tossingRef.current || held.current) return;
      autoDirection.current = -autoDirection.current;
      const direction = autoDirection.current;
      pickUp(direction > 0 ? 0.8 : 0.2, 0.15);
      const t = spring(0.4, 0.75);
      animate(dx, direction * 50, t);
      animate(dy, -20, t);
      animate(lift, 1.03, t);
      cancelSequence();
      later(0.5, () => toss(direction));
    },
    { every: 1.9 },
  );

  const drag = { x: useMV(dx), y: useMV(dy) };
  const grab = { x: useMV(gx), y: useMV(gy) };
  const shift = { x: useMV(sx), y: useMV(sy) };
  const tx = useMV(tossX);
  const ty = useMV(tossY);
  const spin = useMV(tossSpin);
  const scale = useMV(lift);

  return (
    <Stage gap={16}>
      <div style={{ position: "relative", width: W, height: 270, flexShrink: 0 }}>
        {order.map((id, depth) => {
          const isTop = depth === 0;
          const rest = restAngle(id);
          const lever = grab.y < 0.5 ? 1 : -1;
          const swing = clamp((drag.x / 8) * lever, -18, 18);
          const angle = isTop ? rest + swing + spin : rest;
          const x = isTop ? drag.x + tx + shift.x : 0;
          const y = isTop ? drag.y + ty + shift.y : depth * 3;
          const interactive = isTop && !tossing;
          return (
            <div
              key={id}
              {...(interactive ? pan : {})}
              style={{
                position: "absolute",
                left: 0,
                top: 20,
                width: W,
                height: H,
                zIndex: order.length - depth,
                opacity: depth < 4 ? 1 : 0,
                transform: `translate(${x}px, ${y}px) scale(${isTop ? scale : 1})`,
                pointerEvents: interactive ? "auto" : "none",
                touchAction: "none",
                cursor: isTop ? "grab" : undefined,
              }}
            >
              <div
                style={{
                  transform: `rotate(${angle}deg)`,
                  transformOrigin: isTop ? `${grab.x * W}px ${grab.y * H}px` : "50% 50%",
                  borderRadius: 24,
                  boxShadow: isTop ? `0 10px 16px ${black(0.2)}` : `0 3px 6px ${black(0.08)}`,
                }}
              >
                <DeckFace index={id} ctx={ctx} width={W} height={H} />
              </div>
            </div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Grab the card anywhere and toss it" zh="从任意位置拎起卡片并抛出" />
    </Stage>
  );
}
