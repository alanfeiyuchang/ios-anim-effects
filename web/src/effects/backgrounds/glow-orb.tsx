/** backgrounds.glow-orb · 追随光球 (Backgrounds+GlowOrb.swift) */
import { animate, motion, useMotionTemplate, useMotionValue, useTransform } from "motion/react";
import { useLayoutEffect, useRef } from "react";
import { Palette, spring, useAutoplay, type DemoProps, type Point } from "../../kit";
import { BgHint, Layer, SampleTitle, Stage, circle, pixelRatio, prep, sizeOf, useBackgroundsTouch } from "./_support";

const TOUR: [number, number][] = [
  [0.25, 0.3],
  [0.75, 0.35],
  [0.7, 0.75],
  [0.3, 0.7],
  [0.5, 0.45],
];

function drawGrid(canvas: HTMLCanvasElement | null, w: number, h: number, k: number, color: string, radius: number) {
  const g = prep(canvas, w, h, k);
  if (!g) return;
  const spacing = 18;
  g.beginPath();
  for (let y = spacing / 2; y < h; y += spacing) for (let x = spacing / 2; x < w; x += spacing) circle(g, x, y, radius);
  g.fillStyle = color;
  g.fill();
}

export default function GlowOrb({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const dim = useRef<HTMLCanvasElement>(null);
  const bright = useRef<HTMLCanvasElement>(null);
  const x = useMotionValue(170);
  const y = useMotionValue(ctx.isPreview ? 153 : 180);
  const step = useRef(0);
  const diameter = ctx.n("size");
  const reach = diameter * 0.9;

  useLayoutEffect(() => {
    const { w, h } = sizeOf(root.current);
    x.set(w / 2);
    y.set(h * 0.45);
    const k = pixelRatio(root.current);
    drawGrid(dim.current, w, h, k, "rgba(255,255,255,0.1)", 1);
    drawGrid(bright.current, w, h, k, "rgba(255,255,255,0.85)", 1.5);
  }, [x, y]);

  const moveTo = (p: Point) => {
    const t = spring(ctx.n("response"), ctx.n("damping"));
    animate(x, p.x, t);
    animate(y, p.y, t);
  };

  const touch = useBackgroundsTouch((p) => moveTo(p));

  useAutoplay(
    ctx.isPreview,
    () => {
      const { w, h } = sizeOf(root.current);
      step.current += 1;
      const [ux, uy] = TOUR[step.current % TOUR.length];
      moveTo({ x: w * ux, y: h * uy });
    },
    { every: 1.3 },
  );

  const mask = useMotionTemplate`radial-gradient(circle ${reach}px at ${x}px ${y}px, #fff 0px, rgb(255 255 255 / 0.4) ${reach / 2}px, transparent ${reach}px)`;
  const left = useTransform(x, (v) => v - diameter / 2);
  const top = useTransform(y, (v) => v - diameter / 2);

  return (
    <Stage rootRef={root} background="#07080F" handlers={touch}>
      <Layer canvasRef={dim} />
      <motion.div style={{ position: "absolute", inset: 0, WebkitMaskImage: mask, maskImage: mask, pointerEvents: "none" }}>
        <Layer canvasRef={bright} />
      </motion.div>
      <motion.div
        style={{ position: "absolute", left: 0, top: 0, x: left, y: top, width: diameter, height: diameter, mixBlendMode: "plus-lighter", pointerEvents: "none" }}
      >
        <motion.div
          animate={{ scale: [1, 1.08], rotate: [0, 40] }}
          transition={{ duration: 2.2, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
          style={{ position: "absolute", inset: 0 }}
        >
          <div
            style={{
              position: "absolute",
              inset: 0,
              borderRadius: "50%",
              background: `conic-gradient(from 90deg, ${Palette.violet}, ${Palette.pink}, ${Palette.sky}, ${Palette.indigo}, ${Palette.violet})`,
              filter: `blur(${diameter * 0.25}px)`,
            }}
          />
          <div
            style={{
              position: "absolute",
              left: "50%",
              top: "50%",
              width: diameter * 0.16,
              height: diameter * 0.16,
              marginLeft: -diameter * 0.08,
              marginTop: -diameter * 0.08,
              borderRadius: "50%",
              background: "rgb(255 255 255 / 0.9)",
              filter: "blur(6px)",
            }}
          />
        </motion.div>
      </motion.div>
      <SampleTitle title={ctx.t("Move with intent", "专注而行")} subtitle={ctx.t("The workspace for focused teams", "为专注团队打造的工作空间")} size={26} top={38} />
      <BgHint ctx={ctx} en="Tap or drag sideways" zh="点击或横向拖动" />
    </Stage>
  );
}
