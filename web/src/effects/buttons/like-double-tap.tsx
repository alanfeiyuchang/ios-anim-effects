/** buttons.like-double-tap · 双击点赞飞入 (Buttons+LikeDoubleTap.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { Bookmark } from "lucide-react";
import { useCallback, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, demoCard, spring, useAutoplay, useDoubleTap, useHaptics, useTimeouts, type DemoProps, type Point } from "../../kit";
import { LandscapeArt } from "../showcase/signature";
import { BOUNCY, HEART_PATH, SymbolReplace, cubicKF, springKF, sportHash, track, useSince } from "./_a-kit";

const PHOTO_W = 300;
const PHOTO_H = 196;
/** Centre of the small heart button in card coordinates (row starts 10 pt under the photo). */
const TARGET = { x: 16 + 22, y: 196 + 10 + 22 };
const PREVIEW_POINTS: Point[] = [
  { x: 190, y: 80 },
  { x: 110, y: 110 },
  { x: 220, y: 130 },
];

export default function LikeDoubleTap({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [liked, setLiked] = useState(false);
  const likedRef = useRef(false);
  const [count, setCount] = useState(864);
  const [pops, setPops] = useState(0);
  const heartX = useMotionValue(150);
  const heartY = useMotionValue(98);
  const heartScale = useMotionValue(0);
  const heartTilt = useMotionValue(0);
  const [visible, setVisible] = useState(false);
  const busy = useRef(false);
  const step = useRef(0);

  const doubleTap = (p: Point, muted = false) => {
    if (busy.current) return;
    busy.current = true;
    const hang = ctx.n("hang");
    const flight = ctx.n("flight");
    for (const mv of [heartX, heartY, heartScale, heartTilt]) mv.stop();
    heartX.set(p.x);
    heartY.set(p.y);
    heartScale.set(0);
    heartTilt.set(sportHash(step.current + p.x) * 24 - 12);
    setVisible(true);
    if (!muted) haptics.tap("medium");
    after(0.02, () => {
      animate(heartScale, 1, spring(0.35, 0.5));
      after(0.35 + hang, () => {
        animate(heartX, TARGET.x, anim.easeIn(flight));
        animate(heartScale, 0.22, anim.easeIn(flight));
        animate(heartTilt, 0, anim.easeIn(flight));
        animate(heartY, TARGET.y, anim.easeOut(flight));
        after(flight, () => {
          setVisible(false);
          heartScale.set(0);
          if (!likedRef.current) {
            likedRef.current = true;
            setLiked(true);
            setCount((c) => c + 1);
          }
          setPops((n) => n + 1);
          if (!muted) haptics.success();
          busy.current = false;
        });
      });
    });
  };

  const tapSmallHeart = () => {
    const now = !likedRef.current;
    likedRef.current = now;
    setLiked(now);
    setCount((c) => c + (now ? 1 : -1));
    if (now) setPops((n) => n + 1);
    haptics.tap();
  };

  const doubleTapRef = useRef(doubleTap);
  doubleTapRef.current = doubleTap;
  const onDouble = useDoubleTap(useCallback((p: Point) => doubleTapRef.current(p), []));

  useAutoplay(ctx.isPreview, () => {
    if (likedRef.current && step.current % 2 === 1) tapSmallHeart();
    else doubleTap(PREVIEW_POINTS[step.current % PREVIEW_POINTS.length], true);
    step.current += 1;
  }, { every: 2.4, delay: 0.4 });

  const popScale = track(useSince(pops, 0.55), 1, [cubicKF(1.3, 0.1), springKF(1, 0.45, BOUNCY)]);
  const size = ctx.n("size");
  const svgSize = size * 1.3;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), position: "relative", width: PHOTO_W, flexShrink: 0, display: "flex", flexDirection: "column", gap: 10 }}>
        <div
          onPointerUp={onDouble}
          style={{ position: "relative", width: PHOTO_W, height: PHOTO_H, borderRadius: "24px 24px 0 0", overflow: "hidden", cursor: "pointer" }}
        >
          <LandscapeArt seed={0} />
        </div>
        <div style={{ height: 44, padding: "0 16px", marginBottom: 12, display: "flex", alignItems: "center", gap: 8 }}>
          <button type="button" onClick={tapSmallHeart} style={{ width: 44, height: 44, display: "grid", placeItems: "center" }}>
            <span style={{ display: "grid", transform: `scale(${popScale})` }}>
              <SymbolReplace id={liked ? "on" : "off"}>
                <svg viewBox="0 0 24 24" width={30} height={30} style={{ overflow: "visible" }}>
                  {liked ? (
                    <path d={HEART_PATH} fill={Palette.pink} />
                  ) : (
                    <path d={HEART_PATH} fill="none" stroke={Palette.label} strokeWidth={1.9} strokeLinejoin="round" />
                  )}
                </svg>
              </SymbolReplace>
            </span>
          </button>
          <div style={{ display: "flex", fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label }}>
            <NumericText value={count} />
            <span style={{ whiteSpace: "pre" }}>{ctx.t(" likes", " 次赞")}</span>
          </div>
          <div style={{ flex: 1 }} />
          <Bookmark size={21} strokeWidth={2} color={Palette.secondaryLabel} />
        </div>
        <motion.div
          style={{
            position: "absolute",
            left: -svgSize / 2,
            top: -svgSize / 2,
            width: svgSize,
            height: svgSize,
            x: heartX,
            y: heartY,
            rotate: heartTilt,
            scale: heartScale,
            opacity: visible ? 1 : 0,
            pointerEvents: "none",
            filter: "drop-shadow(0 4px 10px rgb(0 0 0 / 0.3))",
          }}
        >
          <svg viewBox="0 0 24 24" width={svgSize} height={svgSize}>
            <path d={HEART_PATH} fill="#fff" />
          </svg>
        </motion.div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Double-tap the photo" zh="双击照片" style={{ paddingBottom: 14 }} />
    </div>
  );
}
