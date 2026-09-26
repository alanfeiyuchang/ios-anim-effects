/** text.wave · 字符波浪 (Text+Wave.swift) */
import { useEffect, useRef } from "react";
import { DemoHint, Palette, fonts, useClock, useHaptics, type DemoProps } from "../../kit";
import { Glyphs } from "./_text-kit";

export default function Wave({ ctx }: DemoProps) {
  const haptics = useHaptics();
  useClock(true, ctx.isPreview ? 30 : undefined);
  const now = performance.now() / 1000;
  const speed = ctx.n("speed");
  const amplitude = ctx.n("amplitude");
  const spread = ctx.n("spread");
  const hue = ctx.b("hue");

  // Swell 0 (rest) → 1 (held), approached exponentially from where it was.
  const swellState = useRef({ from: 0, target: 0, changed: -Infinity });
  const swell = (at: number) => {
    const s = swellState.current;
    const elapsed = Math.max(at - s.changed, 0);
    return s.target + (s.from - s.target) * Math.exp(-elapsed / 0.18);
  };
  const setSwell = (pressing: boolean) => {
    if (ctx.isPreview) return;
    const t = performance.now() / 1000;
    swellState.current = { from: swell(t), target: pressing ? 1 : 0, changed: t };
    if (pressing) haptics.tap("soft");
  };

  // Keep the wave's shape when the Speed slider moves.
  const phaseShift = useRef(0);
  const lastSpeed = useRef(speed);
  useEffect(() => {
    phaseShift.current += (performance.now() / 1000) * (lastSpeed.current - speed);
    lastSpeed.current = speed;
  }, [speed]);

  const phase = now * speed + phaseShift.current;
  const gain = 1 + 0.9 * swell(now);

  const wave = (time: number, amp: number) => (i: number) => {
    const p = time * 4 - i * spread;
    return {
      transform: `translateY(${Math.sin(p) * amp}px) rotate(${Math.cos(p) * amp * 0.6}deg)`,
      filter: hue ? `hue-rotate(${i * 14 + time * 40}deg)` : undefined,
    };
  };

  return (
    <div
      onPointerDown={() => setSwell(true)}
      onPointerUp={() => setSwell(false)}
      onPointerLeave={() => setSwell(false)}
      onPointerCancel={() => setSwell(false)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}
    >
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 + amplitude * 1.4 * 1.9 }}>
        <Glyphs
          text={ctx.t("Good Vibes", "律动文字")}
          fill="linear-gradient(to bottom right, #FFC247, #FF7A5C, #FF5FA2)"
          style={{ fontFamily: fonts.rounded, fontSize: 50, fontWeight: 800, lineHeight: "60px" }}
          glyph={wave(phase, amplitude * gain)}
        />
        <Glyphs
          text={ctx.t("every glyph is alive", "每个字形都在呼吸")}
          style={{ fontFamily: fonts.rounded, fontSize: 18, fontWeight: 600, lineHeight: "22px", color: Palette.secondaryLabel }}
          glyph={wave(phase - 0.4 * speed, amplitude * 0.4 * gain)}
        />
      </div>
      <DemoHint ctx={ctx} en="Touch and hold to swell the wave" zh="按住让波浪涌起" />
    </div>
  );
}
