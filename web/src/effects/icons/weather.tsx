/** icons.weather · 氛围天气图标 (Icons+Weather.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { Palette, hex, spring, textStyle, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { Glyph, circ, type GlyphDef } from "./_icons-kit";

/** SF `cloud.fill`: the big puff right of centre, the small one on the left. */
const cloudPath = (dy = 0) => `M6.5 ${19 + dy}H15a7 7 0 1 0-6.71-9H6.5a4.5 4.5 0 1 0 0 9Z`;
const RAYS = "M12 1.4v2.2M12 20.4v2.2M1.4 12h2.2M20.4 12h2.2M4.5 4.5l1.6 1.6M17.9 17.9l1.6 1.6M4.5 19.5l1.6-1.6M17.9 6.1l1.6-1.6";
const PICKER: GlyphDef[] = [
  [{ d: circ(12, 12, 4.8), mode: "solid" }, { d: RAYS, mode: "stroke", sw: 2 }],
  [
    { d: circ(15.4, 8.4, 3.6) + "M15.4 2.2v1.2M21.6 8.4H20.4M19.8 4l-.9.9M11 4l.9.9", mode: "fill", sw: 1.6, alpha: 0.5, cut: { d: cloudPath(2.5), fill: true, sw: 3 } },
    { d: cloudPath(2.5) },
  ],
  [{ d: cloudPath(-3.5) }, { d: "M8 18.5l-1 3M12.5 18.5l-1 3M17 18.5l-1 3", mode: "stroke", sw: 2, alpha: 0.5 }],
  [{ d: cloudPath(-3.5) }, { d: "M12.4 16.4 9.8 20.4h3.2l-1.4 3.2 3.6-4.6h-3.1l1.3-2.6Z", sw: 0.8, alpha: 0.5 }],
];
const BOLT: GlyphDef = [
  { d: "M15.914 4a1.5 1.5 0 00-2.474-1.561l-9 9A1.5 1.5 0 005.5 14h4.002a.5.5 0 01.471.666L8.086 20a1.5 1.5 0 002.475 1.56l9-9A1.5 1.5 0 0018.5 10h-3.997a.5.5 0 01-.472-.667z" },
];

const LABELS = [
  ["Sunny · 26°", "晴 · 26°"],
  ["Partly cloudy · 21°", "多云 · 21°"],
  ["Light rain · 17°", "小雨 · 17°"],
  ["Thunderstorm · 15°", "雷阵雨 · 15°"],
];

