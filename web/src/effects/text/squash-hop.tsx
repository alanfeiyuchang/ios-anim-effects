/** text.squash-hop · 挤压弹跳 (Text+SquashHop.swift) */
import { useRef } from "react";
import { DemoHint, Palette, fonts, useClock, useHaptics, type DemoProps } from "../../kit";
import { chars, colorGradient } from "./_text-kit";

interface Pose {
  lift: number;
  scaleX: number;
  scaleY: number;
}
const COLORS = [Palette.coral, Palette.amber, Palette.mint, Palette.sky, Palette.violet, Palette.pink];
const secs = () => performance.now() / 1000;

/** Hop cycle: 0–0.08 crouch · 0.08–0.53 airborne · 0.53–0.65 impact · 0.65–0.78 recoil · rest. */
function pose(phase: number, height: number, squash: number): Pose {
  const stretch = 0.12;
  const crouch = 1 - squash * 0.5;
  let scaleY = 1;
  let lift = 0;
  if (phase < 0.08) {
    const q = phase / 0.08;
    if (q < 0.6) scaleY = 1 - (1 - crouch) * Math.sin((Math.PI / 2) * (q / 0.6));
    else {
      const t = (q - 0.6) / 0.4;
      scaleY = crouch + (1 + stretch - crouch) * t * t;
    }
  } else if (phase < 0.53) {
    const a = (Math.PI * (phase - 0.08)) / 0.45;
    lift = height * Math.sin(a);
    scaleY = 1 + stretch * Math.abs(Math.cos(a));
  } else if (phase < 0.65) {
    const q = (phase - 0.53) / 0.12;
    if (q < 0.3) {
      const t = q / 0.3;
      scaleY = 1 + stretch + (-stretch - squash) * (1 - (1 - t) * (1 - t));
    } else {
      const t = (q - 0.3) / 0.7;
      scaleY = 1 - squash + squash * t * t * (3 - 2 * t);
    }
  } else if (phase < 0.78) {
    scaleY = 1 + squash * 0.25 * Math.sin((Math.PI * (phase - 0.65)) / 0.13);
  }
  const dy = scaleY - 1;
  const scaleX = dy > 0 ? 1 - dy * 0.67 : 1 - dy * 0.82;
  return { lift, scaleX, scaleY };
}

const wrapped = (v: number) => {
  const u = v % 1;
  return u < 0 ? u + 1 : u;
};

export default function SquashHop({ ctx }: DemoProps) {
  const haptics = useHaptics();
  useClock(true, ctx.isPreview ? 30 : undefined);
  const kicks = useRef<Record<number, number>>({});
  const letters = chars(ctx.t("BOUNCY", "蹦蹦跳跳"));
  const height = ctx.n("height");
  const squash = ctx.n("squash");
  const period = Math.max(ctx.n("period"), 0.1);
  const time = secs();

  // The looping wave plus any tapped hop: lifts add, scale deviations multiply.
  const combined = (index: number): Pose => {
    const loop = pose(wrapped((time - index * 0.09) / period), height, squash);
    const start = kicks.current[index];
    if (start === undefined) return loop;
    const elapsed = (time - start) / period;
    if (elapsed < 0 || elapsed >= 0.8) return loop;
    const extra = pose(elapsed, height, squash);
    return { lift: loop.lift + extra.lift, scaleX: loop.scaleX * extra.scaleX, scaleY: loop.scaleY * extra.scaleY };
  };

  const kick = (index: number) => {
    if (ctx.isPreview) return;
    kicks.current[index] = secs();
    haptics.tap();
  };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <div style={{ display: "flex", alignItems: "flex-end", gap: 2, paddingTop: height * 2 }}>
        {letters.map((ch, index) => {
          const p = combined(index);
          const air = Math.min(p.lift / Math.max(height, 1), 1);
          return (
            <div key={index} onClick={() => kick(index)} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4, cursor: "pointer" }}>
              <span
                style={{
                  display: "inline-block",
                  fontFamily: fonts.rounded,
                  fontSize: 50,
                  fontWeight: 800,
                  lineHeight: "60px",
                  backgroundImage: colorGradient(COLORS[index % COLORS.length]),
                  WebkitBackgroundClip: "text",
                  backgroundClip: "text",
                  color: "transparent",
                  WebkitTextFillColor: "transparent",
                  transformOrigin: "50% 100%",
                  transform: `translateY(${-p.lift}px) scale(${p.scaleX}, ${p.scaleY})`,
                }}
              >
                {ch}
              </span>
              <span style={{ width: 30 * (1 - air * 0.5), height: 6, borderRadius: "50%", background: Palette.labelAlpha(0.18 * (1 - air * 0.7)), filter: "blur(2px)" }} />
            </div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap a letter to make it hop" zh="点按字母让它起跳" />
    </div>
  );
}
