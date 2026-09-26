/** buttons.like-flip · 翻币爱心 (Buttons+LikeFlip.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, demoCard, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BOUNCY, HEART_PATH, cubicKF, linearKF, springKF, track, useSince } from "./_a-kit";

const COIN = 92;

export default function LikeFlip({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const angle = useMotionValue(0);
  const target = useRef(0);
  const [flips, setFlips] = useState(0);
  const flipsRef = useRef(0);
  const [saves, setSaves] = useState(312);
  const liked = flips % 2 === 1;

  const flip = (muted = false) => {
    flipsRef.current += 1;
    const nowLiked = flipsRef.current % 2 === 1;
    setFlips(flipsRef.current);
    target.current += 180;
    animate(angle, target.current, spring(ctx.n("response"), 0.7));
    setSaves((s) => s + (nowLiked ? 1 : -1));
    after(0.48, () => {
      if (muted) return;
      if (nowLiked) haptics.success();
      else haptics.tap();
    });
  };

  useAutoplay(ctx.isPreview, () => flip(true), { every: 1.5, delay: 0.4 });

  const hop = ctx.n("hop");
  const t = useSince(flips, 0.95);
  const lift = track(t, 0, [cubicKF(hop, 0.25), cubicKF(0, 0.25), cubicKF(0, 0.3)]);
  const squash = track(t, 1, [linearKF(1, 0.5), cubicKF(0.92, 0.08), springKF(1, 0.35, BOUNCY)]);
  const glint = track(t, -1, [linearKF(-1, 0.15), cubicKF(1, 0.3)]);
  const shadow = track(t, 1, [cubicKF(0.6, 0.25), cubicKF(1, 0.25)]);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), width: 280, padding: 20, display: "flex", flexDirection: "column", alignItems: "center", gap: 12, flexShrink: 0 }}>
        <div style={{ height: 150, display: "flex", alignItems: "flex-end" }}>
          <button type="button" onClick={() => flip()} style={{ position: "relative", width: COIN, height: COIN }}>
            <div
              style={{
                position: "absolute",
                left: COIN / 2 - (70 * shadow) / 2,
                bottom: -10,
                width: 70 * shadow,
                height: 12,
                borderRadius: "50%",
                background: `rgb(0 0 0 / ${0.18 * shadow})`,
                filter: "blur(4px)",
              }}
            />
            <div style={{ position: "absolute", inset: 0, transformOrigin: "50% 100%", transform: `translateY(${-lift}px) scale(1, ${squash})` }}>
              <CoinFaces angle={angle} horizontal={ctx.i("axis") === 1} />
              <div style={{ position: "absolute", inset: 0, borderRadius: "50%", overflow: "hidden", pointerEvents: "none" }}>
                <div
                  style={{
                    position: "absolute",
                    left: COIN / 2 - 13,
                    top: -20,
                    width: 26,
                    height: COIN + 40,
                    background: "linear-gradient(90deg, transparent, rgb(255 255 255 / 0.6), transparent)",
                    transform: `translateX(${glint * 70}px) rotate(20deg)`,
                  }}
                />
              </div>
            </div>
          </button>
        </div>
        <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{ctx.t("Lemon ricotta pancakes", "柠檬乳清松饼")}</div>
        <div style={{ display: "flex", fontSize: 15, lineHeight: "20px", color: liked ? Palette.pink : Palette.secondaryLabel, transition: "color 0.3s" }}>
          <NumericText value={saves} />
          <span style={{ whiteSpace: "pre" }}>{ctx.t(" cooks loved this", " 位厨友喜欢")}</span>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the coin" zh="点击硬币" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function CoinFaces({ angle, horizontal }: { angle: ReturnType<typeof useMotionValue<number>>; horizontal: boolean }) {
  const [showBack, setShowBack] = useState(false);
  useMotionValueEvent(angle, "change", (a) => {
    const r = ((a % 360) + 360) % 360;
    setShowBack(r > 90 && r < 270);
  });
  const rotate = useTransform(angle, (a) => (horizontal ? `perspective(${COIN / 0.6}px) rotateX(${-a}deg)` : `perspective(${COIN / 0.6}px) rotateY(${a}deg)`));
  const face = { position: "absolute" as const, inset: 0, borderRadius: "50%", display: "grid", placeItems: "center" };
  return (
    <motion.div style={{ position: "absolute", inset: 0, transform: rotate }}>
      <div
        style={{
          ...face,
          opacity: showBack ? 0 : 1,
          background: `linear-gradient(${Palette.elevated}, ${Palette.surface})`,
          boxShadow: `inset 0 0 0 3px ${Palette.labelAlpha(0.12)}, 0 3px 6px rgb(0 0 0 / 0.12)`,
        }}
      >
        <svg viewBox="0 0 24 24" width={44} height={44}>
          <path d={HEART_PATH} fill="none" stroke={Palette.secondaryLabel} strokeWidth={1.9} strokeLinejoin="round" />
        </svg>
      </div>
      <div
        style={{
          ...face,
          opacity: showBack ? 1 : 0,
          transform: horizontal ? "rotateX(180deg)" : "rotateY(180deg)",
          background: `linear-gradient(135deg, ${Palette.pink}, ${Palette.coral})`,
          boxShadow: "inset 0 0 0 3px rgb(255 255 255 / 0.35), 0 4px 8px rgb(255 95 162 / 0.4)",
        }}
      >
        <svg viewBox="0 0 24 24" width={44} height={44}>
          <path d={HEART_PATH} fill="#fff" />
        </svg>
      </div>
    </motion.div>
  );
}
