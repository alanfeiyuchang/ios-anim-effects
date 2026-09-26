/** morph.list-grid · 列表 ↔ 网格形变 (Morph+ListGrid.swift) */
import { AnimatePresence, motion } from "motion/react";
import { BookOpen, FileText, Film, Image, List, Mic, Music } from "lucide-react";
import { useState } from "react";
import { Palette, anim, delayed, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { sheen } from "./_shared";

const items: { Icon: typeof Music; color: string; title: [string, string]; subtitle: [string, string] }[] = [
  { Icon: Music, color: Palette.pink, title: ["Music", "音乐"], subtitle: ["128 songs", "128 首歌曲"] },
  { Icon: Image, color: Palette.amber, title: ["Photos", "照片"], subtitle: ["2,341 items", "2,341 项"] },
  { Icon: BookOpen, color: Palette.coral, title: ["Books", "图书"], subtitle: ["12 titles", "12 本"] },
  { Icon: Film, color: Palette.indigo, title: ["Films", "影片"], subtitle: ["36 movies", "36 部"] },
  { Icon: Mic, color: Palette.mint, title: ["Podcasts", "播客"], subtitle: ["9 shows", "9 个节目"] },
  { Icon: FileText, color: Palette.sky, title: ["Files", "文件"], subtitle: ["420 MB", "420 MB"] },
];
const WIDTH = 340 - 32;

export default function ListGrid({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [isGrid, setIsGrid] = useState(false);
  const lang = ctx.lang === "zh" ? 1 : 0;
  const spr = spring(ctx.n("response"), ctx.n("damping"));

  const toggle = () => {
    haptics.selection();
    setIsGrid((g) => !g);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.8 });

  const columns = isGrid ? 3 : 1;
  const itemHeight = isGrid ? 104 : 38;
  const spacing = isGrid ? 8 : 4;
  const cellWidth = (WIDTH - (columns - 1) * spacing) / columns;

  return (
    <div style={{ position: "absolute", inset: 0, padding: 16, display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
      <div style={{ position: "relative", alignSelf: "stretch", flex: 1 }}>
        {items.map((item, index) => {
          const t = delayed(spr, index * ctx.n("cascade"));
          const column = index % columns;
          const row = Math.floor(index / columns);
          const iconSize = isGrid ? 36 : 28;
          return (
            <motion.div
              key={index}
              initial={false}
              animate={{
                left: column * (cellWidth + spacing),
                top: row * (itemHeight + spacing),
                width: cellWidth,
                height: itemHeight,
                borderRadius: isGrid ? 18 : 14,
              }}
              transition={t}
              style={{ position: "absolute", background: Palette.elevated, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, overflow: "hidden" }}
            >
              <motion.div
                initial={false}
                animate={{ left: 10, top: isGrid ? 10 : 5, width: iconSize, height: iconSize, borderRadius: isGrid ? 10 : 8 }}
                transition={t}
                style={{ position: "absolute", background: sheen(item.color), display: "grid", placeItems: "center", color: "#fff" }}
              >
                <motion.span initial={false} animate={{ scale: isGrid ? 16 / 13 : 1 }} transition={t} style={{ display: "grid" }}>
                  <item.Icon size={15} strokeWidth={2.5} />
                </motion.span>
              </motion.div>
              <motion.div
                initial={false}
                animate={{ left: isGrid ? 10 : 50, top: isGrid ? 54 : 0.5 }}
                transition={t}
                style={{ position: "absolute", right: 10, display: "flex", flexDirection: "column", gap: 1, whiteSpace: "nowrap" }}
              >
                <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, overflow: "hidden", textOverflow: "ellipsis" }}>{item.title[lang]}</span>
                <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, overflow: "hidden", textOverflow: "ellipsis" }}>{item.subtitle[lang]}</span>
              </motion.div>
            </motion.div>
          );
        })}
      </div>
      <button
        type="button"
        onClick={toggle}
        style={{
          height: 40,
          padding: "0 18px",
          borderRadius: 20,
          ...glass("thin"),
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
          display: "flex",
          alignItems: "center",
          gap: 7,
          fontSize: 15,
          fontWeight: 600,
          flexShrink: 0,
        }}
      >
        <span style={{ position: "relative", width: 18, height: 18, display: "grid", placeItems: "center" }}>
          <AnimatePresence initial={false} mode="popLayout">
            <motion.span
              key={String(isGrid)}
              initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
              exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              transition={anim.snappyD(0.3)}
              style={{ display: "grid" }}
            >
              {isGrid ? <List size={17} strokeWidth={2.6} /> : <svg viewBox="0 0 24 24" width={18} height={18} fill="currentColor">
                  {[0, 1, 2].flatMap((c) => [0, 1].map((r) => <rect key={`${c}${r}`} x={2 + c * 7.2} y={5.2 + r * 7.2} width={5.8} height={5.8} rx={1.4} />))}
                </svg>}
            </motion.span>
          </AnimatePresence>
        </span>
        {isGrid ? (lang ? "列表" : "List") : lang ? "网格" : "Grid"}
      </button>
    </div>
  );
}
