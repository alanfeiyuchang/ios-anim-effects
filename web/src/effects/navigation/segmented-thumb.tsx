/** navigation.segmented-thumb · 分段控件滑块 (Navigation+SegmentedThumb.swift) */
import { animate, motion, useMotionValue, useTransform, type Transition } from "motion/react";
import { useEffect, useRef, useState } from "react";
import {
  DemoHint,
  NumericText,
  Palette,
  anim,
  black,
  clamp,
  fonts,
  localPoint,
  spring,
  useAutoplay,
  useHaptics,
  usePan,
  type DemoProps,
} from "../../kit";

const TITLES: [string, string][] = [
  ["Day", "日"],
  ["Week", "周"],
  ["Month", "月"],
  ["Year", "年"],
];
const VALUES = [8_420, 52_310, 214_880, 2_604_119];

const WIDTH = 300;
const INSET = 4;
const SEG = (WIDTH - INSET * 2) / TITLES.length;
const MAX_X = SEG * (TITLES.length - 1);
const PICKUP = spring(0.3, 0.75);
const FOLLOW = spring(0.18, 0.86); // .interactiveSpring(response: 0.18, dampingFraction: 0.86)

export default function SegmentedThumb({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(0);
  const selectedRef = useRef(0);
  selectedRef.current = selected;
  /** `dragX != nil`: the thumb is lifted (by a finger or the autoplay stand-in). */
  const [lifted, setLifted] = useState(false);
  const liftedRef = useRef(false);
  const [scaleAnim, setScaleAnim] = useState<Transition>(PICKUP);
  const thumbX = useMotionValue(0);
  const maskX = useTransform(thumbX, (x) => -x);
  const hovered = useRef(0);
  const token = useRef(0);
  const engaged = useRef(false);
  const timers = useRef<number[]>([]);
  useEffect(() => () => timers.current.forEach(clearTimeout), []);

  const settle = () => spring(ctx.n("response"), ctx.n("damping"));
  const squished = lifted && ctx.b("squish");

  const lift = (x: number, t: Transition) => {
    if (!liftedRef.current) {
      liftedRef.current = true;
      setLifted(true);
      setScaleAnim(PICKUP);
    }
    animate(thumbX, x, t);
  };

  /** Drops the thumb into `index` (selected = index, dragX = nil) with the settle spring. */
  const drop = (index: number) => {
    const t = settle();
    hovered.current = index;
    setSelected(index);
    liftedRef.current = false;
    setLifted(false);
    setScaleAnim(t);
    animate(thumbX, index * SEG, t);
  };

  const dragChanged = (locationX: number) => {
    const x = clamp(locationX - INSET - SEG / 2, 0, MAX_X);
    if (!liftedRef.current) {
      token.current += 1; // a real finger cancels a simulated drag
      lift(x, PICKUP);
    } else {
      animate(thumbX, x, FOLLOW);
    }
    const index = Math.round(x / SEG);
    if (index !== hovered.current) {
      hovered.current = index;
      haptics.selection();
    }
  };

  const pan = usePan(
    {
      onStart: () => {
        engaged.current = false;
      },
      onChange: ({ translation, location }) => {
        if (!engaged.current) {
          if (!(Math.abs(translation.x) > Math.abs(translation.y))) return;
          engaged.current = true;
        }
        dragChanged(location.x);
      },
      onEnd: ({ location }) => {
        if (!engaged.current) return;
        const x = clamp(location.x - INSET - SEG / 2, 0, MAX_X);
        drop(clamp(Math.round(x / SEG), 0, TITLES.length - 1));
      },
    },
    6,
  );

  const tapSelect = (locationX: number) => {
    const index = clamp(Math.floor((locationX - INSET) / SEG), 0, TITLES.length - 1);
    token.current += 1; // a real finger cancels a simulated drag
    if (index !== selectedRef.current) haptics.selection();
    drop(index);
  };

  // Autoplay stand-in for a finger: pick the thumb up, drag it slowly across one segment, release.
  // Wraps back to Day with a tap.
  const simulateDrag = () => {
    const current = selectedRef.current;
    const next = (current + 1) % TITLES.length;
    if (next === 0) {
      hovered.current = 0;
      setSelected(0);
      animate(thumbX, 0, settle());
      return;
    }
    token.current += 1;
    const run = token.current;
    lift(current * SEG, PICKUP);
    timers.current.push(
      window.setTimeout(() => {
        if (token.current !== run) return;
        animate(thumbX, next * SEG, anim.easeInOut(0.6));
        timers.current.push(
          window.setTimeout(() => {
            if (token.current !== run) return;
            drop(next);
          }, 700),
        );
      }, 200),
    );
  };
  useAutoplay(ctx.isPreview, simulateDrag, { every: 1.6 });

  const labels = (bold: boolean) => (
    <div style={{ display: "flex" }}>
      {TITLES.map(([en, zh], i) => (
        <div
          key={i}
          style={{
            width: SEG,
            height: 36,
            flexShrink: 0,
            display: "grid",
            placeItems: "center",
            fontFamily: fonts.text,
            fontSize: 15,
            lineHeight: "20px",
            fontWeight: bold ? 600 : 500,
            color: bold ? Palette.label : Palette.secondaryLabel,
            whiteSpace: "nowrap",
          }}
        >
          {ctx.t(en, zh)}
        </div>
      ))}
    </div>
  );

  const value = VALUES[selected];

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 30 }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
        <div style={{ fontFamily: fonts.text, fontSize: 15, lineHeight: "20px", fontWeight: 500, color: Palette.secondaryLabel }}>
          {ctx.lang === "zh" ? "步数" : "Steps"}
        </div>
        <NumericText
          value={value}
          text={value.toLocaleString("en-US")}
          style={{ fontFamily: fonts.rounded, fontSize: 44, lineHeight: "52px", fontWeight: 700, color: Palette.label }}
        />
      </div>
      <div
        {...pan}
        onClick={(e) => {
          if (engaged.current) {
            engaged.current = false;
            return;
          }
          tapSelect(localPoint(e, e.currentTarget).x);
        }}
        onPointerDown={(e) => {
          engaged.current = false;
          pan.onPointerDown(e);
        }}
        style={{
          ...pan.style,
          position: "relative",
          width: WIDTH,
          height: 44,
          padding: INSET,
          borderRadius: 14,
          background: Palette.labelAlpha(0.07),
          flexShrink: 0,
          cursor: "pointer",
        }}
      >
        <div style={{ position: "relative", width: WIDTH - INSET * 2, height: 36 }}>
          {labels(false)}
          <motion.div
            style={{ position: "absolute", left: 0, top: 0, width: SEG, height: 36, x: thumbX }}
          >
            <motion.div
              initial={false}
              animate={{ scaleX: squished ? 1.06 : 1, scaleY: squished ? 0.92 : 1 }}
              transition={scaleAnim}
              style={{ width: "100%", height: "100%", borderRadius: 10, background: Palette.elevated, boxShadow: `0 2px 6px ${black(0.12)}` }}
            />
          </motion.div>
          <motion.div
            style={{ position: "absolute", left: 0, top: 0, width: SEG, height: 36, overflow: "hidden", x: thumbX, pointerEvents: "none" }}
          >
            <motion.div style={{ x: maskX }}>{labels(true)}</motion.div>
          </motion.div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap or drag the thumb" zh="点击或拖动滑块" />
    </div>
  );
}
