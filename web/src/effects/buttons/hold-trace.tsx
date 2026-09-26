/** buttons.hold-trace · 描边长按 (Buttons+HoldTrace.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { Check } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, spring, useAutoplay, useHaptics, useSilently, useTimeouts, type DemoProps } from "../../kit";
import { BlurReplace, useLongPress, useSvgID } from "./_a-kit";

const W = 250;
const H = 60;
const PLANE = "M21.3 2.7 L3.2 9.8 C2.3 10.2 2.3 11.4 3.2 11.8 L9.9 14.1 L12.2 20.8 C12.6 21.7 13.8 21.7 14.2 20.8 Z";

/** A capsule outline that starts at the top centre and runs clockwise back to it. */
function capsulePath(x: number, y: number, w: number, h: number) {
  const r = h / 2;
  const midX = x + w / 2;
  return [
    `M${midX} ${y}`,
    `L${x + w - r} ${y}`,
    `A${r} ${r} 0 0 1 ${x + w - r} ${y + h}`,
    `L${x + r} ${y + h}`,
    `A${r} ${r} 0 0 1 ${x + r} ${y}`,
    `L${midX} ${y}`,
  ].join(" ");
}

export default function HoldTrace({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const silently = useSilently();
  const { after, clearAll } = useTimeouts();
  const progress = useMotionValue(0);
  const [pressing, setPressing] = useState(false);
  const [sent, setSent] = useState(false);
  const sentRef = useRef(false);
  const script = useRef<(() => void) | null>(null);
  const duration = ctx.n("duration");
  const line = ctx.n("line");
  const gradID = useSvgID("trace-grad");
  const zh = ctx.lang === "zh";

  const begin = () => {
    if (sentRef.current) return;
    setPressing(true);
    haptics.tap("soft");
    animate(progress, 1, anim.linear(duration));
  };
  const end = () => {
    setPressing(false);
    if (sentRef.current) return;
    animate(progress, 0, spring(0.35, 1));
  };
  const complete = () => {
    if (sentRef.current) return;
    sentRef.current = true;
    setPressing(false);
    animate(progress, 1, anim.easeOut(0.15));
    setSent(true);
    haptics.success();
    after(1.4, () => {
      sentRef.current = false;
      setSent(false);
      animate(progress, 0, spring(0.5, 0.9));
    });
  };
  const cancelScript = () => {
    script.current?.();
    script.current = null;
  };

  const longPress = useLongPress({
    duration,
    maximumDistance: 40,
    onComplete: complete,
    onPressingChanged: (isPressing) => {
      cancelScript();
      if (isPressing) begin();
      else end();
    },
  });

  useAutoplay(ctx.isPreview, () => {
    if (sentRef.current) return;
    begin();
    cancelScript();
    script.current = after(duration, () => {
      script.current = null;
      silently(complete);
    });
  }, { every: duration + 2.4, delay: 0.4 });
  useEffect(() => () => clearAll(), [clearAll]);

  const dash = useTransform(progress, (p) => `${p / 2} 2`);
  const visible = useTransform(progress, (p) => (p > 0.001 ? 1 : 0));
  const path = capsulePath(line / 2, line / 2, W - line, H - line);
  const sentT = sent ? anim.easeOut(0.15) : spring(0.5, 0.9);
  const trace = (mirror: boolean) => (
    <svg
      width={W}
      height={H}
      style={{
        position: "absolute",
        inset: 0,
        overflow: "visible",
        transform: mirror ? "scaleX(-1)" : undefined,
        filter: ctx.b("glow") ? "drop-shadow(0 0 6px rgb(164 107 255 / 0.6))" : undefined,
        pointerEvents: "none",
      }}
    >
      <defs>
        <linearGradient id={gradID + (mirror ? "m" : "")} gradientUnits="userSpaceOnUse" x1="0" y1="0" x2={W} y2="0">
          <stop offset="0" stopColor={Palette.indigo} />
          <stop offset="1" stopColor={Palette.violet} />
        </linearGradient>
      </defs>
      <motion.path
        d={path}
        fill="none"
        stroke={`url(#${gradID}${mirror ? "m" : ""})`}
        strokeWidth={line}
        strokeLinecap="round"
        strokeLinejoin="round"
        pathLength={1}
        style={{ strokeDasharray: dash, opacity: visible }}
      />
    </svg>
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 26 }}>
        <div style={{ width: W, display: "flex", justifyContent: "flex-end" }}>
          <motion.div
            initial={false}
            animate={{ y: sent ? -40 : 0, opacity: sent ? 0 : 1, scale: sent ? 0.9 : 1 }}
            transition={sentT}
            style={{
              originX: 1,
              padding: "10px 14px",
              borderRadius: 18,
              background: Palette.primary,
              color: "#fff",
              fontSize: 15,
              lineHeight: "20px",
            }}
          >
            {ctx.t("Running 5 min late — save me a seat!", "要晚到 5 分钟——帮我占个座！")}
          </motion.div>
        </div>
        <motion.div
          {...longPress}
          initial={false}
          animate={{ scale: pressing ? 0.98 : 1 }}
          transition={spring(0.3, 0.7)}
          style={{ ...longPress.style, position: "relative", width: W, height: H, borderRadius: H / 2 }}
        >
          <div style={{ position: "absolute", inset: 0, borderRadius: H / 2, background: Palette.elevated, boxShadow: `inset 0 0 0 1px ${Palette.labelAlpha(0.12)}` }} />
          <motion.div
            initial={false}
            animate={{ opacity: sent ? 1 : 0 }}
            transition={sentT}
            style={{ position: "absolute", inset: 0, borderRadius: H / 2, background: `linear-gradient(90deg, ${Palette.indigo}, ${Palette.violet})` }}
          />
          {trace(false)}
          {trace(true)}
          <BlurReplace id={sent ? "sent" : "hold"} style={{ position: "absolute", inset: 0, fontSize: 17, fontWeight: 600 }}>
            {sent ? (
              <span style={{ display: "flex", alignItems: "center", gap: 6, color: "#fff" }}>
                <Check size={18} strokeWidth={2.8} />
                {zh ? "已发送" : "Sent"}
              </span>
            ) : (
              <span style={{ display: "flex", alignItems: "center", gap: 6, color: pressing ? Palette.indigo : Palette.label, transition: "color 0.2s" }}>
                <svg viewBox="0 0 24 24" width={19} height={19}>
                  <path d={PLANE} fill="currentColor" />
                </svg>
                {zh ? "长按发送" : "Hold to send"}
              </span>
            )}
          </BlurReplace>
        </motion.div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press and hold to send" zh="按住发送" style={{ paddingBottom: 18 }} />
    </div>
  );
}
