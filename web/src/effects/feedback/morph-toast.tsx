/** feedback.morph-toast · 形变状态吐司 (Feedback+ToastVariations.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { CircleCheck } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, spring, useAutoplay, useClock, useHaptics, useTimeouts, type DemoProps } from "../../kit";

type Stage = 0 | 1 | 2 | 3; // hidden, uploading, done, dot
const TILES = [Palette.coral, Palette.sky, Palette.mint, Palette.violet, Palette.amber, Palette.pink];

export default function MorphToast({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [stage, setStageState] = useState<Stage>(0);
  const [t, setT] = useState<Transition>(spring(0.45, 0.8));
  const stageRef = useRef<Stage>(0);
  const zh = ctx.lang === "zh";
  const setStage = (s: Stage, tr: Transition) => {
    stageRef.current = s;
    setT(tr);
    setStageState(s);
  };

  const start = (buzz = true) => {
    if (stageRef.current !== 0) return;
    clearAll();
    const sp = spring(ctx.n("response"), 0.8);
    if (buzz) haptics.tap();
    setStage(1, sp);
    after(ctx.n("upload"), () => {
      setStage(2, sp);
      if (buzz) haptics.success();
      after(1.6, () => {
        setStage(3, anim.snappyD(0.35));
        after(0.85, () => setStage(0, anim.easeIn(0.3)));
      });
    });
  };

  useAutoplay(ctx.isPreview, () => start(false), { every: ctx.n("upload") + 4.4, delay: 0.4 });

  const visible = stage !== 0;
  const isDot = stage === 3 || stage === 0;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ position: "relative", width: 300, height: 300, flexShrink: 0, borderRadius: 26, overflow: "hidden" }}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 4 }}>
          {Array.from({ length: 9 }, (_, i) => (
            <div
              key={i}
              onClick={() => start()}
              style={{ position: "relative", aspectRatio: "1", borderRadius: 4, background: `linear-gradient(rgb(255 255 255 / 0.14), transparent), ${TILES[i % TILES.length]}`, cursor: "pointer" }}
            >
              <AnimatePresence>
                {i < 3 && stage >= 1 && (
                  <motion.div initial={{ scale: 0, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0, opacity: 0 }} transition={t} style={{ position: "absolute", right: 6, top: 6, width: 18, height: 18 }}>
                    <svg width={18} height={18} viewBox="0 0 18 18">
                      <circle cx={9} cy={9} r={8.5} fill={Palette.indigo} />
                      <path d="M5.4 9.3l2.4 2.3 4.6-4.9" fill="none" stroke="#fff" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          ))}
        </div>
        <div style={{ position: "absolute", left: 0, right: 0, bottom: 24, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
          <motion.div initial={false} animate={{ y: visible ? 0 : 60, opacity: visible ? 1 : 0 }} transition={t}>
            <motion.div
              layout
              transition={t}
              style={{
                position: "relative",
                height: isDot ? 12 : 44,
                minWidth: 12,
                padding: isDot ? 0 : "0 16px",
                borderRadius: 999,
                overflow: "hidden",
                boxShadow: "0 8px 14px rgb(0 0 0 / 0.25)",
                display: "flex",
                alignItems: "center",
                gap: 10,
                color: "#fff",
                fontSize: 15,
                fontWeight: 600,
                whiteSpace: "nowrap",
              }}
            >
              <div style={{ position: "absolute", inset: 0, background: "rgb(0 0 0 / 0.82)" }} />
              <motion.div initial={false} animate={{ opacity: isDot ? 1 : 0 }} transition={t} style={{ position: "absolute", inset: 0, background: Palette.green }} />
              <AnimatePresence mode="popLayout" initial={false}>
                {stage === 1 && (
                  <motion.div key="up" layout="position" initial={{ opacity: 0, filter: "blur(4px)", scale: 0.8 }} animate={{ opacity: 1, filter: "blur(0px)", scale: 1 }} exit={{ opacity: 0, filter: "blur(4px)", scale: 0.8 }} transition={t} style={{ position: "relative", display: "flex", alignItems: "center", gap: 10 }}>
                    <Spinner fps={ctx.isPreview ? 30 : undefined} />
                    {zh ? "正在上传 3 张照片" : "Uploading 3 photos"}
                  </motion.div>
                )}
                {stage === 2 && (
                  <motion.div key="done" layout="position" initial={{ opacity: 0, filter: "blur(4px)", scale: 0.8 }} animate={{ opacity: 1, filter: "blur(0px)", scale: 1 }} exit={{ opacity: 0, filter: "blur(4px)", scale: 0.8 }} transition={t} style={{ position: "relative", display: "flex", alignItems: "center", gap: 10 }}>
                    <CircleCheck size={19} fill={Palette.green} stroke="#1c1c1e" strokeWidth={2.2} />
                    {zh ? "已上传到共享相簿" : "Uploaded to Shared Album"}
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          </motion.div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap a photo to upload" zh="点击照片开始上传" />
    </div>
  );
}

function Spinner({ fps }: { fps?: number }) {
  const t = useClock(true, fps) + performance.timeOrigin / 1000;
  return (
    <svg width={18} height={18} style={{ transform: `rotate(${((t % 0.8) / 0.8) * 360}deg)` }}>
      <circle cx={9} cy={9} r={7.75} fill="none" stroke="#fff" strokeWidth={2.5} strokeLinecap="round" pathLength={1} strokeDasharray="0 0.1 0.7 2" />
    </svg>
  );
}
