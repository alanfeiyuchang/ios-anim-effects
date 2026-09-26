/** buttons.parallax-tilt · 视差倾斜 (Buttons+ParallaxTilt.swift) */
import { animate, motion, useMotionValue, useTransform, type MotionValue, type Transition } from "motion/react";
import { useEffect, useRef } from "react";
import { DemoHint, Palette, alpha, black, clamp, spring, springDB, useAutoplay, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";
import { PlayTvFill } from "./_b-icons";

const W = 260;
const H = 120;
const PREVIEW_PATH: Point[] = [
  { x: 0.8, y: -0.6 },
  { x: -0.7, y: 0.5 },
  { x: 0.2, y: 0.9 },
  { x: -0.9, y: -0.7 },
  { x: 0, y: 0 },
];

const useT = (values: MotionValue<number>[], fn: (v: number[]) => string | number) => useTransform(values, fn);

export default function ParallaxTilt({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const tx = useMotionValue(0);
  const ty = useMotionValue(0);
  const act = useMotionValue(0);
  const activeRef = useRef(false);
  const step = useRef(0);
  const intro = useRef(0);

  const maxTilt = ctx.n("tilt");
  const depth = ctx.n("depth");

  const set = (p: Point, active: boolean, t: Transition) => {
    activeRef.current = active;
    animate(tx, p.x, t);
    animate(ty, p.y, t);
    animate(act, active ? 1 : 0, t);
  };

  const trackPoint = (point: Point) => {
    const nx = clamp((point.x / W) * 2 - 1, -1, 1);
    const ny = clamp((point.y / H) * 2 - 1, -1, 1);
    if (!activeRef.current) haptics.tap();
    set({ x: nx, y: ny }, true, spring(0.3, 0.7));
  };

  const release = () => {
    if (!activeRef.current && tx.get() === 0 && ty.get() === 0) return;
    set({ x: 0, y: 0 }, false, spring(0.45, 0.6));
  };

  const previewStep = () => {
    const target = PREVIEW_PATH[step.current % PREVIEW_PATH.length];
    step.current += 1;
    if (target.x === 0 && target.y === 0) {
      release();
      return;
    }
    set(target, true, springDB(0.8, 0));
  };

  const stopIntro = () => {
    intro.current += 1;
  };
  useEffect(() => stopIntro, []);

  const introSweep = () => {
    stopIntro();
    const run = intro.current;
    PREVIEW_PATH.forEach((_, i) => window.setTimeout(() => run === intro.current && previewStep(), i * 900));
  };

  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? previewStep() : introSweep()), { every: 0.9, delay: 0.3 });

  const pan = usePan({
    onChange: ({ location }) => {
      stopIntro();
      trackPoint(location);
    },
    onEnd: release,
  });

  const perspective = Math.max(W, H) / 0.5;
  const transform = useT([tx, ty, act], ([x, y, a]) => `perspective(${perspective}px) rotateY(${-x * maxTilt}deg) rotateX(${y * maxTilt}deg) scale(${1 + 0.04 * a})`);
  const shadow = useT([tx, ty, act], ([x, y, a]) => `${-x * 10}px ${10 - y * 8}px ${(14 + 8 * a) * 1.5}px ${alpha(Palette.coral, 0.25 + 0.2 * a)}`);
  const backdrop = useT([tx, ty], ([x, y]) => `translate(${-x * depth}px, ${-y * depth}px)`);
  const iconShift = useT([tx, ty], ([x, y]) => `translate(${x * depth * 0.6}px, ${y * depth * 0.6}px)`);
  const textShift = useT([tx, ty], ([x, y]) => `translate(${x * depth * 0.3}px, ${y * depth * 0.3}px)`);
  const glareShift = useT([tx, ty], ([x, y]) => `translate(${-x * W * 0.5}px, ${-y * H * 0.5}px)`);
  const glareOpacity = useT([act], ([a]) => a * 0.8);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <motion.div {...pan} style={{ position: "relative", width: W, height: H, flexShrink: 0, borderRadius: 24, transform, boxShadow: shadow, touchAction: "none", cursor: "pointer" }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: 24, overflow: "hidden", isolation: "isolate" }}>
          <motion.div style={{ position: "absolute", left: -depth, top: -depth, width: W + depth * 2, height: H + depth * 2, overflow: "hidden", transform: backdrop }}>
            <div style={{ position: "absolute", inset: 0, background: `linear-gradient(135deg, ${Palette.amber}, ${Palette.coral}, ${Palette.pink})` }} />
            <div style={{ position: "absolute", left: "50%", top: "50%", width: 120, height: 120, margin: "-60px 0 0 -60px", borderRadius: "50%", background: white(0.28), filter: "blur(20px)", transform: "translate(80px, -40px)" }} />
            <div style={{ position: "absolute", left: "50%", top: "50%", width: 140, height: 140, margin: "-70px 0 0 -70px", borderRadius: "50%", background: alpha(Palette.violet, 0.5), filter: "blur(26px)", transform: "translate(-90px, 50px)" }} />
          </motion.div>
          <div style={{ position: "absolute", inset: 0, padding: "0 22px", display: "flex", alignItems: "center", gap: 14, pointerEvents: "none" }}>
            <motion.div style={{ color: "#fff", filter: `drop-shadow(0 4px 6px ${black(0.25)})`, transform: iconShift }}>
              <PlayTvFill size={40} />
            </motion.div>
            <motion.div style={{ display: "flex", flexDirection: "column", gap: 3, transform: textShift }}>
              <div style={{ fontSize: 10, lineHeight: "12px", fontWeight: 800, letterSpacing: 1.2, color: white(0.8) }}>{ctx.t("NEW SEASON", "全新一季")}</div>
              <div style={{ fontSize: 22, lineHeight: "28px", fontWeight: 800, color: "#fff" }}>{ctx.t("Golden Hour", "黄金时刻")}</div>
            </motion.div>
          </div>
          {ctx.b("glare") && (
            <motion.div
              style={{
                position: "absolute",
                left: W / 2 - 110,
                top: H / 2 - 110,
                width: 220,
                height: 220,
                borderRadius: "50%",
                background: `radial-gradient(110px circle at 50% 50%, ${white(0.55)}, transparent)`,
                mixBlendMode: "plus-lighter",
                transform: glareShift,
                opacity: glareOpacity,
                pointerEvents: "none",
              }}
            />
          )}
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 24, boxShadow: `inset 0 0 0 1px ${white(0.25)}`, pointerEvents: "none" }} />
      </motion.div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press and drag over the tile" zh="按住卡片并拖动" style={{ paddingBottom: 18 }} />
    </div>
  );
}
