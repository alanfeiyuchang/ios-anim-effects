/** morph.polygon-sides · 多边形拖拽形变 (Morph+PolygonSides.swift) */
import { AnimatePresence, animate, motion, useMotionValue } from "motion/react";
import { useRef } from "react";
import { DemoHint, NumericText, Palette, anim, clamp, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { blurReplace, useMV } from "./_shared";

const names: [string, string][] = [
  ["Triangle", "三角形"],
  ["Square", "四边形"],
  ["Pentagon", "五边形"],
  ["Hexagon", "六边形"],
  ["Heptagon", "七边形"],
  ["Octagon", "八边形"],
];

/** Distance from the centre to a regular n-gon's outline (circumradius 1, a vertex at theta = 0). */
function polyRadius(n: number, theta: number) {
  const segment = (2 * Math.PI) / n;
  let local = theta % segment;
  if (local < 0) local += segment;
  const half = segment / 2;
  return Math.cos(half) / Math.cos(local - half);
}

function polygonPath(sides: number, roundness: number, size = 190) {
  const clamped = Math.min(Math.max(sides, 2.6), 8.6);
  const low = Math.max(Math.floor(clamped), 3);
  const high = low + 1;
  const t = Math.min(Math.max(clamped - low, -0.4), 1.4);
  const c = size / 2;
  let d = "";
  for (let i = 0; i < 240; i++) {
    const theta = (i / 240) * 2 * Math.PI;
    const a = polyRadius(low, theta);
    const b = polyRadius(high, theta);
    const blended = a + (b - a) * t;
    const r = (blended * (1 - roundness) + 0.86 * roundness) * c;
    const angle = theta - Math.PI / 2;
    d += `${i === 0 ? "M" : "L"}${(c + Math.cos(angle) * r).toFixed(2)} ${(c + Math.sin(angle) * r).toFixed(2)}`;
  }
  return d + "Z";
}

export default function PolygonSides({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const mv = useMotionValue(3);
  const sides = useMV(mv);
  const target = useRef(3);
  const dragStart = useRef<number | null>(null);
  const dragged = useRef(false);
  const rounded = clamp(Math.round(sides), 3, 8);
  const lang = ctx.lang === "zh" ? 1 : 0;

  const snap = (value: number) => {
    target.current = value;
    animate(mv, value, spring(0.5, ctx.n("damping")));
  };
  const step = () => {
    const current = clamp(Math.round(mv.get()), 3, 8);
    haptics.selection();
    snap(current >= 8 ? 3 : current + 1);
  };
  useAutoplay(ctx.isPreview, step, { every: 1.1 });

  const pan = usePan(
    {
      onStart: () => {
        dragged.current = true;
      },
      onChange: ({ translation }) => {
        // pageSafeHorizontalDrag: only a mostly horizontal drag scrubs.
        if (dragStart.current === null) {
          if (Math.abs(translation.y) > Math.abs(translation.x)) return;
          dragStart.current = mv.get();
        }
        const before = clamp(Math.round(target.current), 3, 8);
        const raw = dragStart.current + translation.x / 36;
        const next = clamp(raw, 3, 8);
        target.current = next;
        animate(mv, next, spring(0.18, 0.86));
        if (clamp(Math.round(next), 3, 8) !== before) haptics.selection();
      },
      onEnd: () => {
        if (dragStart.current === null) return;
        dragStart.current = null;
        snap(clamp(Math.round(target.current), 3, 8));
      },
    },
    10,
  );

  const turn = ctx.b("spin") ? (sides - 3) * 30 : 0;
  const d = polygonPath(sides, ctx.n("round"));
  return (
    <div
      {...pan}
      onClick={() => {
        if (dragged.current) {
          dragged.current = false;
          return;
        }
        step();
      }}
      onPointerDown={(e) => {
        dragged.current = false;
        pan.onPointerDown(e);
      }}
      style={{ ...pan.style, position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 26 }}
    >
      <div style={{ position: "relative", width: 190, height: 190, transform: `rotate(${turn}deg)`, flexShrink: 0 }}>
        <svg viewBox="0 0 190 190" width={190} height={190} style={{ position: "absolute", inset: 0, overflow: "visible", filter: "blur(24px)", opacity: 0.5 }}>
          <defs>
            <linearGradient id="ps-glow" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Palette.amber} />
              <stop offset="0.5" stopColor={Palette.coral} />
              <stop offset="1" stopColor={Palette.pink} />
            </linearGradient>
          </defs>
          <path d={d} fill="url(#ps-glow)" />
        </svg>
        <svg viewBox="0 0 190 190" width={190} height={190} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <defs>
            <linearGradient id="ps-fill" x1="0" y1="0" x2="0" y2="1" gradientUnits="userSpaceOnUse" gradientTransform="scale(190)">
              <stop offset="0" stopColor={Palette.amber} />
              <stop offset="0.5" stopColor={Palette.coral} />
              <stop offset="1" stopColor={Palette.pink} />
            </linearGradient>
          </defs>
          <path d={d} fill="url(#ps-fill)" />
          <path d={d} fill="none" stroke={white(0.45)} strokeWidth={1.5} />
        </svg>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.secondaryLabel }}>
        <span style={{ position: "relative", display: "inline-flex", justifyContent: "flex-end" }}>
          <AnimatePresence initial={false} mode="popLayout">
            <motion.span key={rounded} {...blurReplace()} transition={anim.snappy}>
              {names[rounded - 3][lang]}
            </motion.span>
          </AnimatePresence>
        </span>
        <span style={{ color: Palette.tertiaryLabel }}>·</span>
        <NumericText value={rounded} />
      </div>
      <DemoHint ctx={ctx} en="Drag sideways · tap to add a side" zh="左右拖动 · 点击加一条边" />
    </div>
  );
}
