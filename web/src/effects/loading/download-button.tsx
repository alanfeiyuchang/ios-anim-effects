/** loading.download-button · 下载按钮 (Loading+DownloadButton.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Sparkles } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, demoCard, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { previewFps, primary, usePhase } from "./shared";

type Phase = "idle" | "waiting" | "downloading" | "done";
const SIDE = 36;

export default function DownloadButton({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [phase, setPhase] = useState<Phase>("idle");
  const [progress, setProgress] = useState(0);
  const [transition, setTransition] = useState(spring(0.45, 0.8));
  const phaseRef = useRef(phase);
  phaseRef.current = phase;
  const token = useRef(0);
  const timer = useRef(0);
  const muted = useRef(false);
  useEffect(() => () => clearTimeout(timer.current), []);

  const springT = spring(ctx.n("response"), ctx.n("damping"));

  const begin = () => {
    token.current += 1;
    const current = token.current;
    const speed = ctx.n("speed");
    const quiet = muted.current;
    haptics.tap("medium");
    setTransition(springT);
    setPhase("waiting");
    clearTimeout(timer.current);
    let value = 0;
    const tick = () => {
      if (token.current !== current) return;
      if (value >= 1) {
        timer.current = window.setTimeout(() => {
          if (token.current !== current) return;
          setTransition(springT);
          setPhase("done");
          if (!quiet) haptics.success();
        }, 300);
        return;
      }
      timer.current = window.setTimeout(() => {
        if (token.current !== current) return;
        value = Math.min(1, value + (0.02 + Math.random() * 0.06) * speed);
        setProgress(value);
        tick();
      }, 120);
    };
    timer.current = window.setTimeout(() => {
      if (token.current !== current) return;
      setTransition(anim.easeInOut(0.25));
      setPhase("downloading");
      tick();
    }, 700);
  };

  const tap = () => {
    if (phaseRef.current === "idle") {
      begin();
      return;
    }
    token.current += 1;
    clearTimeout(timer.current);
    haptics.tap();
    setTransition(springT);
    setPhase("idle");
    setProgress(0);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (phaseRef.current === "idle" || phaseRef.current === "done") {
        muted.current = true;
        tap();
        muted.current = false;
      }
    },
    { every: 2.4, delay: 0.6 },
  );

  const zh = ctx.lang === "zh";
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 24 }}>
      <div style={{ ...demoCard(), width: 310, padding: 16, display: "flex", alignItems: "center", gap: 14 }}>
        <div style={{ width: 56, height: 56, borderRadius: 13, background: Palette.primary, display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
          <Sparkles size={26} fill="currentColor" strokeWidth={1.2} />
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
          <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>Motionary</span>
          <span style={{ fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel }}>{zh ? "设计工具" : "Design Tools"}</span>
        </div>
        <div style={{ flex: 1, minWidth: 8 }} />
        <button type="button" onClick={tap} style={{ display: "block" }}>
          <Face phase={phase} progress={progress} zh={zh} preview={ctx.isPreview} transition={transition} />
        </button>
      </div>
      <DemoHint ctx={ctx} en="Tap GET" zh="点击“获取”" />
    </div>
  );
}

function Face({ phase, progress, zh, preview, transition }: { phase: Phase; progress: number; zh: boolean; preview: boolean; transition: ReturnType<typeof spring> }) {
  const circular = phase === "waiting" || phase === "downloading";
  const title = phase === "done" ? (zh ? "打开" : "OPEN") : zh ? "获取" : "GET";
  return (
    <motion.div
      initial={false}
      animate={{ width: circular ? SIDE : 88 }}
      transition={transition}
      style={{ position: "relative", height: SIDE }}
    >
      <motion.div
        initial={false}
        animate={{ opacity: circular ? 0 : 1 }}
        transition={transition}
        style={{ position: "absolute", inset: 0, borderRadius: SIDE / 2, background: alpha(Palette.blue, 0.14) }}
      />
      <motion.div
        initial={false}
        animate={{ opacity: circular ? 1 : 0 }}
        transition={transition}
        style={{ position: "absolute", inset: 0, borderRadius: SIDE / 2, boxShadow: `inset 0 0 0 3px ${primary(0.12)}` }}
      />
      <AnimatePresence>
        {phase === "waiting" && (
          <motion.div key="wait" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={transition} style={{ position: "absolute", inset: 0 }}>
            <WaitingArc preview={preview} />
          </motion.div>
        )}
        {phase === "downloading" && (
          <motion.div key="ring" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={transition} style={{ position: "absolute", inset: 0 }}>
            <svg width={SIDE} height={SIDE} style={{ transform: "rotate(-90deg)", overflow: "visible" }}>
              <motion.circle
                cx={SIDE / 2}
                cy={SIDE / 2}
                r={SIDE / 2 - 1.5}
                fill="none"
                stroke={Palette.blue}
                strokeWidth={3}
                strokeLinecap="round"
                initial={{ pathLength: 0 }}
                animate={{ pathLength: progress, opacity: progress > 0.001 ? 1 : 0 }}
                transition={anim.linear(0.12)}
              />
            </svg>
          </motion.div>
        )}
        {phase === "downloading" && (
          <motion.div
            key="stop"
            initial={{ scale: 0.2, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.2, opacity: 0 }}
            transition={transition}
            style={{ position: "absolute", left: SIDE / 2 - 5.5, top: SIDE / 2 - 5.5, width: 11, height: 11, borderRadius: 2.5, background: Palette.blue }}
          />
        )}
      </AnimatePresence>
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
        <motion.span
          initial={false}
          animate={{ opacity: circular ? 0 : 1, scale: circular ? 0.6 : 1, filter: `blur(${circular ? 4 : 0}px)` }}
          transition={transition}
          style={{ fontSize: 15, fontWeight: 700, color: Palette.blue, whiteSpace: "nowrap" }}
        >
          {title}
        </motion.span>
      </div>
    </motion.div>
  );
}

function WaitingArc({ preview }: { preview: boolean }) {
  const t = usePhase(1, previewFps(preview));
  const deg = (t % 1) * 360;
  return (
    <svg width={SIDE} height={SIDE} style={{ transform: `rotate(${deg}deg)`, overflow: "visible" }}>
      <circle
        cx={SIDE / 2}
        cy={SIDE / 2}
        r={SIDE / 2 - 1.5}
        fill="none"
        stroke={Palette.blue}
        strokeWidth={3}
        strokeLinecap="round"
        pathLength={1}
        strokeDasharray="0.25 2"
      />
    </svg>
  );
}
