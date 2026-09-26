/** navigation.tab-indicator · 滑动标签指示器 (Navigation+TabIndicator.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { useEffect, useState, type ComponentType, type CSSProperties } from "react";
import { Palette, black, fonts, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { Bounce, BlurReplace, HeartFill, HouseFill, PersonFill, SafariFill, colorGradient, primaryCorner, useTextWidths } from "./groupA-kit";

type Icon = ComponentType<{ size: number; color?: string; style?: CSSProperties }>;

const TABS: { icon: Icon; en: string; zh: string; color: string }[] = [
  { icon: HouseFill, en: "Home", zh: "首页", color: Palette.indigo },
  { icon: SafariFill, en: "Explore", zh: "发现", color: Palette.sky },
  { icon: HeartFill, en: "Saved", zh: "收藏", color: Palette.pink },
  { icon: PersonFill, en: "Profile", zh: "我的", color: Palette.amber },
];

/** Icon box of a 17 pt semibold symbol, the HStack spacing to the label, the item's horizontal padding. */
const ICON = 20;
const GAP = 6;
const PAD = 16;
const LABEL_STYLE: CSSProperties = { fontFamily: fonts.text, fontSize: 15, lineHeight: "20px", fontWeight: 600 };
const INSTANT: Transition = { duration: 0 };

export default function TabIndicator({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(0);
  const [bounces, setBounces] = useState<number[]>(() => TABS.map(() => 0));
  const pillStyle = ctx.i("style") === 0;
  const titles = TABS.map((t) => ctx.t(t.en, t.zh));
  const [labelWidths, probe] = useTextWidths(titles, LABEL_STYLE);

  // Frames jump into place until the labels are measured, then animate like SwiftUI's layout does.
  const measured = labelWidths.some((w) => w > 0);
  const [warm, setWarm] = useState(false);
  useEffect(() => {
    if (!measured) return;
    const id = requestAnimationFrame(() => setWarm(true));
    return () => cancelAnimationFrame(id);
  }, [measured]);
  const sp = spring(ctx.n("response"), ctx.n("damping"));
  const layout = warm ? sp : INSTANT;

  const select = (index: number) => {
    if (index === selected) return;
    haptics.selection();
    setBounces((b) => b.map((v, i) => (i === index ? v + 1 : v)));
    setSelected(index);
  };

  useAutoplay(ctx.isPreview, () => select((selected + 1) % TABS.length), { every: 1.2 });

  const widths = TABS.map((_, i) => 2 * PAD + ICON + (i === selected ? GAP + labelWidths[i] : 0));
  const pillX = widths.slice(0, selected).reduce((a, w) => a + w + 2, 0);
  const tab = TABS[selected];
  const PageIcon = tab.icon;

  return (
    <div style={{ position: "absolute", inset: 0, padding: 18, display: "flex", flexDirection: "column", alignItems: "center" }}>
      {probe}
      <div style={{ flex: 1, alignSelf: "stretch", display: "grid", placeItems: "center" }}>
        <BlurReplace id={selected} transition={sp}>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
            <div
              style={{
                width: 84,
                height: 84,
                borderRadius: 26,
                background: colorGradient(tab.color),
                boxShadow: `0 8px 16px color-mix(in srgb, ${tab.color} 35%, transparent)`,
                display: "grid",
                placeItems: "center",
                color: "#fff",
              }}
            >
              <PageIcon size={44} />
            </div>
            <div style={{ fontFamily: fonts.text, fontSize: 20, lineHeight: "25px", fontWeight: 700, color: Palette.label }}>{titles[selected]}</div>
          </div>
        </BlurReplace>
      </div>
      {/* tab bar */}
      <div
        style={{
          position: "relative",
          display: "flex",
          gap: 2,
          padding: 6,
          borderRadius: 999,
          ...glass("regular"),
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 18px ${black(0.12)}`,
          flexShrink: 0,
        }}
      >
        {pillStyle && (
          <motion.div
            initial={false}
            animate={{ x: pillX, width: widths[selected] }}
            transition={layout}
            style={{ position: "absolute", left: 6, top: 6, height: 46, borderRadius: 999, background: primaryCorner }}
          />
        )}
        {TABS.map((t, index) => {
          const isSelected = index === selected;
          const Glyph = t.icon;
          const color = isSelected ? (pillStyle ? "#fff" : tab.color) : Palette.secondaryLabel;
          return (
            <motion.button
              key={index}
              type="button"
              onClick={() => select(index)}
              initial={false}
              animate={{ width: widths[index] }}
              transition={layout}
              style={{ position: "relative", height: 46, flexShrink: 0, borderRadius: 999, color, transition: "color 0.3s" }}
            >
              {!pillStyle && (
                <AnimatePresence initial={false}>
                  {isSelected && (
                    <motion.div
                      initial={{ scale: 0.6, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      exit={{ scale: 0.6, opacity: 0 }}
                      transition={sp}
                      style={{ position: "absolute", inset: 0, borderRadius: 999, background: `color-mix(in srgb, ${tab.color} 16%, transparent)` }}
                    />
                  )}
                </AnimatePresence>
              )}
              <Bounce trigger={bounces[index]} style={{ position: "absolute", left: PAD, top: 13 }}>
                <Glyph size={ICON} />
              </Bounce>
              <AnimatePresence initial={false}>
                {isSelected && (
                  <motion.span
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.8 }}
                    transition={sp}
                    style={{ ...LABEL_STYLE, color: pillStyle ? "#fff" : t.color, position: "absolute", left: PAD + ICON + GAP, top: 13, whiteSpace: "nowrap", transformOrigin: "0% 50%" }}
                  >
                    {titles[index]}
                  </motion.span>
                )}
              </AnimatePresence>
            </motion.button>
          );
        })}
      </div>
    </div>
  );
}
