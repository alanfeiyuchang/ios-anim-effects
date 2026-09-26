/** buttons.like-float · 飘心点赞 (Buttons+LikeFloat.swift) */
import { Eye } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, useAutoplay, useClock, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { LandscapeArt } from "../showcase/signature";
import { BOUNCY, HEART_PATH, cubicKF, springKF, sportHash, track, useSince } from "./_a-kit";

const CARD = 290;
const COLORS = [Palette.pink, Palette.coral, Palette.amber, Palette.red, Palette.violet];

type Heart = { id: number; born: number; seed: number };

export default function LikeFloat({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [hearts, setHearts] = useState<Heart[]>([]);
  const [taps, setTaps] = useState(0);
  const nextID = useRef(0);
  const life = ctx.n("life");

  const tap = () => {
    setTaps((t) => t + 1);
    haptics.tap();
    const id = nextID.current++;
    const heart = { id, born: performance.now() / 1000, seed: sportHash(id * 1.37) };
    setHearts((h) => [...h, heart]);
    after(life + 0.1, () => setHearts((h) => h.filter((x) => x.id !== id)));
  };

  useAutoplay(ctx.isPreview, tap, { every: 0.35, delay: 0.3 });

  useClock(hearts.length > 0, ctx.isPreview ? 30 : undefined);
  const now = performance.now() / 1000;
  const press = track(useSince(taps, 0.45), 1, [cubicKF(0.86, 0.07), springKF(1, 0.35, BOUNCY)]);
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div
        style={{
          position: "relative",
          width: CARD,
          height: CARD,
          flexShrink: 0,
          borderRadius: 26,
          overflow: "hidden",
          boxShadow: "0 10px 18px rgb(0 0 0 / 0.18)",
        }}
      >
        <LandscapeArt seed={1} />
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(transparent 50%, rgb(0 0 0 / 0.45))" }} />
        <div style={{ position: "absolute", inset: 0, padding: 16, display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 800, color: "#fff", padding: "4px 8px", borderRadius: 6, background: Palette.red }}>LIVE</span>
            <span
              style={{
                display: "flex",
                alignItems: "center",
                gap: 4,
                fontSize: 12,
                lineHeight: "14px",
                fontWeight: 600,
                color: "#fff",
                padding: "4px 8px",
                borderRadius: 12,
                background: "rgb(0 0 0 / 0.35)",
                fontVariantNumeric: "tabular-nums",
              }}
            >
              <Eye size={13} strokeWidth={2.4} />
              12.4K
            </span>
          </div>
          <div style={{ flex: 1 }} />
          <div style={{ display: "flex", flexDirection: "column", gap: 2, color: "#fff", paddingRight: 70 }}>
            <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{ctx.t("Sunset session", "日落现场")}</div>
            <div style={{ display: "flex", fontSize: 12, lineHeight: "16px", fontWeight: 600, opacity: 0.85 }}>
              <NumericText value={12480 + taps} />
              <span style={{ whiteSpace: "pre" }}>{zh ? " 次点赞" : " likes"}</span>
            </div>
          </div>
        </div>
        <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
          {hearts.map((h) => (
            <FloatingHeart key={h.id} heart={h} now={now} life={life} rise={ctx.n("rise")} sway={ctx.n("sway")} />
          ))}
        </div>
        <button
          type="button"
          onClick={tap}
          style={{
            position: "absolute",
            right: 16,
            bottom: 16,
            width: 52,
            height: 52,
            borderRadius: "50%",
            background: `linear-gradient(${Palette.pink}, ${Palette.coral})`,
            boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.35), 0 5px 10px rgb(255 95 162 / 0.5)",
            display: "grid",
            placeItems: "center",
            transform: `scale(${press})`,
          }}
        >
          <svg viewBox="0 0 24 24" width={27} height={27}>
            <path d={HEART_PATH} fill="#fff" />
          </svg>
        </button>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the heart quickly" zh="快速连点爱心" style={{ paddingBottom: 14 }} />
    </div>
  );
}

function FloatingHeart({ heart, now, life, rise, sway }: { heart: Heart; now: number; life: number; rise: number; sway: number }) {
  const age = now - heart.born;
  const p = Math.min(Math.max(age / life, 0), 1);
  const pop = Math.min(p / 0.15, 1);
  const scale = (0.4 + 0.6 * pop) * (0.8 + 0.4 * heart.seed);
  const frequency = 2.2 + heart.seed * 1.6;
  const wave = Math.sin(p * frequency * Math.PI + heart.seed * 6);
  const x = wave * sway;
  const y = -rise * p;
  const fade = p < 0.6 ? 1 : Math.max(0, 1 - (p - 0.6) / 0.4);
  const color = COLORS[Math.floor(heart.seed * 100) % COLORS.length];
  return (
    <div
      style={{
        position: "absolute",
        left: CARD - 16 - 26 - 14,
        top: CARD - 16 - 26 - 14,
        width: 28,
        height: 28,
        transform: `translate(${x}px, ${y}px) rotate(${wave * 14}deg) scale(${scale})`,
        opacity: fade,
        filter: "drop-shadow(0 1px 3px rgb(0 0 0 / 0.2))",
      }}
    >
      <svg viewBox="0 0 24 24" width={28} height={28}>
        <path d={HEART_PATH} fill={color} />
      </svg>
    </div>
  );
}
