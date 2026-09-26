/** gestures.slide-to-confirm · 滑动确认 (Gestures+SlideToConfirm.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { Check, ChevronsRight, LockOpen } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, black, clamp, rubberBand, spring, useAutoplay, useClock, useHaptics, usePan, type DemoProps } from "../../kit";
import { colorGradient, predictedEnd, useScript } from "./_a-common";

const TRACK = 290;
const KNOB = 56;
const INSET = 4;
const MAX_X = TRACK - KNOB - INSET * 2;

export default function SlideToConfirm({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const resetTask = useScript();
  const x = useMotionValue(0);
  const [progress, setProgress] = useState(0);
  useMotionValueEvent(x, "change", (v) => setProgress(clamp(v / MAX_X)));
  const [confirmed, setConfirmed] = useState(false);
  const [pressed, setPressed] = useState(false);
  const st = useRef({ held: false, confirmed: false });
  const s = st.current;

  const confirm = (haptic = true) => {
    animate(x, MAX_X, spring(0.35, 0.8));
    s.confirmed = true;
    setConfirmed(true);
    if (haptic) haptics.success();
    resetTask.cancel();
    resetTask.after(1.8, () => {
      animate(x, 0, spring(0.5, 0.86));
      s.confirmed = false;
      setConfirmed(false);
    });
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (s.confirmed) return;
      if (!s.held) {
        s.held = true;
        script.cancel();
        x.stop();
        setPressed(true);
      }
      const raw = translation.x;
      x.set(raw < 0 ? rubberBand(raw, 20) : raw > MAX_X ? MAX_X + rubberBand(raw - MAX_X, 16) : raw);
    },
    onEnd: ({ translation, velocity }) => {
      if (!s.held) return;
      s.held = false;
      setPressed(false);
      if (s.confirmed) return;
      const cur = x.get();
      const flicked = predictedEnd(translation, velocity).x > MAX_X * 1.2 && cur > MAX_X * 0.5;
      if (cur > MAX_X * ctx.n("threshold") || flicked) confirm();
      else animate(x, 0, spring(0.45, ctx.n("damping")));
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (s.confirmed || s.held) return;
      animate(x, MAX_X * 0.92, anim.easeInOut(0.8));
      script.cancel();
      script.after(0.85, () => confirm(false));
    },
    { every: 3.4, delay: 0.8 },
  );

  const fillWidth = useTransform(x, (v) => Math.min(TRACK, KNOB + INSET * 2 + Math.max(v, 0)));
  const knobX = useTransform(x, (v) => INSET + v);
  const confirmSpring = spring(0.35, 0.8);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div style={{ position: "relative", width: TRACK, height: KNOB + INSET * 2, flexShrink: 0 }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: 999, background: Palette.labelAlpha(0.07) }} />
        <motion.div
          initial={false}
          animate={{ opacity: confirmed ? 1 : 0 }}
          transition={confirmed ? confirmSpring : spring(0.5, 0.86)}
          style={{ position: "absolute", inset: 0, borderRadius: 999, background: colorGradient(Palette.green) }}
        />
        <motion.div
          animate={{ opacity: confirmed ? 0 : 0.3 + 0.7 * progress }}
          transition={{ duration: 0 }}
          style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: fillWidth, borderRadius: 999, background: Palette.aurora }}
        />
        <AnimatePresence initial={false}>
          {confirmed ? (
            <motion.div
              key="done"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              transition={confirmSpring}
              style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 7, color: "#fff", fontSize: 17, fontWeight: 600 }}
            >
              <LockOpen size={17} strokeWidth={2.6} />
              {ctx.t("Confirmed", "已确认")}
            </motion.div>
          ) : (
            <motion.div
              key="label"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={confirmSpring}
              style={{ position: "absolute", inset: 0, paddingLeft: KNOB, display: "flex", alignItems: "center", justifyContent: "center" }}
            >
              <div style={{ opacity: Math.max(1 - progress * 2, 0) }}>
                <Shimmer text={ctx.t("Slide to confirm", "滑动以确认")} fps={ctx.isPreview ? 30 : undefined} paused={progress > 0.5} />
              </div>
            </motion.div>
          )}
        </AnimatePresence>
        <motion.div {...pan} style={{ ...pan.style, position: "absolute", left: 0, top: INSET, x: knobX, width: KNOB, height: KNOB, cursor: "grab" }}>
          <motion.div
            initial={false}
            animate={{ scale: pressed ? 0.94 : 1, boxShadow: `0 ${pressed ? 2 : 4}px ${pressed ? 4 : 8}px ${black(pressed ? 0.12 : 0.18)}` }}
            transition={spring(0.25, 0.7)}
            style={{ width: KNOB, height: KNOB, borderRadius: "50%", background: "#fff", display: "grid", placeItems: "center" }}
          >
            <AnimatePresence mode="popLayout" initial={false}>
              <motion.span
                key={confirmed ? "check" : "chev"}
                initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                transition={anim.snappyD(0.3)}
                style={{ display: "grid", color: confirmed ? Palette.green : Palette.indigo }}
              >
                {confirmed ? <Check size={22} strokeWidth={3.2} /> : <ChevronsRight size={22} strokeWidth={3} />}
              </motion.span>
            </AnimatePresence>
          </motion.div>
        </motion.div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 999, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Drag the knob to the end" zh="把滑块拖到最右端" />
    </div>
  );
}

function Shimmer({ text, fps, paused }: { text: string; fps?: number; paused: boolean }) {
  const t = useClock(!paused, fps);
  const phase = (t % 2) / 2;
  const a = (phase * 3 - 1.5) * 100;
  const b = (phase * 3 - 0.5) * 100;
  const dim = Palette.labelAlpha(0.35);
  const bright = Palette.labelAlpha(0.95);
  return (
    <span
      style={{
        fontSize: 17,
        lineHeight: "22px",
        fontWeight: 600,
        whiteSpace: "nowrap",
        backgroundImage: `linear-gradient(90deg, ${dim} ${a}%, ${bright} ${(a + b) / 2}%, ${dim} ${b}%)`,
        WebkitBackgroundClip: "text",
        backgroundClip: "text",
        color: "transparent",
      }}
    >
      {text}
    </span>
  );
}
