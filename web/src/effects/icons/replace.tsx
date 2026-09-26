/** icons.replace · 符号替换 (Icons+Replace.swift) */
import { motion } from "motion/react";
import { useEffect, useId, useRef, useState } from "react";
import { DemoHint, Palette, anim, glass, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { Glyph, Replace, SLASH, SYM, sym, type GlyphDef, type ReplaceStyle } from "./_icons-kit";

const TOGGLES: { on: GlyphDef; off: GlyphDef; slash: boolean }[] = [
  { on: SYM.micFill, off: SYM.micFill, slash: true },
  { on: SYM.bellFill, off: SYM.bellFill, slash: true },
  { on: SYM.lockFill, off: SYM.lockOpenFill, slash: false },
  { on: SYM.videoFill, off: SYM.videoFill, slash: true },
];

const SIZE = sym(30);

export default function ReplaceDemo({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [states, setStates] = useState([true, true, true, false]);
  const [autoIndex, setAutoIndex] = useState(0);
  const style = ctx.i("style");

  const flip = (i: number) => {
    setStates((s) => s.map((v, k) => (k === i ? !v : v)));
    haptics.selection();
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      flip(autoIndex % TOGGLES.length);
      setAutoIndex((n) => n + 1);
    },
    { every: 0.8 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 20 }}>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "84px 84px",
          gap: 18,
          padding: 20,
          borderRadius: 32,
          ...glass("thin"),
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
        }}
      >
        {TOGGLES.map((toggle, i) => {
          const on = states[i];
          const kind: ReplaceStyle | "magic" = style === 1 ? "downUp" : style === 2 ? "upUp" : style === 3 ? "offUp" : toggle.slash ? "magic" : "downUp";
          return (
            <button key={i} type="button" onClick={() => flip(i)} style={{ position: "relative", width: 84, height: 84 }}>
              <motion.div
                initial={false}
                animate={{ opacity: on ? 0 : 1 }}
                transition={anim.snappyD(0.35)}
                style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.labelAlpha(0.08) }}
              />
              <motion.div
                initial={false}
                animate={{ opacity: on ? 1 : 0 }}
                transition={anim.snappyD(0.35)}
                style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.ocean, boxShadow: "0 6px 12px rgb(79 124 255 / 0.35)" }}
              />
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  display: "grid",
                  placeItems: "center",
                  color: on ? "#fff" : Palette.label,
                  transition: "color 0.3s",
                }}
              >
                {kind === "magic" ? (
                  <MagicSlash def={toggle.on} slashed={!on} />
                ) : (
                  <Replace k={on ? "on" : "off"} kind={kind}>
                    <Glyph def={on ? toggle.on : toggle.slash ? slashed(toggle.off) : toggle.off} size={SIZE} />
                  </Replace>
                )}
              </div>
            </button>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap the toggles" zh="点击开关" />
    </div>
  );
}

/** The slashed variant as a static glyph (for the non-magic replace styles). */
function slashed(def: GlyphDef): GlyphDef {
  return [...def.map((l) => ({ ...l, cut: { d: SLASH, sw: 4.6 } })), { d: SLASH, mode: "stroke" as const, sw: 2.1 }];
}

/**
 * Magic Replace between a symbol and its `.slash` variant: the base stays put while the slash
 * draws across it (knocking out a gap as it goes), or retracts when the slash goes away, with a small
 * scale dip.
 */
function MagicSlash({ def, slashed: on }: { def: GlyphDef; slashed: boolean }) {
  const id = useId().replace(/:/g, "");
  const t = anim.snappyD(0.35);
  const mounted = useRef(false);
  useEffect(() => {
    mounted.current = true;
  }, []);
  const from = mounted.current ? (on ? 0 : 1) : on ? 1 : 0;
  return (
    <motion.svg
      width={SIZE}
      height={SIZE}
      viewBox="0 0 24 24"
      style={{ overflow: "visible" }}
      initial={false}
      animate={{ scale: mounted.current ? [1, 0.86, 1] : 1 }}
      key={on ? "a" : "b"}
      transition={{ duration: 0.35, times: [0, 0.4, 1] }}
    >
      <mask id={`${id}-m`} maskUnits="userSpaceOnUse" x={-12} y={-12} width={48} height={48}>
        <rect x={-12} y={-12} width={48} height={48} fill="#fff" />
        <motion.path d={SLASH} stroke="#000" strokeWidth={4.6} strokeLinecap="round" fill="none" initial={{ pathLength: from }} animate={{ pathLength: on ? 1 : 0 }} transition={t} />
      </mask>
      <g mask={`url(#${id}-m)`}>
        <Glyph def={def} size={24} />
      </g>
      <motion.path
        d={SLASH}
        stroke="currentColor"
        strokeWidth={2.1}
        strokeLinecap="round"
        fill="none"
        initial={{ pathLength: from, opacity: on || !mounted.current ? (on ? 1 : 0) : 1 }}
        animate={{ pathLength: on ? 1 : 0, opacity: on ? 1 : 0 }}
        transition={{ pathLength: t, opacity: on ? { duration: 0 } : { duration: 0.05, delay: 0.3 } }}
      />
    </motion.svg>
  );
}
