/** text.slot-reel · 翻滚棱柱数字 (Text+SlotReel.swift) */
import { animate, useMotionValue, useMotionValueEvent, type MotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, demoCard, fonts, spring, springDB, useAutoplay, useHaptics, useLatest, black, white, type DemoProps } from "../../kit";
import { RollingText, randInt } from "./_text-kit";

const FACE = { w: 52, h: 68 };
/** Extra full cycles for the tens and units prisms, so the right side whirls longest. */
const EXTRA_TURNS = [0, 0, 0, 10, 20];
const PRIMARY_STRONG = "linear-gradient(to bottom right, #4B57E0, #7A45D6)";

/** When a `spring(duration: d, bounce: b)` first reaches its target, as a fraction of d. */
function landingFraction(bounce: number, travel: number) {
  const zeta = 1 - bounce;
  if (zeta < 0.999) {
    const root = Math.sqrt(1 - zeta * zeta);
    return (Math.PI - Math.atan(root / zeta)) / (2 * Math.PI * root);
  }
  const goal = 0.5 / Math.max(travel, 1);
  let low = 0;
  let high = 30;
  for (let k = 0; k < 40; k++) {
    const u = (low + high) / 2;
    if ((1 + u) * Math.exp(-u) > goal) low = u;
    else high = u;
  }
  return (low + high) / 4 / Math.PI;
}

export default function SlotReel({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [rolls, setRolls] = useState([0, 4, 8, 2, 5]);
  const [gain, setGain] = useState(0);
  const travel = useRef([1, 1, 1, 1, 1]);
  const ticks = useRef<number[]>([]);
  useEffect(() => () => ticks.current.forEach((t) => window.clearTimeout(t)), []);

  const bounce = (distance: number) => {
    const settle = ctx.n("settle");
    if (settle <= 0.001) return 0;
    const fraction = Math.min(settle / Math.max(distance, 1), 0.3);
    const l = -Math.log(fraction) / Math.PI;
    const zeta = l / Math.sqrt(1 + l * l);
    return Math.min(Math.max(1 - zeta, 0), 0.6);
  };
  const landingTime = (column: number) => ctx.n("duration") * landingFraction(bounce(1), 1) + column * ctx.n("stagger");
  const tumble = (column: number) => {
    const distance = travel.current[column];
    const b = bounce(distance);
    const duration = landingTime(column) / Math.max(landingFraction(b, distance), 0.05);
    return springDB(duration, b);
  };

  const rollsRef = useLatest(rolls);
  const addPoints = () => {
    const current = rollsRef.current;
    const score = Number(current.map((r) => String(((r % 10) + 10) % 10)).join(""));
    const points = randInt(12, 96) * 25;
    const target = (score + points) % 100_000;
    const count = current.length;
    const digits = current.map((_, column) => Math.floor(target / 10 ** (count - 1 - column)) % 10);
    const next = [...current];
    const distances = [...travel.current];
    const landing: number[] = [];
    next.forEach((roll, column) => {
      const delta = (digits[column] - (((roll % 10) + 10) % 10) + 10) % 10;
      const extra = EXTRA_TURNS[column];
      if (delta <= 0 && extra <= 0) return;
      next[column] = roll + delta + extra;
      distances[column] = delta + extra;
      landing.push(column);
    });
    setGain(points);
    travel.current = distances;
    setRolls(next);
    ticks.current.forEach((t) => window.clearTimeout(t));
    ticks.current = [];
    haptics.tap("light");
    // One selection tick per prism, at the moment it first reaches its digit.
    for (const column of landing) ticks.current.push(window.setTimeout(() => haptics.selection(), landingTime(column) * 1000));
  };
  useAutoplay(ctx.isPreview, addPoints, { every: 2.8 });

  const violetText = ctx.scheme === "dark" ? "#C4A0FF" : "#7A45D6";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <button type="button" onClick={addPoints} style={{ ...demoCard(24), width: 330, padding: "16px 18px", display: "flex", flexDirection: "column", gap: 14, textAlign: "left" }}>
        <div style={{ display: "flex", alignItems: "center", alignSelf: "stretch" }}>
          <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 700, textTransform: "uppercase", color: Palette.secondaryLabel }}>{ctx.t("High score", "最高分")}</span>
          <span style={{ flex: 1 }} />
          <span
            style={{
              fontSize: 12,
              lineHeight: "16px",
              fontWeight: 700,
              color: violetText,
              padding: "4px 9px",
              borderRadius: 999,
              background: alpha(Palette.violet, 0.14),
              opacity: gain > 0 ? 1 : 0,
              transition: "opacity 0.3s",
            }}
          >
            <RollingText value={gain} text={`+${gain}`} transition={spring(0.4, 0.8)} />
          </span>
        </div>
        <div style={{ display: "flex", gap: 6, alignSelf: "center" }}>
          {rolls.map((roll, column) => (
            <PrismColumn key={column} roll={roll} transition={tumble(column)} />
          ))}
        </div>
      </button>
      <DemoHint ctx={ctx} en="Tap the score" zh="点击分数" />
    </div>
  );
}

