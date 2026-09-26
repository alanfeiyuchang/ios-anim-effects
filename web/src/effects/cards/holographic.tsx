/** cards.holographic · 镭射全息卡 (Cards+Holographic.swift) */
import { animate, useMotionValue } from "motion/react";
import { Sparkle, Zap } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, clamp, fonts, spring, useClock, usePan, white, type DemoContext, type DemoProps } from "../../kit";
import { Stage, StrokeBorder, angular, linearPoints, persp, useMV } from "./shared";

const W = 190;
const H = 264;
const RAINBOW = ["#FF5E7E", "#FFB86B", "#FFF06B", "#6BFFB0", "#6BD5FF", "#8F6BFF", "#FF6BE0", "#FF5E7E"];
const STRIPES: [string, number][] = Array.from({ length: 13 }, (_, i) => [white(i % 2 === 0 ? 0.95 : 0.2), i / 12]);
const SPOTS = [
  [-62, -92], [58, -70], [-40, -20], [70, 6], [-70, 48], [30, 60], [-10, 104], [64, 100], [8, -110], [-78, -50],
];

export default function Holographic({ ctx }: DemoProps) {
  const px = useMotionValue(0);
  const py = useMotionValue(0);
  const [touched, setTouched] = useState(false);
  const touchedRef = useRef(false);
  const held = useRef(false);

  useClock(true, ctx.isPreview ? 30 : undefined);
  const t = Date.now() / 1000;
  const sway = (time: number) => {
    const amount = ctx.isPreview ? 1 : 0.55;
    return { x: Math.sin(time * 0.9) * 0.9 * amount, y: Math.sin(time * 1.4) * 0.6 * amount };
  };
  const x = useMV(px);
  const y = useMV(py);
  const point = touched ? { x, y } : sway(t);

  const pan = usePan({
    onChange: ({ location }) => {
      held.current = true;
      if (!touchedRef.current) {
        // Continue from wherever the idle sway left the card.
        const s = sway(Date.now() / 1000);
        px.jump(s.x);
        py.jump(s.y);
        touchedRef.current = true;
        setTouched(true);
      }
      const tr = spring(0.45, 0.75);
      animate(px, clamp((location.x / W - 0.5) * 2, -1, 1), tr);
      animate(py, clamp((location.y / H - 0.5) * 2, -1, 1), tr);
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      const tr = spring(ctx.n("release"), 0.5);
      animate(px, 0, tr);
      animate(py, 0, tr);
    },
  });

  return (
    <Stage gap={22}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: W, height: H, cursor: "grab" }}>
        <HoloCard
          point={point}
          intensity={ctx.n("intensity")}
          maxAngle={ctx.n("angle")}
          sparkle={ctx.b("sparkle")}
          sparklePhase={(t % 1000) * 0.7}
          ctx={ctx}
        />
      </div>
      <DemoHint ctx={ctx} en="Drag to tilt the foil" zh="拖动让镭射流动" />
    </Stage>
  );
}

function HoloCard({
  point,
  intensity,
  maxAngle,
  sparkle,
  sparklePhase,
  ctx,
}: {
  point: { x: number; y: number };
  intensity: number;
  maxAngle: number;
  sparkle: boolean;
  sparklePhase: number;
  ctx: DemoContext;
}) {
  const p = persp(W, H, 0.5);
  const foilMask = linearPoints(W, H, [-0.3 + point.x * 0.3, 0], [1.3 + point.x * 0.3, 1], STRIPES);
  const sheen = linearPoints(W, H, [-0.4 + point.x * 0.6, -0.4 + point.y * 0.4], [1.4 + point.x * 0.6, 1.4 + point.y * 0.4], [
    ["transparent", 0.38],
    [white(0.45), 0.5],
    ["transparent", 0.62],
  ]);
  return (
    <div style={{ position: "absolute", inset: 0, filter: `drop-shadow(${-point.x * 14}px ${14 - point.y * 6}px 26px rgb(164 107 255 / 0.4))` }}>
      <div style={{ position: "absolute", inset: 0, transform: `${p} rotateY(${point.x * maxAngle}deg)` }}>
        <div style={{ position: "absolute", inset: 0, transform: `${p} rotateX(${-point.y * maxAngle}deg)` }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: 16, overflow: "hidden", isolation: "isolate" }}>
            <HoloFace ctx={ctx} />
            <div
              style={{
                position: "absolute",
                inset: 0,
                background: angular(RAINBOW, 0.5 + point.x * 0.6, 0.5 + point.y * 0.6, point.x * 120 + point.y * 60),
                WebkitMaskImage: foilMask,
                maskImage: foilMask,
                mixBlendMode: "screen",
                opacity: intensity * 0.75,
              }}
            />
            <div style={{ position: "absolute", inset: 0, background: sheen, mixBlendMode: "plus-lighter" }} />
            {sparkle && <Sparkles phase={sparklePhase + point.x + point.y} />}
          </div>
          <StrokeBorder radius={16} color={white(0.35)} />
        </div>
      </div>
    </div>
  );
}

