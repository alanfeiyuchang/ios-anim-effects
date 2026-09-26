/** buttons.glow-border · 流光描边 (Buttons+GlowBorder.swift) */
import { motion } from "motion/react";
import { WandSparkles } from "lucide-react";
import { useState } from "react";
import { Palette, alpha, hex, pressHandlers, spring, useClock, useHaptics, type DemoProps } from "../../kit";
import { wallSeconds } from "./_b-kit";

const W = 236;
const H = 62;
const R = 20;

/** Colour stops of SwiftUI's evenly spaced `Gradient(colors:)` as a conic-gradient list. */
function stops(colors: string[]): string {
  return colors.map((c, i) => `${c} ${(i / (colors.length - 1)) * 360}deg`).join(", ");
}

export default function GlowBorder({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [pressed, setPressed] = useState(false);
  useClock(true, ctx.isPreview ? 30 : undefined);

  const period = Math.max(ctx.n("period"), 0.2);
  const angle = ((wallSeconds() % period) / period) * 360;
  const glow = ctx.n("glow");
  const colors =
    ctx.i("style") === 1
      ? [...Palette.spectrum, Palette.indigo]
      : [alpha(Palette.violet, 0), alpha(Palette.violet, 0), Palette.violet, Palette.pink, Palette.sky, "#ffffff", alpha(Palette.violet, 0)];
  // AngularGradient starts at 3 o'clock; CSS conic-gradient at 12.
  const conic = `conic-gradient(from ${angle + 90}deg, ${stops(colors)})`;

  const pad = Math.ceil(glow * 3) + 4;
  const side = 270 + glow * 4;
  const maskSvg = `<svg xmlns='http://www.w3.org/2000/svg' width='${W + pad * 2}' height='${H + pad * 2}'><filter id='b' x='-50%' y='-50%' width='200%' height='200%'><feGaussianBlur stdDeviation='${glow}'/></filter><rect x='${pad}' y='${pad}' width='${W}' height='${H}' rx='${R}' fill='black' filter='url(%23b)'/></svg>`;
  const mask = `url("data:image/svg+xml;utf8,${maskSvg.replace(/"/g, "'").replace(/</g, "%3C").replace(/>/g, "%3E")}")`;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <motion.button
        type="button"
        {...pressHandlers(setPressed)}
        onClick={() => haptics.tap("medium")}
        animate={{ scale: pressed ? 0.97 : 1 }}
        transition={spring(0.28, 0.6)}
        style={{ position: "relative", width: W, height: H }}
      >
        {/* The blurred halo, masked by a soft copy of the button shape. */}
        <div
          style={{
            position: "absolute",
            left: -pad,
            top: -pad,
            width: W + pad * 2,
            height: H + pad * 2,
            opacity: 0.7,
            overflow: "hidden",
            WebkitMaskImage: glow > 0 ? mask : undefined,
            maskImage: glow > 0 ? mask : undefined,
            pointerEvents: "none",
          }}
        >
          <div
            style={{
              position: "absolute",
              left: (W + pad * 2) / 2 - side / 2,
              top: (H + pad * 2) / 2 - side / 2,
              width: side,
              height: side,
              borderRadius: "50%",
              background: conic,
              filter: `blur(${glow}px)`,
            }}
          />
        </div>
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: R,
            border: "2px solid transparent",
            background: `linear-gradient(${hex(0x0e0f1a)}, ${hex(0x0e0f1a)}) padding-box, ${conic} border-box`,
          }}
        />
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 8, fontSize: 17, fontWeight: 600, color: "#fff" }}>
          <WandSparkles size={19} strokeWidth={2} />
          {ctx.t("Generate with AI", "用 AI 生成")}
        </div>
      </motion.button>
    </div>
  );
}
