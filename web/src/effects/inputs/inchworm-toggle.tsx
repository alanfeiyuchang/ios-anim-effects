/** inputs.inchworm-toggle · (Inputs+InchwormToggle.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { BatteryLow, BatteryMedium } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, demoCard, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { FadeText, SymbolSwap, useAutoMute } from "./_a-common";

const TRACK_W = 104;
const TRACK_H = 52;
const INSET = 5;
const KNOB = TRACK_H - INSET * 2;

export default function InchwormToggle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const { wrap, muted } = useAutoMute();
  const [isOn, setIsOn] = useState(false);
  const isOnRef = useRef(false);
  const generation = useRef(0);
  const left = useMotionValue(INSET);
  const right = useMotionValue(INSET + KNOB);
  const height = useMotionValue(KNOB);
  const width = useTransform(() => Math.max(right.get() - left.get(), 1));

  const toggle = () => {
    generation.current += 1;
    const current = generation.current;
    const turningOn = !isOnRef.current;
    isOnRef.current = turningOn;
    const head = spring(ctx.n("head"), 0.72);
    const tail = spring(ctx.n("tail"), 0.62);
    const silent = muted();
    setIsOn(turningOn);
    animate(height, KNOB - 6, head);
    if (turningOn) animate(right, TRACK_W - INSET, head);
    else animate(left, INSET, head);
    after(ctx.n("lag"), () => {
      if (current !== generation.current) return;
      animate(height, KNOB, tail);
      if (turningOn) animate(left, TRACK_W - INSET - KNOB, tail);
      else animate(right, INSET + KNOB, tail);
      after(ctx.n("tail") * 0.6, () => {
        if (current !== generation.current || silent) return;
        haptics.tap();
      });
    });
  };
  useAutoplay(ctx.isPreview, wrap(toggle), { every: 1.4, delay: 0.4 });

  const zh = ctx.lang === "zh";
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 310, padding: 16, display: "flex", alignItems: "center", gap: 12 }}>
        <div
          style={{
            width: 38,
            height: 38,
            borderRadius: 10,
            background: `linear-gradient(${Palette.amber}, ${Palette.coral})`,
            display: "grid",
            placeItems: "center",
            color: "#fff",
            flexShrink: 0,
          }}
        >
          <SymbolSwap k={isOn ? "low" : "high"}>{isOn ? <BatteryLow size={20} strokeWidth={2.4} /> : <BatteryMedium size={20} strokeWidth={2.4} />}</SymbolSwap>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 2, flex: 1, minWidth: 0 }}>
          <span style={{ ...textStyle.headline }}>{zh ? "低电量模式" : "Low Power"}</span>
          <FadeText text={isOn ? (zh ? "正在省电" : "Saving energy") : zh ? "已关闭" : "Off"} style={{ ...textStyle.caption, color: Palette.secondaryLabel }} />
        </div>
        <div onClick={toggle} style={{ position: "relative", width: TRACK_W, height: TRACK_H, borderRadius: TRACK_H / 2, flexShrink: 0, cursor: "pointer" }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: TRACK_H / 2, background: Palette.labelAlpha(0.12) }} />
          <motion.div
            initial={false}
            animate={{ opacity: isOn ? 1 : 0 }}
            transition={anim.easeInOut(0.3)}
            style={{ position: "absolute", inset: 0, borderRadius: TRACK_H / 2, background: `linear-gradient(90deg, ${Palette.amber}, ${Palette.coral})` }}
          />
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center" }}>
            <motion.div
              style={{ position: "absolute", left: 0, x: left, width, height, borderRadius: 999, background: "#fff", boxShadow: "0 3px 6px rgb(0 0 0 / 0.18)" }}
            />
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the switch" zh="点击开关" style={{ paddingBottom: 18 }} />
    </div>
  );
}
