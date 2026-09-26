/** cards.jelly-swipe · 果冻滑卡 (Cards+JellySwipe.swift) */
import { animate, useMotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, black, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { DeckFace, Stage, predictEnd, useMV } from "./shared";

/** Area-preserving stretch from a signed strain tensor (e1, e2) = s·(cos 2θ, sin 2θ). */
function strainMatrix(e1: number, e2: number): string {
  const s = Math.sqrt(e1 * e1 + e2 * e2);
  if (s <= 0.0001) return "";
  const along = 1 + s;
  const across = 1 / along;
  const mean = (along + across) / 2;
  const half = (along - across) / 2;
  const a = mean + (half * e1) / s;
  const d = mean - (half * e1) / s;
  const b = (half * e2) / s;
  return `matrix(${a}, ${b}, ${b}, ${d}, 0, 0)`;
}

const POP_TIMES = [0, 0.12, 0.26, 0.4, 0.55].map((t) => t / 0.55);

export default function JellySwipe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [order, setOrder] = useState([0, 1, 2, 3, 4]);
  const ox = useMotionValue(0);
  const oy = useMotionValue(0);
  const e1 = useMotionValue(0);
  const e2 = useMotionValue(0);
  const popX = useMotionValue(1);
  const popY = useMotionValue(1);
  const [flinging, setFlinging] = useState(false);
  const flingingRef = useRef(false);
  const held = useRef(false);
  const relax = useRef(0);
  const target = useRef({ x: 0, y: 0 });
  const script = useRef<number[]>([]);
  const autoDirection = useRef(1);
  const clearScript = () => {
    script.current.forEach((id) => window.clearTimeout(id));
    script.current = [];
  };
  useEffect(
    () => () => {
      clearScript();
      window.clearTimeout(relax.current);
    },
    [],
  );

  const jelly = ctx.n("jelly");
  const threshold = ctx.n("threshold");

  /** `stretch = …` under `.animation(.spring(response: 0.28, dampingFraction: wobble), value: stretch)`. */
  const setStretch = (x: number, y: number) => {
    if (target.current.x === x && target.current.y === y) return;
    target.current = { x, y };
    const t = spring(0.28, ctx.n("wobble"));
    animate(e1, x, t);
    animate(e2, y, t);
  };

  const scheduleRelax = () => {
    window.clearTimeout(relax.current);
    relax.current = window.setTimeout(() => setStretch(0, 0), 80);
  };

  const fling = (direction: number) => {
    if (flingingRef.current) return;
    flingingRef.current = true;
    setFlinging(true);
    haptics.tap("medium");
    setStretch(0.18 * jelly, 0);
    const t = spring(0.38, 0.9);
    animate(ox, direction * 460, t);
    animate(oy, oy.get() + 30, t);
    window.setTimeout(() => {
      setOrder((o) => [...o.slice(1), o[0]]);
      ox.jump(0);
      oy.jump(0);
      e1.jump(0);
      e2.jump(0);
      target.current = { x: 0, y: 0 };
      flingingRef.current = false;
      setFlinging(false);
      // Next tick, so the new top card plays the pop.
      window.setTimeout(() => {
        const opts = { duration: 0.55, times: POP_TIMES, ease: "easeInOut" as const };
        animate(popX, [1, 1.08, 0.95, 1.02, 1], opts);
        animate(popY, [1, 0.92, 1.05, 0.98, 1], opts);
      }, 0);
    }, 300);
  };

  const pan = usePan(
    {
      onChange: ({ translation, velocity }) => {
        if (flingingRef.current) return;
        if (!held.current) {
          held.current = true;
          clearScript();
        }
        ox.jump(translation.x);
        oy.jump(translation.y);
        const speed = Math.hypot(velocity.x, velocity.y);
        if (speed > 1) {
          const amount = Math.min(speed / 3000, 1) * 0.18 * jelly;
          const theta = Math.atan2(velocity.y, velocity.x);
          setStretch(amount * Math.cos(2 * theta), amount * Math.sin(2 * theta));
        } else setStretch(0, 0);
        scheduleRelax();
      },
      onEnd: ({ translation, velocity }) => {
        if (!held.current || flingingRef.current) return;
        held.current = false;
        window.clearTimeout(relax.current);
        const predicted = predictEnd(translation.x, velocity.x);
        if (Math.abs(translation.x) > threshold || Math.abs(predicted) > threshold * 2) fling(predicted >= 0 ? 1 : -1);
        else {
          setStretch(0, 0);
          const t = spring(0.42, 0.6);
          animate(ox, 0, t);
          animate(oy, 0, t);
        }
      },
    },
    10,
  );

  useAutoplay(
    ctx.isPreview,
    () => {
      if (held.current || flingingRef.current) return;
      autoDirection.current = -autoDirection.current;
      const direction = autoDirection.current;
      const t = spring(0.35, 0.8);
      animate(ox, direction * 60, t);
      animate(oy, -4, t);
      setStretch(0.14 * jelly, 0);
      clearScript();
      script.current.push(window.setTimeout(() => setStretch(0, 0), 350));
      script.current.push(window.setTimeout(() => fling(direction), 800));
    },
    { every: 1.8 },
  );

  const x = useMV(ox);
  const y = useMV(oy);
  const s1 = useMV(e1);
  const s2 = useMV(e2);
  const px = useMV(popX);
  const py = useMV(popY);
  const progress = Math.min(Math.abs(x) / Math.max(threshold, 1), 1);

  return (
    <Stage gap={18}>
      <div style={{ position: "relative", width: 190, height: 280, flexShrink: 0 }}>
        {order.map((id, depth) => {
          const isTop = depth === 0;
          const slot = Math.max(depth - progress, 0);
          const appear = depth < 3 ? 1 : depth === 3 ? progress : 0;
          const transform = isTop
            ? `translate(${x}px, ${y}px) scale(${px}, ${py}) ${strainMatrix(s1, s2)}`
            : `translateY(${slot * 14}px) scale(${1 - slot * 0.05})`;
          return (
            <div
              key={id}
              {...(isTop && !flinging ? pan : {})}
              style={{
                position: "absolute",
                left: 0,
                top: 20,
                zIndex: order.length - depth,
                opacity: appear,
                transform,
                pointerEvents: isTop && !flinging ? "auto" : "none",
                touchAction: "none",
                cursor: isTop ? "grab" : undefined,
                borderRadius: 24,
                boxShadow: isTop ? `0 10px 16px ${black(0.18)}` : `0 6px 10px ${black(0.1)}`,
              }}
            >
              <DeckFace index={id} ctx={ctx} />
            </div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Drag fast and flick the card" zh="快速拖动并甩出卡片" />
    </Stage>
  );
}
