/** buttons.like-burst · 点赞爆发 (Buttons+LikeBurst.swift) */
import { MessageSquare, Send } from "lucide-react";
import { useState } from "react";
import { DemoHint, NumericText, Palette, alpha, demoCard, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { LandscapeArt } from "../showcase/signature";
import { BOUNCY, HEART_PATH, SNAPPY, SymbolReplace, cubicKF, linearKF, moveKF, springKF, track, useSince, useSvgID } from "./_a-kit";

export default function LikeBurst({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [liked, setLiked] = useState(false);
  const [count, setCount] = useState(128);
  const [bursts, setBursts] = useState(0);
  const gradID = useSvgID("burst-grad");

  const toggle = () => {
    const now = !liked;
    setLiked(now);
    setCount((c) => c + (now ? 1 : -1));
    if (now) {
      setBursts((b) => b + 1);
      haptics.success();
    } else haptics.tap();
  };

  useAutoplay(ctx.isPreview, toggle, { every: 1.4, delay: 0.4 });

  const t = useSince(bursts, 0.8);
  const overshoot = ctx.n("overshoot");
  const scale = track(t, 1, [cubicKF(0.6, 0.1), springKF(overshoot, 0.18, SNAPPY), springKF(1, 0.5, BOUNCY)]);
  const frame = {
    progress: track(t, 0, [moveKF(0), cubicKF(1, 0.6)]),
    ring: track(t, 0, [moveKF(0), cubicKF(1, 0.45)]),
    opacity: t < 0 ? 0 : track(t, 1, [moveKF(1), linearKF(1, 0.3), linearKF(0, 0.3)]),
  };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(), width: 300, padding: 16, display: "flex", flexDirection: "column", gap: 12, flexShrink: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div
            style={{
              width: 34,
              height: 34,
              borderRadius: "50%",
              background: Palette.sunset,
              display: "grid",
              placeItems: "center",
              fontSize: 12,
              fontWeight: 700,
              color: "#fff",
            }}
          >
            MC
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
            <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label }}>Mia Chen</div>
            <div style={{ fontSize: 11, lineHeight: "13px", color: Palette.secondaryLabel }}>{ctx.t("2 h · Nordkette", "2 小时前 · Nordkette")}</div>
          </div>
        </div>
        <div style={{ fontSize: 13, lineHeight: "18px", color: Palette.label }}>
          {ctx.t("First powder day of the season. Who's in tomorrow?", "今季第一场粉雪，明天谁一起？")}
        </div>
        <div style={{ position: "relative", height: 92, borderRadius: 14, overflow: "hidden" }}>
          <LandscapeArt seed={2} />
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ position: "relative", width: 60, height: 60, zIndex: 1 }}>
            <BurstLayer frame={frame} count={ctx.i("particles")} radius={ctx.n("radius")} seed={bursts} />
            <button
              type="button"
              onClick={toggle}
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: "50%",
                background: liked ? alpha(Palette.pink, 0.12) : Palette.labelAlpha(0.05),
                display: "grid",
                placeItems: "center",
                transition: "background 0.3s",
              }}
            >
              <span style={{ display: "grid", transform: `scale(${scale})` }}>
                <SymbolReplace id={liked ? "on" : "off"}>
                  <svg viewBox="0 0 24 24" width={32} height={32} style={{ overflow: "visible" }}>
                    <defs>
                      <linearGradient id={gradID} x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0" stopColor={Palette.pink} />
                        <stop offset="1" stopColor={Palette.coral} />
                      </linearGradient>
                    </defs>
                    {liked ? (
                      <path d={HEART_PATH} fill={`url(#${gradID})`} />
                    ) : (
                      <path d={HEART_PATH} fill="none" stroke={Palette.secondaryLabel} strokeWidth={1.9} strokeLinejoin="round" />
                    )}
                  </svg>
                </SymbolReplace>
              </span>
            </button>
          </div>
          <NumericText
            value={count}
            style={{ fontSize: 15, fontWeight: 600, color: liked ? Palette.pink : Palette.secondaryLabel, transition: "color 0.3s" }}
          />
          <div style={{ flex: 1 }} />
          <div style={{ display: "flex", alignItems: "center", gap: 5, fontSize: 13, fontWeight: 500, color: Palette.secondaryLabel, fontVariantNumeric: "tabular-nums" }}>
            <MessageSquare size={15} strokeWidth={2} />
            24
          </div>
          <Send size={15} strokeWidth={2} color={Palette.secondaryLabel} />
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the heart to like the post" zh="点击爱心为动态点赞" style={{ paddingBottom: 16 }} />
    </div>
  );
}

function BurstLayer({ frame, count, radius, seed }: { frame: { progress: number; ring: number; opacity: number }; count: number; radius: number; seed: number }) {
  const n = Math.max(count, 1);
  const noise = (index: number, channel: number) => {
    const v = Math.sin(seed * 91.7 + index * 12.9898 + channel * 78.233) * 43758.5453;
    return v - Math.floor(v);
  };
  const ringSize = 40 + 110 * frame.ring;
  const particle = (index: number, inner: boolean) => {
    const step = (2 * Math.PI) / n;
    const channel = inner ? 3 : 0;
    const jitter = (noise(index, channel) - 0.5) * ((24 * Math.PI) / 180);
    const angle = index * step - Math.PI / 2 + (inner ? step / 2 : 0) + jitter;
    const reach = 0.75 + 0.4 * noise(index, channel + 1);
    const base = inner ? 24 + radius * 0.5 : 30 + radius;
    const distance = base * reach * frame.progress;
    const size = (inner ? 5 : 7) + noise(index, channel + 2) * (inner ? 3 : 4);
    const color = Palette.spectrum[(index + (inner ? 3 : 0)) % Palette.spectrum.length];
    const s = 1 - 0.6 * frame.progress;
    return (
      <div
        key={`${index}-${inner}`}
        style={{
          position: "absolute",
          left: 30 - size / 2,
          top: 30 - size / 2,
          width: size,
          height: size,
          borderRadius: "50%",
          background: color,
          transform: `translate(${Math.cos(angle) * distance}px, ${Math.sin(angle) * distance}px) scale(${s})`,
        }}
      />
    );
  };
  return (
    <div style={{ position: "absolute", inset: 0, opacity: frame.opacity, pointerEvents: "none" }}>
      <div
        style={{
          position: "absolute",
          left: 30 - ringSize / 2,
          top: 30 - ringSize / 2,
          width: ringSize,
          height: ringSize,
          borderRadius: "50%",
          boxShadow: `inset 0 0 0 ${Math.max(0.5, 12 * (1 - frame.ring))}px ${Palette.pink}`,
          opacity: 1 - frame.ring,
        }}
      />
      {Array.from({ length: n }, (_, i) => [particle(i, false), particle(i, true)])}
    </div>
  );
}
