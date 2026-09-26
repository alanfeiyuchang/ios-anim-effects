/** buttons.magnetic · 磁吸按钮 (Buttons+Magnetic.swift) */
import { animate, motion, useMotionValue, useTransform, type MotionValue } from "motion/react";
import { Sparkles } from "lucide-react";
import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, clamp, spring, useAutoplay, useHaptics, useTimeouts, usePan, type DemoProps, type Point } from "../../kit";
import { BOUNCY, cubicKF, springKF, track, useSince } from "./_a-kit";

const PREVIEW_PATH: Point[] = [
  { x: 70, y: -40 },
  { x: 150, y: -110 },
  { x: -60, y: 34 },
  { x: -24, y: -56 },
  { x: -150, y: 100 },
];
const PRESS = [cubicKF(0.94, 0.08), springKF(1, 0.4, BOUNCY)];

const smoothstep = (e0: number, e1: number, x: number) => {
  const t = clamp((x - e0) / (e1 - e0));
  return t * t * (3 - 2 * t);
};

export default function Magnetic({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const stage = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState({ width: 340, height: ctx.isPreview ? 340 : 400 });
  useLayoutEffect(() => {
    const el = stage.current;
    if (el) setSize({ width: el.offsetWidth, height: el.offsetHeight });
  }, []);

  const radius = ctx.isPreview ? Math.min(ctx.n("radius"), 100) : ctx.n("radius");
  const strength = ctx.n("strength");
  const springT = spring(ctx.n("response"), ctx.n("damping"));

  const pullX = useMotionValue(0);
  const pullY = useMotionValue(0);
  const influence = useMotionValue(0);
  const fingerX = useMotionValue(0);
  const fingerY = useMotionValue(0);
  const [finger, setFinger] = useState(false);
  const captured = useRef(false);
  const step = useRef(0);
  const [presses, setPresses] = useState(0);
  const active = useRef(false);

  const track2 = (p: Point, simulated: boolean) => {
    const dx = p.x - size.width / 2;
    const dy = p.y - size.height / 2;
    const distance = Math.hypot(dx, dy);
    const weight = 1 - smoothstep(radius * 0.55, radius, distance);
    const inside = weight > 0.001;
    if (inside !== captured.current && !simulated) haptics.tap("soft");
    if (simulated) {
      if (!finger) {
        fingerX.set(p.x);
        fingerY.set(p.y);
      }
      animate(fingerX, p.x, anim.smoothD(0.8));
      animate(fingerY, p.y, anim.smoothD(0.8));
    } else {
      fingerX.stop();
      fingerY.stop();
      fingerX.set(p.x);
      fingerY.set(p.y);
    }
    setFinger(true);
    captured.current = inside;
    animate(influence, weight, springT);
    animate(pullX, dx * strength * weight, springT);
    animate(pullY, dy * strength * weight, springT);
  };

  const release = () => {
    if (!finger && !captured.current && pullX.get() === 0 && pullY.get() === 0) return;
    captured.current = false;
    animate(influence, 0, springT);
    animate(pullX, 0, springT);
    animate(pullY, 0, springT);
    setFinger(false);
  };

  const stepPreview = () => {
    const o = PREVIEW_PATH[step.current % PREVIEW_PATH.length];
    step.current += 1;
    track2({ x: size.width / 2 + o.x, y: size.height / 2 + o.y }, true);
  };

  const stopIntro = () => clearAll();

  useAutoplay(
    ctx.isPreview,
    () => {
      if (ctx.isPreview) {
        stepPreview();
        return;
      }
      stopIntro();
      stepPreview();
      after(1, () => {
        stepPreview();
        after(1, () => {
          stepPreview();
          after(1, release);
        });
      });
    },
    { every: 1.1, delay: 0.3 },
  );

  const hitRadius = Math.max(radius + 8, 100);
  const pan = usePan({
    onStart: ({ start }) => {
      active.current = Math.hypot(start.x - size.width / 2, start.y - size.height / 2) <= hitRadius;
      if (active.current) stopIntro();
    },
    onChange: ({ location }) => {
      if (active.current) track2(location, false);
    },
    onEnd: ({ location }) => {
      if (!active.current) return;
      active.current = false;
      const dx = location.x - (size.width / 2 + pullX.get());
      const dy = location.y - (size.height / 2 + pullY.get());
      if (Math.abs(dx) < 90 && Math.abs(dy) < 30) {
        haptics.tap("medium");
        setPresses((n) => n + 1);
      }
      release();
    },
  });
  useEffect(() => () => clearAll(), [clearAll]);

  const pressScale = track(useSince(presses, 0.5), 1, PRESS);
  const ringColor = useTransform(influence, (i) => Palette.labelAlpha(0.08 + 0.14 * i));

  return (
    <div ref={stage} {...pan} style={{ position: "absolute", inset: 0, touchAction: "none" }}>
      <svg
        width={radius * 2}
        height={radius * 2}
        style={{ position: "absolute", left: size.width / 2 - radius, top: size.height / 2 - radius, overflow: "visible", pointerEvents: "none" }}
      >
        <motion.circle cx={radius} cy={radius} r={radius - 0.5} fill="none" strokeWidth={1} strokeDasharray="4 6" style={{ stroke: ringColor }} />
      </svg>
      <div
        style={{
          position: "absolute",
          left: size.width / 2 - 90,
          top: size.height / 2 - 30,
          width: 180,
          height: 60,
          transform: `scale(${pressScale})`,
          pointerEvents: "none",
        }}
      >
        <Face pullX={pullX} pullY={pullY} influence={influence} title={ctx.lang === "zh" ? "开始体验" : "Get started"} />
      </div>
      <motion.div
        animate={{ opacity: finger ? 1 : 0 }}
        transition={finger ? { duration: 0 } : anim.easeOut(0.2)}
        style={{
          position: "absolute",
          left: -17,
          top: -17,
          x: fingerX,
          y: fingerY,
          width: 34,
          height: 34,
          borderRadius: "50%",
          background: Palette.labelAlpha(0.1),
          boxShadow: `inset 0 0 0 1px ${Palette.labelAlpha(0.25)}`,
          pointerEvents: "none",
        }}
      />
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
        <DemoHint ctx={ctx} en="Move your finger near the button" zh="手指靠近按钮移动" style={{ paddingBottom: 18 }} />
      </div>
    </div>
  );
}

function Face({ pullX, pullY, influence, title }: { pullX: MotionValue<number>; pullY: MotionValue<number>; influence: MotionValue<number>; title: string }) {
  const labelX = useTransform(pullX, (v) => v * 0.35);
  const labelY = useTransform(pullY, (v) => v * 0.35);
  const scale = useTransform(influence, (i) => 1 + 0.06 * i);
  const shadow = useTransform(influence, (i) => `0px ${8 + 6 * i}px ${14 + 8 * i}px rgb(110 123 255 / ${0.3 + 0.2 * i})`);
  return (
    <motion.div
      style={{
        x: pullX,
        y: pullY,
        scale,
        width: 180,
        height: 60,
        borderRadius: 30,
        background: Palette.primary,
        boxShadow: shadow,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        color: "#fff",
        fontSize: 17,
        fontWeight: 600,
        position: "relative",
      }}
    >
      <div style={{ position: "absolute", inset: 0, borderRadius: 30, boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.25)" }} />
      <motion.div style={{ x: labelX, y: labelY, display: "flex", alignItems: "center", gap: 8 }}>
        <Sparkles size={18} strokeWidth={2.2} />
        <span>{title}</span>
      </motion.div>
    </motion.div>
  );
}
