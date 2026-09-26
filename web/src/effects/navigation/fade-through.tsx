/** navigation.fade-through · 淡出穿透 (Navigation+FadeThrough.swift) */
import { AnimatePresence, motion, type Variants } from "motion/react";
import { Calendar, Folder, Inbox, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, delayed, hex, useAutoplay, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { colorGradient } from "./nav-util";

interface FadeDestination {
  icon: LucideIcon;
  filled: boolean;
  title: [string, string];
  tint: string;
}

const fadeDestinations: FadeDestination[] = [
  { icon: Inbox, filled: false, title: ["Inbox", "收件箱"], tint: Palette.indigo },
  { icon: Calendar, filled: false, title: ["Calendar", "日历"], tint: Palette.coral },
  { icon: Folder, filled: true, title: ["Files", "文件"], tint: Palette.mint },
];

interface Custom {
  pattern: number;
  forward: boolean;
  total: number;
}

/** The three Material motion patterns as enter / exit variants (Swift's asymmetric transitions). */
const variants: Variants = {
  enter: ({ pattern, forward }: Custom) =>
    pattern === 1 ? { opacity: 0, x: forward ? 30 : -30, scale: 1 } : pattern === 2 ? { opacity: 0, scale: 0.8, x: 0 } : { opacity: 0, scale: 0.92, x: 0 },
  center: ({ pattern, total }: Custom) => ({
    opacity: 1,
    x: 0,
    scale: 1,
    transition: pattern === 1 ? anim.easeInOut(total) : delayed(anim.easeOut(total * 0.7), total * 0.3),
  }),
  exit: ({ pattern, forward, total }: Custom) =>
    pattern === 1
      ? { opacity: 0, x: forward ? -30 : 30, transition: anim.easeInOut(total) }
      : pattern === 2
        ? { opacity: 0, scale: 1.1, transition: anim.easeIn(total * 0.3) }
        : { opacity: 0, transition: anim.easeIn(total * 0.3) },
};

export default function FadeThrough({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(0);
  const [forward, setForward] = useState(true);
  const sel = useRef(0);

  const select = (index: number) => {
    if (index === sel.current) return;
    haptics.selection();
    setForward(index > sel.current);
    sel.current = index;
    setSelected(index);
  };
  useAutoplay(ctx.isPreview, () => select((sel.current + 1) % fadeDestinations.length), { every: 1.1 });

  const custom: Custom = { pattern: ctx.i("pattern"), forward, total: ctx.n("duration") };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        style={{
          width: 250,
          height: 320,
          flexShrink: 0,
          display: "flex",
          flexDirection: "column",
          background: Palette.elevated,
          borderRadius: 34,
          overflow: "hidden",
          boxShadow: "0 10px 18px rgb(0 0 0 / 0.18)",
          isolation: "isolate",
        }}
      >
        <div style={{ position: "relative", flex: 1, overflow: "hidden" }}>
          <AnimatePresence initial={false} custom={custom}>
            <motion.div key={selected} custom={custom} variants={variants} initial="enter" animate="center" exit="exit" style={{ position: "absolute", inset: 0 }}>
              <FadePage ctx={ctx} destination={fadeDestinations[selected]} />
            </motion.div>
          </AnimatePresence>
        </div>
        <div style={{ display: "flex", paddingTop: 8, paddingBottom: 14, background: Palette.surface }}>
          {fadeDestinations.map((d, index) => {
            const isSelected = index === selected;
            const Icon = d.icon;
            return (
              <div
                key={d.title[0]}
                onClick={() => select(index)}
                style={{
                  flex: 1,
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: 3,
                  cursor: "pointer",
                  color: isSelected ? d.tint : Palette.secondaryLabel,
                  transition: "color 0.2s ease-in-out",
                }}
              >
                <div
                  style={{
                    width: 52,
                    height: 26,
                    borderRadius: 13,
                    display: "grid",
                    placeItems: "center",
                    background: isSelected ? hex(d.tint, 0.18) : "transparent",
                    transition: "background 0.2s ease-in-out",
                  }}
                >
                  <Icon size={18} strokeWidth={2.3} fill={d.filled ? "currentColor" : "none"} />
                </div>
                <span style={{ fontSize: 10, lineHeight: "12px", fontWeight: 600 }}>{ctx.t(...d.title)}</span>
              </div>
            );
          })}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap a destination" zh="点击底部目的地" />
    </div>
  );
}

function FadePage({ ctx, destination }: { ctx: DemoContext; destination: FadeDestination }) {
  const Icon = destination.icon;
  return (
    <div style={{ position: "absolute", inset: 0, background: Palette.elevated, padding: "28px 18px 18px", display: "flex", flexDirection: "column", gap: 12 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <div style={{ width: 38, height: 38, borderRadius: 12, background: colorGradient(destination.tint), color: "#fff", display: "grid", placeItems: "center" }}>
          <Icon size={19} strokeWidth={2.4} fill={destination.filled ? "currentColor" : "none"} />
        </div>
        <span style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{ctx.t(...destination.title)}</span>
      </div>
      {[0, 1, 2, 3].map((i) => (
        <div key={i} style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 28, height: 28, borderRadius: "50%", background: hex(destination.tint, 0.25), flexShrink: 0 }} />
          <div style={{ flex: 1 }}>
            <PlaceholderLines count={2} color={Palette.labelAlpha(0.1)} />
          </div>
        </div>
      ))}
    </div>
  );
}
