/** text.light-sweep · 光扫显现 (Text+LightSweep.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { useState, type CSSProperties } from "react";
import { DemoHint, Palette, alpha, anim, delayed, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { unitGradient, useSize } from "./_text-kit";

export default function LightSweep({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const progressMv = useMotionValue(1);
  const [progress, setProgress] = useState(1);
  useMotionValueEvent(progressMv, "change", setProgress);
  const [captionShown, setCaptionShown] = useState(true);
  const [captionDelay, setCaptionDelay] = useState(0);
  const duration = ctx.n("duration");

  const replay = () => {
    haptics.tap("soft");
    animate(progressMv, 0, anim.easeOut(0.25));
    setCaptionDelay(-1);
    setCaptionShown(false);
    after(0.3, () => {
      animate(progressMv, 1, anim.easeInOut(duration));
      setCaptionDelay(duration + 0.15);
      setCaptionShown(true);
    });
  };
  useAutoplay(ctx.isPreview, replay, { every: duration + 1.6 });

  return (
    <div onClick={replay} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
      <div style={{ width: 290, display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 14 }}>
        <SweepText progress={progress} softness={ctx.n("softness")} glow={ctx.b("glow")} text={ctx.t("Designed\nto move you.", "为触动\n而设计。")} />
        <motion.span
          initial={false}
          animate={{ opacity: captionShown ? 1 : 0, y: captionShown ? 0 : 8 }}
          transition={captionDelay < 0 ? anim.easeOut(0.25) : delayed(spring(0.5, 0.85), captionDelay)}
          style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, color: Palette.secondaryLabel }}
        >
          {ctx.t("Motionary · Autumn collection", "Motionary · 秋季合集")}
        </motion.span>
        <DemoHint ctx={ctx} en="Tap to replay" zh="点击重播" style={{ paddingTop: 10 }} />
      </div>
    </div>
  );
}

function SweepText({ progress, softness, glow, text }: { progress: number; softness: number; glow: boolean; text: string }) {
  const [ref, { w, h }] = useSize<HTMLDivElement>([text]);
  const edge = -softness + progress * (1 + softness * 2);
  const c = (x: number) => Math.min(Math.max(x, 0), 1);
  const start = { x: 0, y: 0.1 };
  const end = { x: 1, y: 0.9 };
  const reveal = unitGradient(w || 1, h || 1, start, end, [
    { color: "#000", location: c(edge - softness) },
    { color: "transparent", location: c(edge) },
  ]);
  const half = softness * 0.5;
  const band = unitGradient(w || 1, h || 1, start, end, [
    { color: "transparent", location: c(edge - softness - half) },
    { color: "#000", location: c(edge - softness * 0.5) },
    { color: "transparent", location: c(edge + half * 0.2) },
  ]);
  const bandOpacity = Math.min(Math.max((1 - progress) * 8, 0), 1);
  const font: CSSProperties = { fontFamily: fonts.text, fontSize: 44, fontWeight: 900, lineHeight: "52px", whiteSpace: "pre" };

  return (
    <div ref={ref} style={{ position: "relative" }}>
      <div style={{ ...font, color: Palette.label, WebkitMaskImage: reveal, maskImage: reveal }}>{text}</div>
      {glow && (
        <div style={{ position: "absolute", inset: 0, opacity: bandOpacity, WebkitMaskImage: band, maskImage: band, pointerEvents: "none" }}>
          <div style={{ filter: `drop-shadow(0 0 6px ${alpha(Palette.coral, 0.8)})` }}>
            <div
              style={{
                ...font,
                backgroundImage: "linear-gradient(to bottom right, #FFC247, #FF7A5C, #FF5FA2)",
                WebkitBackgroundClip: "text",
                backgroundClip: "text",
                color: "transparent",
                WebkitTextFillColor: "transparent",
              }}
            >
              {text}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
