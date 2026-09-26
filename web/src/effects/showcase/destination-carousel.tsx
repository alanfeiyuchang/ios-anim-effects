/** showcase.destination-carousel · 目的地轮播 (TravelCarousel.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, type AnimationPlaybackControls } from "motion/react";
import { Camera, Heart } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, clamp, fonts, glass, rubberBand, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { LandscapeArt, Signature, SignatureStage, signatureEyebrow } from "./signature";

const SPOTS = [
  { en: "Italy", zh: "意大利", nameEn: "Lago di Braies", nameZh: "布拉耶斯湖", shots: 126, seed: 2 },
  { en: "France", zh: "法国", nameEn: "Azure Coast", nameZh: "蔚蓝海岸", shots: 98, seed: 1 },
  { en: "Austria", zh: "奥地利", nameEn: "Nordkette", nameZh: "北链山", shots: 211, seed: 0 },
  { en: "Jordan", zh: "约旦", nameEn: "Wadi Rum", nameZh: "瓦迪拉姆", shots: 74, seed: 3 },
  { en: "Norway", zh: "挪威", nameEn: "Lofoten Nights", nameZh: "罗弗敦之夜", shots: 143, seed: 4 },
];
const COUNT = SPOTS.length;
const CARD_W = 200;
const CARD_H = 240;
/** Card width plus the stack spacing: one page of scroll. */
const PITCH = 214;
const VIEW_W = 340;
const MARGIN = (VIEW_W - CARD_W) / 2;
const MAX_OFFSET = PITCH * (COUNT - 1);

export default function DestinationCarousel({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  /** Scroll offset (content x) in points. */
  const offset = useMotionValue(0);
  const [scroll, setScroll] = useState(0);
  const [current, setCurrent] = useState(0);
  const currentRef = useRef(0);
  const quietUntil = useRef(0);
  const running = useRef<AnimationPlaybackControls | null>(null);
  const dragStart = useRef(0);

  useMotionValueEvent(offset, "change", (v) => {
    setScroll(v);
    const page = clamp(Math.round(v / PITCH), 0, COUNT - 1);
    if (page !== currentRef.current) {
      currentRef.current = page;
      setCurrent(page);
      if (performance.now() >= quietUntil.current) haptics.selection();
    }
  });

  const scrollTo = (page: number, velocity = 0, programmatic = false) => {
    running.current?.stop();
    if (programmatic) quietUntil.current = performance.now() + 800;
    running.current = animate(offset, page * PITCH, { ...spring(programmatic ? 0.55 : 0.45, programmatic ? 0.85 : 1), velocity });
  };

  const advance = () => scrollTo((currentRef.current + 1) % COUNT, 0, true);
  useAutoplay(ctx.isPreview, advance, { every: 1.8 });

  const pan = usePan({
    onStart: () => {
      running.current?.stop();
      dragStart.current = offset.get();
    },
    onChange: ({ translation }) => {
      const raw = dragStart.current - translation.x;
      offset.set(raw < 0 ? rubberBand(raw, 60) : raw > MAX_OFFSET ? MAX_OFFSET + rubberBand(raw - MAX_OFFSET, 60) : raw);
    },
    onEnd: ({ velocity }) => {
      // View-aligned targeting: the page nearest to where the fling would come to rest.
      const projected = offset.get() - velocity.x * 0.18;
      const page = clamp(Math.round(projected / PITCH), 0, COUNT - 1);
      scrollTo(page, -velocity.x);
    },
  });

  const tilt = ctx.n("tilt");
  const shrink = 1 - ctx.n("minScale");
  const parallax = ctx.n("parallax");

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "stretch", justifyContent: "center", gap: 14 }}>
        <div style={{ display: "flex", alignItems: "center", padding: "0 28px" }}>
          <span style={signatureEyebrow()}>{zh ? "热门目的地" : "Trending destinations"}</span>
          <span style={{ flex: 1 }} />
          <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, color: Signature.accent, lineHeight: "15px" }}>{zh ? "查看全部" : "See all"}</span>
        </div>
        <div {...pan} style={{ position: "relative", height: 250, overflow: "hidden", touchAction: "pan-y", cursor: "grab", flexShrink: 0 }}>
          {SPOTS.map((spot, index) => {
            const x = MARGIN + index * PITCH - scroll;
            if (x > VIEW_W + 40 || x + CARD_W < -40) return null;
            const d = clamp((x + CARD_W / 2 - VIEW_W / 2) / PITCH, -1, 1);
            return (
              <div
                key={index}
                style={{
                  position: "absolute",
                  left: x,
                  top: (250 - CARD_H) / 2,
                  width: CARD_W,
                  height: CARD_H,
                  transform: `scale(${1 - Math.abs(d) * shrink}) rotate(${d * tilt}deg)`,
                  opacity: 1 - Math.abs(d) * 0.35,
                }}
              >
                <Card spot={spot} zh={zh} shift={-d * parallax} parallax={parallax} />
              </div>
            );
          })}
        </div>
        <div style={{ display: "flex", justifyContent: "center", gap: 6 }}>
          {SPOTS.map((_, index) => {
            const active = index === current;
            return (
              <motion.div
                key={index}
                initial={false}
                animate={{ width: active ? 22 : 6 }}
                transition={spring(0.35, 0.7)}
                style={{ height: 6, borderRadius: 3, background: active ? Signature.accentGradient : white(0.25) }}
              />
            );
          })}
        </div>
        <DemoHint ctx={ctx} en="Swipe the cards" zh="左右滑动卡片" style={{ paddingTop: 4 }} />
      </div>
    </SignatureStage>
  );
}

function Card({ spot, zh, shift, parallax }: { spot: (typeof SPOTS)[number]; zh: boolean; shift: number; parallax: number }) {
  return (
    <div style={{ position: "absolute", inset: 0, borderRadius: 24, boxShadow: `0 10px 16px rgb(0 0 0 / 0.45)` }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: 24, overflow: "hidden" }}>
        <div style={{ position: "absolute", top: 0, bottom: 0, left: -parallax + shift, width: CARD_W + parallax * 2 }}>
          <LandscapeArt seed={spot.seed} />
        </div>
        <div style={{ position: "absolute", inset: 0, background: `linear-gradient(transparent 50%, rgb(0 0 0 / 0.72))` }} />
        <div style={{ position: "absolute", top: 12, right: 12, width: 32, height: 32, borderRadius: "50%", ...glass("ultraThin", "dark"), display: "grid", placeItems: "center", color: "#fff" }}>
          <Heart size={14} strokeWidth={2.6} />
        </div>
        <div style={{ position: "absolute", left: 16, right: 16, bottom: 16, display: "flex", flexDirection: "column", gap: 3 }}>
          <span style={signatureEyebrow()}>{zh ? spot.zh : spot.en}</span>
          <span style={{ fontFamily: fonts.rounded, fontSize: 20, fontWeight: 700, color: "#fff", lineHeight: "24px", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {zh ? spot.nameZh : spot.nameEn}
          </span>
          <span style={{ display: "flex", alignItems: "center", gap: 4, fontFamily: fonts.text, fontSize: 11, fontWeight: 500, color: white(0.7), lineHeight: "13px" }}>
            <Camera size={12} fill="currentColor" stroke="rgb(0 0 0 / 0.5)" strokeWidth={1.5} />
            {zh ? `${spot.shots} 张照片` : `${spot.shots} shots`}
          </span>
        </div>
      </div>
      <div style={{ position: "absolute", inset: 0, borderRadius: 24, boxShadow: `inset 0 0 0 1px ${white(0.14)}`, pointerEvents: "none" }} />
    </div>
  );
}
