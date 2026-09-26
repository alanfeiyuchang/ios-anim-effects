/** inputs.expanding-search (Inputs+ExpandingSearch.swift) */
import { AnimatePresence, motion } from "motion/react";
import { ArrowUpLeft, ChartColumn, ChevronRight, History, Pointer, Search, SlidersHorizontal, Sparkles } from "lucide-react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { DemoHint, Palette, alpha, delayed, fonts, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { fieldInputStyle } from "./_a-common";

const SUGGESTIONS: [string, string][] = [
  ["Spring animations", "弹簧动画"],
  ["Matched geometry", "几何匹配"],
  ["Mesh gradients", "网格渐变"],
];
const TRENDING: [string, string][] = [
  ["Glass", "玻璃"],
  ["Haptics", "触感"],
  ["Scroll", "滚动"],
];

export default function ExpandingSearch({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [expanded, setExpandedState] = useState(false);
  const expandedRef = useRef(false);
  const [query, setQuery] = useState("");
  const input = useRef<HTMLInputElement>(null);
  const introRun = useRef(0);
  const width = ctx.n("width");
  const t = spring(ctx.n("response"), 0.8);
  const zh = ctx.lang === "zh";
  const L = (en: string, z: string) => (zh ? z : en);

  const setExpanded = (v: boolean) => {
    expandedRef.current = v;
    setExpandedState(v);
  };
  const cancelIntro = () => {
    introRun.current += 1;
  };
  const expand = (userInitiated: boolean) => {
    if (userInitiated) haptics.tap();
    setExpanded(true);
    if (!userInitiated || ctx.isPreview) setQuery(zh ? "弹簧" : "Spring");
    else
      after(0.25, () => {
        if (expandedRef.current) input.current?.focus();
      });
  };
  const collapse = () => {
    input.current?.blur();
    setExpanded(false);
    setQuery("");
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (ctx.isPreview) {
        if (expandedRef.current) collapse();
        else expand(false);
      } else {
        cancelIntro();
        const run = introRun.current;
        if (!expandedRef.current) expand(false);
        after(1.5, () => run === introRun.current && collapse());
      }
    },
    { every: 2.4, delay: 0.5 },
  );

  useEffect(() => () => cancelIntro(), []);

  const dropIn = (delay: number) => ({
    initial: { opacity: 0, y: -8 },
    animate: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: -8 },
    transition: delayed(spring(0.4, 0.8), delay),
  });

  const tileW = (width - 10) / 2;
  const tiles: [ReactNode, string, string, string][] = [
    [<Pointer size={15} strokeWidth={2.6} fill="currentColor" />, "Buttons", "按钮", Palette.primary],
    [<SlidersHorizontal size={15} strokeWidth={2.6} />, "Inputs", "控件", Palette.ocean],
    [<Sparkles size={15} strokeWidth={2.2} fill="currentColor" />, "Ambience", "氛围", Palette.sunset],
    [<ChartColumn size={15} strokeWidth={2.8} />, "Charts", "图表", Palette.aurora],
  ];

  return (
    <div style={{ position: "absolute", inset: 0, paddingTop: ctx.isPreview ? 24 : 34, display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
      <div style={{ position: "relative", width, height: 54, flexShrink: 0 }}>
        <motion.div
          initial={false}
          animate={{ opacity: expanded ? 0 : 1, filter: `blur(${expanded ? 6 : 0}px)`, x: expanded ? -18 : 0 }}
          transition={t}
          style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", justifyContent: "center" }}
        >
          <span style={{ ...textStyle.caption, fontWeight: 600, color: Palette.secondaryLabel }}>Motionary</span>
          <span style={{ fontFamily: fonts.rounded, fontSize: 30, fontWeight: 700, lineHeight: "36px" }}>{L("Library", "资源库")}</span>
        </motion.div>
        <motion.div
          initial={false}
          animate={{
            width: expanded ? width : 54,
            boxShadow: `0 8px ${expanded ? 18 : 10}px rgb(0 0 0 / ${expanded ? 0.12 : 0.08})`,
          }}
          transition={t}
          onClick={() => {
            cancelIntro();
            if (!expandedRef.current) expand(true);
          }}
          style={{ position: "absolute", right: 0, top: 0, height: 54, borderRadius: 27, background: Palette.elevated, cursor: expanded ? "auto" : "pointer" }}
        >
          <div
            style={{
              position: "absolute",
              inset: 0,
              borderRadius: 27,
              boxShadow: `inset 0 0 0 ${expanded ? 1.5 : 1}px ${expanded ? alpha(Palette.indigo, 0.5) : Palette.stroke}`,
              transition: "box-shadow 0.3s",
              pointerEvents: "none",
            }}
          />
          <div style={{ position: "absolute", inset: 0, padding: "0 17px", display: "flex", alignItems: "center", gap: 10, overflow: "hidden", borderRadius: 27 }}>
            <span style={{ display: "grid", flexShrink: 0, color: expanded ? Palette.secondaryLabel : Palette.label, transition: "color 0.3s" }}>
              <Search size={20} strokeWidth={2.8} />
            </span>
            <AnimatePresence initial={false}>
              {expanded && (
                <motion.input
                  key="field"
                  ref={input}
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  onFocus={cancelIntro}
                  placeholder={L("Search effects", "搜索动效")}
                  enterKeyHint="search"
                  className="a-search-field"
                  initial={{ opacity: 0, x: -40 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -40 }}
                  transition={t}
                  style={{ ...fieldInputStyle, flex: 1, height: 40, ...textStyle.body, color: Palette.label, caretColor: Palette.indigo }}
                />
              )}
              {expanded && (
                <motion.button
                  key="cancel"
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    cancelIntro();
                    collapse();
                  }}
                  initial={{ opacity: 0, x: 60 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 60 }}
                  transition={t}
                  style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.indigo, whiteSpace: "nowrap", flexShrink: 0 }}
                >
                  {L("Cancel", "取消")}
                </motion.button>
              )}
            </AnimatePresence>
            <style>{`.a-search-field::placeholder { color: var(--ml-label3); }`}</style>
          </div>
        </motion.div>
      </div>
      <div style={{ position: "relative", width, height: 212, flexShrink: 0 }}>
        <motion.div
          initial={false}
          animate={{ opacity: expanded ? 0 : 1, scale: expanded ? 0.94 : 1, filter: `blur(${expanded ? 4 : 0}px)` }}
          transition={t}
          style={{ position: "absolute", left: 0, right: 0, top: 0, transformOrigin: "50% 0%", display: "flex", flexDirection: "column", gap: 10, pointerEvents: expanded ? "none" : "auto" }}
        >
          <div style={{ display: "grid", gridTemplateColumns: `${tileW}px ${tileW}px`, gap: 10 }}>
            {tiles.map(([icon, en, z, bg], i) => (
              <div key={i} style={{ height: 52, borderRadius: 16, background: bg, color: "#fff", display: "flex", alignItems: "center", gap: 8, padding: "0 12px" }}>
                <span style={{ display: "grid" }}>{icon}</span>
                <span style={{ ...textStyle.subheadline, fontWeight: 600, whiteSpace: "nowrap" }}>{L(en, z)}</span>
              </div>
            ))}
          </div>
          <span style={{ ...textStyle.footnote, fontWeight: 600, color: Palette.secondaryLabel, marginTop: 4 }}>{L("Recently viewed", "最近浏览")}</span>
          <div style={{ height: 48, borderRadius: 14, padding: "0 10px", display: "flex", alignItems: "center", gap: 12, background: `color-mix(in srgb, ${Palette.elevated} 70%, transparent)` }}>
            <div style={{ width: 34, height: 34, borderRadius: 10, background: Palette.primary, display: "grid", placeItems: "center", color: "#fff" }}>
              <Pointer size={15} strokeWidth={2.4} fill="currentColor" />
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 1, flex: 1 }}>
              <span style={{ ...textStyle.subheadline, fontWeight: 600 }}>{L("Magnetic Button", "磁吸按钮")}</span>
              <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{L("Buttons · 2 min ago", "按钮 · 2 分钟前")}</span>
            </div>
            <ChevronRight size={14} strokeWidth={3} style={{ color: Palette.tertiaryLabel }} />
          </div>
        </motion.div>
        <div style={{ position: "absolute", left: 0, right: 0, top: 0, display: "flex", flexDirection: "column", gap: 8 }}>
          <AnimatePresence>
            {expanded &&
              ctx.b("suggestions") &&
              SUGGESTIONS.map(([en, z], i) => (
                <motion.div
                  key={`s${i}`}
                  {...dropIn(0.12 + i * 0.05)}
                  style={{
                    height: 40,
                    borderRadius: 12,
                    padding: "0 14px",
                    display: "flex",
                    alignItems: "center",
                    gap: 10,
                    ...textStyle.subheadline,
                    background: `color-mix(in srgb, ${Palette.elevated} 70%, transparent)`,
                  }}
                >
                  <History size={16} strokeWidth={2.2} style={{ color: Palette.secondaryLabel }} />
                  <span style={{ flex: 1 }}>{L(en, z)}</span>
                  <ArrowUpLeft size={13} strokeWidth={2.8} style={{ color: Palette.tertiaryLabel }} />
                </motion.div>
              ))}
            {expanded && ctx.b("suggestions") && (
              <motion.div key="trending" {...dropIn(0.12 + SUGGESTIONS.length * 0.05)} style={{ paddingTop: 6, display: "flex", flexDirection: "column", gap: 8 }}>
                <span style={{ ...textStyle.footnote, fontWeight: 600, color: Palette.secondaryLabel }}>{L("Trending", "热门")}</span>
                <div style={{ display: "flex", gap: 8 }}>
                  {TRENDING.map(([en, z], i) => (
                    <span
                      key={i}
                      style={{ ...textStyle.footnote, fontWeight: 600, color: Palette.indigo, height: 30, padding: "0 12px", borderRadius: 15, background: alpha(Palette.indigo, 0.12), display: "grid", placeItems: "center" }}
                    >
                      {L(en, z)}
                    </span>
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the search button" zh="点击搜索按钮" style={{ paddingBottom: 16 }} />
    </div>
  );
}
