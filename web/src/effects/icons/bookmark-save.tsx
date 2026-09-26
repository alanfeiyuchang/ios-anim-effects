/** icons.bookmark-save · 书签丝带 (Icons+BookmarkSave.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, demoCard, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { C, L, S, SPRINGS, track, useSince } from "./_icons-kit";

const W = 44;
const H = 58;
const RIBBON = (() => {
  const r = 5;
  const notch = H * 0.22;
  return `M0 ${r}Q0 0 ${r} 0H${W - r}Q${W} 0 ${W} ${r}V${H}L${W / 2} ${H - notch}L0 ${H}Z`;
})();

export default function BookmarkSave({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [saved, setSaved] = useState(false);
  const [saves, setSaves] = useState(0);
  const [unsaves, setUnsaves] = useState(0);
  const [toast, setToast] = useState(false);
  const token = useRef(0);
  const fill = ctx.n("fill");
  const stretch = ctx.n("stretch");

  const ts = useSince(saves, 0.6);
  const tu = useSince(unsaves, 0.45);
  // Whichever keyframe run started last drives the stretch (both animate the same scale).
  const scaleSave = ts < 0 ? 1 : track(ts, 1, [C(stretch, 0.11), S(0.94, 0.16, SPRINGS.snappy), S(1, 0.3, SPRINGS.bouncy)]);
  const scaleUnsave = tu < 0 ? 1 : track(tu, 1, [C(0.9, 0.1), S(1, 0.3, SPRINGS.bouncy)]);
  const scaleY = scaleSave * scaleUnsave;

  const toggle = () => {
    haptics.tap("light");
    token.current += 1;
    const current = token.current;
    if (saved) {
      setUnsaves((n) => n + 1);
      setSaved(false);
      setToast(false);
      return;
    }
    setSaves((n) => n + 1);
    setSaved(true);
    setToast(true);
    after(1.2, () => {
      if (current === token.current) setToast(false);
    });
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.8 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div style={{ ...demoCard(22), width: 300, padding: 18, display: "flex", flexDirection: "column", gap: 10 }}>
        <div style={{ position: "relative", display: "flex", alignItems: "flex-start", gap: 8 }}>
          <div style={{ display: "flex", flexDirection: "column", gap: 4, flex: 1 }}>
            <span style={{ ...textStyle.caption2, fontWeight: 800, color: Palette.coral }}>{ctx.t("DESIGN NOTES", "设计笔记")}</span>
            <span style={{ ...textStyle.headline }}>{ctx.t("Why springs beat curves", "为什么弹簧胜过曲线")}</span>
          </div>
          <button type="button" onClick={toggle} style={{ position: "relative", width: W, height: H, flexShrink: 0 }}>
            <div style={{ transform: `scaleY(${scaleY})`, transformOrigin: "50% 0%" }}>
              <svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} style={{ overflow: "visible" }}>
                <defs>
                  <linearGradient id="bookmark-save-fill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0" stopColor={Palette.amber} />
                    <stop offset="1" stopColor={Palette.coral} />
                  </linearGradient>
                  <clipPath id="bookmark-save-clip">
                    <motion.rect
                      x={-4}
                      y={0}
                      width={W + 8}
                      initial={false}
                      animate={{ height: saved ? H : 0 }}
                      transition={saved ? anim.easeOut(fill) : anim.easeIn(0.25)}
                    />
                  </clipPath>
                </defs>
                <path d={RIBBON} fill="url(#bookmark-save-fill)" clipPath="url(#bookmark-save-clip)" />
                <path
                  d={RIBBON}
                  fill="none"
                  strokeWidth={3}
                  strokeLinejoin="round"
                  style={{ stroke: saved ? Palette.coral : Palette.labelAlpha(0.6), transition: saved ? `stroke ${fill}s ease-out` : "stroke 0.25s ease-in" }}
                />
              </svg>
            </div>
            {ctx.b("sparks") && <Sparks trigger={saves} />}
          </button>
          <div style={{ position: "absolute", right: W + 8, top: 16, width: 64, height: 24, overflow: "hidden", display: "flex", justifyContent: "flex-end" }}>
            <AnimatePresence>
              {toast && (
                <motion.div
                  initial={{ x: 64, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  exit={{ x: 64, opacity: 0, transition: anim.easeIn(0.25) }}
                  transition={spring(0.4, 0.8)}
                  style={{
                    height: 24,
                    padding: "0 10px",
                    borderRadius: 12,
                    background: Palette.coral,
                    color: "#fff",
                    ...textStyle.caption,
                    fontWeight: 700,
                    lineHeight: "24px",
                    whiteSpace: "nowrap",
                  }}
                >
                  {ctx.t("Saved", "已收藏")}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>
        <PlaceholderLines count={3} />
      </div>
      <DemoHint ctx={ctx} en="Tap the bookmark" zh="点击书签" />
    </div>
  );
}

/** Two sparks that flick out sideways from the notch whenever `trigger` changes. */
function Sparks({ trigger }: { trigger: number }) {
  const t = useSince(trigger, 0.5);
  const p = t < 0 ? 1 : track(t, 1, [L(0, 0.001), L(0, 0.08), C(1, 0.4)]);
  const opacity = p < 0.02 || p > 0.98 ? 0 : 1 - p;
  return (
    <div style={{ position: "absolute", left: W / 2 - 3, bottom: -4, width: 6, height: 6, pointerEvents: "none" }}>
      {[-1, 1].map((dir) => (
        <div
          key={dir}
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: "50%",
            background: Palette.amber,
            opacity,
            transform: `translate(${dir * 26 * p}px, ${-6 * p}px) scale(${1 - 0.6 * p})`,
          }}
        />
      ))}
    </div>
  );
}