function HoloFace({ ctx }: { ctx: DemoContext }) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        padding: 16,
        display: "flex",
        flexDirection: "column",
        gap: 10,
        color: "#fff",
        background: "linear-gradient(#1B1A3A, #2A1F4F, #14142B)",
      }}
    >
      <div style={{ display: "flex", alignItems: "center" }}>
        <span style={{ fontFamily: fonts.rounded, fontSize: 15, fontWeight: 800, letterSpacing: 2, lineHeight: "18px" }}>PRISM</span>
        <span style={{ flex: 1 }} />
        <span style={{ fontFamily: fonts.mono, fontSize: 10, fontWeight: 700, opacity: 0.7 }}>No. 042</span>
      </div>
      <div style={{ flex: 1, display: "grid", placeItems: "center", minHeight: 0 }}>
        <div style={{ position: "relative", width: 128, height: 128, borderRadius: "50%", display: "grid", placeItems: "center" }}>
          <div
            style={{
              position: "absolute",
              inset: 0,
              borderRadius: "50%",
              background: `radial-gradient(circle 70px at 50% 50%, rgb(164 107 255 / 0.9) 4px, rgb(110 123 255 / 0.15) 70px)`,
              boxShadow: `inset 0 0 0 1px ${white(0.25)}`,
            }}
          />
          <Zap size={60} fill="#fff" strokeWidth={0} style={{ position: "relative", filter: `drop-shadow(0 0 12px ${Palette.pink}cc)` }} />
        </div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
        <div style={{ display: "flex", alignItems: "baseline" }}>
          <span style={{ fontSize: 13, fontWeight: 700, lineHeight: "16px" }}>{ctx.t("Voltage Sprite", "电光精灵")}</span>
          <span style={{ flex: 1 }} />
          <span style={{ fontFamily: fonts.rounded, fontSize: 9, fontWeight: 800, opacity: 0.75 }}>HP 120</span>
        </div>
        <span
          style={{
            fontSize: 9,
            fontWeight: 500,
            lineHeight: "11px",
            opacity: 0.7,
            display: "-webkit-box",
            WebkitLineClamp: 2,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
          }}
        >
          {ctx.t("Surge — when fully charged, doubles its speed for one turn.", "涌动——充能完毕时，下一回合速度翻倍。")}
        </span>
      </div>
    </div>
  );
}

function Sparkles({ phase }: { phase: number }) {
  return (
    <div style={{ position: "absolute", inset: 0, mixBlendMode: "plus-lighter", pointerEvents: "none" }}>
      {SPOTS.map(([sx, sy], i) => {
        const twinkle = Math.abs(Math.sin(i * 1.7 + phase * 3.2));
        const size = 7 + (i % 3) * 3;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: W / 2 + sx - size / 2,
              top: H / 2 + sy - size / 2,
              width: size,
              height: size,
              color: "#fff",
              opacity: 0.15 + 0.85 * twinkle,
              transform: `scale(${0.6 + 0.4 * twinkle})`,
            }}
          >
            <Sparkle size={size * 1.2} fill="currentColor" strokeWidth={0} style={{ margin: -size * 0.1 }} />
          </div>
        );
      })}
    </div>
  );
}
