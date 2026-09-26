/** buttons.like-liquid · 液态爱心注满 (Buttons+LikeLiquid.swift) */
import { animate, useMotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, useAutoplay, useClock, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BOUNCY, HEART_PATH, cubicKF, linearKF, springKF, track, trackDuration, useSince, useSvgID } from "./_a-kit";

const BOX = 96;
// HEART_PATH spans x 2.2…21.8, y 3.5…20.6: scaled to fit the 96 pt box like `.resizable().scaledToFit()`.
const K = BOX / 19.6;
const HEART_TRANSFORM = `translate(${-2.2 * K} ${(BOX - 17.1 * K) / 2 - 3.5 * K}) scale(${K})`;

function wavePath(level: number, phase: number, amplitude: number): string {
  if (level <= 0.001) return "";
  const calm = Math.sin(level * Math.PI);
  const height = amplitude * calm + 1;
  const surface = BOX - BOX * level;
  let d = `M0 ${BOX}`;
  for (let step = 0; step <= 40; step++) {
    const t = step / 40;
    const y = surface + Math.sin(t * 4 * Math.PI + phase) * height;
    d += ` L${(BOX * t).toFixed(2)} ${y.toFixed(2)}`;
  }
  return d + ` L${BOX} ${BOX} Z`;
}

export default function LikeLiquid({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [liked, setLiked] = useState(false);
  const likedRef = useRef(false);
  const [counted, setCounted] = useState(false);
  const [gulps, setGulps] = useState(0);
  const [waveActive, setWaveActive] = useState(false);
  const generation = useRef(0);
  const level = useMotionValue(0);
  const fill = ctx.n("duration");
  const clipID = useSvgID("liquid-clip");
  const gradID = useSvgID("liquid-grad");

  const toggle = (muted = false) => {
    const now = !likedRef.current;
    likedRef.current = now;
    setLiked(now);
    generation.current += 1;
    const current = generation.current;
    setWaveActive(true);
    animate(level, now ? 1 : 0, anim.easeInOut(fill));
    if (now) {
      setGulps((g) => g + 1);
      after(fill * 0.9, () => {
        if (generation.current !== current || !likedRef.current) return;
        setCounted(true);
        if (!muted) haptics.success();
      });
    } else {
      setCounted(false);
      haptics.tap();
      after(fill + 0.1, () => {
        if (generation.current !== current || likedRef.current) return;
        setWaveActive(false);
      });
    }
  };

  useAutoplay(ctx.isPreview, () => toggle(true), { every: 1.9, delay: 0.4 });

  // TimelineView(.animation(paused: !waveActive)): the wave clock only ticks while there is liquid.
  const clock = useClock(waveActive, ctx.isPreview ? 30 : undefined);
  const [, force] = useState(0);
  useEffect(() => level.on("change", () => force((n) => n + 1)), [level]);
  const phase = ((Date.now() / 1000) % 1400) / 1.4 * ctx.n("speed") * 2 * Math.PI;
  void clock;

  const gulp = [linearKF(1, fill * 0.9), cubicKF(1.12, 0.12), cubicKF(0.96, 0.12), springKF(1, 0.4, BOUNCY)];
  const scale = track(useSince(gulps, trackDuration(gulp)), 1, gulp);
  const count = 2318 + (counted ? 1 : 0);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <button
          type="button"
          onClick={() => toggle()}
          style={{ width: 150, height: 150, borderRadius: "50%", background: Palette.labelAlpha(0.05), display: "grid", placeItems: "center" }}
        >
          <svg width={BOX} height={BOX} viewBox={`0 0 ${BOX} ${BOX}`} style={{ overflow: "visible", transform: `scale(${scale})` }}>
            <defs>
              <clipPath id={clipID}>
                <path d={HEART_PATH} transform={HEART_TRANSFORM} />
              </clipPath>
              <linearGradient id={gradID} gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2={BOX}>
                <stop offset="0" stopColor={Palette.pink} />
                <stop offset="1" stopColor={Palette.coral} />
              </linearGradient>
            </defs>
            <path d={wavePath(level.get(), phase, ctx.n("amplitude"))} fill={`url(#${gradID})`} clipPath={`url(#${clipID})`} />
            <path
              d={HEART_PATH}
              transform={HEART_TRANSFORM}
              fill="none"
              stroke={liked ? Palette.pink : Palette.secondaryLabel}
              strokeWidth={1.25}
              strokeLinejoin="round"
              style={{ transition: "stroke 0.2s" }}
            />
          </svg>
        </button>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
          <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{ctx.t("Midnight Drive", "午夜兜风")}</div>
          <div style={{ display: "flex", fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel }}>
            <NumericText value={count} />
            <span style={{ whiteSpace: "pre" }}>{ctx.t(" likes", " 人喜欢")}</span>
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the heart" zh="点击爱心" style={{ paddingBottom: 18 }} />
    </div>
  );
}
