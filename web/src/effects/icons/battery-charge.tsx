/** icons.battery-charge · 电池充电 (Icons+BatteryCharge.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, fonts, springDB, spring, delayed, textStyle, useAutoplay, useClock, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { Glyph, pulseAt, sym, tintGradient, type GlyphDef } from "./_icons-kit";

const BOLT: GlyphDef = [
  { d: "M15.914 4a1.5 1.5 0 00-2.474-1.561l-9 9A1.5 1.5 0 005.5 14h4.002a.5.5 0 01.471.666L8.086 20a1.5 1.5 0 002.475 1.56l9-9A1.5 1.5 0 0018.5 10h-3.997a.5.5 0 01-.472-.667z", sw: 1.2 },
];

export default function BatteryCharge({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [plugged, setPlugged] = useState(false);
  const levelMV = useMotionValue(0.18);
  const [level, setLevel] = useState(0.18);
  useMotionValueEvent(levelMV, "change", setLevel);
  const pluggedRef = useRef(plugged);
  pluggedRef.current = plugged;
  const running = useRef<{ stop: () => void } | null>(null);

  /** `scripted`: the delayed success haptic stays silent for autoplay and the detail intro. */
  const toggle = (scripted = false) => {
    clearAll();
    running.current?.stop();
    const duration = ctx.n("duration");
    if (pluggedRef.current) {
      haptics.tap("light");
      setPlugged(false);
      running.current = animate(levelMV, 0.18, anim.easeInOut(0.9));
      return;
    }
    haptics.tap("medium");
    setPlugged(true);
    after(0.35, () => {
      running.current = animate(levelMV, 1, anim.easeInOut(duration));
    });
    after(0.35 + duration, () => {
      if (!scripted) haptics.success();
    });
  };
  useAutoplay(ctx.isPreview, () => toggle(true), { every: Math.max(ctx.n("duration") + 1.4, 2.6) });

  const clamped = Math.min(Math.max(level, 0), 1);
  const tint = level < 0.2 ? Palette.red : level < 0.45 ? Palette.amber : Palette.green;
  const sweep = ctx.b("sweep") && plugged;

  return (
    <div
      onClick={() => toggle()}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 20, cursor: "pointer" }}
    >
      <div style={{ display: "flex", alignItems: "center" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 3 }}>
          <div style={{ position: "relative", width: 150, height: 70, borderRadius: 18, boxShadow: `inset 0 0 0 3px ${Palette.labelAlpha(0.55)}` }}>
            <div style={{ position: "absolute", inset: 6, borderRadius: 12, background: Palette.labelAlpha(0.06), overflow: "hidden" }}>
              <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 138 * clamped, borderRadius: 12, overflow: "hidden", background: tintGradient(tint) }}>
                {sweep && <Highlight />}
              </div>
              <div
                style={{
                  position: "absolute",
                  right: 8,
                  bottom: 4,
                  fontFamily: fonts.rounded,
                  fontSize: 15,
                  fontWeight: 700,
                  fontVariantNumeric: "tabular-nums",
                  lineHeight: "18px",
                  color: Palette.labelAlpha(0.75),
                }}
              >
                {Math.round(clamped * 100)}%
              </div>
            </div>
            <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", pointerEvents: "none" }}>
              <AnimatePresence>
                {plugged && (
                  <motion.div
                    initial={{ scale: 0.2, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    exit={{ scale: 0.2, opacity: 0, transition: anim.easeIn(0.2) }}
                    transition={delayed(springDB(0.5, ctx.n("bounce")), 0.25)}
                    style={{ color: "#fff", filter: "drop-shadow(0 0 3px rgb(0 0 0 / 0.35))" }}
                  >
                    <PulsingBolt />
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>
          <div style={{ width: 7, height: 24, borderRadius: 3, background: Palette.labelAlpha(0.55) }} />
        </div>
        <motion.div
          initial={false}
          animate={{ x: plugged ? 0 : 60, opacity: plugged ? 1 : 0 }}
          transition={spring(0.35, 0.8)}
          style={{ display: "flex", alignItems: "center" }}
        >
          <div style={{ width: 18, height: 20, borderRadius: 3, background: Palette.labelAlpha(0.7) }} />
          <div style={{ width: 40, height: 6, borderRadius: 3, background: Palette.labelAlpha(0.45) }} />
        </motion.div>
      </div>
      <div style={{ display: "grid", ...textStyle.subheadline, fontWeight: 600, color: Palette.secondaryLabel }}>
        {[false, true].map((state) => (
          <motion.span key={String(state)} initial={false} animate={{ opacity: plugged === state ? 1 : 0 }} transition={anim.snappy} style={{ gridArea: "1 / 1", textAlign: "center", whiteSpace: "nowrap" }}>
            {state ? ctx.t("Charging", "正在充电") : ctx.t("On battery", "使用电池")}
          </motion.span>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap to plug in / unplug" zh="点击插上 / 拔下电源" />
    </div>
  );
}

/** `.symbolEffect(.pulse, isActive: true)` on the bolt. */
function PulsingBolt() {
  const t = useClock(true);
  return (
    <div style={{ opacity: pulseAt(t) }}>
      <Glyph def={BOLT} size={sym(30)} weight={1.3} />
    </div>
  );
}

/** A soft white band sweeping across the fill: wait 0.3 s, then glide −60 → 160 in 1 s, repeating. */
function Highlight() {
  const t = useClock(true);
  const c = t % 1.3;
  const p = c < 0.3 ? 0 : (c - 0.3) / 1.0;
  const e = p * p * (3 - 2 * p);
  const x = -60 + 220 * e;
  return (
    <div
      style={{
        position: "absolute",
        top: 0,
        bottom: 0,
        left: 0,
        width: 40,
        transform: `translateX(${x}px)`,
        background: "linear-gradient(90deg, rgb(255 255 255 / 0), rgb(255 255 255 / 0.45), rgb(255 255 255 / 0))",
      }}
    />
  );
}
