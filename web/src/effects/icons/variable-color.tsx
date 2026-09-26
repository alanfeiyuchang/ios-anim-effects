/** icons.variable-color · 可变颜色直播 (Icons+VariableColor.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, demoCard, textStyle, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { Glyph, Replace, SYM, sym, variableColorLit, type GlyphDef } from "./_icons-kit";

/** Opacity of a variable layer that is not lit (SF Symbols dims it rather than hiding it). */
const DIM = 0.28;

export default function VariableColor({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [live, setLive] = useState(true);
  const toggle = () => {
    setLive((l) => !l);
    haptics.tap("soft");
  };
  useAutoplay(ctx.isPreview, toggle, { every: 2.4 });
  const zh = ctx.lang === "zh";

  return (
    <div
      onClick={toggle}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ ...demoCard(26), width: 280, padding: "26px 0", display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
        <div style={{ display: "flex", gap: 30 }}>
          <VariableGlyph ctx={ctx} def={SYM.speakerWave3Fill} scale={1.3} tint={Palette.violet} live={live} />
          <VariableGlyph ctx={ctx} def={SYM.dotRadiowaves} scale={1.08} tint={Palette.pink} live={live} />
          <VariableGlyph ctx={ctx} def={SYM.antennaRadiowaves} scale={1.07} tint={Palette.coral} live={live} />
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, ...textStyle.headline }}>
          <Replace k={live ? "live" : "paused"}>
            <div style={{ color: live ? Palette.red : Palette.secondaryLabel }}>
              <Glyph def={live ? SYM.waveform : SYM.pauseCircleFill} size={sym(17)} />
            </div>
          </Replace>
          <span style={{ display: "grid" }}>
            {[true, false].map((state) => (
              <motion.span
                key={String(state)}
                initial={false}
                animate={{ opacity: live === state ? 1 : 0 }}
                transition={{ duration: 0.25 }}
                style={{ gridArea: "1 / 1", color: state ? Palette.label : Palette.secondaryLabel, whiteSpace: "nowrap" }}
              >
                {state ? (zh ? "直播中" : "On Air") : zh ? "已暂停" : "Paused"}
              </motion.span>
            ))}
          </span>
          <motion.span
            animate={live ? { opacity: [1, 0.35] } : { opacity: 0 }}
            transition={live ? { duration: 0.6, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" } : { duration: 0.2 }}
            style={{ width: 8, height: 8, borderRadius: "50%", background: Palette.red }}
          />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to pause or go live" zh="点击暂停或开始直播" />
    </div>
  );
}

function VariableGlyph({ ctx, def, tint, live, scale }: { ctx: DemoProps["ctx"]; def: GlyphDef; tint: string; live: boolean; scale: number }) {
  const t = useClock(live, ctx.isPreview ? 30 : undefined);
  const n = def.length - 1;
  const level = ctx.n("level");
  const lit = live
    ? variableColorLit(t, n, ctx.i("mode") === 1, ctx.b("reversing"), 0.22 / Math.max(ctx.n("speed"), 0.1))
    : Array.from({ length: n }, (_, i) => level > i / n);
  return (
    <div style={{ width: 56, height: 50, display: "grid", placeItems: "center", color: tint }}>
      <Glyph
        def={def}
        size={Math.round(sym(40) * scale)}
        weight={0.9 / scale}
        layerStyle={(i) => (i === 0 ? undefined : { opacity: lit[i - 1] ? 1 : DIM, transition: "opacity 0.14s linear" })}
      />
    </div>
  );
}
