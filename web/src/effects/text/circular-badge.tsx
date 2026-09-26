/** text.circular-badge · 环形文字徽章 (Text+CircularBadge.swift) */
import { motion } from "motion/react";
import { ArrowDown } from "lucide-react";
import { useRef, useState } from "react";
import { Palette, SymbolBounce, alpha, fonts, spring, useAutoplay, useClock, useHaptics, useTimeouts, white, type DemoProps } from "../../kit";
import { chars } from "./_text-kit";

export default function CircularBadge({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [spin, setSpin] = useState(0);
  const [taps, setTaps] = useState(0);
  const [pressed, setPressed] = useState(false);
  const sign = ctx.i("direction") === 0 ? 1 : -1;
  const radius = ctx.n("radius");
  const zh = ctx.lang === "zh";
  const phrase = zh ? "动效词典 · 向下滚动 · 探索更多 · 精心打磨 · " : "MOTION LEXICON • SCROLL TO EXPLORE • ";

  // Integrated ring angle: moving the speed slider changes the rate without snapping the ring.
  const t = useClock(true, ctx.isPreview ? 30 : undefined);
  const phase = useRef({ angle: 0, last: null as number | null });
  const p = phase.current;
  if (p.last !== null) {
    const dt = Math.min(Math.max(t - p.last, 0), 0.1);
    p.angle = (p.angle + dt * ctx.n("speed") * sign) % 360;
  }
  p.last = t;

  const tap = () => {
    haptics.tap("soft");
    setTaps((n) => n + 1);
    setSpin((s) => s + 180);
    setPressed(true);
    after(0.14, () => setPressed(false));
  };
  useAutoplay(ctx.isPreview, tap, { every: 2.6 });

  const glyphs = chars(phrase);
  const step = 360 / Math.max(glyphs.length, 1);
  const size = radius * 2 + 30;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ position: "relative", width: size, height: size, flexShrink: 0 }}>
        <div
          style={{
            position: "absolute",
            left: 30,
            top: 30,
            width: radius * 2 - 30,
            height: radius * 2 - 30,
            borderRadius: "50%",
            boxShadow: `inset 0 0 0 1px ${Palette.labelAlpha(0.08)}`,
          }}
        />
        <motion.div initial={false} animate={{ rotate: spin * sign }} transition={spring(0.8, 0.72)} style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", inset: 0, transform: `rotate(${p.angle}deg)` }}>
            {glyphs.map((g, i) => (
              <span
                key={i}
                style={{
                  position: "absolute",
                  left: "50%",
                  top: "50%",
                  width: 20,
                  height: 20,
                  marginLeft: -10,
                  marginTop: -10,
                  display: "grid",
                  placeItems: "center",
                  fontFamily: fonts.rounded,
                  fontSize: zh ? 14 : 12,
                  fontWeight: 700,
                  color: Palette.label,
                  whiteSpace: "pre",
                  transform: `rotate(${i * step}deg) translateY(${-radius}px)`,
                }}
              >
                {g}
              </span>
            ))}
          </div>
        </motion.div>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
          <motion.button
            type="button"
            onClick={tap}
            animate={{ scale: pressed ? 0.9 : 1 }}
            transition={pressed ? spring(0.18, 0.7) : spring(0.35, 0.5)}
            style={{
              width: 76,
              height: 76,
              borderRadius: "50%",
              background: Palette.primary,
              boxShadow: `inset 0 0 0 1px ${white(0.3)}, 0 8px 14px ${alpha(Palette.indigo, 0.4)}`,
              display: "grid",
              placeItems: "center",
              color: "#fff",
            }}
          >
            <SymbolBounce trigger={taps} kind="bounceDown">
              <ArrowDown size={30} strokeWidth={3} />
            </SymbolBounce>
          </motion.button>
        </div>
      </div>
    </div>
  );
}
