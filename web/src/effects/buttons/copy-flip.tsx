/** buttons.copy-flip · 翻转复制 (Buttons+CopyFlip.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { Check } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { CopyGlyph } from "./_b-icons";

export default function CopyFlip({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const roll = useMotionValue(0);
  const target = useRef(0);
  const copied = useRef(false);
  const [sweep, setSweep] = useState(0);
  const [sweepOpacity, setSweepOpacity] = useState(0);
  const [showBack, setShowBack] = useState(false);
  useMotionValueEvent(roll, "change", (a) => {
    const r = ((a % 360) + 360) % 360;
    setShowBack(r > 90 && r < 270);
  });
  const persp = 104 / Math.max(ctx.n("perspective"), 0.05);
  const transform = useTransform(roll, (a) => `perspective(${persp}px) rotateX(${-a}deg)`);

  const copy = () => {
    if (copied.current) return;
    copied.current = true;
    haptics.success();
    const t = spring(ctx.n("response"), 0.72);
    target.current += 180;
    animate(roll, target.current, t);
    setSweepOpacity(1);
    setSweep(1);
    after(ctx.n("hold"), () => {
      target.current += 180;
      animate(roll, target.current, t);
      setSweepOpacity(0);
      after(0.45, () => {
        setSweep(0);
        copied.current = false;
      });
    });
  };
  useAutoplay(ctx.isPreview, copy, { every: ctx.n("hold") + 1.4, delay: 0.4 });

  const face = (isCopied: boolean) => (
    <div
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: 10,
        background: isCopied ? Palette.successStrong : "rgb(255 255 255 / 0.12)",
        boxShadow: `inset 0 0 0 1px rgb(255 255 255 / ${isCopied ? 0.25 : 0.14})`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 6,
        color: "#fff",
        fontSize: 13,
        fontWeight: 600,
        opacity: showBack === isCopied ? 1 : 0,
        transform: isCopied ? "rotateX(180deg)" : undefined,
      }}
    >
      {isCopied ? <Check size={14} strokeWidth={3.2} /> : <CopyGlyph size={14} />}
      <span>{isCopied ? ctx.t("Copied", "已复制") : ctx.t("Copy", "复制")}</span>
    </div>
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div
        style={{
          width: 300,
          padding: 18,
          borderRadius: 22,
          background: "#16181D",
          boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.08), 0 10px 18px rgb(0 0 0 / 0.25)",
          display: "flex",
          flexDirection: "column",
          gap: 14,
          flexShrink: 0,
        }}
      >
        <div style={{ display: "flex", alignItems: "center" }}>
          <div style={{ display: "flex", gap: 6 }}>
            {[Palette.red, Palette.amber, Palette.green].map((c) => (
              <div key={c} style={{ width: 9, height: 9, borderRadius: "50%", background: c }} />
            ))}
          </div>
          <div style={{ flex: 1 }} />
          <button type="button" onClick={copy} style={{ width: 104, height: 36 }}>
            <motion.div style={{ position: "relative", width: 104, height: 36, transform }}>
              {face(false)}
              {face(true)}
            </motion.div>
          </button>
        </div>
        <div style={{ position: "relative", alignSelf: "flex-start", display: "flex", gap: 8, padding: 6, fontFamily: fonts.mono, fontSize: 14, fontWeight: 500 }}>
          <motion.div
            initial={false}
            animate={{ scaleX: sweep, opacity: sweepOpacity }}
            transition={{ scaleX: sweep ? anim.easeOut(0.35) : { duration: 0 }, opacity: sweepOpacity ? { duration: 0 } : anim.easeOut(0.4) }}
            style={{ position: "absolute", inset: 0, borderRadius: 6, background: "rgb(58 196 255 / 0.28)", originX: 0 }}
          />
          <span style={{ position: "relative", color: Palette.mint }}>$</span>
          <span style={{ position: "relative", color: "#fff", whiteSpace: "nowrap" }}>npm install motion-lexicon</span>
        </div>
        <div style={{ fontFamily: fonts.mono, fontSize: 12, color: "rgb(255 255 255 / 0.4)" }}># 42 packages · 3.1 s</div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap Copy" zh="点击复制" style={{ paddingBottom: 18 }} />
    </div>
  );
}
