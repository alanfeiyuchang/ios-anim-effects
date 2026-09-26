/** gestures.jelly-stretch · 果冻拉伸 (Gestures+Jelly.swift) */
import { animate, motion, useMotionValue, useTransform, type MotionValue } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, hex, spring, useAutoplay, usePan, white, type DemoProps, type Point } from "../../kit";
import { TAU, useScript } from "./_a-common";

/** `JellyStrain`: area-preserving stretch along θ from the signed tensor (e1, e2) = s·(cos 2θ, sin 2θ). */
function strainMatrix(e1: number, e2: number): string {
  const s = Math.hypot(e1, e2);
  if (s <= 0.0001) return "none";
  const along = 1 + s;
  const across = 1 / along;
  const mean = (along + across) / 2;
  const half = (along - across) / 2;
  const a = mean + (half * e1) / s;
  const d = mean - (half * e1) / s;
  const b = (half * e2) / s;
  return `matrix(${a}, ${b}, ${b}, ${d}, 0, 0)`;
}

export default function JellyStretch({ ctx }: DemoProps) {
  const script = useScript();
  const relax = useScript();
  const ox = useMotionValue(0);
  const oy = useMotionValue(0);
  const e1 = useMotionValue(0);
  const e2 = useMotionValue(0);
  const [isDragging, setDragging] = useState(false);
  const held = useRef(false);

  const home = () => spring(ctx.n("response"), ctx.n("damping"));
  const to = (mv: MotionValue<number>, v: number, t: ReturnType<typeof spring>) => animate(mv, v, t);

  const strainFor = (velocity: Point) => {
    const speed = Math.hypot(velocity.x, velocity.y);
    if (speed <= 1) return { x: 0, y: 0 };
    const s = Math.min((speed / 2000) * ctx.n("intensity"), 0.45);
    const theta = Math.atan2(velocity.y, velocity.x);
    return { x: s * Math.cos(2 * theta), y: s * Math.sin(2 * theta) };
  };

  const release = () => {
    const distance = Math.hypot(ox.get(), oy.get());
    const current = Math.hypot(e1.get(), e2.get());
    setDragging(false);
    if (current < 0.05 && distance > 24) {
      const s = Math.min((distance / 90) * 0.16 * ctx.n("intensity"), 0.24);
      const theta = Math.atan2(-oy.get(), -ox.get());
      to(e1, s * Math.cos(2 * theta), anim.easeOut(0.07));
      to(e2, s * Math.sin(2 * theta), anim.easeOut(0.07));
      relax.cancel();
      relax.after(0.07, () => {
        to(e1, 0, home());
        to(e2, 0, home());
      });
      to(ox, 0, home());
      to(oy, 0, home());
      return;
    }
    to(ox, 0, home());
    to(oy, 0, home());
    to(e1, 0, home());
    to(e2, 0, home());
  };

  const pan = usePan({
    onChange: ({ translation, velocity }) => {
      if (!held.current) {
        held.current = true;
        script.cancel();
        ox.stop();
        oy.stop();
        setDragging(true);
      }
      ox.set(translation.x);
      oy.set(translation.y);
      const st = strainFor(velocity);
      to(e1, st.x, spring(0.15, 0.86));
      to(e2, st.y, spring(0.15, 0.86));
      relax.cancel();
      relax.after(0.08, () => {
        if (!held.current) return;
        to(e1, 0, spring(0.3, 0.55));
        to(e2, 0, spring(0.3, 0.55));
      });
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      relax.cancel();
      release();
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (held.current) return;
      const angle = Math.random() * TAU;
      const st = strainFor({ x: Math.cos(angle) * 1600, y: Math.sin(angle) * 1600 });
      const ease = anim.easeOut(0.35);
      to(ox, Math.cos(angle) * 90, ease);
      to(oy, Math.sin(angle) * 70, ease);
      to(e1, st.x, ease);
      to(e2, st.y, ease);
      setDragging(true);
      script.cancel();
      script.after(0.45, () => {
        to(ox, 0, home());
        to(oy, 0, home());
        to(e1, -e1.get() * 0.6, home());
        to(e2, -e2.get() * 0.6, home());
        setDragging(false);
        script.after(0.12, () => {
          to(e1, 0, home());
          to(e2, 0, home());
        });
      });
    },
    { every: 1.9 },
  );

  const blobTransform = useTransform(() => `translate(${ox.get()}px, ${oy.get()}px) ${strainMatrix(e1.get(), e2.get())}`);
  const shadowX = useTransform(ox, (v) => v);
  const shadowY = useTransform(oy, (v) => 76 + Math.max(v, 0) * 0.2);

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <motion.div
        initial={false}
        animate={{ scale: isDragging ? 0.85 : 1 }}
        transition={isDragging ? spring(0.3, 0.7) : home()}
        style={{ position: "absolute", left: 115, top: "50%", marginTop: -11, width: 110, height: 22 }}
      >
        <motion.div
          style={{ x: shadowX, y: shadowY, width: 110, height: 22, borderRadius: "50%", background: hex(Palette.violet, 0.22), filter: "blur(10px)" }}
        />
      </motion.div>
      <motion.div {...pan} style={{ ...pan.style, transform: blobTransform, width: 110, height: 110, position: "relative", cursor: "grab" }}>
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: "50%",
            background: `linear-gradient(135deg, ${Palette.violet}, ${Palette.pink})`,
            boxShadow: `0 10px 18px ${hex(Palette.pink, 0.35)}, inset 0 0 0 1px ${white(0.25)}`,
            overflow: "hidden",
          }}
        >
          <div
            style={{
              position: "absolute",
              left: 55 - 17 - 22,
              top: 55 - 10 - 26,
              width: 34,
              height: 20,
              borderRadius: "50%",
              background: white(0.55),
              transform: "rotate(-35deg)",
              filter: "blur(1.5px)",
            }}
          />
        </div>
      </motion.div>
      <DemoHint ctx={ctx} en="Drag and flick the jelly" zh="拖动并甩动果冻" style={{ position: "absolute", left: 0, right: 0, bottom: 14 }} />
    </div>
  );
}