export default function Weather({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [picked, setPicked] = useState<number | null>(null);
  const paramMode = ctx.i("mode");
  const mode = Math.min(Math.max(picked ?? paramMode, 0), 3);
  // Changing the parameter restarts from that condition.
  const lastParam = useRef(paramMode);
  useEffect(() => {
    if (lastParam.current !== paramMode) {
      lastParam.current = paramMode;
      setPicked(null);
    }
  }, [paramMode]);

  // Scene time carried over from earlier speeds, so moving Speed changes the pace without jumps.
  const clock = useClock(true, ctx.isPreview ? 30 : undefined);
  const speed = ctx.n("speed");
  const shift = useRef({ speed, offset: 0 });
  if (shift.current.speed !== speed) {
    shift.current.offset += clock * (shift.current.speed - speed);
    shift.current.speed = speed;
  }
  const time = clock * speed + shift.current.offset;

  const select = (next: number) => {
    if (next === mode) return;
    haptics.selection();
    setPicked(next);
  };
  useAutoplay(ctx.isPreview, () => select((mode + 1) % 4), { every: 2.8 });

  return (
    <div
      onClick={() => select((mode + 1) % 4)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16, cursor: "pointer" }}
    >
      <Scene time={time} mode={mode} />
      <div style={{ display: "grid", ...textStyle.headline, color: Palette.secondaryLabel }}>
        <AnimatePresence initial={false}>
          <motion.span
            key={mode}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ type: "spring", stiffness: (2 * Math.PI / 0.5) ** 2, damping: (4 * Math.PI * 0.85) / 0.5 }}
            style={{ gridArea: "1 / 1", textAlign: "center", whiteSpace: "nowrap" }}
          >
            {ctx.t(LABELS[mode][0], LABELS[mode][1])}
          </motion.span>
        </AnimatePresence>
      </div>
      <div style={{ display: "flex", gap: 6, padding: 4, borderRadius: 19, background: Palette.labelAlpha(0.06) }}>
        {PICKER.map((def, i) => (
          <div
            key={i}
            onClick={(e) => {
              e.stopPropagation();
              select(i);
            }}
            style={{ position: "relative", width: 40, height: 30, display: "grid", placeItems: "center", cursor: "pointer" }}
          >
            <motion.div
              initial={false}
              animate={{ opacity: i === mode ? 1 : 0 }}
              transition={spring(0.35, 0.8)}
              style={{ position: "absolute", inset: 0, borderRadius: 15, background: Palette.primary }}
            />
            <div style={{ position: "relative", color: i === mode ? "#fff" : Palette.secondaryLabel, transition: "color 0.3s" }}>
              <Glyph def={def} size={19} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function Scene({ time, mode }: { time: number; mode: number }) {
  const sunOnly = mode === 0;
  const stormy = mode === 3;
  const s = spring(0.7, 0.75);
  const flashT = ((time % 3.2) + 3.2) % 3.2;
  const flash = flashT < 0.08 || (flashT > 0.18 && flashT < 0.3) ? 1 : 0;
  const center = (w: number, h: number) => ({ position: "absolute" as const, left: 110 - w / 2, top: 100 - h / 2, width: w, height: h });
  return (
    <div style={{ position: "relative", width: 220, height: 200 }}>
      <motion.div
        initial={false}
        animate={{ scale: sunOnly ? 1 : 0.7, x: sunOnly ? 0 : -34, y: sunOnly ? 0 : -34, opacity: mode <= 1 ? 1 : 0 }}
        transition={s}
        style={center(160, 160)}
      >
        <Sun time={time} />
      </motion.div>
      <motion.div initial={false} animate={{ opacity: sunOnly ? 0 : 0.75 }} transition={s} style={center(0, 0)}>
        <Cloud size={78} dx={38} dy={-26} phase={1.3} time={time} stormy={stormy} />
      </motion.div>
      <motion.div initial={false} animate={{ opacity: mode >= 2 ? 1 : 0 }} transition={s} style={{ ...center(120, 70), y: 58 }}>
        <Rain time={time} />
      </motion.div>
      <motion.div initial={false} animate={{ opacity: sunOnly ? 0 : 1, scale: sunOnly ? 0.6 : 1 }} transition={s} style={center(0, 0)}>
        <Cloud size={118} dx={0} dy={6} phase={0} time={time} stormy={stormy} />
      </motion.div>
      <motion.div initial={false} animate={{ opacity: stormy ? flash : 0 }} transition={{ duration: 0 }} style={{ ...center(50, 50), x: 6, y: 58, color: Palette.amber, filter: `drop-shadow(0 0 12px rgb(255 194 71 / 0.8))` }}>
        <Glyph def={BOLT} size={50} weight={1.4} />
      </motion.div>
    </div>
  );
}

function Sun({ time }: { time: number }) {
  const pulse = Math.sin(time * 2) * 2.5;
  const h = 14 + pulse;
  return (
    <div style={{ position: "relative", width: 160, height: 160 }}>
      <div style={{ position: "absolute", inset: 0, transform: `rotate(${time * 20}deg)` }}>
        {Array.from({ length: 12 }, (_, i) => (
          <div key={i} style={{ position: "absolute", inset: 0, transform: `rotate(${i * 30}deg)` }}>
            <div style={{ position: "absolute", left: 80 - 2.5, top: 80 - 58 - h / 2, width: 5, height: h, borderRadius: 2.5, background: Palette.amber }} />
          </div>
        ))}
      </div>
      <div
        style={{
          position: "absolute",
          left: 41,
          top: 41,
          width: 78,
          height: 78,
          borderRadius: "50%",
          background: `radial-gradient(circle 90px at 0% 0%, #FFE27A 4px, ${Palette.amber}, ${Palette.coral})`,
          boxShadow: `0 0 20px rgb(255 194 71 / 0.6)`,
        }}
      />
    </div>
  );
}

function Cloud({ size, dx, dy, phase, time, stormy }: { size: number; dx: number; dy: number; phase: number; time: number; stormy: boolean }) {
  const drift = Math.sin(time * 0.7 + phase) * 6;
  const box = size * 1.38;
  const top = stormy ? hex(0x9aa3b5) : hex(0xf1f4f9);
  const bottom = stormy ? hex(0x5c6477) : hex(0xaab5c8);
  const id = `weather-cloud-${size}`;
  return (
    <svg
      width={box}
      height={box}
      viewBox="0 0 24 24"
      style={{
        position: "absolute",
        left: -box / 2 + dx + drift,
        top: -box / 2 + dy,
        overflow: "visible",
        filter: "drop-shadow(0 6px 10px rgb(0 0 0 / 0.15))",
      }}
    >
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={top} style={{ transition: "stop-color 0.5s" }} />
          <stop offset="1" stopColor={bottom} style={{ transition: "stop-color 0.5s" }} />
        </linearGradient>
      </defs>
      <path d={cloudPath(0)} fill={`url(#${id})`} />
    </svg>
  );
}

function Rain({ time }: { time: number }) {
  return (
    <div style={{ position: "relative", width: 120, height: 70 }}>
      {Array.from({ length: 9 }, (_, i) => {
        const seed = i * 0.37;
        const cycle = (time * 1.4 + seed) % 1;
        const x = -48 + i * 12;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: 60 - 1.5,
              top: 35 - 7,
              width: 3,
              height: 14,
              borderRadius: 1.5,
              background: Palette.sky,
              opacity: 1 - cycle,
              transform: `translate(${x - cycle * 8}px, ${-26 + cycle * 56}px) rotate(15deg)`,
            }}
          />
        );
      })}
    </div>
  );
}
