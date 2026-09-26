/** icons.appear-disappear · 工具栏换装 · 出现与缩放 (Icons+AppearDisappear.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, anim, glass, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { Glyph, sym, type GlyphDef } from "./_icons-kit";

const outline = (...paths: string[]): GlyphDef => paths.map((d) => ({ d, mode: "stroke" as const, sw: 2 }));

const SLOTS: { browse: GlyphDef; edit: GlyphDef; tint: string }[] = [
  {
    browse: outline("M12 2v13", "m16 6-4-4-4 4", "M8.5 9H6a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-9a2 2 0 0 0-2-2h-2.5"),
    edit: outline("M3 6h18", "M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2", "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6", "M10 11v6M14 11v6"),
    tint: Palette.red,
  },
  {
    browse: outline("M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5Z"),
    edit: outline("M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"),
    tint: Palette.blue,
  },
  {
    browse: outline(
      "M16 10a2 2 0 0 1-2 2H6.828a2 2 0 0 0-1.414.586l-2.202 2.202A.71.71 0 0 1 2 14.286V4a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z",
      "M20 9a2 2 0 0 1 2 2v10.286a.71.71 0 0 1-1.212.502l-2.202-2.202A2 2 0 0 0 17.172 19H10a2 2 0 0 1-2-2v-1",
    ),
    edit: outline("M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2", "M10 8h10a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H10a2 2 0 0 1-2-2V10a2 2 0 0 1 2-2Z", "M15 12v6M12 15h6"),
    tint: Palette.violet,
  },
  {
    browse: outline("M17 3a2 2 0 0 1 2 2v15a1 1 0 0 1-1.496.868l-4.512-2.578a2 2 0 0 0-1.984 0l-4.512 2.578A1 1 0 0 1 5 20V5a2 2 0 0 1 2-2z"),
    edit: outline(
      "M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 0-4H8a2 2 0 0 0 0 4 1 1 0 0 1 1 1z",
      "M12 17v5",
    ),
    tint: Palette.amber,
  },
];

export default function AppearDisappear({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [editing, setEditing] = useState([false, false, false, false]);
  const [chosen, setChosen] = useState<Set<number>>(new Set());
  const [mode, setMode] = useState(false);
  const speed = Math.max(ctx.n("speed"), 0.1);
  const up = ctx.i("direction") === 1;

  const toggleMode = () => {
    haptics.selection();
    const target = !mode;
    setMode(target);
    setChosen(new Set());
    const stagger = ctx.n("stagger");
    SLOTS.forEach((_, i) => {
      const set = () => setEditing((e) => e.map((v, k) => (k === i ? target : v)));
      if (i === 0 || stagger <= 0) set();
      else after(i * stagger, set);
    });
  };

  const choose = (i: number) => {
    haptics.tap("light");
    setChosen((c) => {
      const next = new Set(c);
      if (next.has(i)) next.delete(i);
      else next.add(i);
      return next;
    });
  };

  useAutoplay(ctx.isPreview, toggleMode, { every: 2.0 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <button type="button" onClick={toggleMode} style={{ position: "relative", height: 34, padding: "0 18px", borderRadius: 17 }}>
        <motion.div
          initial={false}
          animate={{ opacity: mode ? 0 : 1 }}
          transition={anim.snappy}
          style={{ position: "absolute", inset: 0, borderRadius: 17, ...glass("thin") }}
        />
        <motion.div initial={false} animate={{ opacity: mode ? 1 : 0 }} transition={anim.snappy} style={{ position: "absolute", inset: 0, borderRadius: 17, background: Palette.primary }} />
        <div style={{ position: "absolute", inset: 0, borderRadius: 17, boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }} />
        <span style={{ position: "relative", ...textStyle.subheadline, fontWeight: 600, color: mode ? "#fff" : Palette.label, transition: "color 0.3s" }}>
          {mode ? ctx.t("Done", "完成") : ctx.t("Select", "选择")}
        </span>
      </button>
      <div
        style={{
          display: "flex",
          gap: 6,
          padding: 8,
          borderRadius: 34,
          ...glass("regular"),
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 10px 18px rgb(0 0 0 / 0.14)`,
        }}
      >
        {SLOTS.map((slot, i) => {
          const isEditing = editing[i];
          const isChosen = chosen.has(i);
          return (
            <button key={i} type="button" onClick={() => choose(i)} style={{ position: "relative", width: 58, height: 52 }}>
              <motion.div
                initial={false}
                animate={{ opacity: isChosen ? 1 : 0 }}
                transition={anim.snappy}
                style={{ position: "absolute", inset: 0, borderRadius: 26, background: Palette.labelAlpha(0.08) }}
              />
              <SlotSymbol def={slot.browse} color={Palette.label} hidden={isEditing} shrinkWhenHidden={!up} scaled={isChosen && !isEditing} speed={speed} />
              <SlotSymbol def={slot.edit} color={slot.tint} hidden={!isEditing} shrinkWhenHidden={up} scaled={isChosen && isEditing} speed={speed} />
            </button>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap Select, then an action" zh="点击「选择」，再点某个操作" />
    </div>
  );
}

/**
 * A symbol under `.symbolEffect(.disappear.{down|up}.byLayer, isActive: hidden)` and
 * `.symbolEffect(.scale.up, isActive: scaled)`: layers blur, fade and scale away one after another
 * (down shrinks them, up grows them) and come back the same way.
 */
function SlotSymbol({
  def,
  color,
  hidden,
  shrinkWhenHidden,
  scaled,
  speed,
}: {
  def: GlyphDef;
  color: string;
  hidden: boolean;
  shrinkWhenHidden: boolean;
  scaled: boolean;
  speed: number;
}) {
  const d = 0.22 / speed;
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color }}>
      <motion.div initial={false} animate={{ scale: scaled ? 1.2 : 1 }} transition={spring(0.35, 0.7)}>
        <Glyph
          def={def}
          size={sym(21)}
          weight={1}
          layerStyle={(i) => ({
            opacity: hidden ? 0 : 1,
            filter: hidden ? "blur(1.5px)" : "blur(0px)",
            transform: `scale(${hidden ? (shrinkWhenHidden ? 0.5 : 1.35) : 1})`,
            transition: `opacity ${d}s ease-out ${(i * 0.04) / speed}s, transform ${d}s ease-out ${(i * 0.04) / speed}s, filter ${d}s ease-out ${(i * 0.04) / speed}s`,
          })}
        />
      </motion.div>
    </div>
  );
}
