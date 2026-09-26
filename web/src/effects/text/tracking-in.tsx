/** text.tracking-in · 字距收拢入场 (Text+TrackingIn.swift) */
import { motion, type Transition } from "motion/react";
import { useState, type CSSProperties } from "react";
import { DemoHint, Palette, anim, delayed, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { chars } from "./_text-kit";

export default function TrackingIn({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [shown, setShown] = useState(true);
  const duration = ctx.n("duration");
  const spread = ctx.n("spread");
  const blur = ctx.n("blur");

  const replay = () => {
    haptics.tap("soft");
    setShown(false);
    after(0.3, () => setShown(true));
  };
  useAutoplay(ctx.isPreview, replay, { every: duration + 1.8 });

  const curve = (delay: number): Transition => (shown ? delayed(anim.curve(0.215, 0.61, 0.355, 1, duration), delay) : anim.easeOut(0.2));

  return (
    <div onClick={replay} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14, cursor: "pointer" }}>
      <TrackingLine
        list={chars(ctx.t("MOTIONARY", "动效词典"))}
        shown={shown}
        spread={spread}
        blur={blur}
        transition={curve(0)}
        font={{ fontFamily: fonts.text, fontSize: 46, fontWeight: 900, lineHeight: "55px", color: Palette.label }}
      />
      <motion.div
        initial={false}
        animate={{ scaleX: shown ? 1 : 0 }}
        transition={shown ? delayed(spring(0.6, 0.9), duration * 0.6) : anim.easeOut(0.2)}
        style={{ width: 180, height: 2, borderRadius: 1, background: `linear-gradient(to right, rgb(255 194 71 / 0), ${Palette.coral}, rgb(255 194 71 / 0))` }}
      />
      <TrackingLine
        list={chars(ctx.t("MOTION, DEFINED", "让界面动起来"))}
        shown={shown}
        spread={spread * 0.5}
        blur={blur * 0.5}
        transition={curve(0.25)}
        font={{ fontFamily: fonts.text, fontSize: 13, fontWeight: 700, lineHeight: "16px", color: Palette.secondaryLabel }}
      />
      <DemoHint ctx={ctx} en="Tap to replay" zh="点击重播" style={{ paddingTop: 16 }} />
    </div>
  );
}

function TrackingLine({ list, shown, spread, blur, transition, font }: { list: string[]; shown: boolean; spread: number; blur: number; transition: Transition; font: CSSProperties }) {
  return (
    <motion.div
      initial={false}
      animate={{ gap: shown ? 2 : spread, scale: shown ? 1 : 1.15, filter: `blur(${shown ? 0 : blur}px)`, opacity: shown ? 1 : 0 }}
      transition={transition}
      style={{ display: "flex", whiteSpace: "pre", ...font }}
    >
      {list.map((ch, i) => (
        <span key={i}>{ch}</span>
      ))}
    </motion.div>
  );
}
