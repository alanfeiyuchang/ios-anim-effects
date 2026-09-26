/** inputs.rocker-switch (Inputs+RockerSwitch.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, demoCard, fonts, hex, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { FadeText, useAutoMute } from "./_a-common";

export default function RockerSwitch({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const { wrap, muted } = useAutoMute();
  const [isOn, setIsOn] = useState(false);
  const [pressed, setPressed] = useState(false);
  const [flips, setFlips] = useState(0);
  const isOnRef = useRef(false);

  const flip = () => {
    setPressed(true);
    const silent = muted();
    after(0.08, () => {
      if (!silent) haptics.tap("rigid");
      const next = !isOnRef.current;
      isOnRef.current = next;
      setIsOn(next);
      setPressed(false);
      if (next) setFlips((f) => f + 1);
    });
  };
  useAutoplay(ctx.isPreview, wrap(flip), { every: 1.4, delay: 0.4 });

  const tilt = ctx.n("tilt");
  const angle = isOn ? tilt : -tilt;
  const snap = spring(ctx.n("response"), 0.9);
  const flicker = ctx.b("flicker");
  const low = flicker ? 0 : 1;
  const dip = flicker ? 0.4 : 1;
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), width: 260, padding: 20, display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <div style={{ display: "flex", alignItems: "center", alignSelf: "stretch" }}>
          <span style={{ ...textStyle.headline }}>{zh ? "工作室暖风机" : "Studio Heater"}</span>
          <div style={{ flex: 1 }} />
          <motion.div
            key={isOn ? `lit-${flips}` : "off"}
            initial={isOn ? { opacity: 1, boxShadow: `0 0 8px ${hex(0xffc247, 0.9)}` } : false}
            animate={
              isOn
                ? {
                    opacity: [1, low, 1, dip, 1],
                    boxShadow: [1, low, 1, dip, 1].map((l) => `0 0 8px ${hex(0xffc247, 0.9 * l)}`),
                  }
                : { opacity: 1, boxShadow: `0 0 8px ${hex(0xffc247, 0)}` }
            }
            transition={isOn ? { duration: 0.26, times: [0, 0.04 / 0.26, 0.1 / 0.26, 0.16 / 0.26, 1], ease: "linear" } : { duration: 0 }}
            style={{ width: 10, height: 10, borderRadius: "50%", background: isOn ? Palette.amber : Palette.labelAlpha(0.15) }}
          />
        </div>
        <motion.div
          onClick={flip}
          animate={{ scale: pressed ? 0.97 : 1 }}
          transition={pressed ? anim.easeOut(0.08) : snap}
          style={{ position: "relative", width: 148, height: 88, borderRadius: 18, cursor: "pointer" }}
        >
          <div style={{ position: "absolute", inset: 0, borderRadius: 18, background: Palette.labelAlpha(0.1), boxShadow: "inset 0 0 0 1px rgb(0 0 0 / 0.12)" }} />
          <div style={{ position: "absolute", inset: 8, perspective: 132 / 0.6 }}>
            <motion.div
              initial={false}
              animate={{ rotateY: angle, boxShadow: `${isOn ? -3 : 3}px 3px 5px rgb(0 0 0 / 0.2)` }}
              transition={snap}
              style={{ position: "absolute", inset: 0, borderRadius: 12, background: Palette.elevated, overflow: "hidden" }}
            >
              <div style={{ position: "absolute", inset: 0, display: "flex" }}>
                <motion.div
                  initial={false}
                  animate={{ opacity: isOn ? 0 : 1 }}
                  transition={snap}
                  style={{ flex: 1, background: "linear-gradient(90deg, rgb(0 0 0 / 0.18), transparent)" }}
                />
                <motion.div
                  initial={false}
                  animate={{ opacity: isOn ? 1 : 0 }}
                  transition={snap}
                  style={{ flex: 1, background: "linear-gradient(90deg, transparent, rgb(0 0 0 / 0.18))" }}
                />
              </div>
              <div style={{ position: "absolute", inset: 0, background: "linear-gradient(rgb(255 255 255 / 0.35), transparent 50%)" }} />
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  padding: "0 26px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  fontFamily: fonts.rounded,
                  fontSize: 22,
                  fontWeight: 800,
                }}
              >
                <span style={{ color: isOn ? Palette.secondaryLabel : Palette.label, transition: "color 0.2s ease-out" }}>O</span>
                <span style={{ color: isOn ? Palette.amber : Palette.secondaryLabel, transition: "color 0.2s ease-out" }}>I</span>
              </div>
              <div style={{ position: "absolute", inset: 0, borderRadius: 12, boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }} />
            </motion.div>
          </div>
        </motion.div>
        <FadeText
          duration={0.2}
          text={isOn ? (zh ? "运行中 · 1,200 W" : "Running · 1,200 W") : zh ? "待机" : "Standby"}
          style={{ ...textStyle.caption, fontWeight: 500, fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}
        />
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the rocker" zh="点击翘板" style={{ paddingBottom: 18 }} />
    </div>
  );
}
