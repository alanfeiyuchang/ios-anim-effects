/** loading.dots-button · 发送 · 跳点 · 已发送 (Loading+ButtonVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Check, Send } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, spring, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { previewFps } from "./shared";

type Phase = "idle" | "sending" | "sent";

export default function DotsButton({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [phase, setPhase] = useState<Phase>("idle");
  const phaseRef = useRef<Phase>("idle");
  phaseRef.current = phase;
  const token = useRef(0);
  const timers = useRef<number[]>([]);
  const muted = useRef(false);
  useEffect(() => () => timers.current.forEach(clearTimeout), []);
  const springT = spring(ctx.n("response"), ctx.n("damping"));

  const send = () => {
    if (phaseRef.current !== "idle") return;
    const wait = ctx.n("duration");
    const quiet = muted.current;
    token.current += 1;
    const current = token.current;
    haptics.tap("medium");
    setPhase("sending");
    timers.current.forEach(clearTimeout);
    timers.current = [
      window.setTimeout(() => {
        if (token.current !== current) return;
        setPhase("sent");
        if (!quiet) haptics.success();
        timers.current.push(window.setTimeout(() => token.current === current && setPhase("idle"), 1400));
      }, wait * 1000),
    ];
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      muted.current = true;
      send();
      muted.current = false;
    },
    { every: ctx.n("duration") + 3.2, delay: 0.5 },
  );

  const zh = ctx.lang === "zh";
  const width = phase === "idle" ? 150 : phase === "sending" ? 96 : 136;
  const roll = {
    initial: { y: 18, opacity: 0, filter: "blur(6px)" },
    animate: { y: 0, opacity: 1, filter: "blur(0px)" },
    exit: { y: -18, opacity: 0, filter: "blur(6px)" },
    transition: springT,
  };
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 20 }}>
      <div
        style={{
          width: 278,
          padding: 14,
          fontSize: 15,
          lineHeight: "20px",
          borderRadius: 18,
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
        }}
      >
        {zh ? "周五的评审我们推到下午三点吧 🙌" : "Let's move Friday's review to 3 pm 🙌"}
      </div>
      <button type="button" onClick={send} style={{ display: "block" }}>
        <motion.div
          initial={false}
          animate={{ width, boxShadow: `0 6px 12px ${alpha(phase === "sent" ? Palette.green : Palette.indigo, 0.35)}` }}
          transition={springT}
          style={{ position: "relative", height: 50, borderRadius: 25, overflow: "hidden", background: Palette.primary, color: "#fff", fontSize: 17, fontWeight: 600 }}
        >
          <motion.div initial={false} animate={{ opacity: phase === "sent" ? 1 : 0 }} transition={springT} style={{ position: "absolute", inset: 0, background: Palette.successStrong }} />
          <AnimatePresence initial={false}>
            <motion.div key={phase} {...roll} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 7, whiteSpace: "nowrap" }}>
              {phase === "idle" && (
                <>
                  <Send size={17} fill="currentColor" strokeWidth={1.6} />
                  {zh ? "发送" : "Send"}
                </>
              )}
              {phase === "sending" && <Dots preview={ctx.isPreview} />}
              {phase === "sent" && (
                <>
                  <Check size={18} strokeWidth={3} />
                  {zh ? "已发送" : "Sent"}
                </>
              )}
            </motion.div>
          </AnimatePresence>
        </motion.div>
      </button>
      <DemoHint ctx={ctx} en="Tap Send" zh="点击发送" />
    </div>
  );
}

function Dots({ preview }: { preview: boolean }) {
  useClock(true, previewFps(preview));
  const t = performance.now() / 1000 / 0.6;
  return (
    <div style={{ display: "flex", gap: 6 }}>
      {[0, 1, 2].map((i) => {
        const raw = t - i * 0.2;
        const phase = raw - Math.floor(raw);
        const lift = phase < 0.5 ? Math.sin(phase * 2 * Math.PI) : 0;
        return <div key={i} style={{ width: 8, height: 8, borderRadius: "50%", background: "#fff", transform: `translateY(${-5 * lift}px)`, opacity: 0.6 + 0.4 * lift }} />;
      })}
    </div>
  );
}
