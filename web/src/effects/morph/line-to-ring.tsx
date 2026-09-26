/** morph.line-to-ring · 直线卷成圆环 (Morph+LineToRing.swift) */
import { AnimatePresence, animate, motion, useMotionValue } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, hex, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { blurReplace, useMV } from "./_shared";

const W = 260;
const H = 200;
const LENGTH = 220;

/** A stroke of fixed arc length whose total turning angle is `curl · 2π`, kept centred. */
function curlPath(curl: number) {
  const kappa = (curl * 2 * Math.PI) / LENGTH;
  const ringRadius = LENGTH / (2 * Math.PI);
  const lift = curl * ringRadius;
  const cx = W / 2;
  const cy = H / 2;
  let d = "";
  for (let i = 0; i <= 120; i++) {
    const u = (i / 120 - 0.5) * LENGTH;
    let x = u;
    let y = 0;
    if (Math.abs(kappa) > 0.0001) {
      const phi = u * kappa;
      x = Math.sin(phi) / kappa;
      y = (1 - Math.cos(phi)) / kappa;
    }
    d += `${i === 0 ? "M" : "L"}${(cx + x).toFixed(2)} ${(cy - y + lift).toFixed(2)}`;
  }
  return d;
}

export default function LineToRing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [curled, setCurled] = useState(false);
  const mv = useMotionValue(0);
  const curl = useMV(mv);
  const width = ctx.n("width");
  const t = spring(ctx.n("response"), 1 - ctx.n("bounce"));

  const toggle = () => {
    haptics.tap("soft");
    const next = !curled;
    setCurled(next);
    animate(mv, next ? 1 : 0, t);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.6 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 30 }}>
      <div onClick={toggle} style={{ position: "relative", width: W, height: H, cursor: "pointer", flexShrink: 0 }}>
        <motion.div
          initial={false}
          animate={{ opacity: curled ? 0 : 1 }}
          transition={t}
          style={{
            position: "absolute",
            left: (W - LENGTH) / 2,
            top: (H - width) / 2,
            width: LENGTH,
            height: width,
            borderRadius: width / 2,
            background: Palette.labelAlpha(0.08),
          }}
        />
        <svg
          viewBox={`0 0 ${W} ${H}`}
          width={W}
          height={H}
          style={{ position: "absolute", inset: 0, overflow: "visible", transform: `rotate(${curl * 90}deg)`, filter: `drop-shadow(0 4px 10px ${hex(Palette.violet, 0.35)})` }}
        >
          <defs>
            <linearGradient id="ltr-stroke" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2={W} y2="0">
              <stop offset="0" stopColor={Palette.indigo} />
              <stop offset="0.5" stopColor={Palette.violet} />
              <stop offset="1" stopColor={Palette.pink} />
            </linearGradient>
          </defs>
          <path d={curlPath(curl)} fill="none" stroke="url(#ltr-stroke)" strokeWidth={width} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <div style={{ height: 20, display: "flex", justifyContent: "center" }}>
        <AnimatePresence initial={false} mode="popLayout">
          <motion.span key={String(curled)} {...blurReplace()} transition={t} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>
            {curled ? ctx.t("Ring", "圆环") : ctx.t("Progress bar", "进度条")}
          </motion.span>
        </AnimatePresence>
      </div>
      <DemoHint ctx={ctx} en="Tap the line" zh="点击线条" />
    </div>
  );
}
