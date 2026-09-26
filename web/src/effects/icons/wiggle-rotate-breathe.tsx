/** icons.wiggle-rotate-breathe · 摇摆 · 旋转 · 呼吸 (Icons+AmbientTrio.swift) */
import { motion } from "motion/react";
import { useRef, useState, type CSSProperties } from "react";
import { DemoHint, Palette, alpha, anim, demoCard, textStyle, useClock, useHaptics, type DemoProps } from "../../kit";
import { Glyph, SYM, breatheAt, rotateAt, sym, wiggleAt, type GlyphDef } from "./_icons-kit";

type Kind = "wiggle" | "rotate" | "breathe";
const PERIOD: Record<Kind, number> = { wiggle: 1.5, rotate: 1.25, breathe: 2 };

const TILES: { kind: Kind; en: string; zh: string; tint: string; def: GlyphDef }[] = [
  { kind: "wiggle", en: "Wiggle", zh: "摇摆", tint: Palette.green, def: SYM.phoneConnectionFill },
  { kind: "rotate", en: "Rotate", zh: "旋转", tint: Palette.blue, def: SYM.gearshape2Fill },
  { kind: "breathe", en: "Breathe", zh: "呼吸", tint: Palette.pink, def: SYM.boltHeartFill },
];

export default function WiggleRotateBreathe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [active, setActive] = useState([true, true, true]);
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div style={{ display: "flex", gap: 14 }}>
        {TILES.map((tile, i) => (
          <button
            key={tile.kind}
            type="button"
            onClick={() => {
              setActive((a) => a.map((v, k) => (k === i ? !v : v)));
              haptics.selection();
            }}
          >
            <motion.div
              initial={false}
              animate={{ opacity: active[i] ? 1 : 0.6 }}
              transition={anim.snappy}
              style={{ ...demoCard(22), width: 92, height: 132, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}
            >
              <div style={{ width: 60, height: 60, borderRadius: "50%", background: alpha(tile.tint, 0.14), display: "grid", placeItems: "center", color: tile.tint }}>
                <Ambient kind={tile.kind} def={tile.def} active={active[i]} speed={ctx.n("speed")} byLayer={ctx.b("byLayer")} fps={ctx.isPreview ? 30 : undefined} />
              </div>
              <span style={{ ...textStyle.footnote, fontWeight: 600, color: active[i] ? Palette.label : Palette.secondaryLabel, transition: "color 0.3s" }}>
                {ctx.t(tile.en, tile.zh)}
              </span>
            </motion.div>
          </button>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap a tile to pause it" zh="点击卡片暂停" />
    </div>
  );
}

/**
 * An indefinite symbol effect (`isActive:`). Turning it off lets the running cycle finish and rest,
 * turning it back on continues from rest.
 */
function Ambient({ kind, def, active, speed, byLayer, fps }: { kind: Kind; def: GlyphDef; active: boolean; speed: number; byLayer: boolean; fps?: number }) {
  const clock = useClock(true, fps);
  const s = Math.max(speed, 0.1);
  const period = PERIOD[kind] / s;
  const memo = useRef({ active, offset: 0, stopAt: Infinity });
  const m = memo.current;
  if (m.active !== active) {
    if (!active) m.stopAt = Math.ceil((clock - m.offset) / period) * period;
    else m.offset = clock - (Number.isFinite(m.stopAt) ? m.stopAt : 0);
    m.active = active;
  }
  const local = active ? clock - m.offset : Math.min(clock - m.offset, m.stopAt);
  const t = local * s;

  const whole = (dt = 0): CSSProperties => {
    const tt = Math.max(0, t - dt);
    if (kind === "wiggle") return { transform: `rotate(${wiggleAt(tt)}deg)` };
    if (kind === "rotate") return { transform: `rotate(${rotateAt(tt)}deg)` };
    const b = breatheAt(tt);
    return { transform: `scale(${b.scale})`, opacity: b.opacity };
  };

  const layer = (i: number): CSSProperties | undefined => {
    if (!byLayer) return undefined;
    if (kind === "rotate") {
      // Each gear turns on its own axis; the small one the other way round.
      const deg = rotateAt(t) * (i === 0 ? 1 : -1.4);
      return { transform: `rotate(${deg}deg)` };
    }
    return whole(i * 0.12);
  };

  return (
    <div style={byLayer ? undefined : whole()}>
      <Glyph def={def} size={sym(38)} layerStyle={layer} />
    </div>
  );
}
