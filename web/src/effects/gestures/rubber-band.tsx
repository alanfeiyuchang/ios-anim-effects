/** gestures.rubber-band · 橡皮筋拖拽 (Gestures+RubberBand.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { Pointer } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, hex, rubberBand, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { TAU, useScript } from "./_a-common";

export default function RubberBand({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const dx = useMotionValue(0);
  const dy = useMotionValue(0);
  const [isDragging, setDragging] = useState(false);
  const [releaseAnim, setReleaseAnim] = useState(false);
  const held = useRef(false);
  const limit = ctx.n("limit");
  const coefficient = ctx.n("coefficient");

  const transform = useTransform(() => {
    const x = rubberBand(dx.get(), limit, coefficient);
    const y = rubberBand(dy.get(), limit, coefficient);
    const distance = Math.hypot(x, y);
    const stretch = 1 + Math.min(distance / Math.max(limit, 1), 1) * 0.08;
    const r = Math.atan2(y, x);
    return `translate(${x}px, ${y}px) rotate(${r}rad) scale(${stretch}, ${1 / stretch}) rotate(${-r}rad)`;
  });

  const release = (haptic = true) => {
    const s = spring(ctx.n("response"), ctx.n("damping"));
    animate(dx, 0, s);
    animate(dy, 0, s);
    setReleaseAnim(true);
    setDragging(false);
    if (haptic) haptics.tap("soft");
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!held.current) {
        held.current = true;
        script.cancel();
        dx.stop();
        dy.stop();
        setReleaseAnim(false);
        setDragging(true);
      }
      dx.set(translation.x);
      dy.set(translation.y);
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      release(true);
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (held.current) return;
      const angle = Math.random() * TAU;
      animate(dx, Math.cos(angle) * 260, spring(0.5, 0.9));
      animate(dy, Math.sin(angle) * 260, spring(0.5, 0.9));
      setReleaseAnim(true);
      setDragging(true);
      script.cancel();
      script.after(0.7, () => release(false));
    },
    { every: 1.5 },
  );

  const ring = Math.min(120 + limit * 2, 330);
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <motion.svg
        width={ring}
        height={ring}
        animate={{ opacity: isDragging ? 1 : 0 }}
        initial={false}
        transition={releaseAnim ? spring(ctx.n("response"), ctx.n("damping")) : anim.easeOut(0.2)}
        style={{ position: "absolute", left: 170 - ring / 2, top: "50%", marginTop: -ring / 2, overflow: "visible" }}
      >
        <circle cx={ring / 2} cy={ring / 2} r={ring / 2 - 0.75} fill="none" stroke={Palette.labelAlpha(0.18)} strokeWidth={1.5} strokeDasharray="4 6" />
      </motion.svg>
      <motion.div
        {...pan}
        style={{
          ...pan.style,
          transform,
          width: 120,
          height: 120,
          borderRadius: 30,
          background: Palette.primary,
          boxShadow: `0 12px 20px ${hex(Palette.indigo, 0.35)}`,
          display: "grid",
          placeItems: "center",
          color: white(0.95),
          cursor: "grab",
        }}
      >
        <Pointer size={40} strokeWidth={2.4} />
      </motion.div>
      <DemoHint ctx={ctx} en="Drag the tile in any direction" zh="向任意方向拖动方块" style={{ position: "absolute", left: 0, right: 0, bottom: 14 }} />
    </div>
  );
}
