/** feedback.error-shake · 错误抖动 (Feedback+Status.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, anim, demoCard, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { PrimaryCapsule, SPRINGS, track, trackDuration, type Keyframe } from "./shared";

export default function ErrorShake({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [attempts, setAttempts] = useState(0);
  const [isError, setIsError] = useState(false);
  const [fade, setFade] = useState(anim.snappyD(0.2));
  const a = ctx.n("amplitude");
  const s = ctx.n("speed");

  const frames: Keyframe[] = [
    { cubic: -a, d: 0.06 * s },
    { cubic: a * 0.8, d: 0.09 * s },
    { cubic: -a * 0.55, d: 0.08 * s },
    { cubic: a * 0.3, d: 0.07 * s },
    { cubic: -a * 0.12, d: 0.06 * s },
    { spring: 0, d: 0.2 * s, ...SPRINGS.snappy },
  ];
  const t = useElapsed(attempts, trackDuration(frames) + 0.6, true);
  const x = t < 0 ? 0 : track(t, 0, frames);

  const fail = () => {
    clearAll();
    setAttempts((n) => n + 1);
    haptics.error();
    setFade(anim.snappyD(0.2));
    setIsError(true);
    after(1.2, () => {
      setFade(anim.smoothD(0.4));
      setIsError(false);
    });
  };

  useAutoplay(ctx.isPreview, fail, { every: 2.0, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ ...demoCard(26), position: "relative", padding: 24, display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <div style={{ position: "relative", display: "grid", placeItems: "center", height: 22 }}>
          <motion.div initial={false} animate={{ opacity: isError ? 0 : 1, y: isError ? 6 : 0 }} transition={fade} style={{ gridArea: "1/1", fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>
            {ctx.t("Enter Passcode", "输入密码")}
          </motion.div>
          <motion.div
            initial={false}
            animate={{ opacity: isError ? 1 : 0, y: isError ? 0 : -6 }}
            transition={fade}
            style={{ gridArea: "1/1", fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.red, whiteSpace: "nowrap" }}
          >
            {ctx.t("Wrong passcode. Try again.", "密码错误，请重试")}
          </motion.div>
        </div>
        <div style={{ transform: `translateX(${x}px)` }}>
          <motion.div
            initial={false}
            animate={{ boxShadow: `inset 0 0 0 ${isError ? 1.5 : 1}px ${isError ? Palette.red : "rgb(var(--ml-label-rgb) / 0.08)"}` }}
            transition={fade}
            style={{ width: 200, height: 50, borderRadius: 25, background: Palette.surface, display: "flex", alignItems: "center", justifyContent: "center", gap: 18 }}
          >
            {[0, 1, 2, 3].map((i) => (
              <motion.div key={i} initial={false} animate={{ backgroundColor: isError ? Palette.red : "rgb(var(--ml-label-rgb))" }} transition={fade} style={{ width: 12, height: 12, borderRadius: "50%" }} />
            ))}
          </motion.div>
        </div>
        <PrimaryCapsule onClick={fail} height={48} style={{ width: 200, justifyContent: "center", boxShadow: "none" }}>
          {ctx.t("Unlock", "解锁")}
        </PrimaryCapsule>
        <div style={{ position: "absolute", left: "50%", bottom: -30, transform: "translate(-50%, 50%)", whiteSpace: "nowrap" }}>
          <DemoHint ctx={ctx} en="Tap Unlock" zh="点击“解锁”" />
        </div>
      </div>
    </div>
  );
}