function PrismColumn({ roll, transition }: { roll: number; transition: ReturnType<typeof springDB> }) {
  const mv = useMotionValue(roll);
  useEffect(() => {
    if (mv.get() === roll) return;
    const controls = animate(mv, roll, transition);
    return () => controls.stop();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [roll]);
  return <TumblingPrismDigit roll={mv} />;
}

/** Face k sits at θ = (k − roll) × 90°: the current face tips up and away while the next rises from below. */
export function TumblingPrismDigit({ roll, fill = PRIMARY_STRONG }: { roll: MotionValue<number>; fill?: string }) {
  const [value, setValue] = useState(roll.get());
  const speed = useRef({ last: null as number | null, time: 0, value: 0 });
  useMotionValueEvent(roll, "change", setValue);

  // Faces per second between rendered frames, for the motion blur.
  const now = performance.now() / 1000;
  const s = speed.current;
  if (s.last !== null) {
    const dt = now - s.time;
    if (dt >= 0.004) s.value = dt > 0.1 ? 0 : Math.abs(value - s.last) / dt;
  }
  s.last = value;
  s.time = now;
  const blur = Math.min(Math.max((s.value - 8) / 32, 0), 1) * 2.4;
  const base = Math.floor(value);
  const fraction = value - base;

  return (
    <div style={{ position: "relative", width: FACE.w, height: FACE.h * 1.42, filter: blur > 0.01 ? `blur(${blur}px)` : undefined }}>
      <PrismFace index={base} degrees={-fraction * 90} fill={fill} />
      <PrismFace index={base + 1} degrees={(1 - fraction) * 90} fill={fill} />
    </div>
  );
}

function PrismFace({ index, degrees, fill }: { index: number; degrees: number; fill: string }) {
  const r = (degrees * Math.PI) / 180;
  const c = Math.cos(r);
  const s = Math.sin(r);
  const digit = ((index % 10) + 10) % 10;
  const shade = s > 0 ? 0.65 * s : 0.2 * (1 - c);
  const glint = s < 0 ? 0.18 * -s : 0;
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        top: (FACE.h * 1.42 - FACE.h) / 2,
        width: FACE.w,
        height: FACE.h,
        borderRadius: 10,
        background: `linear-gradient(${black(shade)}, ${black(shade)}), linear-gradient(${white(glint)}, ${white(glint)}), ${fill}`,
        boxShadow: `inset 0 0 0 1px ${white(0.18)}`,
        display: "grid",
        placeItems: "center",
        fontFamily: fonts.rounded,
        fontSize: 42,
        fontWeight: 800,
        fontVariantNumeric: "tabular-nums",
        color: "#fff",
        transform: `translateY(${(s * FACE.h) / 2}px) scale(${1 - 0.1 * (1 - c)}, ${Math.max(c, 0.001)})`,
        opacity: c > 0.02 ? 1 : 0,
      }}
    >
      {digit}
    </div>
  );
}
