/** navigation.ripple-tab-bar · 涟漪标签栏 (Navigation+RippleTabBar.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, black, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { NavigationScreenPlaceholder } from "./shared";
import { BOUNCY, Glyph, cubicKF, linearKF, springKF, track, trackDuration, useSince, type GlyphName } from "./groupB-kit";

const SYMBOLS: GlyphName[] = ["house.fill", "music.note", "play.rectangle.fill", "bag.fill", "person.crop.circle.fill"];
const TITLES: [string, string][] = [
  ["Home", "首页"],
  ["Music", "音乐"],
  ["Videos", "视频"],
  ["Shop", "商店"],
  ["Me", "我"],
];
const COLORS = [Palette.indigo, Palette.pink, Palette.coral, Palette.mint, Palette.sky];
const SLOT = 60;
const SEQUENCE = [2, 4, 1, 3, 0];

export default function RippleTabBar({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(0);
  const [origin, setOrigin] = useState(0);
  const [waves, setWaves] = useState(0);
  const wavesRef = useRef(0);

  const tap = (index: number) => {
    haptics.tap("light");
    setOrigin(index);
    setSelected(index);
    wavesRef.current += 1;
    setWaves(wavesRef.current);
  };

  useAutoplay(ctx.isPreview, () => tap(SEQUENCE[wavesRef.current % SEQUENCE.length]), { every: 1.3 });

  const stagger = ctx.n("stagger");
  const amplitude = ctx.n("amplitude");
  const falloff = ctx.n("falloff");
  // Long enough for the farthest icon's hop and the ring.
  const t = useSince(waves, Math.max(4 * stagger + 0.64, 0.61));

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 24 }}>
      {ctx.isPreview && (
        <div style={{ paddingTop: 20 }}>
          <NavigationScreenPlaceholder />
        </div>
      )}
      <div style={{ flex: 1, minHeight: 0 }} />
      <div
        style={{
          display: "flex",
          padding: "10px 8px",
          borderRadius: 28,
          flexShrink: 0,
          ...glass("regular"),
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 18px ${black(0.12)}`,
        }}
      >
        {SYMBOLS.map((symbol, index) => {
          const isSelected = index === selected;
          const steps = Math.abs(index - origin);
          const delay = Math.max(steps * stagger, 0.001);
          const height = amplitude * Math.pow(falloff, steps);
          const frames = [linearKF(0, delay), cubicKF(height, 0.14), springKF(0, 0.5, BOUNCY)];
          const lift = t < trackDuration(frames) ? track(t, 0, frames) : 0;
          const fires = index === origin;
          const ringScale = track(t, 0.4, [linearKF(0.4, 0.01), cubicKF(fires ? 3 : 0.4, 0.6)]);
          const ringOpacity = t < 0 ? 0 : track(t, 0, [linearKF(fires ? 0.5 : 0, 0.01), cubicKF(0, 0.6)]);
          const color = COLORS[index];
          const pop = spring(0.35, 0.7);
          return (
            <div
              key={symbol}
              onClick={() => tap(index)}
              style={{ width: SLOT, display: "flex", flexDirection: "column", alignItems: "center", gap: 4, cursor: "pointer" }}
            >
              <div style={{ position: "relative", width: 46, height: 46, transform: `translateY(${-lift}px)` }}>
                <motion.div
                  initial={false}
                  animate={{ scale: isSelected ? 1 : 0.3, opacity: isSelected ? 1 : 0 }}
                  transition={pop}
                  style={{ position: "absolute", inset: 0, borderRadius: "50%", background: alpha(color, 0.16) }}
                />
                <div
                  style={{
                    position: "absolute",
                    inset: 0,
                    borderRadius: "50%",
                    border: `2px solid ${color}`,
                    transform: `scale(${ringScale})`,
                    opacity: ringOpacity,
                    pointerEvents: "none",
                  }}
                />
                <div
                  style={{
                    position: "absolute",
                    inset: 0,
                    display: "grid",
                    placeItems: "center",
                    color: isSelected ? color : Palette.secondaryLabel,
                    transition: "color 0.3s ease-out",
                  }}
                >
                  <Glyph name={symbol} size={22} />
                </div>
              </div>
              <motion.span
                initial={false}
                animate={{ opacity: isSelected ? 1 : 0 }}
                transition={pop}
                style={{ fontSize: 10, lineHeight: "12px", fontWeight: 600, color, whiteSpace: "nowrap" }}
              >
                {ctx.t(...TITLES[index])}
              </motion.span>
            </div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap any icon" zh="点击任一图标" style={{ paddingBottom: 12 }} />
    </div>
  );
}
