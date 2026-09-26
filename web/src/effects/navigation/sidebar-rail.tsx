/** navigation.sidebar-rail · 侧边栏导轨 (Navigation+SidebarRail.swift) */
import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { Clock, Heart, House, Image, Images, Leaf, PanelLeft, Search, Sparkles, Star, Trash2, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, delayed, hex, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";

interface RailItem {
  icon: LucideIcon;
  filled: boolean;
  en: string;
  zh: string;
  colors: [string, string];
}

const railItems: RailItem[] = [
  { icon: House, filled: true, en: "Home", zh: "首页", colors: [Palette.indigo, Palette.violet] },
  { icon: Images, filled: false, en: "Library", zh: "资料库", colors: [Palette.amber, Palette.coral] },
  { icon: Star, filled: true, en: "Favorites", zh: "收藏", colors: [Palette.pink, Palette.violet] },
  { icon: Clock, filled: false, en: "Recents", zh: "最近", colors: [Palette.mint, Palette.sky] },
  { icon: Trash2, filled: false, en: "Deleted", zh: "已删除", colors: ["#8E8E93", "#5A5A60"] },
];

const tileIcons: [LucideIcon, boolean][] = [
  [Image, false],
  [Sparkles, true],
  [Leaf, true],
  [Heart, true],
];

export default function SidebarRail({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [expanded, setExpanded] = useState(false);
  const [selected, setSelected] = useState(0);
  const tick = useRef(0);
  const sel = useRef(0);
  sel.current = selected;
  const sp = spring(ctx.n("response"), ctx.n("damping"));
  const railWidth = expanded ? 150 : 56;

  const toggle = () => {
    haptics.tap();
    setExpanded((e) => !e);
  };
  const select = (index: number) => {
    if (index === sel.current) return;
    haptics.selection();
    sel.current = index;
    setSelected(index);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      tick.current += 1;
      if (tick.current % 3 === 1) toggle();
      else select((sel.current + 1) % railItems.length);
    },
    { every: 1.3 },
  );

  const item = railItems[selected];

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        style={{
          width: 320,
          height: 280,
          flexShrink: 0,
          display: "flex",
          background: Palette.elevated,
          borderRadius: 26,
          overflow: "hidden",
          position: "relative",
          boxShadow: `0 10px 18px rgb(0 0 0 / 0.12)`,
        }}
      >
        {/* Rail */}
        <motion.div
          initial={false}
          animate={{ width: railWidth }}
          transition={sp}
          style={{ flexShrink: 0, height: "100%", padding: 8, background: Palette.surface, overflow: "hidden", display: "flex", flexDirection: "column", gap: 4, alignItems: "stretch" }}
        >
          <button
            type="button"
            onClick={toggle}
            style={{ width: 40, height: 36, marginBottom: 6, display: "grid", placeItems: "center", color: Palette.secondaryLabel, flexShrink: 0 }}
          >
            <PanelLeft size={17} strokeWidth={2.3} />
          </button>
          <LayoutGroup id="sidebar-rail">
            {railItems.map((it, index) => {
              const isSelected = selected === index;
              const Icon = it.icon;
              return (
                <button
                  key={it.en}
                  type="button"
                  onClick={() => select(index)}
                  style={{
                    position: "relative",
                    height: 38,
                    flexShrink: 0,
                    padding: "0 8px",
                    display: "flex",
                    alignItems: "center",
                    gap: 10,
                    color: isSelected ? Palette.indigo : Palette.secondaryLabel,
                    transition: "color 0.2s",
                  }}
                >
                  {isSelected && (
                    <motion.div
                      layoutId="selection"
                      transition={sp}
                      style={{ position: "absolute", inset: 0, borderRadius: 11, background: hex(Palette.indigo, 0.14) }}
                    />
                  )}
                  <span style={{ position: "relative", width: 24, display: "grid", placeItems: "center", flexShrink: 0 }}>
                    <Icon size={16} strokeWidth={2.4} fill={it.filled ? "currentColor" : "none"} />
                  </span>
                  <motion.span
                    initial={false}
                    animate={{ opacity: expanded ? 1 : 0, x: expanded ? 0 : -8, filter: `blur(${expanded ? 0 : 4}px)` }}
                    transition={expanded ? delayed(sp, 0.04 + index * ctx.n("stagger")) : anim.easeOut(0.1)}
                    style={{ position: "relative", whiteSpace: "nowrap", fontSize: 15, lineHeight: "20px", fontWeight: isSelected ? 600 : 500 }}
                  >
                    {ctx.t(it.en, it.zh)}
                  </motion.span>
                </button>
              );
            })}
          </LayoutGroup>
        </motion.div>
        <div style={{ width: 1, flexShrink: 0, background: Palette.stroke }} />
        {/* Content */}
        <div style={{ flex: 1, minWidth: 0, padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ display: "flex", alignItems: "center", height: 25 }}>
            <div style={{ position: "relative", flex: 1, height: 25 }}>
              <AnimatePresence initial={false}>
                <motion.span
                  key={selected}
                  initial={{ opacity: 0, filter: "blur(6px)", scale: 0.85 }}
                  animate={{ opacity: 1, filter: "blur(0px)", scale: 1 }}
                  exit={{ opacity: 0, filter: "blur(6px)", scale: 0.85 }}
                  transition={sp}
                  style={{ position: "absolute", left: 0, top: 0, transformOrigin: "0% 50%", whiteSpace: "nowrap", fontSize: 20, lineHeight: "25px", fontWeight: 700 }}
                >
                  {ctx.t(item.en, item.zh)}
                </motion.span>
              </AnimatePresence>
            </div>
            <Search size={15} strokeWidth={2.6} color={Palette.secondaryLabel} />
          </div>
          {[0, 2].map((row) => (
            <div key={row} style={{ display: "flex", gap: 10 }}>
              {[row, row + 1].map((symbolIndex) => (
                <Tile key={symbolIndex} selected={selected} symbolIndex={symbolIndex} transition={sp} />
              ))}
            </div>
          ))}
          <PlaceholderLines count={2} />
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 26, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Tap the sidebar button or a row" zh="点击侧边栏按钮或任意一行" />
    </div>
  );
}

/** A gradient tile; the gradient colours cross-fade between items like SwiftUI interpolates them. */
function Tile({ selected, symbolIndex, transition }: { selected: number; symbolIndex: number; transition: ReturnType<typeof spring> }) {
  const [Icon, filled] = tileIcons[symbolIndex % tileIcons.length];
  const a = 1 - 0.18 * symbolIndex;
  return (
    <div style={{ position: "relative", flex: 1, height: 70, borderRadius: 14, overflow: "hidden" }}>
      {railItems.map((it, i) => (
        <motion.div
          key={it.en}
          initial={false}
          animate={{ opacity: i === selected ? 1 : 0 }}
          transition={transition}
          style={{ position: "absolute", inset: 0, background: `linear-gradient(135deg, ${hex(it.colors[0], a)}, ${hex(it.colors[1], a)})` }}
        />
      ))}
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: "rgb(255 255 255 / 0.9)" }}>
        <Icon size={21} strokeWidth={2.3} fill={filled ? "currentColor" : "none"} />
      </div>
    </div>
  );
}
