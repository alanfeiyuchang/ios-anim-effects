/** cards.bento-expand · 便当格展开 (Cards+BentoExpand.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { Crosshair, Footprints, Heart, Moon, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, black, delayed, spring, useAutoplay, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { Stage, diag, tr, type LText } from "./shared";

interface Tile {
  title: LText;
  Icon: LucideIcon;
  filled: boolean;
  colors: string[];
  detail: LText;
}

const TILES: Tile[] = [
  { title: ["Sleep", "睡眠"], Icon: Moon, filled: true, colors: [Palette.indigo, Palette.violet], detail: ["7 h 42 min · deep 1 h 50", "7 小时 42 分 · 深睡 1 小时 50 分"] },
  { title: ["Steps", "步数"], Icon: Footprints, filled: true, colors: [Palette.mint, Palette.sky], detail: ["9,214 steps · 6.8 km", "9214 步 · 6.8 公里"] },
  { title: ["Heart", "心率"], Icon: Heart, filled: true, colors: [Palette.pink, Palette.coral], detail: ["62 bpm resting · HRV 48 ms", "静息 62 次/分 · HRV 48 毫秒"] },
  { title: ["Focus", "专注"], Icon: Crosshair, filled: false, colors: [Palette.amber, Palette.coral], detail: ["3 sessions · 2 h 10 min", "3 个时段 · 2 小时 10 分"] },
];

const SIDE = 300;
const GAP = 10;

function frameFor(i: number, selected: number | null) {
  const half = (SIDE - GAP) / 2;
  if (selected === null) return { x: (i % 2) * (half + GAP), y: Math.floor(i / 2) * (half + GAP), w: half, h: half };
  const strip = 62;
  if (i === selected) return { x: 0, y: 0, w: SIDE, h: SIDE - strip - GAP };
  const others = [0, 1, 2, 3].filter((k) => k !== selected);
  const slot = others.indexOf(i);
  const w = (SIDE - GAP * 2) / 3;
  return { x: slot * (w + GAP), y: SIDE - strip, w, h: strip };
}

export default function BentoExpand({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState<number | null>(null);
  const step = useRef(0);
  const sp = spring(ctx.n("response"), ctx.n("damping"));

  const select = (i: number) => {
    haptics.tap("soft");
    setSelected((s) => (s === i ? null : i));
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      const sequence = [0, 2, null, 3, 1, null];
      setSelected(sequence[step.current % sequence.length]);
      step.current += 1;
    },
    { every: 1.6 },
  );

  return (
    <Stage gap={14}>
      <div style={{ position: "relative", width: SIDE, height: SIDE, flexShrink: 0 }}>
        {TILES.map((tile, i) => {
          const f = frameFor(i, selected);
          const hero = selected === i;
          const compact = selected !== null && !hero;
          return (
            <motion.div
              key={i}
              initial={false}
              animate={{ x: f.x, y: f.y, width: f.w, height: f.h }}
              transition={sp}
              onClick={() => select(i)}
              style={{ position: "absolute", left: 0, top: 0, cursor: "pointer" }}
            >
              <TileView tile={tile} hero={hero} compact={compact} ctx={ctx} transition={sp} />
            </motion.div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap a tile" zh="点击任意一块" />
    </Stage>
  );
}

function Glyph({ tile }: { tile: Tile }) {
  const { Icon } = tile;
  return (
    <div style={{ width: 40, height: 40, borderRadius: 12, background: diag(tile.colors), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
      <Icon size={22} fill={tile.filled ? "currentColor" : "none"} strokeWidth={tile.filled ? 0 : 2.4} />
    </div>
  );
}

function TileView({ tile, hero, compact, ctx, transition }: { tile: Tile; hero: boolean; compact: boolean; ctx: DemoContext; transition: Transition }) {
  const detailIn = (delay: number, rise: number) => ({
    initial: { opacity: 0, y: rise },
    animate: { opacity: 1, y: 0, transition: delayed(anim.easeOut(0.3), delay) },
    exit: { opacity: 0, y: rise, transition: anim.easeOut(0.3) },
  });
  return (
    <motion.div
      initial={false}
      animate={{
        borderRadius: compact ? 18 : 22,
        boxShadow: hero ? `inset 0 0 0 1px ${Palette.stroke}, 0 10px 16px ${black(0.16)}` : `inset 0 0 0 1px ${Palette.stroke}, 0 4px 8px ${black(0.08)}`,
      }}
      transition={transition}
      style={{ position: "absolute", inset: 0, background: Palette.elevated }}
    >
      <motion.div initial={false} animate={{ opacity: compact ? 1 : 0 }} transition={transition} style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", pointerEvents: "none" }}>
        <div style={{ transform: "scale(0.8)" }}>
          <Glyph tile={tile} />
        </div>
      </motion.div>
      <motion.div
        initial={false}
        animate={{ opacity: compact ? 0 : 1 }}
        transition={transition}
        style={{ position: "absolute", inset: 0, padding: 16, display: "flex", flexDirection: "column", gap: 8, overflow: "hidden", pointerEvents: "none" }}
      >
        <motion.div initial={false} animate={{ scale: hero ? 1.4 : 1, marginBottom: hero ? 12 : 0 }} transition={transition} style={{ transformOrigin: "0 0", alignSelf: "flex-start" }}>
          <Glyph tile={tile} />
        </motion.div>
        <div style={{ flex: 1, minHeight: 0 }} />
        <span style={{ fontSize: hero ? 20 : 17, lineHeight: hero ? "25px" : "22px", fontWeight: hero ? 700 : 600, whiteSpace: "nowrap" }}>{tr(ctx, tile.title)}</span>
        <AnimatePresence initial={false} mode="popLayout">
          {hero && (
            <motion.span key="detail" {...detailIn(0.15, 10)} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, color: Palette.secondaryLabel, whiteSpace: "nowrap" }}>
              {tr(ctx, tile.detail)}
            </motion.span>
          )}
          {hero && (
            <motion.div key="lines" {...detailIn(0.2, 14)}>
              <PlaceholderLines count={2} />
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </motion.div>
  );
}
