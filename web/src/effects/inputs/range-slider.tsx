/** inputs.range-slider · 价格区间滑块 (Inputs+RangeSlider.swift) */
import { animate, motion, useMotionValue, useTransform, type MotionValue } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, clamp, demoCard, fonts, spring, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";

type Thumb = "lower" | "upper";

const W = 264;
const MAX_PRICE = 500;
const BARS = Array.from({ length: 24 }, (_, i) => {
  const bell = Math.exp(-(((i - 9) / 6) ** 2));
  const n = Math.sin(i * 12.9898 + 4.1) * 43758.5453;
  return 0.18 + 0.62 * bell + 0.2 * (n - Math.floor(n));
});
const PREVIEW_RANGES: [number, number][] = [
  [0.1, 0.46],
  [0.36, 0.9],
  [0.2, 0.5],
  [0.5, 0.78],
];
const price = (v: number) => Math.round((v * MAX_PRICE) / 10) * 10;

function bubbleCenters(xl: number, xu: number): [number, number] {
  const half = 26;
  let left = xl;
  let right = xu;
  if (right - left < half * 2 + 4) {
    const mid = (left + right) / 2;
    left = mid - half - 2;
    right = mid + half + 2;
  }
  const shiftIn = Math.max(0, half - left);
  const shiftOut = Math.max(0, right - (W - half));
  return [left + shiftIn - shiftOut, right + shiftIn - shiftOut];
}

export default function RangeSlider({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [lower, setLower] = useState(0.24);
  const [upper, setUpper] = useState(0.66);
  const [active, setActive] = useState<Thumb | null>(null);
  const g = useRef({ lower: 0.24, upper: 0.66, active: null as Thumb | null, pinned: false, step: 0 });
  const lowerMV = useMotionValue(0.24);
  const upperMV = useMotionValue(0.66);
  const springT = spring(ctx.n("response"), ctx.n("damping"));

  const xl = useTransform(lowerMV, (v) => W * v);
  const xu = useTransform(upperMV, (v) => W * v);
  const fillWidth = useTransform(() => Math.max(xu.get() - xl.get(), 6));
  const bubbleL = useTransform(() => bubbleCenters(xl.get(), xu.get())[0] - 26);
  const bubbleU = useTransform(() => bubbleCenters(xl.get(), xu.get())[1] - 26);

  const setThumb = (thumb: Thumb, v: number, animated: boolean) => {
    const mv = thumb === "lower" ? lowerMV : upperMV;
    g.current[thumb] = v;
    (thumb === "lower" ? setLower : setUpper)(v);
    if (animated) animate(mv, v, springT);
    else {
      mv.stop();
      mv.set(v);
    }
  };
  const setActiveThumb = (a: Thumb | null) => {
    g.current.active = a;
    setActive(a);
  };

  const move = (thumb: Thumb, value: number, animated: boolean) => {
    const gap = ctx.n("gap");
    let target = value;
    let hit = false;
    if (thumb === "lower") {
      const limit = g.current.upper - gap;
      if (target > limit) {
        target = limit;
        hit = true;
      }
      target = Math.max(0, target);
    } else {
      const limit = g.current.lower + gap;
      if (target < limit) {
        target = limit;
        hit = true;
      }
      target = Math.min(1, target);
    }
    const oldPrice = price(g.current[thumb]);
    setThumb(thumb, target, animated);
    if (price(target) !== oldPrice && !hit) haptics.selection();
    if (hit && !g.current.pinned) haptics.tap("rigid");
    g.current.pinned = hit;
  };

  const endDrag = () => {
    if (!(g.current.active || g.current.pinned)) return;
    setActiveThumb(null);
    g.current.pinned = false;
  };

  const pan = usePan({
    onChange: ({ location }) => {
      const v = clamp(location.x / W);
      const thumb = g.current.active;
      if (thumb) move(thumb, v, false);
      else {
        const dl = Math.abs(v - g.current.lower);
        const du = Math.abs(v - g.current.upper);
        const pick: Thumb = dl === du ? (v < g.current.lower ? "lower" : "upper") : dl < du ? "lower" : "upper";
        setActiveThumb(pick);
        move(pick, v, Math.abs(v - g.current[pick]) * W > 14);
      }
    },
    onEnd: endDrag,
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      const step = g.current.step;
      const range = PREVIEW_RANGES[step % PREVIEW_RANGES.length];
      g.current.step += 1;
      setActiveThumb(step % 2 === 0 ? "lower" : "upper");
      setThumb("lower", range[0], true);
      setThumb("upper", range[1], true);
      after(0.7, () => setActiveThumb(null));
    },
    { every: 1.4, delay: 0.4 },
  );

  const inRange = (i: number) => {
    const c = (i + 0.5) / BARS.length;
    return c >= lower && c <= upper;
  };
  const stays = Math.round(BARS.reduce((sum, b, i) => sum + (inRange(i) ? b : 0), 0) * 11);
  const barWidth = (W - 3 * (BARS.length - 1)) / BARS.length;
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: W + 36, padding: 18, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "baseline" }}>
          <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{ctx.t("Price per night", "每晚价格")}</span>
          <span style={{ flex: 1 }} />
          <span style={{ fontSize: 15, fontWeight: 600, color: Palette.blue }}>
            <NumericText value={price(lower) + price(upper) * 1000} text={`$${price(lower)} – $${price(upper)}`} />
          </span>
        </div>
        <div style={{ width: W, height: 40, display: "flex", alignItems: "flex-end", gap: 3 }}>
          {BARS.map((b, i) => (
            <div
              key={i}
              style={{
                width: barWidth,
                height: 40 * b,
                borderRadius: 2,
                background: inRange(i) ? "rgb(79 124 255 / 0.75)" : Palette.labelAlpha(0.12),
                transition: "background-color 0.15s cubic-bezier(0, 0, 0.58, 1)",
              }}
            />
          ))}
        </div>
        <div {...pan} style={{ ...pan.style, position: "relative", width: W, height: 28, marginTop: 34, cursor: "pointer" }}>
          <div style={{ position: "absolute", left: 0, right: 0, top: 11, height: 6, borderRadius: 3, background: Palette.labelAlpha(0.1) }} />
          <motion.div
            style={{ position: "absolute", left: 0, top: 11, height: 6, borderRadius: 3, x: xl, width: fillWidth, background: `linear-gradient(90deg, ${Palette.sky}, ${Palette.blue})` }}
          />
          <Handle x={xl} active={active === "lower"} t={springT} />
          <Handle x={xu} active={active === "upper"} t={springT} />
          <Bubble x={bubbleL} active={active === "lower"} t={springT} label={`$${price(lower)}`} />
          <Bubble x={bubbleU} active={active === "upper"} t={springT} label={`$${price(upper)}`} />
        </div>
        <div style={{ display: "flex", fontSize: 11, lineHeight: "13px", fontWeight: 500, fontVariantNumeric: "tabular-nums", color: Palette.tertiaryLabel }}>
          <span>$0</span>
          <span style={{ flex: 1 }} />
          <span>$500+</span>
        </div>
        <div
          style={{
            marginTop: 2,
            height: 44,
            borderRadius: 22,
            background: Palette.primary,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 15,
            fontWeight: 600,
            color: "#fff",
            whiteSpace: "pre",
          }}
        >
          {zh ? "查看 " : "Show "}
          <NumericText value={stays} />
          {zh ? " 处住宿" : " stays"}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag either handle, or tap the track" zh="拖动任一手柄，或点按轨道" style={{ paddingBottom: 16 }} />
    </div>
  );
}

