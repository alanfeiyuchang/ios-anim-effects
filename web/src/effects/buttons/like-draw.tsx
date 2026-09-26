/** buttons.like-draw · 描线爱心 (Buttons+LikeDraw.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, demoCard, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BlurReplace, cubicKF, linearKF, track, useSince, useSvgID } from "./_a-kit";

const HW = 72;
const HH = 66;

/** A heart that starts and ends at its bottom tip, so trim draws it in one continuous stroke. */
function heartPath(w: number, h: number) {
  return [
    `M${w * 0.5} ${h * 0.92}`,
    `C${w * 0.2} ${h * 0.72} ${w * 0.03} ${h * 0.56} ${w * 0.03} ${h * 0.34}`,
    `C${w * 0.03} ${h * 0.04} ${w * 0.4} 0 ${w * 0.5} ${h * 0.2}`,
    `C${w * 0.6} 0 ${w * 0.97} ${h * 0.04} ${w * 0.97} ${h * 0.34}`,
    `C${w * 0.97} ${h * 0.56} ${w * 0.8} ${h * 0.72} ${w * 0.5} ${h * 0.92}`,
    "Z",
  ].join(" ");
}
const PATH = heartPath(HW, HH);

export default function LikeDraw({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const likedRef = useRef(false);
  const [filled, setFilled] = useState(false);
  const [likes, setLikes] = useState(0);
  const trim = useMotionValue(0);
  const dash = useTransform(trim, (v) => `${v} 2`);
  const trimOpacity = useTransform(trim, (v) => (v > 0.001 ? 1 : 0));
  const gradID = useSvgID("draw-grad");
  const draw = ctx.n("draw");

  const toggle = (muted = false) => {
    const now = !likedRef.current;
    likedRef.current = now;
    clearAll();
    if (now) {
      setLikes((l) => l + 1);
      animate(trim, 1, anim.easeInOut(draw));
      after(draw * 0.85, () => {
        if (!likedRef.current) return;
        setFilled(true);
        if (!muted) haptics.success();
      });
    } else {
      setFilled(false);
      animate(trim, 0, delayed(anim.easeInOut(draw * 0.8), 0.1));
      haptics.tap();
    }
  };

  useAutoplay(ctx.isPreview, () => toggle(true), { every: 1.6, delay: 0.4 });

  const hold = draw * 0.85;
  const sparkT = useSince(likes, hold + 0.45);
  const sparkP = track(sparkT, 0, [linearKF(0, Math.max(hold, 0.001)), linearKF(0.01, 0.01), cubicKF(1, 0.4)]);
  const sparks = ctx.i("sparks");
  const lineWidth = ctx.n("line");

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(), width: 310, padding: "14px 18px", display: "flex", alignItems: "center", gap: 16, flexShrink: 0 }}>
        <button type="button" onClick={() => toggle()} style={{ position: "relative", width: HW + 12, height: HH + 12, flexShrink: 0 }}>
          <svg width={HW} height={HH} viewBox={`0 0 ${HW} ${HH}`} style={{ position: "absolute", left: 6, top: 6, overflow: "visible" }}>
            <defs>
              <linearGradient id={gradID} gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2={HH}>
                <stop offset="0" stopColor={Palette.pink} />
                <stop offset="1" stopColor={Palette.coral} />
              </linearGradient>
            </defs>
            <path d={PATH} fill="none" stroke={Palette.labelAlpha(0.18)} strokeWidth={1.5} strokeLinejoin="round" />
            <motion.path
              d={PATH}
              fill={`url(#${gradID})`}
              initial={false}
              animate={{ scale: filled ? 1 : 0.6, opacity: filled ? 1 : 0 }}
              transition={filled ? spring(0.35, 0.55) : anim.easeIn(0.2)}
              style={{ originX: "50%", originY: "50%", transformBox: "fill-box" }}
            />
            <motion.path
              d={PATH}
              fill="none"
              stroke={Palette.pink}
              strokeWidth={lineWidth}
              strokeLinecap="round"
              strokeLinejoin="round"
              pathLength={1}
              style={{ strokeDasharray: dash, opacity: trimOpacity }}
            />
          </svg>
          {Array.from({ length: Math.max(sparks, 0) }, (_, i) => {
            const angle = (i / Math.max(sparks, 1)) * 360;
            const visible = sparkP > 0.001 && sparkP < 0.999;
            return (
              <div
                key={i}
                style={{
                  position: "absolute",
                  left: 6 + HW / 2 - 1.5,
                  top: 6 + HH / 2 - 6,
                  width: 3,
                  height: 12,
                  borderRadius: 1.5,
                  background: i % 2 === 0 ? Palette.pink : Palette.amber,
                  opacity: visible ? 1 - sparkP * 0.9 : 0,
                  transform: `rotate(${angle}deg) translateY(${-(40 + 18 * sparkP)}px) translateY(6px) scaleY(${1 - 0.7 * sparkP}) translateY(-6px)`,
                  pointerEvents: "none",
                }}
              />
            );
          })}
        </button>
        <div style={{ display: "flex", flexDirection: "column", gap: 4, minWidth: 0 }}>
          <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {ctx.t("The quiet art of easing", "缓动的安静艺术")}
          </div>
          <BlurReplace id={filled ? "saved" : "read"} align="leading" style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500 }}>
            {filled ? (
              <span style={{ color: Palette.pink }}>{ctx.t("Saved to favourites", "已加入收藏")}</span>
            ) : (
              <span style={{ color: Palette.secondaryLabel }}>{ctx.t("8 min read", "阅读约 8 分钟")}</span>
            )}
          </BlurReplace>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the heart" zh="点击爱心" style={{ paddingBottom: 18 }} />
    </div>
  );
}
