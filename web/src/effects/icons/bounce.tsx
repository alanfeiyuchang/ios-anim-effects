/** icons.bounce · 符号弹跳 (Icons+Bounce.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, spring, useAutoplay, useHaptics, useTimeouts, white, type DemoProps } from "../../kit";
import { BOUNCE_DURATION, Glyph, SYM, bounceAt, sym, type GlyphDef, useSince } from "./_icons-kit";

const TILES: { def: GlyphDef; colors: [string, string] }[] = [
  { def: SYM.bellBadgeFill, colors: [Palette.coral, Palette.pink] },
  { def: SYM.trayArrowDownFill, colors: [Palette.sky, Palette.blue] },
  { def: SYM.personCircleBadgePlus, colors: [Palette.mint, Palette.green] },
  { def: SYM.paperplaneFill, colors: [Palette.indigo, Palette.violet] },
];

export default function Bounce({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [counts, setCounts] = useState([0, 0, 0, 0]);
  const [pressed, setPressed] = useState([false, false, false, false]);
  const [autoIndex, setAutoIndex] = useState(0);

  const tap = (i: number, haptic = true) => {
    setCounts((c) => c.map((v, k) => (k === i ? v + 1 : v)));
    if (haptic) haptics.tap("light");
  };

  const setPress = (i: number, value: boolean) => setPressed((p) => p.map((v, k) => (k === i ? value : v)));

  /** A simulated tap: dip the tile to 92% like a real press, then release and bounce the symbol. */
  const simulatePress = (i: number) => {
    setPress(i, true);
    after(0.12, () => {
      setPress(i, false);
      tap(i, false);
    });
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      simulatePress(autoIndex % TILES.length);
      setAutoIndex((n) => n + 1);
    },
    { every: 0.7 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 20 }}>
      <div style={{ display: "grid", gridTemplateColumns: "96px 96px", gap: 18 }}>
        {TILES.map((tile, i) => (
          <Tile
            key={i}
            def={tile.def}
            colors={tile.colors}
            count={counts[i]}
            down={ctx.i("direction") === 1}
            byLayer={ctx.b("byLayer")}
            speed={ctx.n("speed")}
            pressed={pressed[i]}
            onTap={() => tap(i)}
          />
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap any tile" zh="点击任意图标" />
    </div>
  );
}

function Tile({
  def,
  colors,
  count,
  down,
  byLayer,
  speed,
  pressed,
  onTap,
}: {
  def: GlyphDef;
  colors: [string, string];
  count: number;
  down: boolean;
  byLayer: boolean;
  speed: number;
  pressed: boolean;
  onTap: () => void;
}) {
  const [touching, setTouching] = useState(false);
  const s = Math.max(speed, 0.1);
  const elapsed = useSince(count, (BOUNCE_DURATION + 0.2) / s);
  const t = elapsed < 0 ? -1 : elapsed * s;
  const whole = bounceAt(t, down);
  const dip = pressed || touching;
  return (
    <button
      type="button"
      onClick={onTap}
      onPointerDown={() => setTouching(true)}
      onPointerUp={() => setTouching(false)}
      onPointerLeave={() => setTouching(false)}
      onPointerCancel={() => setTouching(false)}
      style={{ display: "block" }}
    >
      <motion.div
        animate={{ scale: dip ? 0.92 : 1 }}
        transition={pressed ? spring(0.2, 0.7) : spring(0.3, 0.6)}
        style={{
          width: 96,
          height: 96,
          borderRadius: 26,
          background: `linear-gradient(135deg, ${colors[0]}, ${colors[1]})`,
          boxShadow: `inset 0 0 0 1px ${white(0.25)}, 0 8px 14px color-mix(in srgb, ${colors[1]} 35%, transparent)`,
          display: "grid",
          placeItems: "center",
          color: "#fff",
        }}
      >
        <Glyph
          def={def}
          size={sym(38)}
          weight={1.05}
          style={byLayer ? undefined : { transform: `translateY(${whole.y * 38}px) scale(${whole.scale})`, transformOrigin: "50% 80%" }}
          layerStyle={
            byLayer
              ? (i) => {
                  const b = bounceAt(t < 0 ? -1 : t - i * 0.07, down);
                  return { transform: `translateY(${b.y * 24}px) scale(${b.scale})`, transformOrigin: "50% 80%" };
                }
              : undefined
          }
        />
      </motion.div>
    </button>
  );
}
