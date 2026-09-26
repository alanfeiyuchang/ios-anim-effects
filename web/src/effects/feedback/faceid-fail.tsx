/** feedback.faceid-fail · 面容识别摇头 (Feedback+ErrorVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, glass, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { SPRINGS, track } from "./shared";

type State = "idle" | "scanning" | "failed";

export default function FaceIDFail({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [state, setStateRaw] = useState<State>("idle");
  const [fails, setFails] = useState(0);
  const stateRef = useRef<State>("idle");
  const zh = ctx.lang === "zh";
  const failed = state === "failed";
  const setState = (s: State) => {
    stateRef.current = s;
    setStateRaw(s);
  };
  const scan = Math.max(ctx.n("scan"), 0.3);

  const attempt = (buzz = true) => {
    if (stateRef.current === "scanning") return;
    clearAll();
    setState("scanning");
    after(scan, () => {
      setState("failed");
      setFails((f) => f + 1);
      if (buzz) haptics.error();
      after(2.0, () => stateRef.current === "failed" && setState("idle"));
    });
  };

  useAutoplay(ctx.isPreview, () => attempt(false), { every: ctx.n("scan") + 3.4, delay: 0.5 });

  const yaw = ctx.n("yaw");
  const e = useElapsed(fails, 1.0, true);
  const angle = e < 0 ? 0 : track(e, 0, [{ cubic: yaw, d: 0.12 }, { cubic: -yaw * 0.78, d: 0.14 }, { cubic: yaw * 0.5, d: 0.12 }, { cubic: -yaw * 0.28, d: 0.1 }, { spring: 0, d: 0.2, ...SPRINGS.smooth }]);
  const tint = failed ? Palette.red : Palette.sky;
  const fade = anim.easeInOut(0.2);
  const captions: Record<State, [string, string]> = { idle: ["Confirm with Face ID", "使用面容 ID 确认"], scanning: ["Scanning…", "正在识别…"], failed: ["Face Not Recognized", "无法识别面容"] };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div
        onClick={() => attempt()}
        style={{ position: "relative", width: 280, padding: "24px 0", borderRadius: 28, ...glass("regular"), boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 10px 20px rgb(0 0 0 / 0.12)`, display: "flex", flexDirection: "column", alignItems: "center", gap: 18, cursor: "pointer" }}
      >
        <div style={{ position: "relative", width: 120, height: 120 }}>
          <motion.div
            animate={state === "scanning" ? { scale: [1, 0.92] } : { scale: 1 }}
            transition={state === "scanning" ? { duration: 0.5, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" } : anim.easeInOut(0.2)}
            style={{ position: "absolute", inset: 0 }}
          >
            <svg width={120} height={120} style={{ overflow: "visible" }}>
              {[0, 1, 2, 3].map((i) => (
                <motion.path
                  key={i}
                  d="M0 26 L0 8 Q0 0 8 0 L26 0"
                  fill="none"
                  initial={false}
                  animate={{ stroke: tint }}
                  transition={fade}
                  strokeWidth={4}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  transform={`rotate(${i * 90} 60 60)`}
                />
              ))}
            </svg>
          </motion.div>
          <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", perspective: 150 }}>
            <motion.div initial={false} animate={{ color: failed ? Palette.red : "rgb(var(--ml-label-rgb))" }} transition={fade} style={{ transform: `rotateY(${angle}deg)`, display: "grid" }}>
              <FaceIDGlyph size={76} />
            </motion.div>
          </div>
          <AnimatePresence>
            {state === "scanning" && (
              <motion.div key="line" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={fade} style={{ position: "absolute", left: 12, top: 58.5 }}>
                <motion.div
                  initial={{ y: -44 }}
                  animate={{ y: 44 }}
                  transition={anim.easeInOut(scan)}
                  style={{ width: 96, height: 3, background: `linear-gradient(90deg, ${alpha(Palette.sky, 0)}, ${alpha(Palette.sky, 0.8)}, ${alpha(Palette.sky, 0)})`, boxShadow: `0 0 6px ${Palette.sky}` }}
                />
              </motion.div>
            )}
          </AnimatePresence>
        </div>
        <div style={{ position: "relative", height: 22, width: "100%" }}>
          <AnimatePresence initial={false}>
            <motion.div
              key={state}
              initial={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
              animate={{ opacity: 1, filter: "blur(0px)", scale: 1 }}
              exit={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
              transition={anim.smoothD(0.3)}
              style={{ position: "absolute", inset: 0, textAlign: "center", fontSize: 17, lineHeight: "22px", fontWeight: 600, color: failed ? Palette.red : undefined }}
            >
              {captions[state][zh ? 1 : 0]}
            </motion.div>
          </AnimatePresence>
        </div>
        <motion.button type="button" initial={false} animate={{ opacity: failed ? 1 : 0 }} transition={anim.smoothD(0.3)} onClick={(e) => { e.stopPropagation(); attempt(); }} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.accent }}>
          {zh ? "再试一次" : "Try Again"}
        </motion.button>
        <DemoHint ctx={ctx} en="Tap the glyph" zh="点击图标" />
      </div>
    </div>
  );
}

/** SF Symbol `faceid`: corner brackets, eyes, nose and smile. */
function FaceIDGlyph({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 76 76" fill="none" stroke="currentColor" strokeWidth={4.2} strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 22 V13 Q4 4 13 4 H22" />
      <path d="M54 4 H63 Q72 4 72 13 V22" />
      <path d="M72 54 V63 Q72 72 63 72 H54" />
      <path d="M22 72 H13 Q4 72 4 63 V54" />
      <path d="M25 26 V31" />
      <path d="M51 26 V31" />
      <path d="M39 26 V41 Q39 45 35 45 H33.5" />
      <path d="M26 53 Q38 62 50 53" />
    </svg>
  );
}
