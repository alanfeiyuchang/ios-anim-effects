/** buttons.ink-ripple · 墨水涟漪 (Buttons+InkRipple.swift) */
import { motion } from "motion/react";
import { Droplet } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, useAutoplay, useHaptics, useTimeouts, type DemoProps, type Point } from "../../kit";
import { BOUNCY, cubicKF, pointIn, springKF, track, useSince } from "./_a-kit";

const W = 250;
const H = 68;
const PREVIEW_POINTS: Point[] = [
  { x: 40, y: 20 },
  { x: 200, y: 50 },
  { x: 125, y: 34 },
  { x: 230, y: 14 },
];

export default function InkRipple({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [ripples, setRipples] = useState<{ id: number; p: Point }[]>([]);
  const [taps, setTaps] = useState(0);
  const nextID = useRef(0);
  const previewIndex = useRef(0);
  const duration = ctx.n("duration");

  const addRipple = (p: Point) => {
    const id = nextID.current++;
    setRipples((r) => [...r, { id, p }]);
    setTaps((t) => t + 1);
    haptics.tap();
    after(duration + 0.15, () => setRipples((r) => r.filter((x) => x.id !== id)));
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      addRipple(PREVIEW_POINTS[previewIndex.current % PREVIEW_POINTS.length]);
      previewIndex.current += 1;
    },
    { every: 1.0, delay: 0.3 },
  );

  const dip = ctx.b("bounce") ? 0.96 : 1;
  const scale = track(useSince(taps, 0.6), 1, [cubicKF(dip, 0.09), springKF(1, 0.45, BOUNCY)]);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ position: "relative", width: W, height: H, transform: `scale(${scale})` }}>
        {ripples.map((r) => (
          <Halo key={r.id} duration={duration * 1.3} />
        ))}
        <div
          onClick={(e) => addRipple(pointIn(e, e.currentTarget))}
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: 20,
            overflow: "hidden",
            background: Palette.ocean,
            boxShadow: "0 10px 16px rgb(79 124 255 / 0.35)",
            cursor: "pointer",
          }}
        >
          <div style={{ position: "absolute", inset: 0, background: "linear-gradient(rgb(255 255 255 / 0.28), transparent 50%)" }} />
          {ripples.map((r) => (
            <Ripple key={r.id} p={r.p} duration={duration} peak={ctx.n("opacity")} />
          ))}
          <div
            style={{
              position: "absolute",
              inset: 0,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
              color: "#fff",
              fontSize: 17,
              fontWeight: 600,
              pointerEvents: "none",
            }}
          >
            <Droplet size={17} fill="currentColor" strokeWidth={0} />
            <span>{ctx.lang === "zh" ? "轻点一下" : "Tap anywhere"}</span>
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap anywhere on the button" zh="点击按钮的任意位置" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Ripple({ p, duration, peak }: { p: Point; duration: number; peak: number }) {
  const radius = Math.hypot(Math.max(p.x, W - p.x), Math.max(p.y, H - p.y));
  return (
    <div style={{ position: "absolute", left: p.x, top: p.y, width: 0, height: 0, pointerEvents: "none" }}>
      <motion.div
        initial={{ scale: 0.02, opacity: peak }}
        animate={{ scale: 1, opacity: 0 }}
        transition={{ scale: anim.easeOut(duration), opacity: anim.easeIn(duration) }}
        style={{ position: "absolute", left: -radius, top: -radius, width: radius * 2, height: radius * 2, borderRadius: "50%", background: "#fff" }}
      />
      <motion.div
        initial={{ scale: 0.6, opacity: 0.9 }}
        animate={{ scale: 1.6, opacity: 0 }}
        transition={anim.easeOut(Math.min(duration * 0.5, 0.35))}
        style={{
          position: "absolute",
          left: -14,
          top: -14,
          width: 28,
          height: 28,
          borderRadius: "50%",
          background: "radial-gradient(closest-side, #fff, rgb(255 255 255 / 0))",
        }}
      />
    </div>
  );
}

function Halo({ duration }: { duration: number }) {
  return (
    <motion.div
      initial={{ scaleX: 1, scaleY: 1, opacity: 0.8 }}
      animate={{ scaleX: 1 + 28 / W, scaleY: 1 + 28 / H, opacity: 0 }}
      transition={anim.easeOut(duration)}
      style={{ position: "absolute", inset: 0, borderRadius: 20, boxShadow: "inset 0 0 0 1.5px rgb(58 196 255 / 0.7)", pointerEvents: "none" }}
    />
  );
}
