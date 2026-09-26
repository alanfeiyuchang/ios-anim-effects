/** text.elastic-letters · 弹性逐字入场 (Text+ElasticLetters.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, anim, delayed, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoContext, type DemoProps } from "../../kit";
import { GradientText, chars } from "./_text-kit";

export default function ElasticLetters({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [shown, setShown] = useState(true);
  const headline = chars(ctx.t("Hello, world!", "你好，世界！"));
  const subline = chars(ctx.t("every letter bounces in", "每一个字都在弹跳"));

  const replay = () => {
    haptics.tap("soft");
    setShown(false);
    after(0.25, () => setShown(true));
  };
  useAutoplay(ctx.isPreview, replay, { every: 3.0 });

  return (
    <div onClick={replay} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14, cursor: "pointer" }}>
      <Letters ctx={ctx} list={headline} offset={0} size={40} weight={800} primary shown={shown} />
      <Letters ctx={ctx} list={subline} offset={headline.length + 4} size={17} weight={600} primary={false} shown={shown} />
      <DemoHint ctx={ctx} en="Tap to replay" zh="点击重播" style={{ paddingTop: 18 }} />
    </div>
  );
}

function Letters({ ctx, list, offset, size, weight, primary, shown }: { ctx: DemoContext; list: string[]; offset: number; size: number; weight: number; primary: boolean; shown: boolean }) {
  const tilt = ctx.n("tilt");
  const font = { fontFamily: fonts.rounded, fontSize: size, fontWeight: weight, lineHeight: `${Math.round(size * 1.2)}px` };
  return (
    <div style={{ display: "flex" }}>
      {list.map((ch, index) => (
        <motion.span
          key={index}
          initial={false}
          animate={{ scale: shown ? 1 : 0.2, rotate: shown ? 0 : -tilt, y: shown ? 0 : 24, opacity: shown ? 1 : 0 }}
          transition={shown ? delayed(spring(0.5, ctx.n("damping")), (offset + index) * ctx.n("stagger")) : anim.easeOut(0.2)}
          style={{ display: "inline-block", transformOrigin: "50% 100%" }}
        >
          {primary ? (
            <GradientText fill={Palette.sunset} style={font}>
              {ch}
            </GradientText>
          ) : (
            <span style={{ ...font, color: Palette.secondaryLabel, whiteSpace: "pre" }}>{ch}</span>
          )}
        </motion.span>
      ))}
    </div>
  );
}
