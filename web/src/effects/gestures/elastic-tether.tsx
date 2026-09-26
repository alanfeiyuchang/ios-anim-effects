/** gestures.elastic-tether · 弹力皮筋 (Gestures+ElasticTether.swift) */
import { animate, motion, useMotionValue, useTransform, type MotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, black, alpha, rubberBand, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";

/** Post tips and the pouch's rest point sit on this line (stage centre = origin). */
const POST_Y = -40;
const POST_X = 78;
const PULL_LIMIT = 140;
const C = 160; // centre of the 320 × 320 frame

const FORK = [
  `M ${C} ${C + 130} L ${C} ${C + 60}`,
  `Q ${C - POST_X} ${C + 50} ${C - POST_X} ${C + POST_Y}`,
  `M ${C} ${C + 60} Q ${C + POST_X} ${C + 50} ${C + POST_X} ${C + POST_Y}`,
].join(" ");

function bandPath(side: number, ex: number, ey: number, sag: number) {
  const px = C + side * POST_X;
  const py = C + POST_Y;
  const tx = C + ex;
  const ty = C + ey;
  const length = Math.hypot(tx - px, ty - py);
  const slack = Math.max(POST_X - length, 0);
  const stretch = Math.max(length - POST_X, 0);
  const cx = (px + tx) / 2;
  const cy = (py + ty) / 2 + slack * sag;
  return { d: `M ${px} ${py} Q ${cx} ${cy} ${tx} ${ty}`, width: Math.max(6 - stretch / 25, 2) };
}

function Band({ side, dx, dy, sag }: { side: number; dx: MotionValue<number>; dy: MotionValue<number>; sag: number }) {
  const d = useTransform(() => bandPath(side, dx.get(), POST_Y + dy.get(), sag).d);
  const w = useTransform(() => bandPath(side, dx.get(), POST_Y + dy.get(), sag).width);
  return <motion.path d={d} strokeWidth={w} stroke="url(#tether-band)" strokeLinecap="round" fill="none" />;
}

export default function ElasticTether({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const dx = useMotionValue(0);
  const dy = useMotionValue(0);
  const endY = useTransform(dy, (v) => POST_Y + v);
  const sx = useMotionValue(0);
  const sy = useMotionValue(POST_Y);
  const stoneScale = useMotionValue(1);
  const stoneAlpha = useMotionValue(1);
  const [dragging, setDragging] = useState(false);
  const firedRef = useRef(false);
  const setFired = (f: boolean) => {
    firedRef.current = f;
    if (!f) {
      sx.stop();
      sy.stop();
      sx.set(dx.get());
      sy.set(POST_Y + dy.get());
    }
  };
  useEffect(() => {
    const follow = () => {
      if (firedRef.current) return;
      sx.set(dx.get());
      sy.set(POST_Y + dy.get());
    };
    const a = dx.on("change", follow);
    const b = dy.on("change", follow);
    return () => {
      a();
      b();
    };
  }, [dx, dy, sx, sy]);
  const held = useRef(false);
  const reload = useRef<number | null>(null);
  const script = useRef<number | null>(null);

  useEffect(
    () => () => {
      if (reload.current) window.clearTimeout(reload.current);
      if (script.current) window.clearTimeout(script.current);
    },
    [],
  );

  const reloadNow = () => {
    if (reload.current) window.clearTimeout(reload.current);
    reload.current = null;
    setFired(false);
    stoneScale.stop();
    stoneAlpha.stop();
    stoneScale.set(1);
    stoneAlpha.set(1);
  };

  const fire = (fromX: number, fromY: number, pullX: number, pullY: number) => {
    sx.stop();
    sy.stop();
    sx.set(fromX);
    sy.set(fromY);
    setFired(true);
    const t = anim.easeOut(0.5);
    animate(sx, fromX - pullX * 2.5, t);
    animate(sy, fromY - pullY * 2.5, t);
    animate(stoneScale, 0.4, t);
    animate(stoneAlpha, 0, t);
    if (reload.current) window.clearTimeout(reload.current);
    reload.current = window.setTimeout(() => {
      reload.current = null;
      setFired(false);
      stoneScale.set(0.5);
      const s = spring(0.3, 0.55);
      animate(stoneScale, 1, s);
      animate(stoneAlpha, 1, s);
    }, 650);
  };

  const release = (haptic: boolean) => {
    const px = dx.get();
    const py = dy.get();
    const pulled = Math.hypot(px, py);
    const s = spring(ctx.n("response"), ctx.n("damping"));
    animate(dx, 0, s);
    animate(dy, 0, s);
    setDragging(false);
    if (pulled > 30) fire(px, POST_Y + py, px, py);
    if (haptic && pulled > 30) haptics.tap(pulled > 100 ? "rigid" : "light");
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!held.current) {
        held.current = true;
        if (script.current) window.clearTimeout(script.current);
        script.current = null;
        reloadNow();
        setDragging(true);
      }
      dx.stop();
      dy.stop();
      dx.set(rubberBand(translation.x, PULL_LIMIT));
      dy.set(rubberBand(translation.y, PULL_LIMIT));
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      release(true);
    },
  });

  const simulate = () => {
    if (held.current) return;
    reloadNow();
    const angle = 1.15 + Math.random() * 0.8;
    const reach = 105 + Math.random() * 30;
    const t = anim.easeOut(0.55);
    animate(dx, Math.cos(angle) * reach, t);
    animate(dy, Math.sin(angle) * reach, t);
    setDragging(true);
    if (script.current) window.clearTimeout(script.current);
    script.current = window.setTimeout(() => {
      script.current = null;
      release(false);
    }, 700);
  };
  useAutoplay(ctx.isPreview, simulate, { every: 2.4 });

  const sag = ctx.n("sag");
  const dragTrans = spring(0.25, 0.7);

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ position: "relative", width: 320, height: 320 }}>
        <svg width={320} height={320} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
          <defs>
            <linearGradient id="tether-fork" gradientUnits="userSpaceOnUse" x1={0} y1={320} x2={0} y2={0}>
              <stop offset={0} stopColor={Palette.indigo} />
              <stop offset={1} stopColor={Palette.violet} />
            </linearGradient>
            <linearGradient id="tether-band" gradientUnits="userSpaceOnUse" x1={0} y1={0} x2={320} y2={0}>
              <stop offset={0} stopColor={Palette.pink} />
              <stop offset={1} stopColor={Palette.coral} />
            </linearGradient>
          </defs>
          <path d={FORK} stroke="url(#tether-fork)" strokeWidth={14} strokeLinecap="round" strokeLinejoin="round" fill="none" style={{ filter: `drop-shadow(0 4px 3px ${black(0.12)})` }} />
          <circle cx={C - POST_X} cy={C + POST_Y} r={8} fill={Palette.violet} />
          <circle cx={C + POST_X} cy={C + POST_Y} r={8} fill={Palette.violet} />
          <Band side={-1} dx={dx} dy={dy} sag={sag} />
          <Band side={1} dx={dx} dy={dy} sag={sag} />
        </svg>
        {/* Pouch */}
        <motion.div style={{ position: "absolute", left: C - 27, top: C - 11, width: 54, height: 22, x: dx, y: endY, pointerEvents: "none" }}>
          <motion.div
            initial={false}
            animate={{ scale: dragging ? 1.06 : 1 }}
            transition={dragTrans}
            style={{ width: 54, height: 22, borderRadius: 11, background: "#7A4A32", boxShadow: `0 2px 3px ${black(0.2)}` }}
          />
        </motion.div>
        {/* Stone */}
        <motion.div
          style={{
            position: "absolute",
            left: C - 20,
            top: C - 20,
            width: 40,
            height: 40,
            x: sx,
            y: sy,
            scale: stoneScale,
            opacity: stoneAlpha,
            pointerEvents: "none",
          }}
        >
          <motion.div
            initial={false}
            animate={{ boxShadow: dragging ? `0 9px 14px ${alpha(Palette.pink, 0.4)}` : `0 5px 8px ${alpha(Palette.pink, 0.4)}` }}
            transition={dragTrans}
            style={{ width: 40, height: 40, borderRadius: "50%", background: `linear-gradient(135deg, ${Palette.pink}, ${Palette.violet})`, position: "relative" }}
          >
            <div style={{ position: "absolute", inset: 5, borderRadius: "50%", background: `linear-gradient(${white(0.6)}, transparent 50%)` }} />
          </motion.div>
        </motion.div>
        {/* Generous invisible handle on the pouch. */}
        <motion.div
          {...pan}
          style={{ position: "absolute", left: C - 38, top: C - 38, width: 76, height: 76, borderRadius: "50%", x: dx, y: endY, touchAction: "none", cursor: "grab" }}
        />
      </div>
      <DemoHint ctx={ctx} en="Draw the pouch back and let go" zh="向后拉动皮兜后松手" style={{ position: "absolute", left: 0, right: 0, bottom: 6 }} />
    </div>
  );
}
