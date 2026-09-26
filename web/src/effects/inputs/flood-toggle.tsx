/** inputs.flood-toggle (Inputs+FloodToggle.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, demoCard, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { FadeText, useAutoMute } from "./_a-common";

const TRACK_W = 96;
const TRACK_H = 52;
const INSET = 5;
const KNOB = TRACK_H - INSET * 2;
const ON_CX = TRACK_W - INSET - KNOB / 2;
const COVER = TRACK_W * 2.1;

export default function FloodToggle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const { wrap, muted } = useAutoMute();
  const [isOn, setIsOn] = useState(false);
  const [flooded, setFlooded] = useState(false);
  const [ripples, setRipples] = useState(0);
  const [wifiPulse, setWifiPulse] = useState(0);
  const isOnRef = useRef(false);
  const generation = useRef(0);

  const toggle = () => {
    generation.current += 1;
    const current = generation.current;
    const turningOn = !isOnRef.current;
    isOnRef.current = turningOn;
    setIsOn(turningOn);
    setWifiPulse((p) => p + 1);
    if (!turningOn) {
      setFlooded(false);
      return;
    }
    const silent = muted();
    after(0.05, () => {
      if (current !== generation.current) return;
      if (!silent) haptics.tap();
      setFlooded(true);
      if (ctx.b("ripple")) setRipples((r) => r + 1);
    });
  };
  useAutoplay(ctx.isPreview, wrap(toggle), { every: 1.6, delay: 0.4 });

  const flood = ctx.n("flood");
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 310, padding: 16, display: "flex", alignItems: "center", gap: 12 }}>
        <div style={{ width: 38, height: 38, borderRadius: 10, background: Palette.primary, display: "grid", placeItems: "center", flexShrink: 0 }}>
          <WifiGlyph trigger={wifiPulse} />
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 2, flex: 1, minWidth: 0 }}>
          <span style={{ ...textStyle.headline }}>Wi-Fi</span>
          <FadeText
            text={isOn ? (zh ? "已连接 · Studio 5G" : "Connected · Studio 5G") : zh ? "已关闭" : "Off"}
            style={{ ...textStyle.caption, color: Palette.secondaryLabel }}
          />
        </div>
        <div onClick={toggle} style={{ position: "relative", width: TRACK_W, height: TRACK_H, flexShrink: 0, cursor: "pointer" }}>
          {ripples > 0 && (
            <motion.div
              key={ripples}
              initial={{ scale: 1, opacity: 0.7 }}
              animate={{ scale: 1.6, opacity: 0 }}
              transition={{ scale: { duration: 0.6, ease: [0.42, 0, 0.58, 1], delay: 0.01 }, opacity: { duration: 0.6, ease: "linear", delay: 0.01 } }}
              style={{ position: "absolute", inset: 0, borderRadius: TRACK_H / 2, boxShadow: `inset 0 0 0 2px ${Palette.indigo}`, pointerEvents: "none" }}
            />
          )}
          <div style={{ position: "absolute", inset: 0, borderRadius: TRACK_H / 2, overflow: "hidden", isolation: "isolate" }}>
            <div style={{ position: "absolute", inset: 0, background: Palette.labelAlpha(0.12) }} />
            <motion.div
              initial={false}
              animate={{ scale: flooded ? 1 : 0.001 }}
              transition={flooded ? anim.easeOut(flood) : anim.easeIn(flood * 0.62)}
              style={{
                position: "absolute",
                left: ON_CX - COVER / 2,
                top: TRACK_H / 2 - COVER / 2,
                width: COVER,
                height: COVER,
                borderRadius: "50%",
                background: `linear-gradient(to bottom left, ${Palette.violet}, ${Palette.indigo})`,
              }}
            />
            <motion.div
              initial={false}
              animate={{ x: isOn ? TRACK_W - INSET - KNOB : INSET }}
              transition={spring(ctx.n("response"), 0.78)}
              style={{ position: "absolute", left: 0, top: INSET, width: KNOB, height: KNOB, borderRadius: "50%", background: "#fff", boxShadow: "0 2px 5px rgb(0 0 0 / 0.18)" }}
            />
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the switch" zh="点击开关" style={{ paddingBottom: 18 }} />
    </div>
  );
}

/** SF `wifi` with `.symbolEffect(.variableColor.iterative, options: .nonRepeating)`: layers light up in turn. */
function WifiGlyph({ trigger }: { trigger: number }) {
  const layers = [
    <circle key="dot" cx="12" cy="19" r="1.7" fill="#fff" />,
    <path key="a1" d="M8.6 15.4a4.9 4.9 0 0 1 6.8 0" />,
    <path key="a2" d="M5.2 12a9.7 9.7 0 0 1 13.6 0" />,
    <path key="a3" d="M1.9 8.6a14.4 14.4 0 0 1 20.2 0" />,
  ];
  return (
    <svg width={21} height={21} viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth={2.5} strokeLinecap="round">
      {layers.map((layer, i) => (
        <motion.g
          key={`${i}-${trigger}`}
          initial={false}
          animate={trigger > 0 ? { opacity: [1, 0.35, 0.35, 1, 1] } : { opacity: 1 }}
          transition={{ duration: 0.75, times: [0, 0.05, 0.1 + i * 0.18, 0.2 + i * 0.18, 1], ease: "easeOut" }}
        >
          {layer}
        </motion.g>
      ))}
    </svg>
  );
}
