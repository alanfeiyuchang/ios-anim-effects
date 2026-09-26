/** buttons.press-scale · 按压缩放 (Buttons+PressScale.swift) */
import { motion } from "motion/react";
import { ArrowRight } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BOUNCY, cubicKF, springKF, track, useLatchedPress, useSince } from "./_a-kit";

const ARROW = [cubicKF(7, 0.14), springKF(0, 0.45, BOUNCY)];

export default function PressScale({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [autoPressed, setAutoPressed] = useState(false);
  const autoRef = useRef(false);
  const [releases, setReleases] = useState(0);
  const { held, handlers } = useLatchedPress();
  const pressed = held || autoPressed;

  useAutoplay(
    ctx.isPreview,
    () => {
      if (ctx.isPreview) {
        autoRef.current = !autoRef.current;
        setAutoPressed(autoRef.current);
        if (!autoRef.current) setReleases((r) => r + 1);
      } else {
        setAutoPressed(true);
        after(0.4, () => {
          setAutoPressed(false);
          setReleases((r) => r + 1);
        });
      }
    },
    { every: 0.9 },
  );

  const arrowX = track(useSince(releases, 0.6), 0, ARROW);
  const scale = ctx.n("scale");

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 20 }}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
          <div style={{ display: "flex", gap: 6 }}>
            {[0, 1, 2].map((i) => (
              <div key={i} style={{ width: i === 2 ? 22 : 7, height: 7, borderRadius: 4, background: i === 2 ? Palette.primary : Palette.labelAlpha(0.12) }} />
            ))}
          </div>
          <div style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700, color: Palette.label }}>{ctx.t("You're all set", "一切准备就绪")}</div>
        </div>
        <motion.button
          type="button"
          {...handlers}
          onClick={() => {
            haptics.tap();
            setReleases((r) => r + 1);
          }}
          animate={{
            scale: pressed ? scale : 1,
            filter: pressed ? "brightness(0.9)" : "brightness(1)",
            boxShadow: pressed ? "0px 3px 6px rgba(110, 123, 255, 0.22)" : "0px 10px 16px rgba(110, 123, 255, 0.4)",
          }}
          transition={spring(ctx.n("response"), ctx.n("damping"))}
          style={{
            position: "relative",
            width: 220,
            height: 58,
            borderRadius: 29,
            background: Palette.primary,
            color: "#fff",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
            fontFamily: fonts.text,
            fontSize: 17,
            fontWeight: 600,
          }}
        >
          <div
            style={{
              position: "absolute",
              inset: 1.5,
              borderRadius: 29,
              background: "linear-gradient(rgb(255 255 255 / 0.28), transparent 50%)",
              pointerEvents: "none",
            }}
          />
          <div style={{ position: "absolute", inset: 0, borderRadius: 29, boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.22)", pointerEvents: "none" }} />
          <span style={{ position: "relative" }}>{ctx.lang === "zh" ? "继续" : "Continue"}</span>
          <ArrowRight size={19} strokeWidth={2.4} style={{ position: "relative", transform: `translateX(${arrowX}px)` }} />
        </motion.button>
        <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, color: Palette.tertiaryLabel }}>
          {ctx.t("7-day free trial · cancel anytime", "7 天免费试用 · 随时取消")}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press and hold the button" zh="按住按钮再松开" style={{ paddingBottom: 18 }} />
    </div>
  );
}
