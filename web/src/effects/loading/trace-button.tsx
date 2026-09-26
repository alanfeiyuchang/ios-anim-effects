/** loading.trace-button · 描边追光按钮 (Loading+ButtonVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Check } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { makeRun, previewFps, primary, springSmooth, useAnimatedNumber, type Run } from "./shared";

type Phase = "idle" | "working" | "done";
const W = 230;
const H = 56;
const COLORS = [Palette.sky, Palette.sky, Palette.blue, Palette.indigo, Palette.violet, Palette.violet];

/** The capsule outline inset 1.5 pt, starting where the top edge begins, clockwise. */
const r = (H - 3) / 2;
const OUTLINE = `M ${1.5 + r} 1.5 H ${W - 1.5 - r} A ${r} ${r} 0 0 1 ${W - 1.5 - r} ${H - 1.5} H ${1.5 + r} A ${r} ${r} 0 0 1 ${1.5 + r} 1.5 Z`;

/** `TraceSlice`: a stretch of the outline that may wrap across the seam. */
function Slice({ from, length, color, width = 3, cap = "butt" }: { from: number; length: number; color: string; width?: number; cap?: "butt" | "round" }) {
  let start = from - Math.floor(from);
  if (start >= 1) start = 0;
  const len = Math.min(Math.max(length, 0), 1);
  const end = start + len;
  const seg = (a: number, b: number, k: string) =>
    b - a > 0.0005 ? <path key={k} d={OUTLINE} pathLength={1} fill="none" stroke={color} strokeWidth={width} strokeLinecap={cap} strokeDasharray={`${b - a} 2`} strokeDashoffset={-a} /> : null;
  return (
    <>
      {seg(start, Math.min(end, 1), "a")}
      {end > 1 && seg(0, end - 1, "b")}
    </>
  );
}

export default function TraceButton({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [phase, setPhase] = useState<Phase>("idle");
  const [started, setStarted] = useState(0);
  const [closeFrom, setCloseFrom] = useState(0);
  const closed = useAnimatedNumber(0);
  const phaseRef = useRef<Phase>("idle");
  phaseRef.current = phase;
  const task = useRef<Run | null>(null);
  const muted = useRef(false);
  useEffect(() => () => task.current?.cancel(), []);

  const tap = () => {
    if (phaseRef.current === "done") {
      task.current?.cancel();
      setPhase("idle");
      closed.to(0, springSmooth(0.35));
      return;
    }
    if (phaseRef.current !== "idle") return;
    const live = !ctx.isPreview;
    const quiet = muted.current;
    haptics.tap("medium");
    const start = performance.now();
    setStarted(start);
    closed.mv.jump(0);
    closed.target.current = 0;
    setPhase("working");
    const wait = ctx.n("duration");
    const lap = Math.max(ctx.n("lap"), 0.2);
    task.current?.cancel();
    const run = makeRun();
    task.current = run;
    (async () => {
      await run.sleep(wait);
      const head = ((performance.now() - start) / 1000 / lap) % 1;
      setCloseFrom(head);
      setPhase("done");
      closed.to(1, anim.easeInOut(0.5));
      if (!quiet) haptics.success();
      if (!live) {
        await run.sleep(2.2);
        setPhase("idle");
        closed.to(0, springSmooth(0.35));
      }
    })().catch(() => {});
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      muted.current = true;
      tap();
      muted.current = false;
    },
    { every: ctx.n("duration") + 3.4, delay: 0.5 },
  );

  const zh = ctx.lang === "zh";
  const done = phase === "done";
  const push = { initial: { y: H, opacity: 0 }, animate: { y: 0, opacity: 1 }, exit: { y: -H, opacity: 0 }, transition: anim.easeInOut(0.3) };
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <button type="button" onClick={tap} style={{ display: "block" }}>
        <div style={{ position: "relative", width: W, height: H, borderRadius: H / 2 }}>
          <div
            style={{
              position: "absolute",
              inset: 0,
              borderRadius: H / 2,
              background: alpha(Palette.green, done ? 0.12 : 0),
              boxShadow: `inset 0 0 0 1px ${primary(0.15)}`,
              transition: "background 0.3s cubic-bezier(0.42,0,0.58,1)",
            }}
          />
          <AnimatePresence>
            {phase === "working" && (
              <motion.div key="comet" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={anim.easeInOut(0.3)} style={{ position: "absolute", inset: 0 }}>
                <Comet started={started} lap={Math.max(ctx.n("lap"), 0.2)} length={ctx.n("length")} preview={ctx.isPreview} />
              </motion.div>
            )}
          </AnimatePresence>
          {closed.value > 0.001 && (
            <svg width={W} height={H} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
              <Slice from={closeFrom} length={closed.value} color={Palette.green} cap="round" />
            </svg>
          )}
          <div style={{ position: "absolute", inset: 0, overflow: "hidden", borderRadius: H / 2 }}>
            <AnimatePresence initial={false}>
              <motion.div key={phase} {...push} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 6, fontSize: 17, fontWeight: 600 }}>
                {phase === "idle" && <span>{zh ? "部署" : "Deploy"}</span>}
                {phase === "working" && (
                  <motion.span
                    animate={{ opacity: [1, 0.55] }}
                    transition={{ duration: 0.7, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
                    style={{ color: Palette.secondaryLabel }}
                  >
                    {zh ? "正在部署…" : "Deploying…"}
                  </motion.span>
                )}
                {phase === "done" && (
                  <span style={{ display: "flex", alignItems: "center", gap: 6, color: Palette.green }}>
                    <Check size={17} strokeWidth={3} />
                    {zh ? "已上线" : "Live"}
                  </span>
                )}
              </motion.div>
            </AnimatePresence>
          </div>
        </div>
      </button>
      <DemoHint ctx={ctx} en="Tap Deploy" zh="点击部署" />
    </div>
  );
}

function Comet({ started, lap, length, preview }: { started: number; lap: number; length: number; preview: boolean }) {
  useClock(true, previewFps(preview));
  const head = ((performance.now() - started) / 1000 / lap) % 1;
  const slice = length / 6;
  const comet = COLORS.map((c, i) => <Slice key={i} from={head - length + i * slice} length={slice + 0.002} color={alpha(c, (i + 1) / 6)} />);
  return (
    <>
      <svg width={W} height={H} style={{ position: "absolute", inset: 0, overflow: "visible", filter: "blur(5px)", opacity: 0.7 }}>
        {comet}
      </svg>
      <svg width={W} height={H} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        {comet}
      </svg>
    </>
  );
}
