/** inputs.rolling-toggle (Inputs+RollingToggle.swift) */
import { motion } from "motion/react";
import { Sun } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { FadeText, systemGray, useAutoMute } from "./_a-common";

const TRACK_W = 116;
const TRACK_H = 54;
const BALL = 42;
const INSET = (TRACK_H - BALL) / 2;
const TRAVEL = TRACK_W - INSET * 2 - BALL;

export default function RollingToggle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const { wrap, muted } = useAutoMute();
  const [isOn, setIsOn] = useState(false);

  const toggle = () => {
    setIsOn((v) => !v);
    const silent = muted();
    after(ctx.n("response") * 0.6, () => {
      if (!silent) haptics.tap();
    });
  };
  useAutoplay(ctx.isPreview, wrap(toggle), { every: 1.5, delay: 0.4 });

  const t = spring(ctx.n("response"), ctx.n("damping"));
  const x = isOn ? TRAVEL : 0;
  const degrees = ((x / (BALL / 2)) * ctx.n("slip") * 180) / Math.PI;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
      <div style={{ flex: 1 }} />
      <div onClick={toggle} style={{ position: "relative", width: TRACK_W, height: TRACK_H, borderRadius: TRACK_H / 2, cursor: "pointer", flexShrink: 0 }}>
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: TRACK_H / 2,
            background: Palette.labelAlpha(0.1),
            boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
          }}
        />
        <motion.div
          initial={false}
          animate={{ width: INSET + x + BALL / 2, opacity: isOn ? 1 : 0.35 }}
          transition={t}
          style={{ position: "absolute", left: 0, top: 0, height: TRACK_H, borderRadius: TRACK_H / 2, background: `linear-gradient(90deg, ${Palette.sky}, ${Palette.mint})` }}
        />
        <motion.div initial={false} animate={{ x: INSET + x }} transition={t} style={{ position: "absolute", left: 0, top: INSET, width: BALL, height: BALL }}>
          {/* contact shadow */}
          <div
            style={{
              position: "absolute",
              left: BALL * 0.1,
              width: BALL * 0.8,
              height: 6,
              bottom: -3,
              borderRadius: "50%",
              background: "rgb(0 0 0 / 0.22)",
              filter: "blur(3px)",
            }}
          />
          <motion.div
            initial={false}
            animate={{ rotate: degrees }}
            transition={t}
            style={{ position: "absolute", inset: 0, borderRadius: "50%", overflow: "hidden", boxShadow: "0 2px 4px rgb(0 0 0 / 0.18)" }}
          >
            <div
              style={{
                position: "absolute",
                inset: 0,
                background: `radial-gradient(circle ${BALL * 0.7}px at 35% 30%, #fff 1px, rgb(219 219 219) ${BALL * 0.7}px)`,
              }}
            />
            <div
              style={{
                position: "absolute",
                left: 0,
                right: 0,
                top: BALL / 2 - 3.5,
                height: 7,
                borderRadius: 4,
                opacity: 0.85,
                background: isOn ? Palette.mint : Palette.coral,
              }}
            />
            <div style={{ position: "absolute", left: 0, right: 0, top: BALL / 2 - 11 - 8, height: 16, display: "grid", placeItems: "center", color: isOn ? Palette.sky : systemGray }}>
              <Sun size={16} fill="currentColor" strokeWidth={2.6} />
            </div>
          </motion.div>
          {/* specular highlight that stays put while the ball turns underneath */}
          <div
            style={{
              position: "absolute",
              top: 3,
              left: (BALL - BALL * 0.55) / 2,
              width: BALL * 0.55,
              height: BALL * 0.3,
              borderRadius: "50%",
              background: "linear-gradient(rgb(255 255 255 / 0.75), rgb(255 255 255 / 0))",
              pointerEvents: "none",
            }}
          />
        </motion.div>
      </div>
      <FadeText
        text={isOn ? ctx.t("Auto-Brightness on", "自动亮度已开启") : ctx.t("Auto-Brightness off", "自动亮度已关闭")}
        style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.secondaryLabel }}
      />
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the switch" zh="点击开关" style={{ paddingBottom: 18 }} />
    </div>
  );
}
