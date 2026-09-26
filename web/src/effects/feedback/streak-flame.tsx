/** feedback.streak-flame · 连胜点燃 (Feedback+BadgeVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Check } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, anim, demoCard, fonts, spring, useAutoplay, useElapsed, useHaptics, type DemoProps } from "../../kit";
import { SPRINGS, track } from "./shared";

interface Ember { id: number; born: number; drift: number; rise: number; size: number }
const rand = (a: number, b: number) => a + Math.random() * (b - a);

export default function StreakFlame({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [checked, setChecked] = useState(false);
  const [ignites, setIgnites] = useState(0);
  const embers = useRef<Ember[]>([]);
  const nextEmber = useRef(0);
  const checkedRef = useRef(false);
  const zh = ctx.lang === "zh";
  const days = checked ? 7 : 6;

  const toggle = () => {
    if (checkedRef.current) {
      checkedRef.current = false;
      setChecked(false);
      return;
    }
    const now = performance.now() / 1000;
    embers.current = embers.current.filter((e) => now - e.born <= 1.0);
    for (let i = 0; i < Math.max(ctx.i("embers"), 0); i++) {
      embers.current.push({ id: nextEmber.current++, born: now, drift: rand(-26, 26), rise: rand(44, 72), size: rand(3, 5.5) });
    }
    setIgnites((n) => n + 1);
    checkedRef.current = true;
    setChecked(true);
    haptics.success();
  };

  useAutoplay(ctx.isPreview, toggle, { every: 2.2, delay: 0.5 });

  const e = useElapsed(ignites, 1.0, true);
  const surge = ctx.n("surge");
  const scale = e < 0 ? 1 : track(e, 1, [{ cubic: 0.85, d: 0.08 }, { cubic: surge, d: 0.14 }, { spring: 1, d: 0.5, ...SPRINGS.bouncy }]);
  const angle = e < 0 ? 0 : track(e, 0, [{ linear: 0, d: 0.1 }, { cubic: 6, d: 0.1 }, { cubic: -6, d: 0.12 }, { cubic: 3, d: 0.1 }, { cubic: 0, d: 0.12 }]);
  const labels = zh ? ["一", "二", "三", "四", "五", "六", "日"] : ["M", "T", "W", "T", "F", "S", "S"];
  const flameT = anim.easeOut(0.3);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ ...demoCard(22), padding: 20, display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
        <div style={{ position: "relative", height: 80, width: 120, display: "grid", placeItems: "center" }}>
          <EmberField embers={embers} trigger={ignites} fps={ctx.isPreview ? 30 : undefined} />
          <div style={{ transform: `rotate(${angle}deg) scale(${scale})`, transformOrigin: "50% 100%" }}>
            <motion.div
              initial={false}
              animate={{ filter: `saturate(${checked ? 1 : 0}) drop-shadow(0 0 7px ${alpha(Palette.coral, checked ? 0.6 : 0)})`, opacity: checked ? 1 : 0.45 }}
              transition={flameT}
            >
              <FlameGlyph />
            </motion.div>
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "baseline", gap: 6 }}>
          <span style={{ fontFamily: fonts.rounded, fontSize: 44, lineHeight: "52px", fontWeight: 800 }}>
            <NumericText value={days} />
          </span>
          <span style={{ fontSize: 15, fontWeight: 600, color: Palette.secondaryLabel }}>{zh ? "天连胜" : "day streak"}</span>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          {labels.map((label, i) => (
            <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
              <DayDot today={i === 6} checked={checked} />
              <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 600, color: Palette.secondaryLabel }}>{label}</span>
            </div>
          ))}
        </div>
        <button type="button" onClick={toggle} style={{ position: "relative", width: 220, height: 46, borderRadius: 23, overflow: "hidden", color: "#fff", fontSize: 17, fontWeight: 600 }}>
          <div style={{ position: "absolute", inset: 0, background: Palette.sunset }} />
          <motion.div initial={false} animate={{ opacity: checked ? 1 : 0 }} transition={anim.snappyD(0.3)} style={{ position: "absolute", inset: 0, background: Palette.successStrong }} />
          <AnimatePresence initial={false}>
            <motion.span key={checked ? "y" : "n"} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={anim.snappyD(0.3)} style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
              {checked ? (zh ? "今日已签到" : "Checked in") : zh ? "签到" : "Check in"}
            </motion.span>
          </AnimatePresence>
        </button>
      </div>
      <DemoHint ctx={ctx} en="Tap Check in" zh="点击签到" />
    </div>
  );
}

function DayDot({ today, checked }: { today: boolean; checked: boolean }) {
  const filled = !today || checked;
  return (
    <div style={{ position: "relative", width: 26, height: 26, borderRadius: "50%", boxShadow: `inset 0 0 0 2px ${alpha(Palette.amber, 0.6)}` }}>
      <motion.div
        initial={false}
        animate={{ scale: filled ? 1 : 0.01, opacity: filled ? 1 : 0 }}
        transition={today ? spring(0.35, 0.45) : { duration: 0 }}
        style={{ position: "absolute", inset: 0, borderRadius: "50%", background: `linear-gradient(rgb(255 255 255 / 0.14), transparent), ${Palette.amber}` }}
      />
      {filled && (
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: "#fff" }}>
          <Check size={11} strokeWidth={4} />
        </div>
      )}
    </div>
  );
}

/** SF Symbol `flame.fill` with the amber → coral → red gradient. */
function FlameGlyph() {
  return (
    <svg width={50} height={60} viewBox="0 0 50 60">
      <defs>
        <linearGradient id="streak-flame" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={Palette.amber} />
          <stop offset="0.5" stopColor={Palette.coral} />
          <stop offset="1" stopColor={Palette.red} />
        </linearGradient>
      </defs>
      <path
        fillRule="evenodd"
        fill="url(#streak-flame)"
        d="M25 58C12 58 3 50 3 38C3 28 9 21 14 15C15.5 13.2 18.3 14 18.4 16.3C18.6 19.8 19.9 23 22.5 24.6C22.2 15 26 7.5 32 2.5C33.6 1.2 36 2.3 36 4.4C36.2 11 39.6 15.8 43 20.8C45.6 24.7 47 29.5 47 36C47 49.5 37.5 58 25 58ZM25 52C30.5 52 34 48.2 34 43C34 37.6 30 34 27.6 29.8C26.9 28.6 25.2 28.6 24.6 29.9C23.6 32 22 33.4 20.4 35.2C17.9 37.9 16 40.2 16 43.5C16 48.5 19.8 52 25 52Z"
      />
    </svg>
  );
}

