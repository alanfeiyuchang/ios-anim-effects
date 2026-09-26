/** morph.tile-mosaic · 瓷砖马赛克揭示 (Morph+TileMosaic.swift) */
import { animate, useMotionValue } from "motion/react";
import { CarFront, Flame, Waves } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, anim, black, localPoint, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { backOut, diag, useMV } from "./_shared";

const arts: { title: [string, string]; Icon: typeof Flame; fill: boolean; colors: string[] }[] = [
  { title: ["Night Drive", "夜行"], Icon: CarFront, fill: true, colors: ["#7B61FF", "#1B1464"] },
  { title: ["Tidal", "潮汐"], Icon: Waves, fill: false, colors: ["#21D4A8", "#2A6DF4"] },
  { title: ["Ember", "余烬"], Icon: Flame, fill: true, colors: ["#FFC247", "#FF4D5E"] },
];
const W = 260;
const H = 300;

function mosaicPath(progress: number, origin: { x: number; y: number }, columns: number, spread: number, overshoot: number) {
  const cell = W / columns;
  const rows = Math.ceil(H / cell);
  const ox = origin.x * W;
  const oy = origin.y * H;
  const maxDistance = Math.max(Math.hypot(W, H), 1);
  const span = Math.max(1 - spread, 0.1);
  let d = "";
  for (let row = 0; row < rows; row++) {
    for (let column = 0; column < columns; column++) {
      const cx = (column + 0.5) * cell;
      const cy = (row + 0.5) * cell;
      const delay = (Math.hypot(cx - ox, cy - oy) / maxDistance) * spread;
      const local = Math.min(Math.max((progress - delay) / span, 0), 1);
      if (local <= 0) continue;
      const side = cell * backOut(local, overshoot) + (local >= 1 ? 1 : 0);
      if (side <= 0) continue;
      const r = Math.min(Math.max(cell * 0.25 * (1 - local), 0), side / 2);
      const x = cx - side / 2;
      const y = cy - side / 2;
      d +=
        r > 0.01
          ? `M${x + r} ${y}H${x + side - r}A${r} ${r} 0 0 1 ${x + side} ${y + r}V${y + side - r}A${r} ${r} 0 0 1 ${x + side - r} ${y + side}H${x + r}A${r} ${r} 0 0 1 ${x} ${y + side - r}V${y + r}A${r} ${r} 0 0 1 ${x + r} ${y}Z`
          : `M${x} ${y}H${x + side}V${y + side}H${x}Z`;
    }
  }
  return d || "M0 0Z";
}

export default function TileMosaic({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const target = useRef(0);
  const autoIndex = useRef(0);
  const [origin, setOrigin] = useState({ x: 0.5, y: 0.5 });
  const mv = useMotionValue(0);
  const step = useMV(mv);
  const lang = ctx.lang === "zh" ? 1 : 0;

  const reveal = (point: { x: number; y: number }) => {
    haptics.tap("soft");
    setOrigin(point);
    target.current += 1;
    animate(mv, target.current, anim.linear(ctx.n("duration")));
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      const corners = [
        { x: 0, y: 0 },
        { x: 1, y: 1 },
        { x: 0.5, y: 0.5 },
        { x: 1, y: 0 },
      ];
      autoIndex.current += 1;
      reveal(corners[autoIndex.current % corners.length]);
    },
    { every: 1.6 },
  );

  const s = Math.max(step, 0);
  const base = Math.floor(s);
  const t = s - base;
  const d = mosaicPath(t, origin, Math.max(ctx.i("columns"), 2), ctx.n("spread"), ctx.n("overshoot"));

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div
        onClick={(e) => {
          const p = localPoint(e, e.currentTarget);
          reveal({ x: p.x / W, y: p.y / H });
        }}
        style={{ position: "relative", width: W, height: H, borderRadius: 28, overflow: "hidden", boxShadow: `0 10px 18px ${black(0.2)}`, cursor: "pointer", flexShrink: 0 }}
      >
        <Art art={arts[base % arts.length]} lang={lang} />
        <div style={{ position: "absolute", inset: 0, clipPath: `path('${d}')` }}>
          <Art art={arts[(base + 1) % arts.length]} lang={lang} />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap anywhere on the cover" zh="点击封面任意位置" />
    </div>
  );
}

function Art({ art, lang }: { art: (typeof arts)[number]; lang: number }) {
  const { Icon } = art;
  return (
    <div style={{ position: "absolute", inset: 0, background: diag(...art.colors) }}>
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: white(0.28) }}>
        <Icon size={120} strokeWidth={art.fill ? 1.2 : 2.6} fill={art.fill ? "currentColor" : "none"} />
      </div>
      <div style={{ position: "absolute", left: 20, bottom: 20, display: "flex", flexDirection: "column", gap: 4, color: "#fff" }}>
        <span style={{ fontSize: 22, lineHeight: "28px", fontWeight: 800 }}>{art.title[lang]}</span>
        <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, opacity: 0.75 }}>Motionary · EP</span>
      </div>
    </div>
  );
}
