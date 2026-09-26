/** gestures.pendulum-swing · 摆动工牌 (Gestures+PendulumSwing.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, alpha, anim, black, clamp, demoCard, fonts, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { PersonFill } from "./_b-icons";

export default function PendulumSwing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const dx = useMotionValue(0);
  const dy = useMotionValue(0);
  const angle = useMotionValue(0);
  const [dragging, setDragging] = useState(false);
  const draggingRef = useRef(false);
  const held = useRef(false);
  const relax = useRef<number | null>(null);
  const script = useRef<number[]>([]);

  const cancelRelax = () => {
    if (relax.current) window.clearTimeout(relax.current);
    relax.current = null;
  };
  const cancelScript = () => {
    script.current.forEach((t) => window.clearTimeout(t));
    script.current = [];
  };
  useEffect(
    () => () => {
      cancelRelax();
      cancelScript();
    },
    [],
  );

  const swing = () => spring(0.45, ctx.n("damping"));
  const lagAngle = (vx: number) => {
    const limit = ctx.n("maxAngle");
    return clamp((vx / 40) * ctx.n("sensitivity"), -limit, limit);
  };
  const setDrag = (v: boolean) => {
    draggingRef.current = v;
    setDragging(v);
  };

  const relaxWhenStill = () => {
    cancelRelax();
    relax.current = window.setTimeout(() => {
      relax.current = null;
      if (!draggingRef.current) return;
      animate(angle, 0, swing());
    }, 90);
  };

  const release = (haptic: boolean) => {
    cancelRelax();
    // Flying home to the left means the badge lags to the right, and vice versa.
    const kick = lagAngle(-dx.get() * 6);
    const back = spring(0.5, 0.7);
    animate(dx, 0, back);
    animate(dy, 0, back);
    setDrag(false);
    animate(angle, kick, swing());
    relax.current = window.setTimeout(() => {
      relax.current = null;
      animate(angle, 0, swing());
    }, 180);
    if (haptic) haptics.tap("soft");
  };

  const pan = usePan({
    onChange: ({ translation, velocity }) => {
      if (!held.current) {
        held.current = true;
        cancelScript();
        setDrag(true);
      }
      dx.stop();
      dy.stop();
      dx.set(translation.x);
      dy.set(translation.y);
      animate(angle, lagAngle(velocity.x), swing());
      relaxWhenStill();
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      release(true);
    },
  });

  const simulate = () => {
    if (held.current) return;
    const side = Math.random() < 0.5 ? 1 : -1;
    const t = anim.easeInOut(0.5);
    animate(dx, side * 90, t);
    animate(dy, 14, t);
    setDrag(true);
    animate(angle, lagAngle(side * 900), swing());
    cancelScript();
    script.current.push(
      window.setTimeout(() => animate(angle, 0, swing()), 550),
      window.setTimeout(() => release(false), 1000),
    );
  };
  useAutoplay(ctx.isPreview, simulate, { every: 2.4 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ transform: "translateY(-12px)" }}>
        <motion.div {...pan} style={{ x: dx, y: dy, touchAction: "none", cursor: "grab" }}>
          <motion.div style={{ rotate: angle, transformOrigin: "50% 0%", display: "flex", flexDirection: "column", alignItems: "center" }}>
            <div
              style={{
                position: "relative",
                zIndex: 1,
                top: 8,
                width: 12,
                height: 12,
                borderRadius: "50%",
                background: Palette.violet,
                display: "grid",
                placeItems: "center",
              }}
            >
              <div style={{ width: 4, height: 4, borderRadius: "50%", background: "#fff" }} />
            </div>
            <motion.div
              initial={false}
              animate={{
                boxShadow: dragging
                  ? `inset 0 0 0 1px ${Palette.stroke}, 0 10px 18px ${black(0.12)}, 0 14px 20px ${black(0.2)}`
                  : `inset 0 0 0 1px ${Palette.stroke}, 0 10px 18px ${black(0.12)}, 0 8px 12px ${black(0.12)}`,
              }}
              transition={dragging ? spring(0.25, 0.7) : spring(0.5, 0.7)}
              style={{ ...demoCard(22), position: "relative", width: 150, height: 200, overflow: "hidden" }}
            >
              <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 70, background: `linear-gradient(${alpha(Palette.violet, 0.28)}, transparent)` }} />
              <div style={{ position: "relative", display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
                <div style={{ marginTop: 14, width: 34, height: 8, borderRadius: 6, background: Palette.labelAlpha(0.1) }} />
                <div style={{ width: 56, height: 56, borderRadius: "50%", background: Palette.primary, display: "grid", placeItems: "center", color: "#fff" }}>
                  <PersonFill size={26} />
                </div>
                <div style={{ fontFamily: fonts.rounded, fontSize: 13, lineHeight: "16px", fontWeight: 800, letterSpacing: 2, color: Palette.violet, marginRight: -2 }}>
                  {ctx.t("GUEST", "访客")}
                </div>
                <div style={{ alignSelf: "stretch", padding: "0 22px" }}>
                  <PlaceholderLines count={2} />
                </div>
              </div>
            </motion.div>
          </motion.div>
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Drag the badge side to side" zh="左右拖动工牌" style={{ position: "absolute", left: 0, right: 0, bottom: 8 }} />
    </div>
  );
}
