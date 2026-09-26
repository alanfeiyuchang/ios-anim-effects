/** inputs.day-night-toggle · 昼夜切换开关 (Inputs+DayNightToggle.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, delayed, hex, spring, textStyle, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { FadeText } from "./_a-common";

export default function DayNightToggle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [isNight, setIsNight] = useState(false);
  const toggle = () => {
    haptics.tap("medium");
    setIsNight((v) => !v);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.6, delay: 0.5 });
  const t = spring(ctx.n("response"), ctx.n("damping"));

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
      <div style={{ flex: 1 }} />
      <button type="button" onClick={toggle}>
        <Switch isNight={isNight} showHalo={ctx.b("halo")} t={t} />
      </button>
      <FadeText
        text={isNight ? ctx.t("Dark", "深色") : ctx.t("Light", "浅色")}
        style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.secondaryLabel }}
      />
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the switch" zh="点击开关切换昼夜" style={{ paddingBottom: 18 }} />
    </div>
  );
}

type T = ReturnType<typeof spring>;

/** A child centred in the 180 × 76 track, offset by (x, y). */
const centred = (w: number, h: number) => ({ position: "absolute" as const, left: 90 - w / 2, top: 38 - h / 2, width: w, height: h });

function Switch({ isNight, showHalo, t }: { isNight: boolean; showHalo: boolean; t: T }) {
  const knobX = isNight ? 52 : -52;
  return (
    <motion.div
      initial={false}
      animate={{ boxShadow: `0 8px 16px ${isNight ? hex(0x1d2247, 0.35) : hex(0x3a8dff, 0.35)}` }}
      transition={t}
      style={{ position: "relative", width: 180, height: 76, borderRadius: 38 }}
    >
      <div style={{ position: "absolute", inset: 0, borderRadius: 38, overflow: "hidden", isolation: "isolate" }}>
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(#74C8FF, #3A8DFF)" }} />
        <motion.div
          initial={false}
          animate={{ opacity: isNight ? 1 : 0 }}
          transition={t}
          style={{ position: "absolute", inset: 0, background: "linear-gradient(#1D2247, #0B0D1E)" }}
        />
        {showHalo && (
          <motion.div initial={false} animate={{ x: knobX }} transition={t} style={{ position: "absolute", inset: 0 }}>
            {[0, 1, 2].map((ring) => {
              const d = 96 + ring * 36;
              return <div key={ring} style={{ ...centred(d, d), borderRadius: "50%", background: white(0.1) }} />;
            })}
          </motion.div>
        )}
        <StarField isNight={isNight} />
        <motion.div
          initial={false}
          animate={{ x: 34, y: isNight ? 70 : 22, opacity: isNight ? 0 : 1 }}
          transition={t}
          style={{ position: "absolute", inset: 0 }}
        >
          <CloudBank />
        </motion.div>
        <motion.div initial={false} animate={{ x: knobX, rotate: isNight ? 0 : -120 }} transition={t} style={{ ...centred(60, 60) }}>
          <motion.div
            initial={false}
            animate={{
              boxShadow: `0 0 12px ${hex(0xffb02e, isNight ? 0 : 0.65)}, 2px 3px 6px rgb(0 0 0 / 0.25)`,
            }}
            transition={t}
            style={{ position: "absolute", inset: 0, borderRadius: "50%" }}
          />
          <SunFace />
          <motion.div
            initial={false}
            animate={{ opacity: isNight ? 1 : 0 }}
            transition={t}
            style={{ position: "absolute", inset: 0, borderRadius: "50%", background: "linear-gradient(135deg, #F1F3FA, #C4CAD9)" }}
          >
            {[
              [16, -8, -10],
              [10, 12, 4],
              [8, -4, 14],
            ].map(([d, x, y], i) => (
              <div key={i} style={{ position: "absolute", left: 30 + x - d / 2, top: 30 + y - d / 2, width: d, height: d, borderRadius: "50%", background: "#A9B0C2" }} />
            ))}
          </motion.div>
        </motion.div>
      </div>
      <div style={{ position: "absolute", inset: 0, borderRadius: 38, boxShadow: "inset 0 0 0 1px rgb(0 0 0 / 0.08)", pointerEvents: "none" }} />
    </motion.div>
  );
}

function SunFace() {
  return (
    <div style={{ position: "absolute", inset: 0, borderRadius: "50%" }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: "50%",
          background: "radial-gradient(circle 40px at 36% 32%, #FFF1A8 2px, #FFC83D 21px, #FF9A1F 40px)",
        }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: "50%",
          background: "linear-gradient(135deg, rgb(255 255 255 / 0.55), transparent, rgb(196 88 10 / 0.45))",
          WebkitMaskImage: "radial-gradient(circle, transparent 27.5px, #000 28px)",
          maskImage: "radial-gradient(circle, transparent 27.5px, #000 28px)",
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 30 - 12 - 9,
          top: 30 - 14 - 5,
          width: 18,
          height: 10,
          borderRadius: "50%",
          background: white(0.55),
          transform: "rotate(-35deg)",
          filter: "blur(3px)",
        }}
      />
    </div>
  );
}

function CloudBank() {
  const puffs: [number, number, number, string][] = [
    [46, -34, 6, white(0.7)],
    [56, 6, -4, white(0.7)],
    [40, -18, 14, "#fff"],
    [50, 20, 12, "#fff"],
    [36, 50, 4, "#fff"],
  ];
  return (
    <>
      {puffs.map(([d, x, y, c], i) => (
        <div key={i} style={{ position: "absolute", left: 90 + x - d / 2, top: 38 + y - d / 2, width: d, height: d, borderRadius: "50%", background: c }} />
      ))}
    </>
  );
}

const STARS: [number, number][] = [
  [-62, -18],
  [-34, -24],
  [-48, 8],
  [-14, -4],
  [-70, 16],
];

function StarField({ isNight }: { isNight: boolean }) {
  return (
    <>
      {STARS.map(([x, y], index) => {
        const size = index % 2 === 0 ? 9 : 6;
        return (
          <motion.div
            key={index}
            initial={false}
            animate={{ scale: isNight ? 1 : 0.1, opacity: isNight ? 1 : 0 }}
            transition={delayed(spring(0.45, 0.6), isNight ? 0.12 + index * 0.06 : 0)}
            style={{ ...centred(size + 2, size + 2), x, y, display: "grid", placeItems: "center" }}
          >
            {isNight ? (
              <motion.div
                animate={{ opacity: [1, 0.45] }}
                transition={{ duration: 0.9 + index * 0.2, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
              >
                <Sparkle size={size + 2} />
              </motion.div>
            ) : (
              <Sparkle size={size + 2} />
            )}
          </motion.div>
        );
      })}
    </>
  );
}

/** SF `sparkle`: a four-pointed star with concave sides. */
function Sparkle({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 20 20">
      <path d="M10 0 C10.9 6.2 13.8 9.1 20 10 C13.8 10.9 10.9 13.8 10 20 C9.1 13.8 6.2 10.9 0 10 C6.2 9.1 9.1 6.2 10 0Z" fill="#fff" />
    </svg>
  );
}
