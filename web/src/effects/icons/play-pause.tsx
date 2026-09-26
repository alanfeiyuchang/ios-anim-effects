/** icons.play-pause · 播放 ↔ 暂停形变 (Icons+PlayPause.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useEffect, useState } from "react";
import { DemoHint, Palette, demoCard, spring, textStyle, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { Glyph, SYM, sym } from "./_icons-kit";

type Pt = [number, number];
// The two play halves overlap by 0.04 across the midline so no seam shows between them.
const PLAY_LEFT: Pt[] = [[0.1, 0], [0.545, 0.2618], [0.545, 0.7382], [0.1, 1]];
const PLAY_RIGHT: Pt[] = [[0.505, 0.2382], [0.95, 0.5], [0.95, 0.5], [0.505, 0.7618]];
const PAUSE_LEFT: Pt[] = [[0.1, 0], [0.38, 0], [0.38, 1], [0.1, 1]];
const PAUSE_RIGHT: Pt[] = [[0.62, 0], [0.9, 0], [0.9, 1], [0.62, 1]];

function quad(a: Pt[], b: Pt[], progress: number, size: number) {
  const t = Math.min(Math.max(progress, -0.2), 1.2);
  return (
    a
      .map((p, i) => `${i === 0 ? "M" : "L"}${((p[0] + (b[i][0] - p[0]) * t) * size).toFixed(3)} ${((p[1] + (b[i][1] - p[1]) * t) * size).toFixed(3)}`)
      .join("") + "Z"
  );
}
const shapePath = (p: number) => quad(PLAY_LEFT, PAUSE_LEFT, p, 30) + quad(PLAY_RIGHT, PAUSE_RIGHT, p, 30);

export default function PlayPause({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [playing, setPlaying] = useState(false);
  const progress = useMotionValue(0);
  const spin = ctx.b("spin");
  const response = ctx.n("response");
  const damping = ctx.n("damping");
  const rotation = useMotionValue(0);

  useEffect(() => {
    const a = animate(progress, playing ? 1 : 0, spring(response, damping));
    const b = animate(rotation, spin && playing ? 180 : 0, spring(response, damping));
    return () => {
      a.stop();
      b.stop();
    };
  }, [playing, spin, response, damping, progress, rotation]);

  const d = useTransform(progress, shapePath);

  const toggle = () => {
    setPlaying((p) => !p);
    haptics.tap("medium");
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.6 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ position: "relative", ...demoCard(28), width: 290, padding: 20, display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 14, alignSelf: "stretch" }}>
          <div style={{ width: 60, height: 60, borderRadius: 14, background: Palette.sunset, display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
            <Glyph def={SYM.musicNote} size={sym(22)} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <span style={{ ...textStyle.headline }}>{ctx.t("Midnight Drive", "午夜驾驶")}</span>
              <EqualizerBars active={playing} preview={ctx.isPreview} />
            </div>
            <span style={{ ...textStyle.subheadline, color: Palette.secondaryLabel }}>{ctx.t("Neon Coast", "霓虹海岸")}</span>
          </div>
        </div>
        <button
          type="button"
          onClick={toggle}
          style={{ width: 76, height: 76, borderRadius: "50%", background: Palette.primary, boxShadow: `0 8px 14px rgb(164 107 255 / 0.4)`, display: "grid", placeItems: "center" }}
        >
          <motion.svg width={30} height={30} viewBox="0 0 30 30" style={{ overflow: "visible", rotate: rotation }}>
            <motion.path d={d} fill="#fff" stroke="#fff" strokeWidth={5} strokeLinejoin="round" />
          </motion.svg>
        </button>
        <DemoHint ctx={ctx} en="Tap play" zh="点击播放" style={{ position: "absolute", left: 0, right: 0, bottom: -30, whiteSpace: "nowrap" }} />
      </div>
    </div>
  );
}

function EqualizerBars({ active, preview }: { active: boolean; preview: boolean }) {
  const t = useClock(active, preview ? 30 : undefined);
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 2, height: 14 }}>
      {[0, 1, 2].map((i) => {
        const h = active ? 8 + Math.sin(t * (7 + i * 2.3) + i * 1.7) * 6 : 4;
        return <div key={i} style={{ width: 3, height: h, borderRadius: 1.5, background: Palette.pink }} />;
      })}
    </div>
  );
}
