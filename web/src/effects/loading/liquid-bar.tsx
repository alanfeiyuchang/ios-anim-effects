/** loading.liquid-bar · 液体晃动进度条 (Loading+BarVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Circle, CircleCheck, Droplet, RotateCcw } from "lucide-react";
import { useId, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, demoCard, spring, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { previewFps, primary, springSmooth, useAnimatedNumber } from "./shared";

const GOAL = 8;
const W = 264;
const H = 44;

function frontPath(level: number, phase: number, amplitude: number) {
  const clamped = Math.min(Math.max(level, 0), 1);
  if (clamped <= 0.001) return "";
  const base = W * clamped;
  const reach = clamped >= 0.999 ? amplitude + 2 : 0;
  let d = "M 0 0";
  for (let s = 0; s <= 24; s++) {
    const f = s / 24;
    d += ` L ${(base + amplitude * Math.sin(f * 2 * Math.PI + phase) + reach).toFixed(2)} ${(H * f).toFixed(2)}`;
  }
  return `${d} L 0 ${H} Z`;
}

export default function LiquidBar({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [glasses, setGlasses] = useState(0);
  const glassesRef = useRef(0);
  const kick = useRef(-1e9);
  const level = useAnimatedNumber(0);
  const zh = ctx.lang === "zh";
  const done = glasses >= GOAL;

  const addGlass = () => {
    if (glassesRef.current >= GOAL) {
      glassesRef.current = 0;
      setGlasses(0);
      level.to(0, springSmooth(0.8));
      kick.current = performance.now();
      return;
    }
    kick.current = performance.now();
    const next = glassesRef.current + 1;
    glassesRef.current = next;
    setGlasses(next);
    level.to(next / GOAL, spring(0.6, 0.7));
    if (next >= GOAL) haptics.success();
    else haptics.tap("soft");
  };
  useAutoplay(ctx.isPreview, addGlass, { every: 1.4, delay: 0.5 });

  const liters = glasses * 0.25;
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div style={{ ...demoCard(), padding: 18 }}>
        <div style={{ width: W, display: "flex", flexDirection: "column", gap: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>
            <span style={{ position: "relative", width: 20, height: 20, display: "grid", placeItems: "center" }}>
              <AnimatePresence mode="popLayout" initial={false}>
                <motion.span
                  key={done ? "done" : "open"}
                  initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                  animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                  exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                  transition={anim.snappyD(0.3)}
                  style={{ display: "grid", color: done ? Palette.green : Palette.secondaryLabel }}
                >
                  {done ? <CircleCheck size={19} fill="currentColor" stroke="var(--ml-elevated)" strokeWidth={2.2} /> : <Circle size={19} strokeWidth={1.8} />}
                </motion.span>
              </AnimatePresence>
            </span>
            <span>{zh ? "今日饮水" : "Water today"}</span>
            <span style={{ flex: 1 }} />
            <span style={{ color: Palette.secondaryLabel }}>
              <NumericText value={liters} text={`${liters.toFixed(2)} / 2.00 L`} />
            </span>
          </div>
          <Track level={level.value} kick={kick.current} slosh={ctx.n("slosh")} decay={Math.max(ctx.n("decay"), 0.1)} rest={ctx.n("wave")} preview={ctx.isPreview} />
          <button
            type="button"
            onClick={addGlass}
            style={{
              height: 40,
              borderRadius: 20,
              background: Palette.ocean,
              color: "#fff",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 6,
              fontSize: 15,
              fontWeight: 600,
            }}
          >
            {done ? <RotateCcw size={16} strokeWidth={2.6} /> : <Droplet size={15} fill="currentColor" strokeWidth={1.5} />}
            {done ? (zh ? "重新开始" : "Start over") : "+ 250 ml"}
          </button>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap + 250 ml" zh="点击 +250 ml" />
    </div>
  );
}

function Track({ level, kick, slosh, decay, rest, preview }: { level: number; kick: number; slosh: number; decay: number; rest: number; preview: boolean }) {
  useClock(true, previewFps(preview));
  const id = useId().replace(/:/g, "");
  const now = performance.now();
  const t = now / 1000;
  const since = Math.max(0, (now - kick) / 1000);
  const amplitude = rest + slosh * Math.exp((-since * 3) / decay);
  const d = frontPath(level, t * 3.2, amplitude);
  const bubbles = [];
  for (let i = 0; i < 9; i++) {
    const seed = i * 0.618;
    const rise = (t * (0.35 + 0.1 * (i % 3)) + seed) % 1;
    const x = W * ((seed * 1.7) % 1) + Math.sin(t * 3 + seed * 6) * 3;
    const y = H * (1 - rise);
    bubbles.push(<circle key={i} cx={x} cy={y} r={1.5 + (i % 3)} fill={`rgb(255 255 255 / ${0.45 * (1 - rise * 0.6)})`} />);
  }
  return (
    <div style={{ position: "relative", width: W, height: H, borderRadius: H / 2, overflow: "hidden", background: primary(0.07) }}>
      <svg width={W} height={H} style={{ position: "absolute", inset: 0 }}>
        <defs>
          <linearGradient id={`l${id}`} x1="0" y1="0" x2="0" y2={H} gradientUnits="userSpaceOnUse">
            <stop offset="0" stopColor={Palette.sky} />
            <stop offset="1" stopColor={Palette.blue} />
          </linearGradient>
          <clipPath id={`c${id}`}>
            <path d={d || "M0 0"} />
          </clipPath>
        </defs>
        {d && <path d={d} fill={`url(#l${id})`} />}
        {d && <g clipPath={`url(#c${id})`}>{bubbles}</g>}
      </svg>
      <div style={{ position: "absolute", inset: 0, borderRadius: H / 2, boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }} />
    </div>
  );
}
