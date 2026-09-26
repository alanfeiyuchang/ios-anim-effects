/** buttons.spotlight · 聚光卡片 (Buttons+Spotlight.swift) */
import { animate, motion, useMotionTemplate, useMotionValue } from "motion/react";
import { ChevronRight, Zap } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, black, localPoint, spring, springDB, useAutoplay, useHaptics, usePan, type DemoProps, type Point } from "../../kit";

const W = 290;
const H = 96;
const TINT = Palette.violet;
const PREVIEW_POINTS: Point[] = [
  { x: 250, y: 30 },
  { x: 150, y: 80 },
  { x: 30, y: 20 },
  { x: 200, y: 60 },
];

export default function Spotlight({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const sx = useMotionValue(60);
  const sy = useMotionValue(40);
  const light = useMotionValue(0);
  const [pressed, setPressed] = useState(false);
  const activeRef = useRef(false);
  const pressedRef = useRef(false);
  const step = useRef(0);
  const intro = useRef(0);
  const card = useRef<HTMLDivElement>(null);

  const setActive = (on: boolean, t = anim.easeOut(0.3)) => {
    activeRef.current = on;
    animate(light, on ? 1 : 0, t);
  };
  const moveSpot = (p: Point, t = springDB(Math.max(ctx.n("lag"), 0.05), 0)) => {
    animate(sx, p.x, t);
    animate(sy, p.y, t);
  };

  const move = (p: Point) => {
    if (!activeRef.current) {
      sx.jump(p.x);
      sy.jump(p.y);
      haptics.tap("soft");
      setActive(true, anim.easeOut(0.2));
    } else {
      moveSpot(p);
    }
  };

  const stopIntro = () => {
    intro.current += 1;
  };
  useEffect(() => stopIntro, []);

  const endTouch = () => {
    if (!pressedRef.current) return;
    pressedRef.current = false;
    setPressed(false);
    setActive(false);
  };

  const previewMove = () => {
    const point = PREVIEW_POINTS[step.current % PREVIEW_POINTS.length];
    step.current += 1;
    activeRef.current = true;
    light.jump(1);
    moveSpot(point, springDB(0.9, 0));
  };

  const introSweep = () => {
    stopIntro();
    const run = intro.current;
    let i = 0;
    const next = () => {
      if (run !== intro.current) return;
      if (i < 3) {
        previewMove();
        i += 1;
        window.setTimeout(next, 900);
      } else {
        setActive(false);
      }
    };
    next();
  };

  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? previewMove() : introSweep()), { every: 1.0, delay: 0.2 });

  const pan = usePan({
    onChange: ({ location }) => {
      stopIntro();
      if (!pressedRef.current) {
        pressedRef.current = true;
        setPressed(true);
      }
      move(location);
    },
    onEnd: endTouch,
  });

  const radius = ctx.n("radius");
  const intensity = ctx.n("intensity");
  const glowBg = useMotionTemplate`radial-gradient(${radius}px circle at ${sx}px ${sy}px, ${alpha(TINT, intensity)}, ${alpha(TINT, 0)})`;
  const ringMask = useMotionTemplate`radial-gradient(${radius}px circle at ${sx}px ${sy}px, #000, transparent)`;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <motion.div
        ref={card}
        {...pan}
        onPointerMove={(e) => {
          pan.onPointerMove(e);
          // `.onContinuousHover`: a mouse moving over the card steers the light without pressing.
          if (e.pointerType === "mouse" && !pressedRef.current && card.current) move(localPoint(e, card.current));
        }}
        onPointerLeave={() => {
          if (!pressedRef.current && activeRef.current) setActive(false);
        }}
        animate={{ scale: pressed ? 0.97 : 1 }}
        transition={spring(0.3, 0.6)}
        style={{
          position: "relative",
          width: W,
          height: H,
          flexShrink: 0,
          borderRadius: 22,
          overflow: "hidden",
          background: Palette.elevated,
          boxShadow: `0 10px 16px ${black(0.1)}`,
          touchAction: "none",
          cursor: "pointer",
        }}
      >
        <motion.div style={{ position: "absolute", inset: 0, background: glowBg, opacity: light, pointerEvents: "none" }} />
        <div style={{ position: "absolute", inset: 0, borderRadius: 22, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
        <motion.div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: 22,
            boxShadow: `inset 0 0 0 1.5px ${TINT}`,
            WebkitMaskImage: ringMask,
            maskImage: ringMask,
            opacity: light,
            pointerEvents: "none",
          }}
        />
        <div style={{ position: "absolute", inset: 0, padding: "0 20px", display: "flex", alignItems: "center", gap: 14, pointerEvents: "none" }}>
          <div
            style={{
              width: 48,
              height: 48,
              flexShrink: 0,
              borderRadius: 14,
              background: `linear-gradient(${alpha("#B98AFF", 1)}, ${TINT})`,
              display: "grid",
              placeItems: "center",
              color: "#fff",
            }}
          >
            <Zap size={22} fill="currentColor" strokeWidth={0} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 3, flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label, whiteSpace: "nowrap" }}>{ctx.t("Deploy to production", "部署到生产环境")}</div>
            <div style={{ fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel, whiteSpace: "nowrap" }}>{ctx.t("~42 s · 3 regions", "约 42 秒 · 3 个区域")}</div>
          </div>
          <ChevronRight size={15} strokeWidth={3.2} color={Palette.tertiaryLabel} />
        </div>
      </motion.div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag across the card" zh="在卡片上拖动手指" style={{ paddingBottom: 18 }} />
    </div>
  );
}
