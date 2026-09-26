/** morph.liquid-glass · 液态玻璃融合 (Morph+LiquidGlass.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { Camera, Image, Mic, Plus } from "lucide-react";
import { useMemo, useState } from "react";
import { DemoHint, Palette, fonts, hex, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { useMV } from "./_shared";

const actions = [Camera, Image, Mic];
const MAIN = 64;
const SMALL = 56;
const INSET = 12;
const HEIGHT = 100;
const STEP = 2;

/** Complementary error function (Abramowitz–Stegun 7.1.26). */
function erfc(x: number) {
  const z = Math.abs(x);
  const t = 1 / (1 + 0.3275911 * z);
  const y = t * (0.254829592 + t * (-0.284496736 + t * (1.421413741 + t * (-1.453152027 + t * 1.061405429)))) * Math.exp(-z * z);
  return x >= 0 ? y : 2 - y;
}

interface Disc {
  x: number;
  y: number;
  r: number;
}

/**
 * The metaball: discs blurred by `goo` and alpha-thresholded at 0.5 (the Canvas `alphaThreshold` on `blur`
 * trick), traced with marching squares. Returns the filled region as a path and its outline segments.
 */
function metaball(discs: Disc[], width: number, goo: number) {
  const sigma = Math.max(goo * 0.6, 0.5);
  const k = 1 / (sigma * Math.SQRT2);
  const cols = Math.ceil(width / STEP);
  const rows = Math.ceil(HEIGHT / STEP);
  const f: number[] = new Array((cols + 1) * (rows + 1));
  for (let j = 0; j <= rows; j++) {
    for (let i = 0; i <= cols; i++) {
      const px = i * STEP;
      const py = j * STEP;
      let v = 0;
      for (const d of discs) {
        const dist = Math.hypot(px - d.x, py - d.y);
        if (dist - d.r > sigma * 4) continue;
        v += 0.5 * erfc((dist - d.r) * k);
      }
      f[j * (cols + 1) + i] = v - 0.5;
    }
  }
  const at = (i: number, j: number) => f[j * (cols + 1) + i];
  let fill = "";
  let edge = "";
  const pt = (x: number, y: number) => `${x.toFixed(2)} ${y.toFixed(2)}`;
  for (let j = 0; j < rows; j++) {
    let runStart = -1;
    const flushRun = (end: number) => {
      if (runStart < 0) return;
      fill += `M${runStart * STEP} ${j * STEP}H${end * STEP}V${(j + 1) * STEP}H${runStart * STEP}Z`;
      runStart = -1;
    };
    for (let i = 0; i < cols; i++) {
      const a = at(i, j);
      const b = at(i + 1, j);
      const c = at(i + 1, j + 1);
      const d = at(i, j + 1);
      const inside = [a > 0, b > 0, c > 0, d > 0];
      if (inside.every(Boolean)) {
        if (runStart < 0) runStart = i;
        continue;
      }
      flushRun(i);
      if (!inside.some(Boolean)) continue;
      // Corners (clockwise) with the crossing points between them.
      const x0 = i * STEP;
      const y0 = j * STEP;
      const corners = [
        [x0, y0, a],
        [x0 + STEP, y0, b],
        [x0 + STEP, y0 + STEP, c],
        [x0, y0 + STEP, d],
      ] as const;
      const poly: [number, number][] = [];
      const crossings: [number, number][] = [];
      for (let n = 0; n < 4; n++) {
        const [px, py, pv] = corners[n];
        const [qx, qy, qv] = corners[(n + 1) % 4];
        if (pv > 0) poly.push([px, py]);
        if (pv > 0 !== qv > 0) {
          const t = pv / (pv - qv);
          const cp: [number, number] = [px + (qx - px) * t, py + (qy - py) * t];
          poly.push(cp);
          crossings.push(cp);
        }
      }
      fill += "M" + poly.map(([x, y]) => pt(x, y)).join("L") + "Z";
      for (let n = 0; n + 1 < crossings.length; n += 2) edge += `M${pt(...crossings[n])}L${pt(...crossings[n + 1])}`;
    }
    flushRun(cols);
  }
  return { fill: fill || "M0 0Z", edge };
}

