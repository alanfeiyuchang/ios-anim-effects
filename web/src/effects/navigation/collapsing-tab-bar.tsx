/** navigation.collapsing-tab-bar · 滚动收起标签栏 (Navigation+CollapsingTabBar.swift) */
import { animate, motion, type AnimationPlaybackControls } from "motion/react";
import { Bike, Leaf, Music, Paintbrush, PersonStanding, Search, Sunrise, Utensils } from "lucide-react";
import { useEffect, useRef, useState, type ComponentType, type CSSProperties } from "react";
import { DemoHint, Palette, anim, black, demoCard, fonts, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BellFill, HouseFill, PersonFill, PlaySquareStackFill, colorGradient } from "./groupA-kit";

type Icon = ComponentType<{ size: number; style?: CSSProperties }>;
const TABS: Icon[] = [HouseFill, PlaySquareStackFill, BellFill, PersonFill];
const TAB_W = 52;

const POSTS: { icon: (size: number) => React.ReactNode; title: [string, string]; meta: [string, string] }[] = [
  { icon: (s) => <Sunrise size={s} strokeWidth={2.6} />, title: ["Chasing golden hour", "追逐黄金时刻"], meta: ["Mia · Photography · 4 min", "米娅 · 摄影 · 4 分钟"] },
  { icon: (s) => <Utensils size={s} strokeWidth={2.6} />, title: ["Five-minute breakfast bowls", "五分钟早餐碗"], meta: ["Kai · Food · 3 min", "凯 · 美食 · 3 分钟"] },
  { icon: (s) => <PersonStanding size={s} strokeWidth={2.6} />, title: ["A weekend on the ridge", "山脊上的周末"], meta: ["Lena · Travel · 6 min", "莉娜 · 旅行 · 6 分钟"] },
  { icon: (s) => <Paintbrush size={s} strokeWidth={2.4} fill="currentColor" />, title: ["Color theory for UI", "界面色彩理论"], meta: ["Sam · Design · 8 min", "萨姆 · 设计 · 8 分钟"] },
  { icon: (s) => <Music size={s} strokeWidth={2.6} />, title: ["Songs for deep focus", "深度专注歌单"], meta: ["Noor · Music · 2 min", "努尔 · 音乐 · 2 分钟"] },
  { icon: (s) => <Leaf size={s} strokeWidth={2.2} fill="currentColor" />, title: ["Keeping ferns alive", "养活蕨类的秘诀"], meta: ["Ava · Home · 5 min", "艾娃 · 家居 · 5 分钟"] },
  { icon: (s) => <Bike size={s} strokeWidth={2.4} />, title: ["Commuting by bike", "骑车通勤这一年"], meta: ["Leo · City · 7 min", "利奥 · 城市 · 7 分钟"] },
];

