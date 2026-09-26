/** icons.ripple-grid · 符号涟漪矩阵 (Icons+RippleGrid.swift) */
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BOUNCE_DURATION, C, Glyph, SYM, bounceAt, circ, rotateOnce, rrect, sym, track, useSince, wiggleOnce, type GlyphDef } from "./_icons-kit";

const sparkle = (cx: number, cy: number, r: number) =>
  `M${cx} ${cy - r}Q${cx + r * 0.18} ${cy - r * 0.18} ${cx + r} ${cy}Q${cx + r * 0.18} ${cy + r * 0.18} ${cx} ${cy + r}Q${cx - r * 0.18} ${cy + r * 0.18} ${cx - r} ${cy}Q${cx - r * 0.18} ${cy - r * 0.18} ${cx} ${cy - r}Z`;

const SECONDARY = 0.45;

const SYMBOLS: GlyphDef[] = [
  SYM.heartFill,
  [
    {
      d: "M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z",
    },
  ],
  [{ d: "M15.914 4a1.5 1.5 0 00-2.474-1.561l-9 9A1.5 1.5 0 005.5 14h4.002a.5.5 0 01.471.666L8.086 20a1.5 1.5 0 002.475 1.56l9-9A1.5 1.5 0 0018.5 10h-3.997a.5.5 0 01-.472-.667z" }],
  [{ d: "M12 2.5q1 4 4 6.5t3 5.5a7 7 0 0 1-14 0 5 5 0 0 1 1.4-3.6q.6 2.6 3.1 2.6c0-2-1.5-3-1.5-5q0-2 4-6Z" }],
  [
    { d: "M11 20a10 10 0 0010-10 25.9 25.9 0 00-1.04-7.281 1 1 0 00-1.755-.325C15.833 5.5 13 5.5 9.8 6.1A7 7 0 0011 20Z" },
    { d: "M2.5 21.5a5 5 0 012.9-4.5C8 15.8 9 15.6 12.5 12.5", mode: "stroke", sw: 2 },
  ],
  [
    { d: "M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401Z" },
    { d: sparkle(18.4, 5, 3.4) + sparkle(22, 10.4, 1.8), mode: "solid", alpha: SECONDARY },
  ],
  [
    { d: circ(9.5, 8, 3.6) + "M9.5 1.6v1.2M3.1 8H1.9M4.9 3.4l.9.9M14.1 3.4l-.9.9", mode: "fill", sw: 1.6, alpha: SECONDARY, cut: { d: "M17.5 21.5H8.4a5.2 5.2 0 1 1 5-6.8h1.6a3.4 3.4 0 1 1 2.5 6.8Z", sw: 3.2, fill: true } },
    { d: "M17.5 21.5H8.4a5.2 5.2 0 1 1 5-6.8h1.6a3.4 3.4 0 1 1 2.5 6.8Z" },
  ],
  [{ d: "M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z" }],
  SYM.bellFill,
  [
    {
      d: "M13.997 4a2 2 0 0 1 1.76 1.05l.486.9A2 2 0 0 0 18.003 7H20a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.997a2 2 0 0 0 1.759-1.048l.489-.904A2 2 0 0 1 10.004 4z",
      cut: { d: circ(12, 13, 4.2), sw: 1.6 },
    },
    { d: circ(12, 13, 2.6), mode: "solid", alpha: SECONDARY },
  ],
  SYM.musicNote,
  SYM.paperplaneFill,
  [
    { d: rrect(3.2, 11.4, 17.6, 10.4, 1.6) + rrect(2, 7, 20, 4.2, 1.2), cut: { d: "M12 7v15", sw: 2 } },
    { d: "M12 7C10.5 3 6.5 2.6 6.5 4.8 6.5 6.6 9.6 7 12 7Zm0 0c1.5-4 5.5-4.4 5.5-2.2 0 1.8-3.1 2.2-5.5 2.2Z", mode: "stroke", sw: 1.7, alpha: SECONDARY },
  ],
  [
    { d: "M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z" },
    { d: sparkle(20, 4, 2.6) + sparkle(4.2, 19.6, 2), mode: "solid", alpha: SECONDARY },
  ],
  [
    { d: circ(12, 12, 10), mode: "solid", alpha: SECONDARY },
    { d: "M7.4 4.2c1.6.8 1.4 2.6 3 3 1.8.4 2.4 1.8 1.2 3.2-1 1.2-2.8.4-3.4 1.8-.6 1.4 1 2.6.4 4.2-.4 1-1.6 1.2-2.2 2.6A10 10 0 0 1 7.4 4.2ZM15.4 13.4c1.4-.6 3 0 3.2 1.6.2 1.4-1 2.4-1 3.6a10 10 0 0 1-2.6 2.4c-.8-1.8.4-2.6-.2-4.2-.4-1.2-.8-2.8.6-3.4Z", mode: "solid" },
  ],
  [
    { d: "M3.5 15.5v-3.5a8.5 8.5 0 0 1 17 0v3.5", mode: "stroke", sw: 2 },
    { d: rrect(2.4, 13, 5.6, 8.6, 2.2) + rrect(16, 13, 5.6, 8.6, 2.2) },
  ],
];

