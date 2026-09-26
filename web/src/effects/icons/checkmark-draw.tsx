/** icons.checkmark-draw · 对勾描绘 (Icons+Checkmark.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, delayed, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";

const SIZE = 120;

export default function CheckmarkDraw({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const color = ctx.i("color") === 1 ? Palette.blue : ctx.i("color") === 2 ? Palette.violet : Palette.green;
  const line = ctx.n("lineWidth");
  const ring = useMotionValue(0);
  const tick = useMotionValue(0);
  const pop = useMotionValue(0.9);
  const haloOpacity = useMotionValue(0);
  const haloScale = useMotionValue(1);
  const [labelOn, setLabelOn] = useState(false);
  const running = useRef<{ stop: () => void }[]>([]);

  const ringVisible = useTransform(ring, (v) => (v > 0.001 ? 1 : 0));
  const tickVisible = useTransform(tick, (v) => (v > 0.001 ? 1 : 0));
  useMotionValueEvent(tick, "change", (v) => setLabelOn(v > 0.5));

  const shadow = useTransform(pop, (s) => {
    const r = Math.max(0, ((s - 0.9) / 0.1) * 18);
    return `drop-shadow(0 8px ${r}px ${alpha(color, 0.3)})`;
  });

  /** `scripted`: autoplay and the detail intro stay silent, including the delayed success haptic. */
  const play = (scripted = false) => {
    const duration = ctx.n("duration");
    running.current.forEach((a) => a.stop());
    running.current = [];
    clearAll();
    ring.set(0);
    tick.set(0);
    pop.set(0.9);
    haloOpacity.set(0);
    haloScale.set(1);
    after(0.06, () => {
      running.current.push(animate(ring, 1, anim.easeInOut(duration)));
      running.current.push(animate(tick, 1, delayed(anim.easeOut(0.35), duration * 0.7)));
      after(duration * 0.7 + 0.25, () => {
        // Burst: the halo appears at 50% at the badge's edge, then expands and fades out.
        haloOpacity.set(0.5);
        running.current.push(animate(pop, 1, spring(0.4, 0.5)));
        running.current.push(animate(haloOpacity, 0, anim.easeOut(0.7)));
        running.current.push(animate(haloScale, 1.5, anim.easeOut(0.7)));
        if (!scripted) haptics.success();
      });
    });
  };

  useAutoplay(ctx.isPreview, () => play(true), { every: 2.6, delay: 0.2 });

  const r = SIZE / 2;
  return (
    <div
      onClick={() => play()}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 26, cursor: "pointer" }}
    >
      <motion.div style={{ position: "relative", width: SIZE, height: SIZE, scale: pop, filter: shadow }}>
        <motion.div
          style={{ position: "absolute", inset: -1, borderRadius: "50%", border: `2px solid ${color}`, opacity: haloOpacity, scale: haloScale }}
        />
        <svg width={SIZE} height={SIZE} viewBox={`0 0 ${SIZE} ${SIZE}`} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <motion.circle cx={r} cy={r} r={r} fill={alpha(color, 0.14)} style={{ opacity: ring }} />
          <motion.circle
            cx={r}
            cy={r}
            r={r}
            fill="none"
            stroke={color}
            strokeWidth={line}
            strokeLinecap="round"
            transform={`rotate(-90 ${r} ${r})`}
            style={{ pathLength: ring, opacity: ringVisible }}
          />
          <motion.path
            d={`M${26 + 68 * 0.05} ${26 + 68 * 0.55}L${26 + 68 * 0.38} ${26 + 68 * 0.85}L${26 + 68 * 0.95} ${26 + 68 * 0.18}`}
            fill="none"
            stroke={color}
            strokeWidth={line * 1.15}
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{ pathLength: tick, opacity: tickVisible }}
          />
        </svg>
      </motion.div>
      <span style={{ ...textStyle.headline, opacity: labelOn ? 1 : 0.25, transition: "opacity 0.3s ease-out" }}>{ctx.t("Payment complete", "支付成功")}</span>
      <DemoHint ctx={ctx} en="Tap to replay" zh="点击重播" />
    </div>
  );
}
