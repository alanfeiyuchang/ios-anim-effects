/** buttons.hold-to-confirm · 长按确认 (Buttons+HoldToConfirm.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { Check, FileText, Trash2 } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, demoCard, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BlurReplace, cubicKF, linearKF, track, trackDuration, useLongPress, useSince } from "./_a-kit";

const W = 260;
const H = 62;

export default function HoldToConfirm({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const progress = useMotionValue(0);
  const rowScale = useMotionValue(1);
  const follow = useRef(true);
  const [pressing, setPressing] = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const confirmedRef = useRef(false);
  const script = useRef<(() => void) | null>(null);
  const duration = ctx.n("duration");
  const zh = ctx.lang === "zh";

  useMotionValueEvent(progress, "change", (p) => {
    if (follow.current) rowScale.set(1 - p * 0.04);
  });

  const beginHold = () => {
    if (confirmedRef.current) return;
    follow.current = true;
    setPressing(true);
    haptics.tap();
    animate(progress, 1, anim.linear(duration));
  };
  const endHold = () => {
    setPressing(false);
    if (confirmedRef.current) return;
    animate(progress, 0, spring(ctx.n("drain"), 1));
  };
  const confirm = (silent = false) => {
    if (confirmedRef.current) return;
    confirmedRef.current = true;
    setPressing(false);
    follow.current = false;
    const t = anim.snappyD(0.25);
    animate(progress, 1, t);
    animate(rowScale, 0.9, t);
    setConfirmed(true);
    if (!silent) haptics.success();
    after(1.4, () => {
      const r = spring(0.5, 0.9);
      confirmedRef.current = false;
      setConfirmed(false);
      animate(progress, 0, r);
      animate(rowScale, 1, r);
    });
  };
  const cancelScript = () => {
    script.current?.();
    script.current = null;
  };

  const longPress = useLongPress({
    duration,
    maximumDistance: 40,
    onComplete: () => confirm(),
    onPressingChanged: (isPressing) => {
      cancelScript();
      if (isPressing) beginHold();
      else endHold();
    },
  });

  useAutoplay(ctx.isPreview, () => {
    if (confirmedRef.current) return;
    beginHold();
    cancelScript();
    script.current = after(duration, () => {
      script.current = null;
      confirm(true);
    });
  }, { every: duration + 2.4, delay: 0.4 });
  useEffect(() => () => clearAll(), [clearAll]);

  // HoldEdgeShake: jitters sideways during the last ~28% of a hold.
  const active = pressing && !confirmed;
  const [shakes, setShakes] = useState(0);
  useEffect(() => {
    if (active) setShakes((s) => s + 1);
  }, [active]);
  const amount = ctx.n("shake");
  const beat = (duration * 0.28) / 8;
  const shakeTrack = [
    linearKF(0, duration * 0.72),
    ...[0.4, -0.5, 0.6, -0.7, 0.8, -0.9, 1, -1].map((k) => cubicKF(amount * k, beat)),
    linearKF(0, 0.05),
  ];
  const jitter = track(useSince(shakes, trackDuration(shakeTrack)), 0, shakeTrack);

  const clip = useTransform(progress, (p) => `inset(0 ${W - W * p}px 0 0)`);
  const edgeX = useTransform(progress, (p) => Math.max(W * p - 4, 0));
  const pressT = spring(0.3, 0.7);
  const rowT = confirmed ? anim.snappyD(0.25) : spring(0.5, 0.9);

  const label = (color: string) => (
    <BlurReplace id={confirmed ? "done" : "hold"} style={{ position: "absolute", inset: 0, color, fontSize: 17, fontWeight: 600 }}>
      {confirmed ? (
        <span style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <Check size={18} strokeWidth={2.8} />
          {zh ? "已删除" : "Deleted"}
        </span>
      ) : (
        <span style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <Trash2 size={18} strokeWidth={2.4} />
          {zh ? "长按删除" : "Hold to delete"}
        </span>
      )}
    </BlurReplace>
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
        <motion.div style={{ scale: rowScale }}>
          <motion.div
            initial={false}
            animate={{ filter: confirmed ? "blur(8px)" : "blur(0px)", opacity: confirmed ? 0 : 1, y: confirmed ? -10 : 0 }}
            transition={rowT}
            style={{ ...demoCard(18), width: W, padding: 12, display: "flex", alignItems: "center", gap: 12 }}
          >
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: 11,
                background: `linear-gradient(135deg, ${Palette.amber}, ${Palette.coral})`,
                display: "grid",
                placeItems: "center",
                color: "#fff",
              }}
            >
              <FileText size={21} strokeWidth={2.3} />
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
              <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label }}>{zh ? "第三季度路线图.key" : "Q3 Roadmap.key"}</div>
              <div style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{zh ? "24 MB · 今天编辑" : "24 MB · Edited today"}</div>
            </div>
          </motion.div>
        </motion.div>
        <div style={{ transform: `translateX(${active ? jitter : 0}px)` }}>
          <motion.div
            {...longPress}
            initial={false}
            animate={{
              scale: active ? 0.97 : 1,
              boxShadow: pressing || confirmed ? "0px 8px 16px rgba(255, 77, 94, 0.3)" : "0px 8px 16px rgba(255, 77, 94, 0.12)",
            }}
            transition={pressT}
            style={{ ...longPress.style, position: "relative", width: W, height: H, borderRadius: H / 2 }}
          >
            <div style={{ position: "absolute", inset: 0, borderRadius: H / 2, overflow: "hidden" }}>
              <div style={{ position: "absolute", inset: 0, background: Palette.elevated }} />
              <div style={{ position: "absolute", inset: 0, background: "rgb(255 77 94 / 0.1)" }} />
              {label(Palette.red)}
              <motion.div style={{ position: "absolute", inset: 0, clipPath: clip }}>
                <div style={{ position: "absolute", inset: 0, background: `linear-gradient(90deg, ${Palette.red}, ${Palette.coral})` }} />
                {label("#fff")}
              </motion.div>
              <motion.div
                initial={false}
                animate={{ opacity: active ? 1 : 0 }}
                transition={pressT}
                style={{
                  position: "absolute",
                  left: 0,
                  top: (H - H * 0.56) / 2,
                  width: 3,
                  height: H * 0.56,
                  borderRadius: 1.5,
                  background: "rgb(255 255 255 / 0.75)",
                  filter: "blur(1.5px)",
                  x: edgeX,
                  pointerEvents: "none",
                }}
              />
            </div>
            <div style={{ position: "absolute", inset: 0, borderRadius: H / 2, boxShadow: "inset 0 0 0 1px rgb(255 77 94 / 0.22)", pointerEvents: "none" }} />
          </motion.div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press and hold, or let go early" zh="长按完成，或中途松手" style={{ paddingBottom: 18 }} />
    </div>
  );
}
