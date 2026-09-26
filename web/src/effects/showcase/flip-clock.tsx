/** showcase.flip-clock · 翻页时钟 (TravelFlipClock.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Earth } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, SymbolBounce, fonts, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";

const CITIES = [
  { en: "Hangzhou", zh: "杭州", zone: "Asia/Shanghai", code: "HGH" },
  { en: "Nice", zh: "尼斯", zone: "Europe/Paris", code: "NCE" },
  // A half-hour zone, so switching to or from it changes the minute digits and all four tiles cascade.
  { en: "New Delhi", zh: "新德里", zone: "Asia/Kolkata", code: "DEL" },
  { en: "New York", zh: "纽约", zone: "America/New_York", code: "JFK" },
];
const TILE_W = 52;
const TILE_H = 76;
const TRACK_W = 310 - 36;
const CHIP_W = (TRACK_W - 8 - 12) / 4;

function digitsFor(zone: string, date: Date): string[] {
  const parts = new Intl.DateTimeFormat("en-GB", { timeZone: zone, hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).formatToParts(date);
  const h = parts.find((p) => p.type === "hour")?.value ?? "00";
  const m = parts.find((p) => p.type === "minute")?.value ?? "00";
  return (h.padStart(2, "0") + m.padStart(2, "0")).split("");
}

export default function FlipClock({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  const [city, setCity] = useState(0);
  const cityRef = useRef(0);
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = window.setInterval(() => setNow(new Date()), 5000);
    return () => clearInterval(id);
  }, []);

  const select = (index: number) => {
    if (index === cityRef.current) return;
    haptics.selection();
    cityRef.current = index;
    setCity(index);
  };
  useAutoplay(ctx.isPreview, () => select((cityRef.current + 1) % CITIES.length), { every: 2.0, delay: 0.8 });

  const digits = digitsFor(CITIES[city].zone, now);
  const duration = ctx.n("duration");
  const stagger = ctx.n("stagger");
  const bounce = ctx.n("bounce");
  const depth = ctx.n("perspective");

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(), width: 310, padding: 18, display: "flex", flexDirection: "column", gap: 16, flexShrink: 0 }}>
          <div style={{ display: "flex", alignItems: "center" }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={signatureEyebrow()}>{zh ? "当地时间" : "Local time"}</span>
              <span style={{ position: "relative", height: 22 }}>
                <AnimatePresence initial={false}>
                  <motion.span
                    key={city}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={spring(0.35, 0.8)}
                    style={{ position: "absolute", left: 0, top: 0, whiteSpace: "nowrap", fontFamily: fonts.rounded, fontSize: 18, fontWeight: 700, color: "#fff", lineHeight: "22px" }}
                  >
                    {zh ? CITIES[city].zh : CITIES[city].en}
                  </motion.span>
                </AnimatePresence>
              </span>
            </div>
            <span style={{ flex: 1 }} />
            <SymbolBounce trigger={city}>
              <span style={{ color: Signature.accent, display: "grid" }}>
                <Earth size={20} strokeWidth={2.2} />
              </span>
            </SymbolBounce>
          </div>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 5 }}>
            <FlipDigit value={digits[0]} duration={duration} delay={0} bounce={bounce} depth={depth} />
            <FlipDigit value={digits[1]} duration={duration} delay={stagger} bounce={bounce} depth={depth} />
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <span style={{ width: 5, height: 5, borderRadius: "50%", background: Signature.textSecondary }} />
              <span style={{ width: 5, height: 5, borderRadius: "50%", background: Signature.textSecondary }} />
            </div>
            <FlipDigit value={digits[2]} duration={duration} delay={stagger * 2} bounce={bounce} depth={depth} />
            <FlipDigit value={digits[3]} duration={duration} delay={stagger * 3} bounce={bounce} depth={depth} />
          </div>
          <div style={{ position: "relative", display: "flex", gap: 4, padding: 4, borderRadius: 99, background: white(0.06) }}>
            <motion.div
              initial={false}
              animate={{ x: city * (CHIP_W + 4) }}
              transition={spring(0.35, 0.8)}
              style={{ position: "absolute", left: 4, top: 4, width: CHIP_W, height: 30, borderRadius: 99, background: Signature.accentGradient }}
            />
            {CITIES.map((c, i) => (
              <button
                key={c.code}
                type="button"
                onClick={() => select(i)}
                style={{
                  position: "relative",
                  flex: 1,
                  height: 30,
                  display: "grid",
                  placeItems: "center",
                  fontFamily: fonts.rounded,
                  fontSize: 12,
                  fontWeight: 700,
                  color: i === city ? "#000" : Signature.textSecondary,
                  transition: "color 0.3s",
                }}
              >
                {c.code}
              </button>
            ))}
          </div>
          <SignatureRim />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap a city to flip the clock" zh="点击城市切换时钟" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

/** Owns the flip queue: each flip runs to completion, then the newest pending value flips in. */
function FlipDigit({ value, duration, delay, bounce, depth }: { value: string; duration: number; delay: number; bounce: number; depth: number }) {
  const [shown, setShown] = useState({ current: value, previous: value, start: -1 });
  const [, setTick] = useState(0);
  const pending = useRef<string | null>(null);
  const busy = useRef(false);
  const currentRef = useRef(value);
  const params = useRef({ duration, delay });
  params.current = { duration, delay };

  const alive = useRef(true);
  const raf = useRef(0);
  const timer = useRef(0);
  useEffect(() => {
    alive.current = true;
    return () => {
      alive.current = false;
      busy.current = false;
      clearTimeout(timer.current);
      cancelAnimationFrame(raf.current);
    };
  }, []);

  useEffect(() => {
    if (value === currentRef.current && !busy.current) return;
    pending.current = value;
    if (busy.current) return;
    busy.current = true;
    const run = () => {
      if (!alive.current) return;
      const next = pending.current;
      pending.current = null;
      if (next === null) {
        busy.current = false;
        return;
      }
      if (next === currentRef.current) return run();
      const prev = currentRef.current;
      currentRef.current = next;
      const start = performance.now();
      setShown({ current: next, previous: prev, start });
      const frame = (t: number) => {
        if (!alive.current) return;
        setTick(t);
        if (t - start < params.current.duration * 1000) raf.current = requestAnimationFrame(frame);
        else {
          setShown((sh) => ({ ...sh, start: -1 }));
          run();
        }
      };
      raf.current = requestAnimationFrame(frame);
    };
    timer.current = window.setTimeout(run, params.current.delay * 1000);
  }, [value]);

  const p = shown.start < 0 ? 1 : Math.min(Math.max((performance.now() - shown.start) / (duration * 1000), 0), 1);
  const topAngle = p < 0.5 ? -90 * (p / 0.5) ** 2 : -90;
  let bottomAngle = 90;
  if (p >= 0.5) {
    const s = (p - 0.5) / 0.5;
    bottomAngle = s < 0.6 ? 90 * (1 - (s / 0.6) ** 2) : 14 * bounce * Math.sin((Math.PI * (s - 0.6)) / 0.4);
  }
  const persp = Math.max(TILE_W, TILE_H / 2) / Math.max(depth, 0.05);
  const flipping = shown.start >= 0;
  return (
    <div style={{ position: "relative", width: TILE_W, height: TILE_H + 1.5, filter: "drop-shadow(0 5px 8px rgb(0 0 0 / 0.4))" }}>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", gap: 1.5 }}>
        <Half text={shown.current} top />
        <Half text={flipping ? shown.previous : shown.current} top={false} />
      </div>
      {flipping && (
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", gap: 1.5 }}>
          <div style={{ transformOrigin: "50% 100%", transform: `perspective(${persp}px) rotateX(${topAngle}deg)`, filter: `brightness(${1 + topAngle * 0.003})` }}>
            <Half text={shown.previous} top />
          </div>
          <div style={{ transformOrigin: "50% 0%", transform: `perspective(${persp}px) rotateX(${bottomAngle}deg)`, filter: `brightness(${1 - bottomAngle * 0.002})` }}>
            <Half text={shown.current} top={false} />
          </div>
        </div>
      )}
    </div>
  );
}

/** One half (top or bottom) of a digit tile, clipped from a full-size tile. */
function Half({ text, top }: { text: string; top: boolean }) {
  return (
    <div style={{ position: "relative", width: TILE_W, height: TILE_H / 2, overflow: "hidden" }}>
      <div
        style={{
          position: "absolute",
          left: 0,
          top: top ? 0 : -TILE_H / 2,
          width: TILE_W,
          height: TILE_H,
          borderRadius: 10,
          background: `linear-gradient(${Signature.cardHigh}, #131316)`,
          boxShadow: `inset 0 0 0 1px ${Signature.hairline}`,
          display: "grid",
          placeItems: "center",
        }}
      >
        <span style={{ ...signatureNumber(50), color: "#fff", lineHeight: "60px" }}>{text}</span>
      </div>
    </div>
  );
}
