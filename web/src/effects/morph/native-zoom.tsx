/** morph.native-zoom · 缩放推入转场 (Morph+NativeZoom.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { ChevronDown, Flame, Leaf, MoonStar, Waves } from "lucide-react";
import { Mountain2, SunHorizon, type SymbolComponent } from "./_symbols";
import { useRef, useState } from "react";
import { DemoHint, Palette, black, fonts, pressHandlers, rubberBand, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { diag, layoutRect, predicted, useMV, useSize, type Rect } from "./_shared";

interface Tile {
  id: number;
  Icon: SymbolComponent;
  fill: boolean;
  colors: string[];
  title: [string, string];
  meta: [string, string];
  blurb: [string, string];
}

const tiles: Tile[] = [
  { id: 0, Icon: Mountain2, fill: true, colors: [Palette.sky, Palette.indigo], title: ["Alpine Lake", "高山湖泊"], meta: ["Photo · 4K · 12 MB", "照片 · 4K · 12 MB"], blurb: ["First light over still water, shot at 5:40 AM.", "清晨 5:40，第一缕光落在平静的湖面上。"] },
  { id: 1, Icon: SunHorizon, fill: true, colors: [Palette.amber, Palette.coral], title: ["Golden Hour", "黄金时刻"], meta: ["Photo · 4K · 9 MB", "照片 · 4K · 9 MB"], blurb: ["Warm backlight and long shadows on the dunes.", "暖色逆光与沙丘上拉长的影子。"] },
  { id: 2, Icon: Leaf, fill: true, colors: [Palette.mint, Palette.green], title: ["Fern Study", "蕨类习作"], meta: ["Photo · Macro · 7 MB", "照片 · 微距 · 7 MB"], blurb: ["A macro of new fronds unrolling after rain.", "雨后新叶舒展开来的微距特写。"] },
  { id: 3, Icon: MoonStar, fill: true, colors: [Palette.violet, "#241B5C"], title: ["Night Sky", "星夜"], meta: ["Photo · 30 s exposure", "照片 · 30 秒曝光"], blurb: ["The Milky Way rising above the ridge line.", "银河从山脊线上方缓缓升起。"] },
  { id: 4, Icon: Waves, fill: false, colors: [Palette.sky, Palette.mint], title: ["Tide Pools", "潮汐池"], meta: ["Photo · 4K · 10 MB", "照片 · 4K · 10 MB"], blurb: ["Low tide reveals a tiny world between rocks.", "退潮后，礁石间露出一个微小的世界。"] },
  { id: 5, Icon: Flame, fill: true, colors: [Palette.coral, Palette.pink], title: ["Campfire", "篝火"], meta: ["Video · 0:42", "视频 · 0:42"], blurb: ["Sparks drifting up into a cold autumn night.", "火星飘进寒冷的秋夜。"] },
];

export default function NativeZoom({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const root = useRef<HTMLDivElement>(null);
  const tileRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const stage = useSize(root, { width: 340, height: ctx.isPreview ? 340 : 400 });
  const [shown, setShown] = useState(0);
  const [autoIndex, setAutoIndex] = useState(0);
  const openMV = useMotionValue(0);
  const dxMV = useMotionValue(0);
  const dyMV = useMotionValue(0);
  const open = useMV(openMV);
  const dx = useMV(dxMV);
  const dy = useMV(dyMV);
  const lift = Math.min(Math.max(dx, dy, 0) / 320, 1);
  const columns = ctx.i("columns") === 0 ? 2 : 3;
  const corner = ctx.n("corner");
  const lang = ctx.lang === "zh" ? 1 : 0;
  const engaged = useRef(false);

  const present = (id: number) => {
    if (openMV.get() !== 0) return;
    setShown(id);
    haptics.tap("soft");
    animate(openMV, 1, spring(0.5, 0.86));
  };
  const close = () => {
    const t = spring(0.5, 0.86);
    animate(openMV, 0, t);
    animate(dxMV, 0, t);
    animate(dyMV, 0, t);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (openMV.get() > 0) close();
      else {
        present(tiles[autoIndex % tiles.length].id);
        setAutoIndex((i) => i + 2);
      }
    },
    { every: 2.2 },
  );

  const pan = usePan(
    {
      onStart: ({ translation }) => {
        // PageSafePan(directions: [.down, .right]): only a mostly down or right drag engages.
        engaged.current = openMV.get() > 0.5 && (translation.y > Math.abs(translation.x) || translation.x > Math.abs(translation.y));
      },
      onChange: ({ translation: t }) => {
        if (!engaged.current) return;
        dxMV.set(t.x > 0 ? t.x : rubberBand(t.x, 12));
        dyMV.set(t.y > 0 ? t.y : rubberBand(t.y, 12));
      },
      onEnd: ({ translation, velocity }) => {
        if (!engaged.current) return;
        engaged.current = false;
        const l = Math.min(Math.max(dxMV.get(), dyMV.get(), 0) / 320, 1);
        if (l > 0.33 || Math.max(predicted(translation.x, velocity.x), predicted(translation.y, velocity.y)) > 420) close();
        else {
          animate(dxMV, 0, spring(0.4, 0.8));
          animate(dyMV, 0, spring(0.4, 0.8));
        }
      },
    },
    6,
  );

  const el = tileRefs.current[shown];
  const source: Rect = el && root.current ? layoutRect(el, root.current) : { x: 0, y: 0, w: 0, h: 0 };
  const p = open;
  const w = source.w + (stage.width - source.w) * p;
  const h = source.h + (stage.height - source.h) * p;
  const cx = source.x + source.w / 2 + (stage.width / 2 - (source.x + source.w / 2)) * p;
  const cy = source.y + source.h / 2 + (stage.height / 2 - (source.y + source.h / 2)) * p;
  const s = stage.width > 0 ? w / stage.width : 1;
  const radius = corner * (1 - p) + 34 * lift;
  const tile = tiles[shown % tiles.length];

  return (
    <div ref={root} style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", inset: 0, padding: "18px 18px 0", display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <div style={{ fontSize: 22, lineHeight: "28px", fontWeight: 700 }}>{lang ? "相簿" : "Albums"}</div>
          <DemoHint ctx={ctx} en="Tap a tile · pull down or swipe right to go back" zh="点击图块 · 下拉或右滑返回" style={{ textAlign: "left" }} />
        </div>
        <div style={{ display: "grid", gridTemplateColumns: `repeat(${columns}, 1fr)`, gap: 10 }}>
          {tiles.map((t) => (
            <TileButton
              key={t.id}
              ref={(node) => {
                tileRefs.current[t.id] = node;
              }}
              tile={t}
              ratio={columns === 2 ? 1.8 : 1}
              symbol={columns === 2 ? 34 : 26}
              corner={corner}
              press={ctx.n("press")}
              hidden={p > 0 && shown === t.id}
              onTap={() => present(t.id)}
            />
          ))}
        </div>
      </div>
      <div style={{ position: "absolute", inset: 0, background: "#000", opacity: 0.3 * p, pointerEvents: "none" }} />
      <div
        {...pan}
        style={{
          ...pan.style,
          position: "absolute",
          inset: 0,
          transform: `translate(${dx * 0.6}px, ${dy * 0.6}px) scale(${1 - lift * 0.3})`,
          pointerEvents: p > 0.5 ? "auto" : "none",
        }}
      >
        <div
          style={{
            position: "absolute",
            left: cx - w / 2,
            top: cy - h / 2,
            width: w,
            height: h,
            borderRadius: radius,
            overflow: "hidden",
            opacity: p > 0.001 ? 1 : 0,
            boxShadow: `0 12px 24px ${black(0.22 * lift)}`,
          }}
        >
          <div style={{ position: "absolute", left: 0, top: 0, width: stage.width, height: stage.height, transform: `scale(${s})`, transformOrigin: "0 0" }}>
            <DetailScreen tile={tile} lang={lang} onClose={close} />
          </div>
          <div style={{ position: "absolute", inset: 0, opacity: Math.max(0, 1 - p * 2.2) }}>
            <TileArt tile={tile} symbol={30 + 34 * p} />
          </div>
        </div>
      </div>
    </div>
  );
}

function TileArt({ tile, symbol }: { tile: Tile; symbol: number }) {
  const { Icon } = tile;
  return (
    <div style={{ position: "absolute", inset: 0, background: diag(...tile.colors), display: "grid", placeItems: "center", color: white(0.92) }}>
      <Icon
        size={symbol}
        strokeWidth={tile.fill ? 1.2 : 2.2}
        fill={tile.fill ? "currentColor" : "none"}
        style={{ filter: `drop-shadow(0 3px 3px ${black(0.15)})` }}
      />
    </div>
  );
}

function TileButton({
  ref,
  tile,
  ratio,
  symbol,
  corner,
  press,
  hidden,
  onTap,
}: {
  ref: (node: HTMLButtonElement | null) => void;
  tile: Tile;
  ratio: number;
  symbol: number;
  corner: number;
  press: number;
  hidden: boolean;
  onTap: () => void;
}) {
  const [pressed, setPressed] = useState(false);
  return (
    <motion.button
      ref={ref}
      type="button"
      onClick={onTap}
      {...pressHandlers(setPressed)}
      animate={{ scale: pressed ? press : 1 }}
      transition={spring(0.3, 0.6)}
      style={{ position: "relative", aspectRatio: String(ratio), borderRadius: corner, overflow: "hidden", opacity: hidden ? 0 : 1 }}
    >
      <TileArt tile={tile} symbol={symbol} />
    </motion.button>
  );
}

function DetailScreen({ tile, lang, onClose }: { tile: Tile; lang: number; onClose: () => void }) {
  return (
    <div style={{ position: "absolute", inset: 0, background: Palette.elevated, display: "flex", flexDirection: "column", gap: 14 }}>
      <div style={{ position: "relative", height: 170, flexShrink: 0 }}>
        <TileArt tile={tile} symbol={64} />
        <button
          type="button"
          onClick={onClose}
          onPointerDown={(e) => e.stopPropagation()}
          style={{ position: "absolute", left: 12, top: 12, width: 32, height: 32, borderRadius: 16, background: black(0.25), display: "grid", placeItems: "center", color: "#fff" }}
        >
          <ChevronDown size={16} strokeWidth={3} />
        </button>
      </div>
      <div style={{ padding: "0 18px", display: "flex", flexDirection: "column", gap: 4 }}>
        <div style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700, fontFamily: fonts.text }}>{tile.title[lang]}</div>
        <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, color: Palette.secondaryLabel }}>{tile.meta[lang]}</div>
      </div>
      <div style={{ padding: "0 18px", fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel }}>{tile.blurb[lang]}</div>
    </div>
  );
}