function EmberField({ embers, trigger, fps }: { embers: React.MutableRefObject<Ember[]>; trigger: number; fps?: number }) {
  const canvas = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const el = canvas.current;
    if (!el) return;
    const dpr = Math.max(2, window.devicePixelRatio || 1);
    el.width = 120 * dpr;
    el.height = 120 * dpr;
    const g = el.getContext("2d")!;
    let raf = 0;
    let last = 0;
    const frame = (ms: number) => {
      raf = requestAnimationFrame(frame);
      if (fps && ms - last < 1000 / fps - 1) return;
      last = ms;
      const now = performance.now() / 1000;
      g.setTransform(dpr, 0, 0, dpr, 0, 0);
      g.clearRect(0, 0, 120, 120);
      let alive = false;
      for (const e of embers.current) {
        const age = now - e.born;
        if (age < 0 || age >= 0.9) continue;
        alive = true;
        const u = age / 0.9;
        const eased = 1 - (1 - u) * (1 - u);
        const r = e.size * (1 - 0.5 * u);
        g.fillStyle = e.id % 2 === 0 ? alpha(Palette.amber, 1 - u) : alpha(Palette.coral, 1 - u);
        g.beginPath();
        g.arc(60 + e.drift * eased, 90 - e.rise * eased, r, 0, Math.PI * 2);
        g.fill();
      }
      if (!alive) cancelAnimationFrame(raf);
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [trigger, embers, fps]);
  return <canvas ref={canvas} style={{ position: "absolute", left: 0, top: -40, width: 120, height: 120, pointerEvents: "none" }} />;
}