function Handle({ x, active, t }: { x: MotionValue<number>; active: boolean; t: ReturnType<typeof spring> }) {
  const left = useTransform(x, (v) => v - 13);
  return (
    <motion.div style={{ position: "absolute", top: 1, left: 0, x: left, width: 26, height: 26 }}>
      <motion.div
        initial={false}
        animate={{ scale: active ? 1.15 : 1, boxShadow: `inset 0 0 0 ${active ? 2.5 : 0}px ${Palette.blue}, 0 2px 5px rgb(0 0 0 / 0.22)` }}
        transition={t}
        style={{ width: 26, height: 26, borderRadius: "50%", background: "#fff" }}
      />
    </motion.div>
  );
}

function Bubble({ x, active, t, label }: { x: MotionValue<number>; active: boolean; t: ReturnType<typeof spring>; label: string }) {
  return (
    <motion.div style={{ position: "absolute", left: 0, top: 2 - 32, x, width: 52, height: 24, pointerEvents: "none" }}>
      <motion.div
        initial={false}
        animate={{ scale: active ? 1.1 : 0.92, y: active ? -4 : 0, backgroundColor: `rgb(79 124 255 / ${active ? 1 : 0.8})` }}
        transition={t}
        style={{
          width: 52,
          height: 24,
          borderRadius: 12,
          originY: 1,
          display: "grid",
          placeItems: "center",
          fontFamily: fonts.rounded,
          fontSize: 12,
          fontWeight: 700,
          fontVariantNumeric: "tabular-nums",
          color: "#fff",
        }}
      >
        {label}
      </motion.div>
    </motion.div>
  );
}
