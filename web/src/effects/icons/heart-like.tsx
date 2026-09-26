/** icons.heart-like · 点赞爱心迸发 (Icons+HeartLike.swift) */
import { MessageCircle, Send } from "lucide-react";
import { useCallback, useState } from "react";
import {
  DemoHint,
  NumericText,
  Palette,
  demoCard,
  fonts,
  useAutoplay,
  useDoubleTap,
  useHaptics,
  white,
  type DemoProps,
} from "../../kit";
import { C, Glyph, L, Replace, S, SPRINGS, SYM, sym, track, useSince } from "./_icons-kit";

const POP_SCALE = [S(1.15, 0.22, SPRINGS.bouncy), S(1.0, 0.28, SPRINGS.snappy), L(1.0, 0.2), C(1.3, 0.2)];
const POP_OPACITY = [L(1, 0.08), L(1, 0.62), C(0, 0.2)];
const HEART_SCALE = [C(0.7, 0.1), S(1.25, 0.15, SPRINGS.snappy), S(1.0, 0.35, SPRINGS.bouncy)];
const HEART_BURST = [L(0, 0.1), C(1, 0.55)];

export default function HeartLike({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [liked, setLiked] = useState(false);
  const [count, setCount] = useState(1284);
  const [bursts, setBursts] = useState(0);
  const [pops, setPops] = useState(0);

  const tint = ctx.i("color") === 1 ? Palette.pink : ctx.i("color") === 2 ? Palette.violet : Palette.red;

  const toggle = useCallback(() => {
    const now = !liked;
    setLiked(now);
    setCount((c) => c + (now ? 1 : -1));
    if (now) {
      setBursts((b) => b + 1);
      haptics.tap("medium");
    } else {
      haptics.selection();
    }
  }, [liked, haptics]);

  const doubleTap = useCallback(() => {
    setPops((p) => p + 1);
    if (!liked) toggle();
    else haptics.tap("soft");
  }, [liked, toggle, haptics]);
  const onDoubleTap = useDoubleTap(doubleTap);

  useAutoplay(ctx.isPreview, () => (liked ? toggle() : doubleTap()), { every: 1.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ ...demoCard(24), width: 280, display: "flex", flexDirection: "column" }}>
        <div
          onPointerUp={onDoubleTap}
          style={{
            position: "relative",
            height: 158,
            borderRadius: "24px 24px 0 0",
            overflow: "hidden",
            background: `linear-gradient(135deg, ${Palette.amber}, ${Palette.coral}, ${Palette.pink})`,
            cursor: "pointer",
          }}
        >
          <svg width={130} height={76} viewBox="0 0 130 76" style={{ position: "absolute", left: 22, bottom: -14 }}>
            <mask id="heart-like-snow">
              <rect width={130} height={76} fill="#fff" />
              <path d="M57 30l7 4.5 6.5-5 6.5 5 6.5-5 7 4.5M16 45l5.5 3.5 5-4 5 4 5-3.5" fill="none" stroke="#000" strokeWidth={3.2} strokeLinejoin="round" strokeLinecap="round" />
            </mask>
            <path
              d="M24 76 71 8.5q5-6.5 10 0L130 76ZM0 76 29 31q4-6 8 0L67 76Z"
              fill={white(0.35)}
              mask="url(#heart-like-snow)"
            />
          </svg>
          <div style={{ position: "absolute", right: 22, top: 22, width: 34, height: 34, borderRadius: "50%", background: white(0.55), filter: "blur(2px)" }} />
          <PhotoPop trigger={pops} />
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 4, paddingLeft: 4, paddingRight: 18, color: Palette.secondaryLabel }}>
          <button type="button" onClick={toggle} style={{ position: "relative", width: 58, height: 58, flexShrink: 0 }}>
            <div style={{ position: "absolute", left: -11, top: -11, transform: "scale(0.72)", width: 80, height: 80 }}>
              <HeartFace liked={liked} trigger={bursts} tint={tint} radius={ctx.n("radius")} particles={Math.max(ctx.i("count"), 1)} />
            </div>
          </button>
          <NumericText
            value={count}
            text={count.toLocaleString("en-US")}
            style={{ fontFamily: fonts.rounded, fontSize: 17, fontWeight: 600, color: liked ? tint : Palette.label, transition: "color 0.35s" }}
          />
          <div style={{ flex: 1 }} />
          <MessageCircle size={21} strokeWidth={2} style={{ transform: "scaleX(-1)" }} />
          <Send size={20} strokeWidth={2} style={{ marginLeft: 14 }} />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap the heart or double-tap the photo" zh="点击爱心或双击图片" />
    </div>
  );
}


function PhotoPop({ trigger }: { trigger: number }) {
  const t = useSince(trigger, 0.9);
  if (t < 0) return null;
  const scale = track(t, 0, POP_SCALE);
  const opacity = track(t, 0, POP_OPACITY);
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", pointerEvents: "none" }}>
      <div style={{ color: "#fff", transform: `scale(${scale})`, opacity, filter: "drop-shadow(0 4px 10px rgb(0 0 0 / 0.18))" }}>
        <Glyph def={SYM.heartFill} size={sym(64)} />
      </div>
    </div>
  );
}

function HeartFace({ liked, trigger, tint, radius, particles }: { liked: boolean; trigger: number; tint: string; radius: number; particles: number }) {
  const t = useSince(trigger, 0.7);
  const scale = t < 0 ? 1 : track(t, 1, HEART_SCALE);
  const p = t < 0 ? 0 : track(t, 0, HEART_BURST);
  const active = p > 0 && p < 1;
  const fade = active ? Math.sin(p * Math.PI) : 0;
  return (
    <div style={{ position: "relative", width: 80, height: 80 }}>
      <div
        style={{
          position: "absolute",
          left: 10,
          top: 10,
          width: 60,
          height: 60,
          borderRadius: "50%",
          boxShadow: `inset 0 0 0 ${3 * (1 - p) + 0.5}px color-mix(in srgb, ${tint} ${60 * (1 - p)}%, transparent)`,
          transform: `scale(${0.4 + p * 1.6})`,
          opacity: active ? 1 : 0,
        }}
      />
      {Array.from({ length: particles }, (_, i) => {
        const angle = (i / particles) * 2 * Math.PI - Math.PI / 2;
        const distance = 18 + p * radius;
        const size = 8 * (1 - p) + 2;
        const color = i % 2 === 0 ? tint : Palette.spectrum[i % Palette.spectrum.length];
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: 40 - size / 2 + Math.cos(angle) * distance,
              top: 40 - size / 2 + Math.sin(angle) * distance,
              width: size,
              height: size,
              borderRadius: "50%",
              background: color,
              opacity: fade,
            }}
          />
        );
      })}
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", transform: `scale(${scale})` }}>
        <Replace k={liked ? "on" : "off"}>
          <div style={{ color: liked ? tint : Palette.secondaryLabel }}>
            <Glyph def={liked ? SYM.heartFill : SYM.heart} size={Math.round(48 * 1.1)} weight={1.1} />
          </div>
        </Replace>
      </div>
    </div>
  );
}
