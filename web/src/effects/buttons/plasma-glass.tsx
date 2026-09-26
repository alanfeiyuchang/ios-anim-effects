/** buttons.plasma-glass · 等离子玻璃 (Buttons+PlasmaGlass.swift) */
import { motion } from "motion/react";
import { Sparkles } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, black, pressHandlers, spring, useAutoplay, useClock, useHaptics, white, type DemoProps } from "../../kit";
import { cub, spr, track, useKeyframes, wallSeconds } from "./_b-kit";

const W = 230;
const H = 64;

const BLOBS = [
  { color: Palette.violet, px: 7, py: 5, phase: 0 },
  { color: Palette.pink, px: 9, py: 6, phase: 1.7 },
  { color: Palette.sky, px: 6, py: 8, phase: 3.4 },
  { color: Palette.mint, px: 8, py: 7, phase: 5.1 },
];

export default function PlasmaGlass({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [taps, setTaps] = useState(0);
  const [pressed, setPressed] = useState(false);
  useClock(true, ctx.isPreview ? 30 : undefined);

  const tap = () => {
    setTaps((n) => n + 1);
    haptics.tap("soft");
  };
  useAutoplay(ctx.isPreview, tap, { every: 2.4, delay: 0.8 });

  const time = (wallSeconds() % 3600) * ctx.n("speed");
  const blur = ctx.n("blur");
  const kt = useKeyframes(taps, 1.1);
  const scale = kt < 0 ? 1 : track(kt, [spr(1.35, 0.25, 0.5, 0.85), cub(1.35, 0.25), spr(1, 0.6, 0.5, 1)], 1);
  const glow = kt < 0 ? 0 : track(kt, [cub(0.15, 0.2), cub(0.15, 0.3), cub(0, 0.5)], 0);

  /** The drifting blobs on a canvas `bleed` pt larger than the button on every side. */
  const blobLayer = (bleed: number) => (
    <div
      style={{
        position: "absolute",
        left: -bleed,
        top: -bleed,
        width: W + bleed * 2,
        height: H + bleed * 2,
        transform: `scale(${scale})`,
        filter: `brightness(${1 + glow * 1.4})`,
      }}
    >
      {BLOBS.map((b, i) => {
        const ax = (time * 2 * Math.PI) / b.px + b.phase;
        const ay = (time * 2 * Math.PI) / b.py + b.phase * 0.7;
        const x = Math.cos(ax) * W * 0.38;
        const y = Math.sin(ay) * H * 0.45;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: (W + bleed * 2) / 2 - 35 + x,
              top: (H + bleed * 2) / 2 - 35 + y,
              width: 70,
              height: 70,
              borderRadius: "50%",
              background: b.color,
              filter: `blur(${blur * 1.4}px)`,
            }}
          />
        );
      })}
    </div>
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 26 }}>
        <div style={{ fontSize: 20, lineHeight: "25px", fontWeight: 600, color: Palette.label }}>{ctx.t("What should we plan today?", "今天想计划点什么？")}</div>
        <motion.button
          type="button"
          {...pressHandlers(setPressed)}
          onClick={tap}
          animate={{ scale: pressed ? 0.96 : 1 }}
          transition={spring(0.3, 0.6)}
          style={{ position: "relative", width: W, height: H }}
        >
          {ctx.b("halo") && <div style={{ position: "absolute", inset: 0, filter: "blur(26px)", opacity: 0.7, pointerEvents: "none" }}>{blobLayer(80)}</div>}
          <div style={{ position: "absolute", inset: 0, borderRadius: H / 2, overflow: "hidden", isolation: "isolate" }}>
            {blobLayer(0)}
            <div style={{ position: "absolute", inset: 0, background: white(0.2) }} />
            <div style={{ position: "absolute", inset: 2, borderRadius: H / 2, background: `linear-gradient(${white(0.5)}, transparent 50%)` }} />
            <div
              style={{
                position: "absolute",
                inset: 0,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 8,
                fontSize: 17,
                fontWeight: 600,
                color: "#fff",
                filter: `drop-shadow(0 1px 4px ${black(0.2)})`,
              }}
            >
              <Sparkles size={19} fill="currentColor" strokeWidth={1.6} />
              {ctx.t("Ask anything", "随便问问")}
            </div>
          </div>
          <div style={{ position: "absolute", inset: 0, borderRadius: H / 2, boxShadow: `inset 0 0 0 1px ${white(0.45)}`, pointerEvents: "none" }} />
        </motion.button>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the glass button" zh="点击玻璃按钮" style={{ paddingBottom: 18 }} />
    </div>
  );
}
