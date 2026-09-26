/** icons.ai-sparkle · AI 星芒 (Icons+AISparkle.swift) */
import { useRef, useState, type CSSProperties } from "react";
import { DemoHint, Palette, useClock, useHaptics, type DemoProps } from "../../kit";

const COLORS = [Palette.violet, Palette.pink, Palette.amber, Palette.sky, Palette.violet];

/** Four-point star with concave sides, in a `size` square. */
function starPath(size: number) {
  const r = size / 2;
  const c = r;
  const k = r * 0.14;
  return `M${c} ${c - r}Q${c + k} ${c - k} ${c + r} ${c}Q${c + k} ${c + k} ${c} ${c + r}Q${c - k} ${c + k} ${c - r} ${c}Q${c - k} ${c - k} ${c} ${c - r}Z`;
}

/** A star filled with the rotating angular gradient (`AngularGradient(colors:center:angle:)`). */
function Star({ size, angle, style }: { size: number; angle: number; style?: CSSProperties }) {
  return (
    <div
      style={{
        width: size,
        height: size,
        clipPath: `path('${starPath(size)}')`,
        background: `conic-gradient(from ${90 + angle}deg, ${COLORS.join(", ")})`,
        ...style,
      }}
    />
  );
}

export default function AISparkle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const now = useClock(true, ctx.isPreview ? 30 : undefined);
  const [flipped, setFlipped] = useState(false);
  const thinking = (ctx.i("mode") === 1) !== flipped;
  const speed = ctx.n("speed");
  const rate = speed * (thinking ? 2.5 : 1);

  // Scene clock rebased whenever its rate changes, so switching Thinking or Speed never jumps.
  const clock = useRef({ base: 0, start: 0, rate, sparkBase: 0, sparkStart: 0, speed, flippedAt: -Infinity, thinking });
  const c = clock.current;
  if (c.rate !== rate) {
    c.base += (now - c.start) * c.rate;
    c.start = now;
    c.rate = rate;
  }
  if (c.speed !== speed) {
    c.sparkBase += (now - c.sparkStart) * c.speed;
    c.sparkStart = now;
    c.speed = speed;
  }
  if (c.thinking !== thinking) {
    c.thinking = thinking;
    c.flippedAt = now;
  }
  const time = c.base + (now - c.start) * rate;
  const sparkTime = c.sparkBase + (now - c.sparkStart) * speed;
  const fade = Math.min(Math.max((now - c.flippedAt) / 0.3, 0), 1);
  const sparkOpacity = thinking ? fade : 1 - fade;

  const toggle = () => {
    if (ctx.isPreview) return;
    setFlipped((f) => !f);
    haptics.tap("light");
  };

  const angle = time * 60;
  const sway = 12 * Math.sin((time * 2 * Math.PI) / 4);
  const breath = 0.99 + 0.07 * Math.sin((time * 2 * Math.PI) / 2.2);

  const satellite = (phase: number, x: number, y: number) => {
    const cycle = (time / 1.6 + phase) % 1;
    const pulse = Math.sin(cycle * Math.PI);
    const scale = 0.3 + 0.7 * pulse * pulse;
    return (
      <div style={{ position: "absolute", left: 130 - 17 + x, top: 130 - 17 + y, transform: `rotate(${90 * cycle}deg) scale(${scale})` }}>
        <Star size={34} angle={angle} />
      </div>
    );
  };

  const orbit = ((sparkTime / 1.2) % 1) * 2 * Math.PI;

  return (
    <div
      onClick={toggle}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: 260, height: 260 }}>
        <div style={{ position: "absolute", left: 65, top: 65, filter: "blur(26px)", opacity: ctx.n("glow") }}>
          <Star size={130} angle={angle} />
        </div>
        <div style={{ position: "absolute", left: 65, top: 65, transform: `rotate(${sway}deg) scale(${breath})` }}>
          <Star size={130} angle={angle} />
        </div>
        {satellite(0, 78, -70)}
        {satellite(0.5, -74, 66)}
        <div
          style={{
            position: "absolute",
            left: 130 - 3.5 + 92 * Math.cos(orbit),
            top: 130 - 3.5 + 92 * Math.sin(orbit) * 0.55,
            width: 7,
            height: 7,
            borderRadius: "50%",
            background: "#fff",
            boxShadow: `0 0 6px ${Palette.pink}`,
            opacity: sparkOpacity,
          }}
        />
      </div>
      <DemoHint ctx={ctx} en="Tap to toggle Thinking" zh="点击切换「思考中」" />
    </div>
  );
}
