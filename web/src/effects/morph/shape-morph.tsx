/** morph.shape-morph · 形状形变 (Morph+ShapeMorph.swift) */
import { AnimatePresence, animate, motion, useMotionValue } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, springDB, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { blurReplace, useMV } from "./_shared";

const names: [string, string][] = [
  ["Circle", "圆形"],
  ["Squircle", "超椭圆"],
  ["Blob", "液滴"],
  ["Flower", "花瓣"],
];

function radius(kind: number, theta: number) {
  switch (kind) {
    case 0:
      return 0.84;
    case 1: {
      const n = 5;
      const denom = Math.abs(Math.cos(theta)) ** n + Math.abs(Math.sin(theta)) ** n;
      return 0.8 / denom ** (1 / n);
    }
    case 2:
      return 0.84 + 0.09 * Math.sin(3 * theta + 0.6) + 0.05 * Math.cos(5 * theta - 0.4);
    default:
      return 0.8 + 0.14 * Math.cos(6 * theta);
  }
}

/** MorphingBlob.path(in: 200×200): 180 radial samples blended between two silhouettes. */
function blobPath(progress: number, size = 200) {
  const p = Math.max(progress, 0);
  const base = Math.floor(p);
  const t = p - base;
  const from = base % 4;
  const to = (from + 1) % 4;
  const c = size / 2;
  const scale = size / 2;
  let d = "";
  for (let i = 0; i < 180; i++) {
    const theta = (i / 180) * 2 * Math.PI;
    const r = (1 - t) * radius(from, theta) + t * radius(to, theta);
    d += `${i === 0 ? "M" : "L"}${(c + Math.cos(theta) * r * scale).toFixed(2)} ${(c + Math.sin(theta) * r * scale).toFixed(2)}`;
  }
  return d + "Z";
}

export default function ShapeMorph({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [step, setStep] = useState(0);
  const mv = useMotionValue(0);
  const progress = useMV(mv);
  const lang = ctx.lang === "zh" ? 1 : 0;

  const advance = () => {
    haptics.tap("soft");
    const next = step + 1;
    setStep(next);
    animate(mv, next, springDB(ctx.n("duration"), ctx.n("bounce")));
  };
  useAutoplay(ctx.isPreview, advance, { every: 1.4 });

  const d = blobPath(progress);
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 28 }}>
      <div
        onClick={advance}
        style={{
          position: "relative",
          width: 200,
          height: 200,
          cursor: "pointer",
          transform: `rotate(${ctx.b("spin") ? progress * 45 : 0}deg)`,
          filter: `hue-rotate(${progress * 40}deg)`,
        }}
      >
        <motion.svg
          viewBox="0 0 200 200"
          width={200}
          height={200}
          initial={{ opacity: 0.4, scale: 0.92 }}
          animate={{ opacity: 0.7, scale: 1.04 }}
          transition={{ duration: 1.6, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
          style={{ position: "absolute", inset: 0, overflow: "visible", filter: "blur(28px)" }}
        >
          <defs>
            <linearGradient id="sm-glow" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Palette.indigo} />
              <stop offset="1" stopColor={Palette.violet} />
            </linearGradient>
          </defs>
          <path d={d} fill="url(#sm-glow)" />
        </motion.svg>
        <svg viewBox="0 0 200 200" width={200} height={200} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <defs>
            <linearGradient id="sm-fill" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Palette.pink} />
              <stop offset="0.5" stopColor={Palette.violet} />
              <stop offset="1" stopColor={Palette.indigo} />
            </linearGradient>
          </defs>
          <path d={d} fill="url(#sm-fill)" />
          <path d={d} fill="none" stroke={white(0.35)} strokeWidth={1} />
        </svg>
      </div>
      <div style={{ position: "relative", height: 20, width: 200, display: "flex", justifyContent: "center" }}>
        <AnimatePresence initial={false} mode="popLayout">
          <motion.span
            key={step}
            {...blurReplace()}
            transition={springDB(ctx.n("duration"), ctx.n("bounce"))}
            style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}
          >
            {names[step % 4][lang]}
          </motion.span>
        </AnimatePresence>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 14 }}>
        <DemoHint ctx={ctx} en="Tap the shape" zh="点击图形" />
      </div>
    </div>
  );
}