const PULSE = [C(1, 0.12), C(0, 0.4)];

export default function RippleGrid({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [triggers, setTriggers] = useState<number[]>(() => Array(16).fill(0));
  const timers = useRef<number[]>([]);
  useEffect(() => () => timers.current.forEach(clearTimeout), []);

  const ripple = (origin: number) => {
    const stagger = ctx.n("stagger");
    const ox = origin % 4;
    const oy = Math.floor(origin / 4);
    haptics.tap("light");
    // A new tap replaces the running wave (its wavefront re-covers the grid anyway).
    timers.current.forEach(clearTimeout);
    timers.current = [];
    for (let i = 0; i < 16; i++) {
      const delay = Math.hypot((i % 4) - ox, Math.floor(i / 4) - oy) * stagger;
      const fire = () => setTriggers((t) => t.map((v, k) => (k === i ? v + 1 : v)));
      if (delay < 0.001) fire();
      else timers.current.push(window.setTimeout(fire, delay * 1000));
    }
  };

  useAutoplay(ctx.isPreview, () => ripple(Math.floor(Math.random() * 16)), { every: 1.8, delay: 0.3 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 58px)", gap: 12 }}>
        {SYMBOLS.map((def, i) => (
          <Cell key={i} def={def} tint={Palette.spectrum[(i + Math.floor(i / 4)) % Palette.spectrum.length]} trigger={triggers[i]} effect={ctx.i("effect")} onTap={() => ripple(i)} />
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap any symbol" zh="点击任意符号" />
    </div>
  );
}

function Cell({ def, tint, trigger, effect, onTap }: { def: GlyphDef; tint: string; trigger: number; effect: number; onTap: () => void }) {
  const t = useSince(trigger, Math.max(BOUNCE_DURATION, 0.9));
  const pulse = t < 0 ? 0 : track(t, 0, PULSE);
  let transform = "";
  if (t >= 0) {
    if (effect === 1) transform = `rotate(${wiggleOnce(t)}deg)`;
    else if (effect === 2) transform = `rotate(${rotateOnce(t)}deg)`;
    else {
      const b = bounceAt(t);
      transform = `translateY(${b.y * 26}px) scale(${b.scale})`;
    }
  }
  return (
    <div
      onClick={onTap}
      style={{
        width: 58,
        height: 58,
        borderRadius: 16,
        background: alpha(tint, 0.12 + pulse * 0.2),
        transform: `scale(${1 + pulse * 0.08})`,
        display: "grid",
        placeItems: "center",
        color: tint,
        cursor: "pointer",
      }}
    >
      <div style={{ transform, transformOrigin: "50% 80%" }}>
        <Glyph def={def} size={sym(26)} />
      </div>
    </div>
  );
}
