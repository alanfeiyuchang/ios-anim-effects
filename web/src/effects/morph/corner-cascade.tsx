/** morph.corner-cascade · 圆角接力 (Morph+CornerCascade.swift) */
import { AnimatePresence, animate, motion, useMotionValue } from "motion/react";
import { Circle, Droplet, Folder, Leaf, Square } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, anim, hex, springDB, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { backOut, blurReplace, useMV } from "./_shared";

/** Corner radii as fractions of the half side: top-leading, top-trailing, bottom-trailing, bottom-leading. */
const shapes = [
  [0.14, 0.14, 0.14, 0.14],
  [1, 1, 1, 1],
  [1, 0.1, 1, 0.1],
  [1, 1, 0.08, 1],
  [0.62, 0.62, 0.1, 0.1],
];
const names: [string, string][] = [
  ["Square", "方形"],
  ["Circle", "圆形"],
  ["Leaf", "叶片"],
  ["Drop", "水滴"],
  ["Tab", "标签"],
];
const symbols = [Square, Circle, Leaf, Droplet, Folder];
const SIZE = 180;

const reflected = (v: number) => (v > 1 ? Math.max(2 - v, 0) : v < 0 ? Math.min(-v, 1) : v);

function cascadePath(step: number, stagger: number, overshoot: number) {
  const s = Math.max(step, 0);
  const base = Math.floor(s);
  const t = s - base;
  const from = shapes[base % shapes.length];
  const to = shapes[(base + 1) % shapes.length];
  const half = SIZE / 2;
  const span = Math.max(1 - 3 * stagger, 0.1);
  const r = [0, 1, 2, 3].map((corner) => {
    const local = Math.min(Math.max((t - corner * stagger) / span, 0), 1);
    const value = from[corner] + (to[corner] - from[corner]) * backOut(local, overshoot);
    return reflected(value) * half;
  });
  const [tl, tr, br, bl] = r;
  const w = SIZE;
  const h = SIZE;
  return `M${tl} 0H${w - tr}A${tr} ${tr} 0 0 1 ${w} ${tr}V${h - br}A${br} ${br} 0 0 1 ${w - br} ${h}H${bl}A${bl} ${bl} 0 0 1 0 ${h - bl}V${tl}A${tl} ${tl} 0 0 1 ${tl} 0Z`;
}

export default function CornerCascade({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [target, setTarget] = useState(0);
  const mv = useMotionValue(0);
  const step = useMV(mv);
  const index = Math.floor(target) % shapes.length;
  const lang = ctx.lang === "zh" ? 1 : 0;

  const advance = () => {
    haptics.tap("soft");
    const next = target + 1;
    setTarget(next);
    animate(mv, next, springDB(ctx.n("duration"), 0));
  };
  useAutoplay(ctx.isPreview, advance, { every: 1.5 });

  const d = cascadePath(step, ctx.n("stagger"), ctx.n("overshoot"));
  const Icon = symbols[index];
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 26 }}>
      <div onClick={advance} style={{ position: "relative", width: SIZE, height: SIZE, cursor: "pointer", flexShrink: 0 }}>
        <svg
          viewBox={`0 0 ${SIZE} ${SIZE}`}
          width={SIZE}
          height={SIZE}
          style={{ position: "absolute", inset: 0, overflow: "visible", filter: `drop-shadow(0 10px 20px ${hex(Palette.indigo, 0.35)})` }}
        >
          <defs>
            <linearGradient id="cc-fill" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Palette.sky} />
              <stop offset="0.5" stopColor={Palette.indigo} />
              <stop offset="1" stopColor={Palette.violet} />
            </linearGradient>
          </defs>
          <path d={d} fill="url(#cc-fill)" />
          <path d={d} fill="none" stroke={white(0.5)} strokeWidth={1.5} />
        </svg>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: white(0.92) }}>
          <AnimatePresence initial={false} mode="popLayout">
            <motion.span
              key={index}
              initial={{ scale: 0.4, opacity: 0, filter: "blur(4px)" }}
              animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
              exit={{ scale: 0.4, opacity: 0, filter: "blur(4px)" }}
              transition={anim.snappyD(0.35)}
              style={{ display: "grid" }}
            >
              <Icon size={38} fill="currentColor" strokeWidth={1.4} />
            </motion.span>
          </AnimatePresence>
        </div>
      </div>
      <div style={{ height: 20, display: "flex", justifyContent: "center" }}>
        <AnimatePresence initial={false} mode="popLayout">
          <motion.span key={index} {...blurReplace()} transition={springDB(ctx.n("duration"), 0)} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>
            {names[index][lang]}
          </motion.span>
        </AnimatePresence>
      </div>
      <DemoHint ctx={ctx} en="Tap the tile" zh="点击方块" />
    </div>
  );
}
