/** buttons.repel-letters · 斥力文字 (Buttons+RepelLetters.swift) */
import { motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, fonts, hex, spring, useAutoplay, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";

const W = 290;
const H = 68;
const PREVIEW_PATH: Point[] = [
  { x: 60, y: 30 },
  { x: 120, y: 44 },
  { x: 180, y: 26 },
  { x: 240, y: 40 },
];

export default function RepelLetters({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [finger, setFinger] = useState<Point | null>(null);
  const fingerRef = useRef<Point | null>(null);
  fingerRef.current = finger;
  const step = useRef(0);
  const intro = useRef(0);
  const zh = ctx.lang === "zh";
  const letters = Array.from(zh ? "探索更多内容" : "EXPLORE MORE");
  const advance = zh ? 30 : 16;

  const stopIntro = () => {
    intro.current += 1;
  };
  useEffect(() => stopIntro, []);

  const introSweep = () => {
    stopIntro();
    const run = intro.current;
    PREVIEW_PATH.forEach((p, i) => window.setTimeout(() => run === intro.current && setFinger(p), i * 450));
    window.setTimeout(() => run === intro.current && setFinger(null), PREVIEW_PATH.length * 450);
  };

  const previewStep = () => {
    const point = PREVIEW_PATH[step.current % PREVIEW_PATH.length];
    step.current += 1;
    setFinger(step.current % 5 === 0 ? null : point);
  };

  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? previewStep() : introSweep()), { every: 0.7, delay: 0.3 });

  const pan = usePan({
    onChange: ({ location }) => {
      stopIntro();
      if (fingerRef.current === null) haptics.tap();
      setFinger(location);
    },
    onEnd: () => setFinger(null),
  });

  const radius = ctx.n("radius");
  const strength = ctx.n("strength");
  const response = ctx.n("response");
  const total = letters.length * advance;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
        <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("Spring collection", "春季系列")}</div>
        <div
          {...pan}
          style={{
            position: "relative",
            width: W,
            height: H,
            borderRadius: H / 2,
            background: `linear-gradient(${hex(0x2a2a33)}, ${hex(0x111116)})`,
            boxShadow: `0 10px 16px ${black(0.25)}`,
            touchAction: "none",
            cursor: "pointer",
          }}
        >
          {finger && (
            <div
              style={{
                position: "absolute",
                left: finger.x - 50,
                top: finger.y - 50,
                width: 100,
                height: 100,
                borderRadius: "50%",
                background: `radial-gradient(50px circle at 50% 50%, ${hex(0xa46bff, 0.45)}, transparent)`,
                pointerEvents: "none",
              }}
            />
          )}
          {letters.map((ch, index) => {
            const cx = (W - total) / 2 + advance * (index + 0.5);
            const cy = H / 2;
            let dx = 0;
            let dy = 0;
            let tilt = 0;
            let weight = 0;
            if (finger) {
              const ddx = cx - finger.x;
              const ddy = cy - finger.y;
              const distance = Math.max(Math.hypot(ddx, ddy), 0.5);
              weight = Math.max(0, 1 - distance / radius);
              const push = strength * weight;
              const ux = ddx / distance;
              const uy = ddy / distance;
              tilt = ux * weight * 25;
              dx = ux * push;
              dy = uy * push;
            }
            return (
              <motion.div
                key={index}
                initial={false}
                animate={{ x: dx, y: dy, rotate: tilt, scale: 1 + 0.2 * weight }}
                transition={{ ...spring(response, 0.55), delay: index * 0.01 }}
                style={{
                  position: "absolute",
                  left: cx - advance / 2,
                  top: cy - 15,
                  width: advance,
                  height: 30,
                  display: "grid",
                  placeItems: "center",
                  fontFamily: fonts.mono,
                  fontSize: zh ? 20 : 19,
                  fontWeight: 700,
                  color: "#fff",
                  pointerEvents: "none",
                  whiteSpace: "pre",
                }}
              >
                {ch}
              </motion.div>
            );
          })}
          <div style={{ position: "absolute", inset: 0, borderRadius: H / 2, boxShadow: `inset 0 0 0 1px ${white(0.14)}`, pointerEvents: "none" }} />
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Slide your finger across the label" zh="手指在文字上滑动" style={{ paddingBottom: 18 }} />
    </div>
  );
}
