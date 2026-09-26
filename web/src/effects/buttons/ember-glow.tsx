/** buttons.ember-glow · 余烬辉光 (Buttons+EmberGlow.swift) */
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, hex, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { cub, spr, track, useKeyframes, wallSeconds } from "./_b-kit";

const BUTTON = { w: 220, h: 60 };
const CANVAS = { w: 300, h: 250 };

const noise = (index: number, channel: number) => {
  const n = Math.sin(index * 12.9898 + channel * 78.233) * 43758.5453;
  return n - Math.floor(n);
};

/** Ember colour over its life: amber blending to coral between 20 % and 70 %. */
function coolDown(life: number, opacity: number) {
  const x = Math.min(Math.max((life - 0.2) / 0.5, 0), 1);
  const t = x * x * (3 - 2 * x);
  return `rgb(255 ${194 + (122 - 194) * t} ${71 + (92 - 71) * t} / ${Math.max(0, Math.min(opacity, 1))})`;
}

export default function EmberGlow({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [lastStoke, setLastStoke] = useState(-Infinity);
  const [stokes, setStokes] = useState(0);
  useClock(true, ctx.isPreview ? 30 : undefined);

  const stoke = () => {
    setLastStoke(performance.now() / 1000);
    setStokes((s) => s + 1);
    haptics.tap("medium");
  };
  useAutoplay(ctx.isPreview, stoke, { every: 2.6, delay: 1.0 });

  const age = performance.now() / 1000 - lastStoke;
  const boost = Math.max(0, 1 - age / 0.8);
  const t = wallSeconds();
  const heat = ctx.n("heat");

  const fast = Math.sin(t * 23.7) * 0.3;
  const flicker = Math.sin(t * 9.1) * 0.5 + fast + Math.sin(t * 4.3) * 0.2;
  const glowRadius = 12 + 4 * flicker + 10 * boost;
  const glowOpacity = (0.35 + 0.2 * boost) * heat + 0.1;

  const kt = useKeyframes(stokes, 0.53);
  const scale = kt < 0 ? 1 : track(kt, [cub(0.96, 0.08), spr(1, 0.45, 0.5, 0.7)], 1);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div
        style={{
          position: "relative",
          width: CANVAS.w,
          height: CANVAS.h,
          flexShrink: 0,
          borderRadius: 28,
          background: `linear-gradient(${hex(0x1a1210)}, ${hex(0x0d0a09)})`,
        }}
      >
        <EmberField time={t} boost={boost} count={ctx.i("count")} rise={ctx.n("rise")} heat={heat} />
        <button
          type="button"
          onClick={stoke}
          style={{
            position: "absolute",
            left: (CANVAS.w - BUTTON.w) / 2,
            top: CANVAS.h - 40 - BUTTON.h,
            width: BUTTON.w,
            height: BUTTON.h,
            borderRadius: BUTTON.h / 2,
            border: "1.5px solid transparent",
            background: `linear-gradient(${hex(0x1e1715)}, ${hex(0x1e1715)}) padding-box, linear-gradient(${Palette.amber}, ${Palette.coral}) border-box`,
            boxShadow: `0 0 ${glowRadius}px ${alpha(Palette.coral, Math.min(glowOpacity, 1))}`,
            transform: `scale(${scale})`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
            fontSize: 17,
            fontWeight: 600,
            color: "#fff",
          }}
        >
          <svg width={20} height={20} viewBox="0 0 24 24">
            <defs>
              <linearGradient id="ember-glow-flame" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor={Palette.amber} />
                <stop offset="1" stopColor={Palette.coral} />
              </linearGradient>
            </defs>
            <path
              d="M12 3q1 4 4 6.5t3 5.5a1 1 0 0 1-14 0 5 5 0 0 1 1-3 1 1 0 0 0 5 0c0-2-1.5-3-1.5-5q0-2 2.5-4"
              fill="url(#ember-glow-flame)"
              stroke="url(#ember-glow-flame)"
              strokeWidth={1.5}
              strokeLinejoin="round"
            />
          </svg>
          {ctx.t("Go live", "开始直播")}
        </button>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap to stoke the embers" zh="点击让火花更旺" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function EmberField({ time, boost, count, rise, heat }: { time: number; boost: number; count: number; rise: number; heat: number }) {
  const ref = useRef<HTMLCanvasElement>(null);
  const scale = 3;
  useEffect(() => {
    const el = ref.current;
    const g = el?.getContext("2d");
    if (!el || !g) return;
    g.setTransform(scale, 0, 0, scale, 0, 0);
    g.clearRect(0, 0, CANVAS.w, CANVAS.h);
    g.globalCompositeOperation = "lighter";
    const emitterWidth = BUTTON.w - 30;
    const emitterY = CANVAS.h - 40 - BUTTON.h;
    const total = Math.max(count, 1);
    for (let index = 0; index < total; index++) {
      const period = 1.6 + noise(index, 1) * 1.0;
      const shifted = time + noise(index, 2) * period;
      const life = (shifted % period) / period;
      const startX = CANVAS.w / 2 + (noise(index, 3) - 0.5) * emitterWidth;
      const sway = Math.sin(time * 2.2 + index) * 8 * life;
      const x = startX + sway;
      // A stoke lifts the plume higher instead of changing speed, so the phase never jumps.
      const lift = rise * (1 + 0.4 * boost);
      const y = emitterY - lift * life;
      const radius = (1 + noise(index, 4) * 1.5) * (1.2 - 0.7 * life);
      const warmth = 0.55 + 0.45 * heat;
      const a = (1 - life) * warmth * (0.7 + 0.3 * boost);
      g.fillStyle = coolDown(life, a * 0.25);
      g.beginPath();
      g.arc(x, y, radius * 2, 0, Math.PI * 2);
      g.fill();
      g.fillStyle = coolDown(life, a);
      g.beginPath();
      g.arc(x, y, radius, 0, Math.PI * 2);
      g.fill();
    }
  });
  return (
    <canvas
      ref={ref}
      width={CANVAS.w * scale}
      height={CANVAS.h * scale}
      style={{ position: "absolute", inset: 0, width: CANVAS.w, height: CANVAS.h, pointerEvents: "none" }}
    />
  );
}
