/** inputs.swatch-picker · 色板选择器 (Inputs+SwatchPicker.swift) */
import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { Check, Nfc } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, ease, fonts, hex, mix, spring, springAt, useAutoplay, useElapsed, useHaptics, type DemoProps } from "../../kit";

const SWATCHES = [
  { en: "Midnight", zh: "午夜蓝", light: "#3A3F6B", dark: "#14172E" },
  { en: "Indigo", zh: "靛蓝", light: Palette.indigo, dark: "#3B3FA8" },
  { en: "Lagoon", zh: "泻湖青", light: Palette.mint, dark: "#0E7D8C" },
  { en: "Sunset", zh: "落日橙", light: Palette.amber, dark: Palette.coral },
  { en: "Rose", zh: "玫瑰粉", light: Palette.pink, dark: "#B0306A" },
  { en: "Graphite", zh: "石墨灰", light: "#9A9AA3", dark: "#3C3C43" },
];
const PREVIEW_ORDER = [3, 1, 4, 2, 0, 5];
const gradient = (s: (typeof SWATCHES)[number]) => `linear-gradient(135deg, ${s.light}, ${s.dark})`;

export default function SwatchPicker({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(0);
  const [previous, setPrevious] = useState(0);
  const [flicks, setFlicks] = useState(0);
  const sel = useRef(0);
  const flickCount = useRef(0);

  const select = (index: number) => {
    if (index === sel.current) return;
    setPrevious(sel.current);
    sel.current = index;
    setSelected(index);
    flickCount.current += 1;
    setFlicks(flickCount.current);
  };

  useAutoplay(ctx.isPreview, () => select(PREVIEW_ORDER[flickCount.current % PREVIEW_ORDER.length]), { every: 1.1, delay: 0.4 });

  const ringT = spring(ctx.n("response"), ctx.n("damping"));
  const dir = selected >= previous ? 1 : -1;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
      <div style={{ flex: 1 }} />
      <Card selected={selected} flicks={flicks} flick={ctx.b("flick")} />
      <LayoutGroup>
        <div style={{ display: "flex", gap: 8 }}>
          {SWATCHES.map((s, index) => {
            const isSelected = index === selected;
            return (
              <button
                key={index}
                type="button"
                onClick={() => {
                  if (index !== sel.current) haptics.selection();
                  select(index);
                }}
                style={{ position: "relative", width: 44, height: 44, borderRadius: "50%", display: "grid", placeItems: "center" }}
              >
                {isSelected && (
                  <motion.div
                    layoutId="swatch-ring"
                    transition={ringT}
                    style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: `inset 0 0 0 2px ${Palette.labelAlpha(0.75)}` }}
                  />
                )}
                <motion.div
                  initial={false}
                  animate={{ scale: isSelected ? 1 : 0.82 }}
                  transition={ringT}
                  style={{ position: "absolute", left: 5, top: 5, width: 34, height: 34, borderRadius: "50%", background: gradient(s), boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.25)" }}
                />
                <motion.div
                  initial={false}
                  animate={{ scale: isSelected ? 1 : 0.3, opacity: isSelected ? 1 : 0 }}
                  transition={ringT}
                  style={{ position: "relative", color: "#fff", display: "grid" }}
                >
                  <Check size={14} strokeWidth={4} />
                </motion.div>
              </button>
            );
          })}
        </div>
      </LayoutGroup>
      <div style={{ position: "relative", width: 200, height: 22, overflow: "hidden" }}>
        <AnimatePresence initial={false} custom={dir}>
          <motion.div key={selected} custom={dir} initial="enter" animate="center" exit="exit" style={{ position: "absolute", inset: 0, display: "flex", justifyContent: "center" }}>
            <motion.span
              custom={dir}
              variants={{
                enter: (d: number) => ({ x: `${100 * d}%`, opacity: 0 }),
                center: { x: "0%", opacity: 1 },
                exit: (d: number) => ({ x: `${-100 * d}%`, opacity: 0 }),
              }}
              transition={ringT}
              style={{ display: "inline-block", fontSize: 15, lineHeight: "22px", fontWeight: 600, color: Palette.label, whiteSpace: "nowrap" }}
            >
              {ctx.t(SWATCHES[selected].en, SWATCHES[selected].zh)}
            </motion.span>
          </motion.div>
        </AnimatePresence>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap a swatch to recolor the card" zh="点击色块为卡片换色" style={{ paddingBottom: 14 }} />
    </div>
  );
}

function Card({ selected, flicks, flick }: { selected: number; flicks: number; flick: boolean }) {
  // keyframeAnimator: cubic to 10° / 0.97 in 0.12 s, then a bouncy spring back.
  const t = useElapsed(flicks, 0.7, true);
  let angle = 0;
  let scale = 1;
  if (t >= 0) {
    const toAngle = flick ? 10 : 0;
    const toScale = flick ? 0.97 : 1;
    if (t < 0.12) {
      const p = ease.inOut(t / 0.12);
      angle = mix(0, toAngle, p);
      scale = mix(1, toScale, p);
    } else {
      angle = mix(toAngle, 0, springAt(t - 0.12, 0.5, 0.7));
      scale = mix(toScale, 1, springAt(t - 0.12, 0.5, 0.7));
    }
  }
  return (
    <div style={{ perspective: 417, flexShrink: 0 }}>
      <div
        style={{
          position: "relative",
          width: 250,
          height: 150,
          borderRadius: 20,
          transform: `rotateY(${angle}deg) scale(${scale})`,
          boxShadow: `0 12px 18px ${hex(SWATCHES[selected].dark, 0.4)}`,
          transition: "box-shadow 0.35s ease-in-out",
        }}
      >
        <div style={{ position: "absolute", inset: 0, borderRadius: 20, overflow: "hidden" }}>
          {SWATCHES.map((s, index) => (
            <motion.div
              key={index}
              initial={false}
              animate={{ opacity: index === selected ? 1 : 0 }}
              transition={anim.easeInOut(0.35)}
              style={{ position: "absolute", inset: 0, background: gradient(s) }}
            />
          ))}
          <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, rgb(255 255 255 / 0.28), transparent, rgb(255 255 255 / 0.06))" }} />
          <div style={{ position: "absolute", inset: 0, padding: 18, display: "flex", flexDirection: "column", alignItems: "flex-start" }}>
            <div style={{ display: "flex", alignItems: "center", alignSelf: "stretch" }}>
              <div style={{ width: 36, height: 27, borderRadius: 5, background: "linear-gradient(#F5D98B, #C9A24A)" }} />
              <span style={{ flex: 1 }} />
              <Nfc size={20} strokeWidth={2.4} color="rgb(255 255 255 / 0.85)" />
            </div>
            <span style={{ flex: 1 }} />
            <span style={{ fontFamily: fonts.mono, fontSize: 17, lineHeight: "22px", fontWeight: 600, color: "#fff", whiteSpace: "pre" }}>••••  4821</span>
            <span style={{ fontFamily: fonts.rounded, fontSize: 10, lineHeight: "13px", fontWeight: 700, letterSpacing: 1.4, color: "rgb(255 255 255 / 0.7)" }}>MOTION LEXICON</span>
          </div>
          <div style={{ position: "absolute", inset: 0, borderRadius: 20, boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.18)" }} />
        </div>
      </div>
    </div>
  );
}