export default function CollapsingTabBar({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [collapsed, setCollapsed] = useState(false);
  const collapsedRef = useRef(false);
  const [selected, setSelected] = useState(0);
  const scroller = useRef<HTMLDivElement>(null);
  const lastOffset = useRef(0);
  /** Signed scroll travel since the last direction reversal, so slow scrolls add up. */
  const travel = useRef(0);
  const autoDown = useRef(true);
  const scripted = useRef<AnimationPlaybackControls | null>(null);
  useEffect(() => () => scripted.current?.stop(), []);

  const barSpring = spring(ctx.n("response"), 0.85);

  const setCollapsedTo = (target: boolean) => {
    if (target === collapsedRef.current) return;
    collapsedRef.current = target;
    setCollapsed(target);
  };

  const handleScroll = (oldValue: number, newValue: number) => {
    const delta = newValue - oldValue;
    if (newValue < 24) {
      travel.current = 0;
      setCollapsedTo(false);
      return;
    }
    if (delta === 0) return;
    // A change of direction starts a fresh tally.
    if (travel.current !== 0 && delta > 0 !== travel.current > 0) travel.current = 0;
    travel.current += delta;
    const collapseAfter = ctx.n("sensitivity");
    if (travel.current > collapseAfter) setCollapsedTo(true);
    else if (travel.current < -collapseAfter / 2) setCollapsedTo(false);
  };

  const onScroll = () => {
    const el = scroller.current;
    if (!el) return;
    const value = el.scrollTop;
    handleScroll(lastOffset.current, value);
    lastOffset.current = value;
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const el = scroller.current;
      if (!el) return;
      scripted.current?.stop();
      const target = Math.min(autoDown.current ? 420 : 0, el.scrollHeight - el.clientHeight);
      scripted.current = animate(el.scrollTop, target, { ...anim.smoothD(1.1), onUpdate: (v) => (el.scrollTop = v) });
      autoDown.current = !autoDown.current;
    },
    { every: 2.0 },
  );

  const tap = (index: number) => {
    haptics.selection();
    if (collapsedRef.current) {
      // Tapping the minimized pill brings the full bar back, as on iOS 26.
      travel.current = 0;
      setCollapsedTo(false);
    } else {
      setSelected(index);
    }
  };

  const pillW = 12 + (collapsed ? 1 : TABS.length) * TAB_W;

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div
        ref={scroller}
        onScroll={onScroll}
        onWheel={() => scripted.current?.stop()}
        onPointerDown={() => scripted.current?.stop()}
        style={{ position: "absolute", inset: 0, overflowY: "auto", touchAction: "pan-y", scrollbarWidth: "none", overscrollBehavior: "contain" }}
      >
        <div style={{ padding: "16px 16px 90px", display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ padding: "0 4px", display: "flex", flexDirection: "column", gap: 2 }}>
            <div style={{ fontFamily: fonts.text, fontSize: 22, lineHeight: "28px", fontWeight: 700, color: Palette.label }}>
              {ctx.lang === "zh" ? "为你推荐" : "For You"}
            </div>
            <DemoHint ctx={ctx} en="Scroll down to shrink the bar, up to restore it" zh="向下滚动收起标签栏，向上滚动恢复" style={{ textAlign: "left" }} />
          </div>
          {Array.from({ length: 14 }, (_, index) => (
            <FeedCard key={index} index={index} t={ctx.t} />
          ))}
        </div>
      </div>
      {/* bar */}
      <div style={{ position: "absolute", left: 20, right: 20, bottom: 16, display: "flex", alignItems: "center", gap: 10, pointerEvents: "none" }}>
        <motion.div
          initial={false}
          animate={{ width: pillW }}
          transition={barSpring}
          style={{
            position: "relative",
            height: 56,
            borderRadius: 999,
            ...glass("regular"),
            boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 16px ${black(0.12)}`,
            flexShrink: 0,
          }}
        >
          {TABS.map((Glyph, index) => {
            const isSelected = index === selected;
            const shown = !collapsed || isSelected;
            const x = 6 + (collapsed ? 0 : index * TAB_W);
            return (
              <motion.button
                key={index}
                type="button"
                onClick={() => tap(index)}
                initial={false}
                animate={{ x, scale: shown ? 1 : 0.6, opacity: shown ? 1 : 0 }}
                transition={barSpring}
                style={{
                  position: "absolute",
                  left: 0,
                  top: 6,
                  width: TAB_W,
                  height: 44,
                  display: "grid",
                  placeItems: "center",
                  pointerEvents: shown ? "auto" : "none",
                  color: isSelected ? Palette.indigo : Palette.secondaryLabel,
                  transition: "color 0.3s",
                }}
              >
                <motion.div
                  initial={false}
                  animate={{ opacity: isSelected ? 1 : 0 }}
                  transition={anim.snappy}
                  style={{ position: "absolute", inset: 0, borderRadius: 999, background: "rgb(110 123 255 / 0.14)" }}
                />
                <Glyph size={21} style={{ position: "relative" }} />
              </motion.button>
            );
          })}
        </motion.div>
        <div style={{ flex: 1 }} />
        <div
          style={{
            width: 56,
            height: 56,
            borderRadius: "50%",
            display: "grid",
            placeItems: "center",
            color: Palette.label,
            ...glass("regular"),
            boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 16px ${black(0.12)}`,
            pointerEvents: "auto",
            flexShrink: 0,
          }}
        >
          <Search size={21} strokeWidth={2.6} />
        </div>
      </div>
    </div>
  );
}

function FeedCard({ index, t }: { index: number; t: (en: string, zh: string) => string }) {
  const post = POSTS[index % POSTS.length];
  const color = Palette.spectrum[index % Palette.spectrum.length];
  return (
    <div style={{ ...demoCard(20), padding: 12, display: "flex", alignItems: "center", gap: 12 }}>
      <div style={{ width: 56, height: 56, borderRadius: 14, background: colorGradient(color), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
        {post.icon(26)}
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 3, minWidth: 0 }}>
        <div style={{ fontFamily: fonts.text, fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
          {t(...post.title)}
        </div>
        <div style={{ fontFamily: fonts.text, fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
          {t(...post.meta)}
        </div>
      </div>
    </div>
  );
}
