/** text.shimmer · 微光扫过 (Text+Shimmer.swift) */
import { motion } from "motion/react";
import { ChevronsRight, Sparkle } from "lucide-react";
import { useEffect, useRef, useState, type CSSProperties } from "react";
import { DemoHint, Palette, fonts, glass, useClock, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { evenStops, unitGradient, useSize } from "./_text-kit";

const SWEEP_DURATION = 0.65;
/** Sweep cycles per second: one pass every 2.2 s at speed 1. */
const rate = (speed: number) => Math.max(speed, 0.05) / 2.2;

export default function Shimmer({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [sweepStart, setSweepStart] = useState(-Infinity);
  useClock(true, ctx.isPreview ? 30 : undefined);

  // Sweep cycles carried over from earlier speeds (moving the slider changes the pace, not the band).
  const speed = ctx.n("speed");
  const cycleShift = useRef(0);
  const lastSpeed = useRef(speed);
  useEffect(() => {
    cycleShift.current += (Date.now() / 1000) * (rate(lastSpeed.current) - rate(speed));
    lastSpeed.current = speed;
  }, [speed]);
  const cycles = (Date.now() / 1000) * rate(speed) + cycleShift.current;

  const fireSweep = () => {
    if (ctx.isPreview) return;
    haptics.tap("soft");
    setSweepStart(performance.now() / 1000);
  };

  return (
    <div
      onClick={fireSweep}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 34, cursor: "pointer" }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <motion.span
          animate={{ opacity: [1, 0.35, 1] }}
          transition={{ duration: 1.1, repeat: Infinity, ease: "easeInOut" }}
          style={{ display: "grid", color: Palette.indigo }}
        >
          <svg width={22} height={22} viewBox="0 0 24 24">
            <defs>
              <linearGradient id="shimmer-sparkle" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0" stopColor={Palette.indigo} />
                <stop offset="1" stopColor={Palette.violet} />
              </linearGradient>
            </defs>
            <Sparkle size={24} fill="url(#shimmer-sparkle)" stroke="url(#shimmer-sparkle)" strokeWidth={1.5} />
          </svg>
        </motion.span>
        <ShimmerText
          text={ctx.t("Thinking…", "思考中…")}
          style={{ fontFamily: fonts.rounded, fontSize: 34, fontWeight: 600, lineHeight: "41px" }}
          ctx={ctx}
          cycles={cycles}
          sweepStart={sweepStart}
        />
      </div>
      <div style={{ width: 280, padding: 6, display: "flex", alignItems: "center", gap: 14, borderRadius: 999, ...glass("regular"), boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }}>
        <span style={{ width: 52, height: 52, borderRadius: "50%", background: Palette.primary, display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
          <ChevronsRight size={22} strokeWidth={3} />
        </span>
        <ShimmerText
          text={ctx.t("slide to unlock", "滑动来解锁")}
          style={{ fontSize: 20, fontWeight: 500, lineHeight: "25px" }}
          ctx={ctx}
          cycles={cycles}
          sweepStart={sweepStart + 0.12}
        />
      </div>
      <DemoHint ctx={ctx} en="Tap to send a sweep of light" zh="点击扫过一道光" />
    </div>
  );
}

function ShimmerText({ text, style, ctx, cycles, sweepStart }: { text: string; style: CSSProperties; ctx: DemoContext; cycles: number; sweepStart: number }) {
  const [ref, { w, h }] = useSize<HTMLSpanElement>([text]);
  const band = ctx.n("band");
  const pink = ctx.i("style") === 1;
  const dim = Palette.labelAlpha(0.28);
  const colors = pink ? [dim, Palette.violet, Palette.pink, Palette.amber, dim] : [dim, Palette.label, dim];

  const t = cycles - Math.floor(cycles);
  const center = -band + t * (1 + band * 2);
  const base = unitGradient(w || 1, h || 1, { x: center - band, y: 0.2 }, { x: center + band, y: 0.8 }, evenStops(colors));

  const raw = (performance.now() / 1000 - sweepStart) / SWEEP_DURATION;
  const sweeping = raw >= 0 && raw <= 1;
  const s = sweeping ? raw : 1;
  const eased = s * s * (3 - 2 * s);
  const sb = band * 0.7;
  const sc = -sb + eased * (1 + sb * 2);
  const glow = pink ? Palette.pink : Palette.label;
  const sweep = unitGradient(w || 1, h || 1, { x: sc - sb, y: 0.2 }, { x: sc + sb, y: 0.8 }, evenStops(["transparent", glow, "transparent"]));

  const paint = (fill: string): CSSProperties => ({
    backgroundImage: fill,
    WebkitBackgroundClip: "text",
    backgroundClip: "text",
    color: "transparent",
    WebkitTextFillColor: "transparent",
  });

  return (
    <span ref={ref} style={{ position: "relative", display: "inline-block", whiteSpace: "pre", ...style }}>
      <span style={paint(base)}>{text}</span>
      <span aria-hidden style={{ position: "absolute", inset: 0, opacity: sweeping ? 1 : 0, ...paint(sweep) }}>
        {text}
      </span>
    </span>
  );
}
