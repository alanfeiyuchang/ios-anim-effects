/** feedback.glitch-error · 故障风报错 (Feedback+ErrorVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { CircleAlert } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, demoCard, fonts, useAutoplay, useClock, useHaptics, useTimeouts, type DemoProps } from "../../kit";

const hash = (step: number, salt: number) => {
  const v = Math.sin((step * 31 + salt) * 12.9898) * 43758.5453;
  return v - Math.floor(v);
};

export default function GlitchError({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [glitching, setGlitching] = useState(false);
  const [invalid, setInvalid] = useState(false);
  const [start, setStart] = useState(0);
  const busy = useRef(false);
  const zh = ctx.lang === "zh";
  const fade = anim.easeInOut(0.2);

  const apply = (buzz = true) => {
    if (busy.current) return;
    busy.current = true;
    clearAll();
    setStart(performance.now() / 1000);
    setGlitching(true);
    after(Math.max(ctx.n("duration"), 0.1), () => {
      setGlitching(false);
      setInvalid(true);
      if (buzz) haptics.error();
      after(2.2, () => {
        setInvalid(false);
        busy.current = false;
      });
    });
  };

  useAutoplay(ctx.isPreview, () => apply(false), { every: 3.0, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ ...demoCard(22), width: 306, padding: 18, display: "flex", flexDirection: "column", gap: 10 }}>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "优惠码" : "Promo code"}</span>
        <div style={{ display: "flex", gap: 10 }}>
          <div style={{ position: "relative", flex: 1, height: 50, borderRadius: 14, background: Palette.surface, padding: "0 14px", display: "flex", alignItems: "center", overflow: "hidden" }}>
            <motion.div
              initial={false}
              animate={{ boxShadow: `inset 0 0 0 ${invalid ? 1.5 : 1}px ${invalid ? Palette.red : "rgb(var(--ml-label-rgb) / 0.1)"}` }}
              transition={fade}
              style={{ position: "absolute", inset: 0, borderRadius: 14, pointerEvents: "none" }}
            />
            <GlitchText glitching={glitching} invalid={invalid} start={start} intensity={ctx.n("intensity")} fps={ctx.isPreview ? 30 : undefined} fade={fade} />
          </div>
          <button
            type="button"
            onClick={() => apply()}
            style={{ width: 74, height: 50, borderRadius: 14, background: Palette.primary, color: "#fff", fontSize: 15, fontWeight: 600 }}
          >
            {zh ? "使用" : "Apply"}
          </button>
        </div>
        <div style={{ position: "relative", height: 16, fontSize: 12, lineHeight: "16px", fontWeight: 500 }}>
          <AnimatePresence initial={false}>
            <motion.div
              key={invalid ? "bad" : "ok"}
              initial={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
              animate={{ opacity: 1, filter: "blur(0px)", scale: 1 }}
              exit={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
              transition={fade}
              style={{ position: "absolute", left: 0, top: 0, display: "flex", alignItems: "center", gap: 6, transformOrigin: "0% 50%", whiteSpace: "nowrap", color: invalid ? Palette.red : Palette.secondaryLabel }}
            >
              {invalid && <CircleAlert size={13} fill="currentColor" stroke="var(--ml-elevated)" strokeWidth={2.4} />}
              {invalid ? (zh ? "该优惠码已过期" : "This code has expired") : zh ? "每单限用一个优惠码" : "One code per order"}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap Apply" zh="点击使用" />
    </div>
  );
}

function GlitchText({ glitching, invalid, start, intensity, fps, fade }: { glitching: boolean; invalid: boolean; start: number; intensity: number; fps?: number; fade: ReturnType<typeof anim.easeInOut> }) {
  useClock(glitching, fps);
  const label = (color: string, extra?: React.CSSProperties) => (
    <span style={{ fontFamily: fonts.mono, fontSize: 20, lineHeight: "24px", height: 24, fontWeight: 700, color, whiteSpace: "nowrap", display: "block", ...extra }}>SPRING24</span>
  );
  if (!glitching) {
    return (
      <motion.span initial={false} animate={{ color: invalid ? Palette.red : "rgb(var(--ml-label-rgb))" }} transition={fade} style={{ position: "relative" }}>
        <span style={{ fontFamily: fonts.mono, fontSize: 20, lineHeight: "24px", fontWeight: 700, whiteSpace: "nowrap", textDecoration: invalid ? `line-through ${Palette.red}` : "none", textDecorationThickness: 1.5 }}>SPRING24</span>
      </motion.span>
    );
  }
  const step = Math.floor(Math.max(0, performance.now() / 1000 - start) / 0.05);
  const red = (hash(step, 1) * 2 - 1) * intensity;
  const cyan = (hash(step, 2) * 2 - 1) * intensity;
  const split = 6 + 12 * hash(step, 3);
  const top = (hash(step, 4) * 2 - 1) * intensity;
  const bottom = (hash(step, 5) * 2 - 1) * intensity;
  return (
    <div style={{ position: "relative", height: 24 }}>
      {label("rgb(255 59 48 / 0.7)", { transform: `translateX(${Math.abs(red)}px)` })}
      <div style={{ position: "absolute", left: 0, top: 0 }}>{label("rgb(50 173 230 / 0.7)", { transform: `translateX(${-Math.abs(cyan)}px)` })}</div>
      <div style={{ position: "absolute", left: 0, top: 0, clipPath: `inset(0 -20px ${24 - split}px -20px)`, transform: `translateX(${top}px)` }}>{label(Palette.label)}</div>
      <div style={{ position: "absolute", left: 0, top: 0, clipPath: `inset(${split}px -20px 0 -20px)`, transform: `translateX(${bottom}px)` }}>{label(Palette.label)}</div>
    </div>
  );
}
