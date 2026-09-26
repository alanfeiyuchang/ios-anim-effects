/** morph.search-expand · 搜索栏展开 (Morph+SearchExpand.swift) */
import { AnimatePresence, motion } from "motion/react";
import { ArrowUpLeft, Atom, Hand, Hourglass, Layers, PanelBottom, PanelsTopLeft, Search, Type } from "lucide-react";
import { useEffect, useState } from "react";
import { Palette, alpha, anim, black, delayed, glass, hex, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { LayoutRoot, diag } from "./_shared";
import { XCircleFill } from "./_symbols";

const results: [typeof Hand, [string, string]][] = [
  [Hand, ["Spring Button", "弹簧按钮"]],
  [PanelsTopLeft, ["Springy Tab Bar", "弹簧标签栏"]],
  [Atom, ["Spring Physics", "弹簧物理"]],
  [PanelBottom, ["Spring-loaded Sheet", "弹簧面板"]],
];

export default function SearchExpand({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [expanded, setExpanded] = useState(false);
  const [query, setQuery] = useState("");
  const zh = ctx.lang === "zh";
  const lang = zh ? 1 : 0;
  const spr = spring(ctx.n("response"), ctx.n("damping"));

  const toggle = () => {
    haptics.tap();
    setExpanded((e) => !e);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 2.8 });

  // .task(id: expanded) { await typeQuery() }
  useEffect(() => {
    if (!expanded) {
      setQuery("");
      return;
    }
    const target = zh ? "弹簧" : "spring";
    const timers: number[] = [];
    const chars = Array.from(target);
    chars.forEach((_, i) => {
      timers.push(window.setTimeout(() => setQuery(chars.slice(0, i + 1).join("")), 400 + i * (zh ? 220 : 90)));
    });
    return () => timers.forEach((t) => window.clearTimeout(t));
  }, [expanded, zh]);

  const capsule = {
    ...glass("regular"),
    borderRadius: 25,
    boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 6px 14px ${black(0.12)}`,
  };
  const hasQuery = query.length > 0;

  return (
    <LayoutRoot>
      <motion.div
        initial={false}
        animate={{ filter: `blur(${expanded ? 8 : 0}px)`, opacity: expanded ? 0.5 : 1 }}
        transition={spr}
        style={{ position: "absolute", inset: 0 }}
      >
        <Backdrop lang={lang} />
      </motion.div>
      <div style={{ position: "absolute", left: 16, right: 16, bottom: 16, display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
        <AnimatePresence>
          {expanded && (
            <motion.div
              key="panel"
              initial={{ opacity: 0, scale: 0.94 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              transition={spr}
              style={{
                alignSelf: "stretch",
                transformOrigin: "50% 100%",
                padding: 14,
                borderRadius: 24,
                ...glass("regular"),
                boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 18px ${black(0.1)}`,
                display: "flex",
                flexDirection: "column",
                gap: 2,
              }}
            >
              <div style={{ position: "relative", height: 16, marginBottom: 6, overflow: "hidden" }}>
                <AnimatePresence initial={false} mode="popLayout">
                  <motion.span
                    key={hasQuery ? "n" : "r"}
                    initial={{ y: 10, opacity: 0, filter: "blur(2px)" }}
                    animate={{ y: 0, opacity: 1, filter: "blur(0px)" }}
                    exit={{ y: -10, opacity: 0, filter: "blur(2px)" }}
                    transition={anim.snappy}
                    style={{ display: "block", fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel }}
                  >
                    {!hasQuery ? (zh ? "最近搜索" : "RECENT") : zh ? `${results.length} 个结果` : `${results.length} RESULTS`}
                  </motion.span>
                </AnimatePresence>
              </div>
              {results.map(([Icon, title], index) => {
                const text = title[lang];
                const chars = Array.from(text);
                const n = Array.from(query).length;
                return (
                  <motion.div
                    key={index}
                    initial={false}
                    animate={{ opacity: hasQuery ? 1 : 0, y: hasQuery ? 0 : 10 }}
                    transition={hasQuery ? delayed(spring(0.4, 0.85), index * ctx.n("stagger")) : anim.easeOut(0.1)}
                    style={{ height: 42, display: "flex", alignItems: "center", gap: 12 }}
                  >
                    <span style={{ width: 30, height: 30, borderRadius: 15, background: alpha(Palette.indigo, 0.12), display: "grid", placeItems: "center", color: Palette.indigo }}>
                      <Icon size={14} strokeWidth={2.6} fill={index === 0 ? "currentColor" : "none"} />
                    </span>
                    <span style={{ fontSize: 15, lineHeight: "20px" }}>
                      <b style={{ color: Palette.indigo, fontWeight: 700 }}>{chars.slice(0, n).join("")}</b>
                      {chars.slice(n).join("")}
                    </span>
                    <span style={{ flex: 1 }} />
                    <ArrowUpLeft size={13} strokeWidth={2.6} color={Palette.tertiaryLabel} />
                  </motion.div>
                );
              })}
            </motion.div>
          )}
        </AnimatePresence>
        {expanded ? (
          <div style={{ position: "relative", alignSelf: "stretch", height: 50, padding: "0 16px", display: "flex", alignItems: "center", gap: 10 }}>
            <motion.div layoutId="bg" transition={spr} style={{ position: "absolute", inset: 0, ...capsule }} />
            <motion.span layoutId="icon" transition={spr} style={{ position: "relative", display: "grid" }}>
              <Search size={19} strokeWidth={2.6} />
            </motion.span>
            <span style={{ position: "relative", display: "flex", alignItems: "center", gap: 1, fontSize: 17, lineHeight: "22px" }}>
              <span style={{ color: hasQuery ? Palette.label : Palette.secondaryLabel }}>{hasQuery ? query : zh ? "搜索动效" : "Search effects"}</span>
              <motion.span
                animate={{ opacity: [1, 0] }}
                transition={{ duration: 0.45, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
                style={{ width: 2, height: 20, borderRadius: 1, background: Palette.indigo }}
              />
            </span>
            <span style={{ flex: 1 }} />
            <motion.button
              type="button"
              onClick={toggle}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={spr}
              style={{ position: "relative", display: "grid", color: Palette.secondaryLabel }}
            >
              <XCircleFill size={23} />
            </motion.button>
          </div>
        ) : (
          <button type="button" onClick={toggle} style={{ position: "relative", height: 50, padding: "0 22px", display: "flex", alignItems: "center", gap: 8, fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>
            <motion.div layoutId="bg" transition={spr} style={{ position: "absolute", inset: 0, ...capsule }} />
            <motion.span layoutId="icon" transition={spr} style={{ position: "relative", display: "grid" }}>
              <Search size={19} strokeWidth={2.6} />
            </motion.span>
            <span style={{ position: "relative" }}>{zh ? "搜索" : "Search"}</span>
          </button>
        )}
      </div>
    </LayoutRoot>
  );
}

function Backdrop({ lang }: { lang: number }) {
  const tiles: [typeof Hand, string[], [string, string], boolean][] = [
    [Hand, [Palette.indigo, Palette.violet], ["Buttons", "按钮"], true],
    [Layers, [Palette.pink, Palette.coral], ["Cards", "卡片"], true],
    [Hourglass, [Palette.mint, Palette.sky], ["Loading", "加载"], false],
    [Type, [Palette.amber, Palette.coral], ["Text", "文字"], false],
  ];
  return (
    <div style={{ position: "absolute", inset: 0, padding: 18, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, alignContent: "start" }}>
      {tiles.map(([Icon, colors, title, fill], i) => (
        <div
          key={i}
          style={{
            height: 100,
            borderRadius: 18,
            background: diag(...colors),
            boxShadow: `0 5px 10px ${hex(colors[0], 0.25)}`,
            padding: 12,
            display: "flex",
            flexDirection: "column",
            justifyContent: "flex-end",
            gap: 6,
            color: "#fff",
          }}
        >
          <Icon size={22} strokeWidth={2.3} fill={fill ? "currentColor" : "none"} />
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 700 }}>{title[lang]}</span>
        </div>
      ))}
    </div>
  );
}
