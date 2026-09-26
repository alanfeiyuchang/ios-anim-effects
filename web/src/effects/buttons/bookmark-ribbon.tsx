/** buttons.bookmark-ribbon · 书签丝带收藏 (Buttons+BookmarkRibbon.swift) */
import { motion } from "motion/react";
import { Bookmark } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, demoCard, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { LandscapeArt } from "../showcase/signature";
import { BlurReplace, PressButton, SMOOTH, SymbolReplace, cubicKF, linearKF, springKF, track, trackDuration, useSince } from "./_a-kit";

export default function BookmarkRibbon({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [saved, setSaved] = useState(false);
  const savedRef = useRef(false);
  const [saves, setSaves] = useState(0);

  const toggle = () => {
    const becoming = !savedRef.current;
    savedRef.current = becoming;
    setSaved(becoming);
    if (becoming) {
      setSaves((s) => s + 1);
      haptics.tap("medium");
    } else haptics.tap();
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.7, delay: 0.4 });

  const swing = ctx.n("swing");
  const swingTrack = [linearKF(0, 0.12), cubicKF(swing, 0.2), cubicKF(-swing * 0.57, 0.2), cubicKF(swing * 0.28, 0.18), springKF(0, 0.3, SMOOTH)];
  const angle = track(useSince(saves, trackDuration(swingTrack)), 0, swingTrack);
  const length = ctx.n("length");

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), position: "relative", width: 290, padding: 16, display: "flex", flexDirection: "column", gap: 14, flexShrink: 0 }}>
        <div style={{ position: "relative", height: 110, borderRadius: 16, overflow: "hidden" }}>
          <LandscapeArt seed={3} />
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
          <div style={{ fontSize: 10, lineHeight: "12px", fontWeight: 800, letterSpacing: 1, color: Palette.secondaryLabel }}>{ctx.t("TRAVEL · 6 MIN", "旅行 · 6 分钟")}</div>
          <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {ctx.t("Chasing light across the dunes", "追逐沙丘上的光")}
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center" }}>
          <div style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{ctx.t("by Lena Ortiz", "作者 Lena Ortiz")}</div>
          <div style={{ flex: 1 }} />
          <PressButton scale={0.94} dim={0.04} onClick={toggle} style={{ position: "relative", height: 36, borderRadius: 18 }}>
            <motion.div
              initial={false}
              animate={{ paddingLeft: saved ? 16 : 14, paddingRight: saved ? 16 : 14 }}
              transition={saved ? spring(0.45, ctx.n("damping")) : anim.easeIn(0.25)}
              style={{
                height: 36,
                borderRadius: 18,
                display: "flex",
                alignItems: "center",
                gap: 6,
                fontSize: 15,
                fontWeight: 600,
                color: saved ? Palette.violet : "#fff",
                background: saved ? alpha(Palette.violet, 0.14) : Palette.primary,
              }}
            >
              <SymbolReplace id={saved ? "on" : "off"}>
                <Bookmark size={16} strokeWidth={2.4} fill={saved ? "currentColor" : "none"} />
              </SymbolReplace>
              <BlurReplace id={saved ? "saved" : "save"}>
                <span>{saved ? ctx.t("Saved", "已收藏") : ctx.t("Save", "收藏")}</span>
              </BlurReplace>
            </motion.div>
          </PressButton>
        </div>
        <motion.div
          initial={false}
          animate={{ height: saved ? length : 0 }}
          transition={saved ? spring(0.45, ctx.n("damping")) : anim.easeIn(0.25)}
          style={{
            position: "absolute",
            top: 0,
            right: 30,
            width: 26,
            transformOrigin: "50% 0%",
            rotate: angle,
            pointerEvents: "none",
            filter: "drop-shadow(0 3px 4px rgb(110 123 255 / 0.35))",
          }}
        >
          <div
            style={{
              position: "absolute",
              inset: 0,
              background: `linear-gradient(${Palette.violet}, ${Palette.indigo})`,
              clipPath: "polygon(0 0, 100% 0, 100% 100%, 50% calc(100% - min(10.4px, 100%)), 0 100%)",
            }}
          />
        </motion.div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap Save" zh="点击收藏" style={{ paddingBottom: 18 }} />
    </div>
  );
}
