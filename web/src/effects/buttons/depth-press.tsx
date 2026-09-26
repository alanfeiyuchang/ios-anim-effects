/** buttons.depth-press · 立体按压 (Buttons+DepthPress.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { GradientBorder, useLatchedPress } from "./_a-kit";

const TOP = "#FF9A7A";
const BOTTOM = Palette.coral;
const BASE = "#C2452F";
const W = 220;
const H = 62;

export default function DepthPress({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [autoPressed, setAutoPressed] = useState(false);
  const autoRef = useRef(false);
  // The medium haptic lands as the face bottoms out (the stiff press spring has covered ~90% by 80 ms).
  const { held, handlers } = useLatchedPress({ pressDelay: 0.08, onPress: () => haptics.tap("medium") });
  const pressed = held || autoPressed;

  useAutoplay(ctx.isPreview, () => {
    if (ctx.isPreview) {
      autoRef.current = !autoRef.current;
      setAutoPressed(autoRef.current);
    } else {
      setAutoPressed(true);
      after(0.4, () => setAutoPressed(false));
    }
  }, { every: 0.8 });

  const depth = ctx.n("depth");
  const travel = ctx.n("travel");
  const t = pressed ? spring(0.12, 0.9) : spring(0.35, ctx.n("bounce"));

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <button type="button" {...handlers} style={{ position: "relative", width: W, height: H + depth, flexShrink: 0 }}>
        <motion.div
          initial={false}
          animate={{
            boxShadow: pressed ? "0px 2px 4px rgba(194, 69, 47, 0.25)" : "0px 10px 14px rgba(194, 69, 47, 0.45)",
          }}
          transition={t}
          style={{ position: "absolute", left: 0, top: depth, width: W, height: H, borderRadius: 18, background: BASE }}
        />
        <motion.div
          initial={false}
          animate={{ y: pressed ? depth * travel : 0 }}
          transition={t}
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            width: W,
            height: H,
            borderRadius: 18,
            background: `linear-gradient(${TOP}, ${BOTTOM})`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontFamily: fonts.rounded,
            fontSize: 20,
            fontWeight: 800,
            letterSpacing: 1,
            color: "#fff",
            textShadow: "0 1.5px 0 rgb(194 69 47 / 0.6)",
          }}
        >
          <GradientBorder radius={18} width={1.5} gradient="linear-gradient(rgb(255 255 255 / 0.5), transparent 50%)" />
          {ctx.lang === "zh" ? "开始游戏" : "PLAY NOW"}
        </motion.div>
      </button>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press the key" zh="按下这个键" style={{ paddingBottom: 18 }} />
    </div>
  );
}
