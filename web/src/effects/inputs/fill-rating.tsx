/** inputs.fill-rating (Inputs+FillRating.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, type Transition } from "motion/react";
import { useId, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, clamp, demoCard, ease, fonts, mix, progress, spring, springAt, springDB, textStyle, useAutoplay, useElapsed, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";

const HEART = 40;
const SPACING = 10;
const ROW = HEART * 5 + SPACING * 4;
const PREVIEW = [4.5, 2, 3.5, 5, 1.5];
const HEART_PATH =
  "M12 21.2c-.3 0-.6-.1-.8-.3C6.3 17 2 13.3 2 8.6 2 5.6 4.3 3.3 7.2 3.3c1.9 0 3.6 1 4.8 2.6 1.2-1.6 2.9-2.6 4.8-2.6 2.9 0 5.2 2.3 5.2 5.3 0 4.7-4.3 8.4-9.2 12.3-.2.2-.5.3-.8.3Z";

export default function FillRating({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const ratingMV = useMotionValue(3.5);
  const [shown, setShown] = useState(3.5);
  useMotionValueEvent(ratingMV, "change", setShown);
  const [target, setTarget] = useState(3.5);
  const targetRef = useRef(3.5);
  const [fingerX, setFingerX] = useState<number | null>(null);
  const fingerRef = useRef<number | null>(null);
  const [scaleT, setScaleT] = useState<Transition>(spring(0.2, 0.8));
  const [beats, setBeats] = useState([0, 0, 0, 0, 0]);
  const step = useRef(0);
  const snapStep = ctx.i("step") === 1 ? 1 : ctx.i("step") === 2 ? 0.1 : 0.5;

  const setRating = (value: number, t: Transition, silent: boolean) => {
    const oldFull = Math.floor(targetRef.current);
    targetRef.current = value;
    setTarget(value);
    animate(ratingMV, value, t);
    const newFull = Math.floor(value);
    if (newFull > oldFull) {
      setBeats((b) => b.map((v, i) => (i >= oldFull && i < newFull ? v + 1 : v)));
      if (!silent) haptics.selection();
    }
  };
  const setFinger = (x: number | null) => {
    fingerRef.current = x;
    setFingerX(x);
  };

  const ratingAt = (x: number) => {
    const cell = HEART + SPACING;
    const index = Math.floor(x / cell);
    const within = Math.min((x - index * cell) / HEART, 1);
    return clamp(index + within, 0, 5);
  };

  const release = (silent: boolean) => {
    if (fingerRef.current === null) return;
    const snapped = clamp(Math.round(targetRef.current / snapStep) * snapStep, 0, 5);
    const t = spring(ctx.n("response"), 0.7);
    setScaleT(t);
    setFinger(null);
    setRating(snapped, t, silent);
  };

  const pan = usePan({
    onChange: ({ location }) => {
      const x = clamp(location.x, 0, ROW);
      const t = spring(0.2, 0.8);
      setScaleT(t);
      setFinger(x);
      setRating(ratingAt(x), t, false);
    },
    onEnd: () => release(false),
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      const tg = PREVIEW[step.current % PREVIEW.length];
      step.current += 1;
      const t = springDB(0.6, 0);
      setScaleT(t);
      setFinger(tg * (HEART + SPACING) - SPACING / 2);
      setRating(tg - 0.2, t, true);
      after(0.75, () => release(true));
    },
    { every: 1.5, delay: 0.3 },
  );

  const scaleFor = (index: number) => {
    if (fingerX === null) return 1;
    const center = index * (HEART + SPACING) + HEART / 2;
    const distance = Math.abs(fingerX - center) / (HEART + SPACING);
    const extra = ctx.n("magnify") - 1;
    if (distance < 0.5) return 1 + extra;
    if (distance < 1.5) return 1 + extra * 0.32;
    return 1;
  };
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: ROW + 36, padding: 18, display: "flex", flexDirection: "column", gap: 16 }}>
        <div style={{ display: "flex", alignItems: "baseline" }}>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ ...textStyle.headline }}>{zh ? "给这道菜谱打分" : "Rate this recipe"}</span>
            <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{zh ? "味噌拉面" : "Miso Ramen"}</span>
          </div>
          <div style={{ flex: 1 }} />
          <NumericText value={target} text={target.toFixed(1)} style={{ fontFamily: fonts.rounded, fontSize: 30, fontWeight: 700, color: Palette.pink, lineHeight: "36px" }} />
        </div>
        <div {...pan} style={{ ...pan.style, display: "flex", gap: SPACING, height: HEART * 1.4, alignItems: "center", cursor: "pointer" }}>
          {Array.from({ length: 5 }, (_, index) => (
            <motion.div key={index} initial={false} animate={{ scale: scaleFor(index) }} transition={scaleT} style={{ width: HEART, height: HEART }}>
              <Heart fill={clamp(shown - index)} beat={beats[index]} />
            </motion.div>
          ))}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag slowly across the hearts" zh="在爱心上慢慢横向拖动" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Heart({ fill, beat }: { fill: number; beat: number }) {
  const id = `a-heart-${useId().replace(/:/g, "")}`;
  const t = useElapsed(beat, 0.35, true);
  let s = 1;
  if (t >= 0 && t < 0.35) s = t < 0.12 ? mix(1, 1.18, ease.inOut(progress(t, 0, 0.12))) : mix(1.18, 1, springAt(t - 0.12, 0.23, 0.7));
  // heart.fill at 0.86 × 40 pt semibold: ~38 × 34 glyph centred in the 40 pt frame.
  return (
    <div style={{ position: "relative", width: HEART, height: HEART, transform: `scale(${s})` }}>
      <svg width={44} height={44} viewBox="0 0 24 24" style={{ position: "absolute", left: -2, top: -2 }}>
        <defs>
          <linearGradient id={`${id}-g`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0.14" stopColor={Palette.pink} />
            <stop offset="0.88" stopColor={Palette.coral} />
          </linearGradient>
          <clipPath id={`${id}-c`}>
            <rect x={(2 / 44) * 24} y="0" width={((HEART * fill) / 44) * 24} height="24" />
          </clipPath>
        </defs>
        <path d={HEART_PATH} style={{ fill: Palette.labelAlpha(0.12) }} />
        <path d={HEART_PATH} fill={`url(#${id}-g)`} clipPath={`url(#${id}-c)`} />
      </svg>
    </div>
  );
}
