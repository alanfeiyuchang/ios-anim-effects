/** cards.peek · 长按预览 (Cards+Peek.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { Flame, Flower2, Heart, MoonStar, Share, Trash2, Waves, type LucideIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, glass, spring, useAutoplay, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { diag, tr, type LText } from "./shared";

interface Tile {
  title: LText;
  Icon: LucideIcon;
  filled: boolean;
  colors: string[];
}

const TILES: Tile[] = [
  { title: ["Nightfall", "夜幕"], Icon: MoonStar, filled: true, colors: [Palette.indigo, Palette.violet] },
  { title: ["Tides", "潮汐"], Icon: Waves, filled: false, colors: [Palette.sky, Palette.blue] },
  { title: ["Bloom", "花开"], Icon: Flower2, filled: true, colors: [Palette.pink, Palette.coral] },
  { title: ["Ember", "余烬"], Icon: Flame, filled: true, colors: [Palette.amber, Palette.coral] },
];

const slot = (i: number) => ({ x: (i % 2 === 0 ? -1 : 1) * 67, y: (i < 2 ? -1 : 1) * 67 });

export default function Peek({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [peeked, setPeeked] = useState<number | null>(null);
  const [pressing, setPressing] = useState<number | null>(null);
  const [transition, setTransition] = useState<Transition>(spring(0.3, 0.7));
  const peekedRef = useRef<number | null>(null);
  peekedRef.current = peeked;
  const autoIndex = useRef(0);
  const timers = useRef<number[]>([]);
  const later = (s: number, fn: () => void) => timers.current.push(window.setTimeout(fn, s * 1000));
  const longPress = useRef(0);
  useEffect(
    () => () => {
      timers.current.forEach((id) => window.clearTimeout(id));
      window.clearTimeout(longPress.current);
    },
    [],
  );

  const peek = (i: number) => {
    if (peekedRef.current !== null) return;
    haptics.tap("medium");
    setTransition(spring(ctx.n("response"), 0.72));
    peekedRef.current = i;
    setPeeked(i);
    setPressing(null);
  };
  const dismiss = () => {
    setTransition(spring(ctx.n("response"), 0.8));
    peekedRef.current = null;
    setPeeked(null);
  };
  const press = (i: number | null, t = spring(0.3, 0.7)) => {
    setTransition(t);
    setPressing(i);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (peekedRef.current === null) {
        const index = autoIndex.current % 4;
        press(index, spring(0.25, 0.7));
        later(0.3, () => peek(index));
        // Detail intro: close the peek again so the stage is left at rest.
        if (!ctx.isPreview) later(1.7, () => peekedRef.current === index && dismiss());
        autoIndex.current += 1;
      } else dismiss();
    },
    { every: 1.6 },
  );

  /** The click that ends a long press must not close the peek it just opened. */
  const suppressClick = useRef(false);
  const tileHandlers = (i: number) => ({
    onPointerDown: () => {
      if (peekedRef.current !== null) return;
      press(i);
      window.clearTimeout(longPress.current);
      longPress.current = window.setTimeout(() => {
        suppressClick.current = true;
        peek(i);
      }, 350);
    },
    onPointerUp: () => {
      window.clearTimeout(longPress.current);
      if (peekedRef.current === null) press(null);
    },
    onPointerLeave: () => {
      window.clearTimeout(longPress.current);
      if (peekedRef.current === null) setPressing((p) => (p === i ? null : p));
    },
    onClick: () => {
      if (suppressClick.current) {
        suppressClick.current = false;
        return;
      }
      if (peekedRef.current !== null) dismiss();
    },
  });

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      {TILES.map((tile, i) => {
        const isPeeked = peeked === i;
        const dimmed = peeked !== null && !isPeeked;
        const s = slot(i);
        return (
          <motion.div
            key={i}
            initial={false}
            animate={{
              x: isPeeked ? 0 : s.x,
              y: isPeeked ? -52 : s.y,
              scale: isPeeked ? ctx.n("scale") : 1,
              filter: `blur(${dimmed ? ctx.n("blur") : 0}px)`,
            }}
            transition={transition}
            {...tileHandlers(i)}
            style={{ position: "absolute", left: 170 - 60, top: "calc(50% - 60px)", zIndex: isPeeked ? 2 : 0, cursor: "pointer" }}
          >
            <motion.div initial={false} animate={{ scale: pressing === i ? 0.95 : 1 }} transition={transition}>
              <TileView tile={tile} ctx={ctx} />
            </motion.div>
          </motion.div>
        );
      })}
      <motion.div
        initial={false}
        animate={{ opacity: peeked === null ? 0 : 0.22 }}
        transition={transition}
        onClick={dismiss}
        style={{ position: "absolute", inset: 0, background: "#000", zIndex: 1, pointerEvents: peeked !== null ? "auto" : "none" }}
      />
      <div style={{ position: "absolute", left: 170 - 95, top: "calc(50% + 104px - 58px)", width: 190, zIndex: 3, pointerEvents: peeked !== null ? "auto" : "none" }}>
      <AnimatePresence>
        {peeked !== null && (
          <motion.div
            key="menu"
            initial={{ scale: 0.85, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.85, opacity: 0 }}
            transition={transition}
            onClick={() => {
              haptics.selection();
              dismiss();
            }}
            style={{ transformOrigin: "50% 0", cursor: "pointer" }}
          >
            <Menu ctx={ctx} />
          </motion.div>
        )}
      </AnimatePresence>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 10, opacity: peeked === null ? 1 : 0, pointerEvents: "none", zIndex: 4 }}>
        <DemoHint ctx={ctx} en="Long-press a tile" zh="长按任一卡片" />
      </div>
    </div>
  );
}

function TileView({ tile, ctx }: { tile: Tile; ctx: DemoContext }) {
  const { Icon } = tile;
  return (
    <div style={{ position: "relative", width: 120, height: 120, borderRadius: 26, background: diag(tile.colors), boxShadow: `0 6px 10px ${black(0.14)}`, overflow: "hidden" }}>
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", transform: "translateY(-10px)", color: "#fff", filter: `drop-shadow(0 3px 6px ${black(0.15)})` }}>
        <Icon size={44} fill={tile.filled ? "currentColor" : "none"} strokeWidth={tile.filled ? 0.8 : 2.4} />
      </div>
      <span style={{ position: "absolute", left: 12, bottom: 12, fontSize: 12, lineHeight: "16px", fontWeight: 700, color: "#fff" }}>{tr(ctx, tile.title)}</span>
    </div>
  );
}

function Menu({ ctx }: { ctx: DemoContext }) {
  const row = (title: string, Icon: LucideIcon, tint: string) => (
    <div style={{ display: "flex", alignItems: "center", height: 38, padding: "0 14px", color: tint, fontSize: 15 }}>
      <span>{title}</span>
      <span style={{ flex: 1 }} />
      <Icon size={17} strokeWidth={1.8} />
    </div>
  );
  const divider = <div style={{ height: 0.5, background: Palette.labelAlpha(0.2) }} />;
  return (
    <div style={{ width: 190, borderRadius: 16, overflow: "hidden", ...glass("regular"), boxShadow: `0 8px 18px ${black(0.18)}` }}>
      {row(ctx.t("Share", "分享"), Share, Palette.label)}
      {divider}
      {row(ctx.t("Favorite", "收藏"), Heart, Palette.label)}
      {divider}
      {row(ctx.t("Delete", "删除"), Trash2, Palette.red)}
    </div>
  );
}
