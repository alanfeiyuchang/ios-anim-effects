/** icons.draw-on · 符号笔绘 (Icons+DrawOn.swift) */
import { motion } from "motion/react";
import { useEffect, useId, useRef, useState } from "react";
import { DemoHint, Palette, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { sym } from "./_icons-kit";

/** Symbol → layers → strokes (each stroke is one pen path, drawn from its start). */
const SYMBOLS: string[][][] = [
  [
    [
      "m21 17-2.156-1.868A.5.5 0 0 0 18 15.5v.5a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1c0-2.545-3.991-3.97-8.5-4a1 1 0 0 0 0 5c4.153 0 4.745-11.295 5.708-13.5a2.5 2.5 0 1 1 3.31 3.284",
    ],
    ["M3 21h18"],
  ],
  [["M2 8h9a2 2 0 1 0-1.2-3.6", "M2 12h15.5a2.5 2.5 0 1 0-2-4", "M2 16h12a2 2 0 1 1-1.2 3.6"]],
  [
    ["M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z"],
    ["M8 12l2.5 2.5L16 9"],
  ],
  [
    ["M16 12a4 4 0 1 1-8 0 4 4 0 1 1 8 0"],
    ["M12 2v2", "M19.07 4.93l-1.41 1.41", "M22 12h-2", "M19.07 19.07l-1.41-1.41", "M12 22v-2", "M4.93 19.07l1.41-1.41", "M2 12h2", "M4.93 4.93l1.41 1.41"],
  ],
];

export default function DrawOn({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [hidden, setHidden] = useState(true);

  const toggle = (haptic = true) => {
    const next = !hidden;
    setHidden(next);
    if (haptic && !next) haptics.tap("soft");
  };

  // The detail stage draws once on arrival (no intro play erasing it again).
  useEffect(() => {
    if (ctx.isPreview) return;
    const id = window.setTimeout(() => setHidden(false), 300);
    return () => window.clearTimeout(id);
  }, [ctx.isPreview]);
  useAutoplay(ctx.isPreview, () => toggle(false), { every: 2.4, delay: 0.3, intro: false });

  return (
    <div
      onClick={() => toggle()}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 24, cursor: "pointer" }}
    >
      <div style={{ display: "grid", gridTemplateColumns: "96px 96px", columnGap: 34, rowGap: 30 }}>
        {SYMBOLS.map((layers, i) => (
          <div key={i} style={{ width: 96, height: 80, display: "grid", placeItems: "center" }}>
            <DrawSymbol layers={layers} hidden={hidden} playback={ctx.i("playback")} speed={Math.max(ctx.n("speed"), 0.1)} />
          </div>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap to draw / erase" zh="点击绘制 / 擦除" />
    </div>
  );
}

/**
 * `.symbolEffect(.drawOff, isActive: hidden)`: strokes retract along their path to erase and draw
 * back on from their start. By layer staggers the layers, Whole draws every stroke together,
 * Individually draws one stroke after another.
 */
function DrawSymbol({ layers, hidden, playback, speed }: { layers: string[][]; hidden: boolean; playback: number; speed: number }) {
  const gid = useId().replace(/:/g, "");
  const mounted = useRef(false);
  useEffect(() => {
    mounted.current = true;
  }, []);
  const strokes = layers.flatMap((paths, layer) => paths.map((d, k) => ({ d, layer, k })));
  const count = strokes.length;
  const size = sym(64);
  const draw = 0.5 / speed;
  const erase = 0.32 / speed;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ overflow: "visible" }}>
      <defs>
        <linearGradient id={gid} x1="0" y1="0" x2="24" y2="24" gradientUnits="userSpaceOnUse">
          <stop offset="0" stopColor={Palette.indigo} />
          <stop offset="1" stopColor={Palette.violet} />
        </linearGradient>
      </defs>
      {strokes.map((s, i) => {
        let delay = 0;
        let duration = hidden ? erase : draw;
        if (playback === 0) delay = s.layer * (hidden ? 0.12 : 0.28) / speed;
        else if (playback === 2) {
          duration = (hidden ? erase : draw) * 0.6;
          const order = hidden ? count - 1 - i : i;
          delay = order * duration * 0.85;
        }
        if (playback === 0 && hidden) delay = (layers.length - 1 - s.layer) * 0.12 / speed;
        const animated = mounted.current;
        return (
          <motion.path
            key={i}
            d={s.d}
            fill="none"
            stroke={`url(#${gid})`}
            strokeWidth={1.6}
            strokeLinecap="round"
            strokeLinejoin="round"
            initial={{ pathLength: hidden ? 0 : 1, opacity: hidden ? 0 : 1 }}
            animate={{ pathLength: hidden ? 0 : 1, opacity: hidden ? 0 : 1 }}
            transition={
              animated
                ? {
                    pathLength: { duration, delay, ease: [0.4, 0, 0.2, 1] },
                    opacity: hidden ? { duration: 0.01, delay: delay + duration } : { duration: 0.01, delay },
                  }
                : { duration: 0 }
            }
          />
        );
      })}
    </svg>
  );
}
