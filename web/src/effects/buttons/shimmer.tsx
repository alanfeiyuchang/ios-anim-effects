/** buttons.shimmer · 扫光按钮 (Buttons+Shimmer.swift) */
import { motion } from "motion/react";
import { Crown } from "lucide-react";
import { useState } from "react";
import { Palette, hex, pressHandlers, spring, useClock, useHaptics, white, type DemoProps } from "../../kit";
import { wallSeconds } from "./_b-kit";

const W = 240;
const H = 62;

export default function Shimmer({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [pressed, setPressed] = useState(false);
  useClock(true, ctx.isPreview ? 30 : undefined);

  // 0…1 while the band travels, parked at 1 during the pause.
  const duration = Math.max(ctx.n("duration"), 0.1);
  const cycle = duration + ctx.n("pause");
  const local = wallSeconds() % cycle;
  const x0 = Math.min(local / duration, 1);
  const progress = x0 < 0.5 ? 2 * x0 * x0 : 1 - Math.pow(-2 * x0 + 2, 2) / 2;

  const bandWidth = ctx.n("width");
  const intensity = ctx.n("intensity");
  const travel = W / 2 + bandWidth + 20;
  const x = -travel + progress * travel * 2;

  // The hairline glint: a band mask along the 20°-tilted gradient line.
  const along = x * Math.cos((20 * Math.PI) / 180);
  const half = (bandWidth * 1.3) / 2;
  const mask = `linear-gradient(110deg, transparent calc(50% + ${along - half}px), #000 calc(50% + ${along}px), transparent calc(50% + ${along + half}px))`;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <motion.button
        type="button"
        {...pressHandlers(setPressed)}
        onClick={() => haptics.tap("medium")}
        animate={{ scale: pressed ? 0.96 : 1 }}
        transition={spring(0.3, 0.6)}
        style={{ position: "relative", width: W, height: H, borderRadius: H / 2, boxShadow: `0 10px 18px ${hex(0x4b2a8c, 0.45)}` }}
      >
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: H / 2,
            overflow: "hidden",
            background: `linear-gradient(135deg, ${hex(0x2b2f77)}, ${hex(0x4b2a8c)})`,
            isolation: "isolate",
          }}
        >
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 8, fontSize: 17, fontWeight: 600, color: "#fff" }}>
            <Crown size={19} fill={Palette.amber} color={Palette.amber} strokeWidth={1.6} />
            {ctx.t("Upgrade to Pro", "升级到 Pro")}
          </div>
          <div
            style={{
              position: "absolute",
              left: W / 2 - bandWidth / 2,
              top: H / 2 - (H * 2.2) / 2,
              width: bandWidth,
              height: H * 2.2,
              transform: `translateX(${x}px) rotate(20deg)`,
              background: `linear-gradient(90deg, transparent, ${white(intensity)}, transparent)`,
              mixBlendMode: "plus-lighter",
              pointerEvents: "none",
            }}
          />
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: H / 2, boxShadow: `inset 0 0 0 1px ${white(0.16)}`, pointerEvents: "none" }} />
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: H / 2,
            boxShadow: `inset 0 0 0 1.2px ${white(Math.min(0.35 + intensity, 1))}`,
            WebkitMaskImage: mask,
            maskImage: mask,
            pointerEvents: "none",
          }}
        />
      </motion.button>
    </div>
  );
}
