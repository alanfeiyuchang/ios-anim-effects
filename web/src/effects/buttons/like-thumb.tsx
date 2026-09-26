/** buttons.like-thumb · 点赞手势回弹 (Buttons+LikeThumb.swift) */
import { ThumbsUp } from "lucide-react";
import { useState } from "react";
import { DemoHint, NumericText, Palette, alpha, demoCard, fonts, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BOUNCY, SymbolReplace, cubicKF, linearKF, springKF, track, useSince } from "./_a-kit";

export default function LikeThumb({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [liked, setLiked] = useState(false);
  const [count, setCount] = useState(41);
  const [flicks, setFlicks] = useState(0);

  const toggle = (muted = false) => {
    const now = !liked;
    setLiked(now);
    setCount((c) => c + (now ? 1 : -1));
    if (!now) {
      haptics.tap("soft");
      return;
    }
    setFlicks((f) => f + 1);
    // Autoplay mutes haptics only while the action runs, so remember that for the delayed tick.
    after(0.26, () => !muted && haptics.tap());
  };

  useAutoplay(ctx.isPreview, () => toggle(true), { every: 1.3, delay: 0.4 });

  const t = useSince(flicks, 1);
  const windup = ctx.n("windup");
  const flick = ctx.n("flick");
  const angle = track(t, 0, [cubicKF(-windup, 0.12), cubicKF(12, 0.14), springKF(0, 0.5, BOUNCY)]);
  const scale = track(t, 1, [cubicKF(0.88, 0.12), cubicKF(flick, 0.14), springKF(1, 0.5, BOUNCY)]);
  const lift = track(t, 0, [cubicKF(0, 0.12), cubicKF(6, 0.14), springKF(0, 0.5, BOUNCY)]);
  const rise = track(t, 0, [linearKF(0, 0.2), cubicKF(36, 0.7)]);
  const floatScale = track(t, 0.6, [linearKF(0.6, 0.2), springKF(1, 0.3, BOUNCY)]);
  const floatOpacity = t < 0 ? 0 : track(t, 0, [linearKF(0, 0.2), linearKF(1, 0.1), linearKF(1, 0.25), linearKF(0, 0.35)]);
  const color = liked ? Palette.blue : Palette.secondaryLabel;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(), width: 300, padding: 18, display: "flex", flexDirection: "column", gap: 14, flexShrink: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 34, height: 34, borderRadius: "50%", background: Palette.ocean, display: "grid", placeItems: "center", fontSize: 12, fontWeight: 700, color: "#fff" }}>
            JK
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label }}>Jonas Kim</div>
            <div style={{ fontSize: 11, lineHeight: "13px", color: Palette.secondaryLabel }}>{ctx.t("Replied · 12 min", "回复于 12 分钟前")}</div>
          </div>
        </div>
        <div style={{ fontSize: 15, lineHeight: "20px", color: Palette.label }}>
          {ctx.t("The easing on the second screen is perfect. Ship it!", "第二屏的缓动曲线太完美了，直接上线吧！")}
        </div>
        <div style={{ display: "flex", justifyContent: "flex-end" }}>
          <button
            type="button"
            onClick={() => toggle()}
            style={{
              width: 116,
              height: 44,
              borderRadius: 22,
              background: liked ? alpha(Palette.blue, 0.12) : Palette.labelAlpha(0.05),
              transition: "background 0.3s",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
            }}
          >
            <span style={{ position: "relative", width: 28, height: 28, display: "grid", placeItems: "center" }}>
              <span
                style={{
                  display: "grid",
                  transformOrigin: "0% 100%",
                  transform: `translateY(${-lift}px) rotate(${angle}deg) scale(${scale})`,
                  color,
                  transition: "color 0.3s",
                }}
              >
                <SymbolReplace id={liked ? "on" : "off"}>
                  <ThumbsUp size={22} strokeWidth={2.3} fill={liked ? "currentColor" : "none"} />
                </SymbolReplace>
              </span>
              {ctx.b("plusOne") && (
                <span
                  style={{
                    position: "absolute",
                    left: "50%",
                    top: 3,
                    transform: `translate(-50%, ${-rise}px) scale(${floatScale})`,
                    opacity: floatOpacity,
                    fontFamily: fonts.rounded,
                    fontSize: 13,
                    lineHeight: "16px",
                    fontWeight: 800,
                    color: Palette.blue,
                    whiteSpace: "nowrap",
                    pointerEvents: "none",
                  }}
                >
                  +1
                </span>
              )}
            </span>
            <NumericText value={count} style={{ fontSize: 15, fontWeight: 600, color, transition: "color 0.3s" }} />
          </button>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the thumb" zh="点击大拇指" style={{ paddingBottom: 18 }} />
    </div>
  );
}
