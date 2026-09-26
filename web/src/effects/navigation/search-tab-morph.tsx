/** navigation.search-tab-morph · 搜索标签形变 (Navigation+SearchTabMorph.swift) */
import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { ArrowUpRight, Search } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, anim, black, delayed, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { NavigationScreenPlaceholder } from "./shared";
import { Glyph, type GlyphName } from "./groupB-kit";

const SYMBOLS: GlyphName[] = ["house.fill", "square.stack.fill", "dot.radiowaves"];
const TITLES: [string, string][] = [
  ["Home", "首页"],
  ["Library", "资料库"],
  ["Radio", "电台"],
];
const SUGGESTIONS: [string, string][] = [
  ["Lo-fi focus", "专注低保真"],
  ["Morning jazz", "晨间爵士"],
  ["Rain sounds", "雨声白噪音"],
];

/** `.transition(.blurReplace)` */
const blurReplace = {
  initial: { opacity: 0, scale: 0.8, filter: "blur(6px)" },
  animate: { opacity: 1, scale: 1, filter: "blur(0px)" },
  exit: { opacity: 0, scale: 0.8, filter: "blur(6px)" },
};

const capsule = (): React.CSSProperties => ({
  position: "relative",
  height: 56,
  borderRadius: 28,
  overflow: "hidden",
  flexShrink: 0,
  ...glass("regular"),
  boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 16px ${black(0.12)}`,
});

export default function SearchTabMorph({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [searching, setSearchingState] = useState(false);
  const [selected, setSelected] = useState(0);
  const morph = spring(ctx.n("response"), ctx.n("damping"));

  const setSearching = (value: boolean) => {
    if (value === searching) return;
    haptics.tap(value ? "medium" : "light");
    setSearchingState(value);
  };

  useAutoplay(ctx.isPreview, () => setSearching(!searching), { every: 1.8 });

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      {ctx.isPreview && (
        <motion.div
          initial={false}
          animate={{ opacity: searching ? 0 : 1, filter: `blur(${searching ? 6 : 0}px)` }}
          transition={anim.easeInOut(0.3)}
          style={{ position: "absolute", top: 20, left: 0, right: 0, display: "flex", justifyContent: "center" }}
        >
          <NavigationScreenPlaceholder />
        </motion.div>
      )}
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
        <div style={{ flex: 1, minHeight: 0 }} />
        {/* Suggestions */}
        <div style={{ display: "flex", flexDirection: "column", gap: 8, pointerEvents: searching ? "auto" : "none" }}>
          {SUGGESTIONS.map(([en, zh], index) => {
            const delay = searching ? index * ctx.n("stagger") + 0.12 : 0;
            return (
              <motion.div
                key={en}
                initial={false}
                animate={{ opacity: searching ? 1 : 0, filter: `blur(${searching ? 0 : 6}px)`, y: searching ? 0 : 16 }}
                transition={delayed(spring(0.4, 0.85), delay)}
                style={{
                  width: 298,
                  height: 44,
                  padding: "0 16px",
                  display: "flex",
                  alignItems: "center",
                  gap: 10,
                  borderRadius: 14,
                  background: Palette.elevated,
                }}
              >
                <ArrowUpRight size={13} strokeWidth={3} color={Palette.indigo} />
                <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500 }}>{ctx.t(en, zh)}</span>
              </motion.div>
            );
          })}
        </div>
        {/* Bar */}
        <div style={{ display: "flex", gap: 10, flexShrink: 0 }}>
          <motion.div initial={false} animate={{ width: searching ? 56 : 232 }} transition={morph} style={capsule()}>
            <AnimatePresence initial={false}>
              {searching ? (
                <motion.div
                  key="bubble"
                  {...blurReplace}
                  transition={morph}
                  onClick={() => setSearching(false)}
                  style={{ position: "absolute", left: 0, top: 0, width: 56, height: 56, display: "grid", placeItems: "center", color: Palette.indigo, cursor: "pointer" }}
                >
                  <Glyph name={SYMBOLS[selected]} size={21} />
                </motion.div>
              ) : (
                <motion.div
                  key="tabs"
                  {...blurReplace}
                  transition={morph}
                  style={{ position: "absolute", inset: 0, padding: 4, display: "flex", gap: 2 }}
                >
                  <LayoutGroup id="search-tab-morph">
                    {SYMBOLS.map((symbol, index) => {
                      const isSelected = index === selected;
                      return (
                        <div
                          key={symbol}
                          onClick={() => {
                            haptics.selection();
                            setSelected(index);
                          }}
                          style={{ position: "relative", flex: 1, minWidth: 0, cursor: "pointer" }}
                        >
                          {isSelected && (
                            <motion.div
                              layoutId="searchTabSelection"
                              transition={morph}
                              style={{ position: "absolute", inset: 0, borderRadius: 24, background: Palette.primary }}
                            />
                          )}
                          <div
                            style={{
                              transition: "color 0.3s ease-in-out",
                              position: "relative",
                              height: "100%",
                              display: "flex",
                              flexDirection: "column",
                              alignItems: "center",
                              justifyContent: "center",
                              gap: 2,
                              color: isSelected ? "#fff" : Palette.secondaryLabel,
                            }}
                          >
                            <Glyph name={symbol} size={18} />
                            <span style={{ fontSize: 10, lineHeight: "12px", fontWeight: 600, whiteSpace: "nowrap" }}>{ctx.t(...TITLES[index])}</span>
                          </div>
                        </div>
                      );
                    })}
                  </LayoutGroup>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
          <motion.div
            initial={false}
            animate={{ width: searching ? 232 : 56 }}
            transition={morph}
            onClick={() => !searching && setSearching(true)}
            style={{ ...capsule(), cursor: searching ? "default" : "pointer" }}
          >
            <div
              style={{
                position: "absolute",
                inset: 0,
                display: "flex",
                alignItems: "center",
                gap: 8,
                paddingLeft: searching ? 18 : 19,
              }}
            >
              <span style={{ display: "grid", flexShrink: 0, color: searching ? Palette.secondaryLabel : Palette.indigo, transition: "color 0.3s ease-in-out" }}>
                <Search size={18} strokeWidth={2.8} />
              </span>
              <AnimatePresence initial={false}>
                {searching && (
                  <motion.div
                    key="caret"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={morph}
                    style={{ flexShrink: 0 }}
                  >
                    <motion.div
                      animate={{ opacity: [1, 0] }}
                      transition={{ duration: 0.5, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
                      style={{ width: 2, height: 20, background: Palette.indigo }}
                    />
                  </motion.div>
                )}
                {searching && (
                  <motion.span
                    key="placeholder"
                    initial={{ opacity: 0, x: 12 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 12 }}
                    transition={morph}
                    style={{ fontSize: 15, lineHeight: "20px", color: Palette.tertiaryLabel, whiteSpace: "nowrap", flexShrink: 0 }}
                  >
                    {ctx.t("Artists, songs, podcasts", "歌手、歌曲、播客")}
                  </motion.span>
                )}
              </AnimatePresence>
            </div>
          </motion.div>
        </div>
        <DemoHint ctx={ctx} en="Tap search, then the bubble" zh="点击搜索，再点击圆泡" style={{ paddingBottom: 8 }} />
      </div>
    </div>
  );
}
