/** loading.ai-generating · AI 撰写卡片 (Loading+AIGenerating.swift) */
import { AnimatePresence, motion } from "motion/react";
import { CircleCheck, Sparkles } from "lucide-react";
import { useEffect, useRef, useState, type CSSProperties } from "react";
import { DemoHint, Palette, alpha, anim, spring, useClock, useHaptics, type DemoProps } from "../../kit";
import { previewFps, primary, usePhase } from "./shared";

const COLORS = [Palette.sky, Palette.violet, Palette.pink, Palette.amber, Palette.mint, Palette.sky];
const WIDTHS = [250, 232, 244, 150];

export default function AIGenerating({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [done, setDone] = useState(false);
  const [run, setRun] = useState(0);
  const latest = useRef(ctx);
  latest.current = ctx;

  useEffect(() => {
    const c = latest.current;
    const live = !c.isPreview && run > 0;
    setDone(false);
    const timers = [
      window.setTimeout(() => {
        setDone(true);
        if (live) haptics.success();
        if (latest.current.isPreview) timers.push(window.setTimeout(() => setRun((r) => r + 1), 2200));
      }, c.n("hold") * 1000),
    ];
    return () => timers.forEach(clearTimeout);
  }, [run, haptics]);

  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <Card done={done} period={ctx.n("period")} glow={ctx.n("glow")} zh={ctx.lang === "zh"} preview={ctx.isPreview} />
      <DemoHint ctx={ctx} en="Tap to regenerate" zh="点击重新生成" />
    </div>
  );
}

function Card({ done, period, glow, zh, preview }: { done: boolean; period: number; glow: number; zh: boolean; preview: boolean }) {
  const fps = previewFps(preview);
  const turn = usePhase(1 / Math.max(period, 0.1), fps, !done);
  const fade = anim.easeOut(0.4);
  const cardSpring = spring(0.55, 0.85);
  const smooth = anim.smoothD(0.4);
  const t = done ? cardSpring : smooth;
  return (
    <div style={{ position: "relative", width: 290 }}>
      {/* `.blur(radius: glow).drawingGroup()`: the group is rendered in the card's own bounds, so the
          glow is clipped to that rectangle and only shows past the rounded corners. */}
      <motion.div initial={false} animate={{ opacity: done ? 0 : 0.85 }} transition={fade} style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, filter: `blur(${glow}px)` }}>
          <SpectralBorder turn={turn} lineWidth={5} />
        </div>
      </motion.div>
      <div
        style={{
          position: "relative",
          padding: 20,
          borderRadius: 24,
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 16px rgb(0 0 0 / 0.08)`,
          display: "flex",
          flexDirection: "column",
          gap: 16,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10, height: 32 }}>
          <div style={{ width: 32, height: 32, borderRadius: "50%", background: `linear-gradient(135deg, ${Palette.violet}, ${Palette.pink})`, display: "grid", placeItems: "center", color: "#fff" }}>
            <motion.span
              animate={done ? { opacity: 1 } : { opacity: [1, 0.35, 1] }}
              transition={done ? { duration: 0.3 } : { duration: 1.4, repeat: Infinity, ease: "easeInOut" }}
              style={{ display: "grid" }}
            >
              <Sparkles size={15} fill="currentColor" strokeWidth={1.6} />
            </motion.span>
          </div>
          <div style={{ display: "grid", fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>
            <AnimatePresence initial={false}>
              <motion.span key={done ? "done" : "writing"} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={t} style={{ gridArea: "1 / 1", whiteSpace: "nowrap" }}>
                {done ? (zh ? "草稿已生成" : "Draft ready") : zh ? "正在撰写回复…" : "Writing a reply…"}
              </motion.span>
            </AnimatePresence>
          </div>
          <div style={{ flex: 1 }} />
          <AnimatePresence>
            {done && (
              <motion.span
                initial={{ scale: 0.4, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.4, opacity: 0 }}
                transition={t}
                style={{ display: "grid", color: Palette.green }}
              >
                <CircleCheck size={21} fill="currentColor" stroke="var(--ml-elevated)" strokeWidth={2.2} />
              </motion.span>
            )}
          </AnimatePresence>
        </div>
        <div style={{ display: "grid", alignItems: "start" }}>
          <motion.div initial={false} animate={{ opacity: done ? 0 : 1 }} transition={fade} style={{ gridArea: "1 / 1" }}>
            <ShimmerLines fps={fps} paused={done} />
          </motion.div>
          <motion.div
            initial={false}
            animate={{ opacity: done ? 1 : 0, filter: `blur(${done ? 0 : 8}px)`, y: done ? 0 : 6 }}
            transition={t}
            style={{ gridArea: "1 / 1", width: 250, fontSize: 15, lineHeight: "20px" }}
          >
            {zh
              ? "谢谢更新！周四上午十点可以。我会带上新的动效规范，我们一起过一遍转场细节。"
              : "Thanks for the update — Thursday at 10 works. I'll bring the new motion specs so we can walk through the transitions together."}
          </motion.div>
        </div>
      </div>
      <motion.div initial={false} animate={{ opacity: done ? 0 : 1 }} transition={fade} style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <SpectralBorder turn={turn} lineWidth={2} />
      </motion.div>
    </div>
  );
}

/** `RoundedRectangle(24).strokeBorder(AngularGradient(colors, angle: turn · 360°), lineWidth:)` */
function SpectralBorder({ turn, lineWidth }: { turn: number; lineWidth: number }) {
  const deg = (turn % 1) * 360;
  const stops = COLORS.map((c, i) => `${c} ${((i / (COLORS.length - 1)) * 360).toFixed(1)}deg`).join(", ");
  const ring: CSSProperties = {
    position: "absolute",
    inset: 0,
    borderRadius: 24,
    padding: lineWidth,
    background: `conic-gradient(from ${90 + deg}deg, ${stops})`,
    WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
    WebkitMaskComposite: "xor",
    mask: "linear-gradient(#000 0 0) content-box exclude, linear-gradient(#000 0 0)",
  };
  return <div style={ring} />;
}

function ShimmerLines({ fps, paused }: { fps?: number; paused: boolean }) {
  useClock(!paused, fps);
  const t = performance.now() / 1000;
  const x = ((t / 1.6) % 1) * 2.4 - 0.7;
  const p0 = (x - 0.4) * 250;
  const span = 0.8 * 250;
  const sheen = `linear-gradient(90deg, ${alpha(Palette.violet, 0)} ${p0}px, ${alpha(Palette.violet, 0.55)} ${p0 + 0.42 * span}px, ${alpha(Palette.pink, 0.5)} ${p0 + 0.58 * span}px, ${alpha(Palette.pink, 0)} ${p0 + span}px)`;
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      {WIDTHS.map((w, i) => (
        <div key={i} style={{ position: "relative", width: w, height: 10, borderRadius: 5, background: primary(0.07), overflow: "hidden" }}>
          <div style={{ position: "absolute", left: 0, top: 0, width: 250, height: 10, background: sheen }} />
        </div>
      ))}
    </div>
  );
}