export default function LiquidGlass({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [expanded, setExpanded] = useState(false);
  const mv = useMotionValue(0);
  const progress = useMV(mv);
  const gap = ctx.n("gap");
  const goo = 2 + ctx.n("spacing") * 0.22;
  const spr = spring(ctx.n("response"), 0.75);
  const width = INSET * 2 + MAIN + actions.length * (SMALL + gap);

  const toggle = () => {
    haptics.tap("medium");
    const next = !expanded;
    setExpanded(next);
    animate(mv, next ? 1 : 0, spr);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.8 });

  const shape = useMemo(() => {
    const cy = HEIGHT / 2;
    const mainX = INSET + MAIN / 2;
    const grow = Math.min(Math.max(progress, 0), 1);
    const r = (SMALL / 2) * (0.45 + 0.55 * grow);
    const discs: Disc[] = [{ x: mainX, y: cy, r: MAIN / 2 }];
    actions.forEach((_, i) => discs.push({ x: mainX + (MAIN / 2 + gap + SMALL / 2 + i * (SMALL + gap)) * progress, y: cy, r }));
    return metaball(discs, width, goo);
  }, [progress, gap, goo, width]);

  const tint = `linear-gradient(to right, ${hex(Palette.indigo, 0.6)} 0%, ${hex(Palette.indigo, 0.5)} 20%, ${white(0.14)} 34%, ${white(0.14)} 100%)`;
  const sheenTop = `linear-gradient(to bottom, ${white(0.35)}, transparent 50%)`;

  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
      <Backdrop />
      <div style={{ position: "absolute", left: "50%", top: "50%", width, height: HEIGHT, marginLeft: -width / 2, marginTop: -HEIGHT / 2 }}>
        <svg width={width} height={HEIGHT} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
          <path d={shape.fill} fill="rgb(0 0 0 / 0.15)" transform="translate(0 6)" style={{ filter: "blur(12px)" }} />
        </svg>
        <div
          style={{
            position: "absolute",
            inset: 0,
            clipPath: `path('${shape.fill}')`,
            background: `${sheenTop}, ${tint}`,
            backdropFilter: "blur(14px) saturate(1.8) brightness(1.08)",
            WebkitBackdropFilter: "blur(14px) saturate(1.8) brightness(1.08)",
          }}
        />
        {/* Specular rim: a bright edge that is strongest along the top of every drop. */}
        <svg width={width} height={HEIGHT} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
          <defs>
            <linearGradient id="lg-rim" x1="0" y1="0" x2="0" y2={HEIGHT} gradientUnits="userSpaceOnUse">
              <stop offset="0.2" stopColor="#fff" stopOpacity="0.85" />
              <stop offset="0.5" stopColor="#fff" stopOpacity="0.15" />
              <stop offset="0.8" stopColor="#fff" stopOpacity="0.5" />
            </linearGradient>
          </defs>
          <path d={shape.edge} fill="none" stroke="url(#lg-rim)" strokeWidth={1.4} strokeLinecap="round" />
        </svg>
        {actions.map((Icon, index) => {
          const travel = MAIN / 2 + gap + SMALL / 2 + index * (SMALL + gap);
          return (
            <motion.div
              key={index}
              onClick={toggle}
              initial={false}
              animate={{ scale: expanded ? 1 : 0.4, opacity: expanded ? 1 : 0, x: INSET + MAIN / 2 - SMALL / 2 + (expanded ? travel : 0) }}
              transition={spr}
              style={{
                position: "absolute",
                left: 0,
                top: (HEIGHT - SMALL) / 2,
                width: SMALL,
                height: SMALL,
                borderRadius: SMALL / 2,
                display: "grid",
                placeItems: "center",
                color: "#fff",
                cursor: "pointer",
                pointerEvents: expanded ? "auto" : "none",
              }}
            >
              <Icon size={22} strokeWidth={2.4} />
            </motion.div>
          );
        })}
        <motion.div
          onClick={toggle}
          whileTap={{ scale: 1.08 }}
          style={{ position: "absolute", left: INSET, top: (HEIGHT - MAIN) / 2, width: MAIN, height: MAIN, borderRadius: MAIN / 2, display: "grid", placeItems: "center", color: "#fff", cursor: "pointer" }}
        >
          <motion.span initial={false} animate={{ rotate: expanded ? 45 : 0 }} transition={spr} style={{ display: "grid" }}>
            <Plus size={27} strokeWidth={2.6} />
          </motion.span>
        </motion.div>
      </div>
      <div className="ml-dark" style={{ position: "absolute", left: 0, right: 0, bottom: 16, pointerEvents: "none" }}>
        <DemoHint ctx={ctx} en="Tap the + button" zh="点击“+”按钮" />
      </div>
    </div>
  );
}

function Backdrop() {
  return (
    <div style={{ position: "absolute", inset: 0, background: `linear-gradient(to bottom right, ${Palette.violet}, ${Palette.pink}, ${Palette.amber})` }}>
      <div style={{ position: "absolute", left: "50%", top: "50%", width: 180, height: 180, margin: "-90px 0 0 -90px", borderRadius: "50%", background: Palette.sky, filter: "blur(30px)", transform: "translate(-90px, -80px)" }} />
      <div style={{ position: "absolute", left: "50%", top: "50%", width: 140, height: 140, margin: "-70px 0 0 -70px", borderRadius: "50%", background: hex(Palette.mint, 0.8), filter: "blur(24px)", transform: "translate(110px, 90px)" }} />
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "grid",
          placeItems: "center",
          transform: "translateY(-6px)",
          fontFamily: fonts.rounded,
          fontSize: 120,
          fontWeight: 900,
          color: white(0.25),
        }}
      >
        Aa
      </div>
    </div>
  );
}
