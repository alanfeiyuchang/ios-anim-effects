/** gestures.stretch-slide · 拉伸滑动发送 (Gestures+StretchSlide.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { Check, Send } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, clamp, delayed, hex, rubberBand, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { colorGradient, useScript } from "./_a-common";

const TRACK = 290;
const KNOB = 56;
const INSET = 4;
const MAX_X = TRACK - KNOB - INSET * 2;

export default function StretchSlide({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const resetTask = useScript();
  const head = useMotionValue(0);
  const tail = useMotionValue(0);
  const [progress, setProgress] = useState(0);
  useMotionValueEvent(head, "change", (v) => setProgress(clamp(v / MAX_X)));
  const [sent, setSent] = useState(false);
  const [planeGone, setPlaneGone] = useState<{ gone: boolean; t: ReturnType<typeof spring> }>({ gone: false, t: anim.easeIn(0.35) });
  const st = useRef({ held: false, sent: false });
  const s = st.current;
  const lag = ctx.n("lag");

  const recoil = () => {
    animate(tail, 0, spring(0.25, 0.8));
    animate(head, 0, spring(0.45 + lag, 0.72));
  };

  const commit = (haptic: boolean) => {
    const sp = spring(0.4, 0.75);
    animate(head, MAX_X, sp);
    animate(tail, 0, sp);
    s.sent = true;
    setSent(true);
    setPlaneGone({ gone: true, t: delayed(anim.easeIn(0.35), 0.1) });
    if (haptic) haptics.success();
    resetTask.cancel();
    resetTask.after(1.8, () => {
      const back = spring(0.5, 0.86);
      s.sent = false;
      setSent(false);
      animate(head, 0, back);
      animate(tail, 0, back);
      setPlaneGone({ gone: false, t: delayed(anim.easeOut(0.2), 0.3) });
    });
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (s.sent) return;
      if (!s.held) {
        s.held = true;
        script.cancel();
      }
      const raw = translation.x;
      const h = raw < 0 ? rubberBand(raw, 16) : raw > MAX_X ? MAX_X + rubberBand(raw - MAX_X, 16) : raw;
      head.stop();
      head.set(h);
      if (h < tail.get()) {
        tail.stop();
        tail.set(h);
      } else animate(tail, h, spring(lag, 0.7));
    },
    onEnd: () => {
      if (!s.held) return;
      s.held = false;
      if (s.sent) return;
      if (head.get() > MAX_X * ctx.n("threshold")) commit(true);
      else recoil();
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (s.sent || s.held) return;
      animate(head, MAX_X * 0.95, anim.easeInOut(0.8));
      animate(tail, MAX_X * 0.95, spring(0.8 + lag, 0.8));
      script.cancel();
      script.after(0.85, () => commit(false));
    },
    { every: 3.4, delay: 0.8 },
  );

  const pillX = useTransform(tail, (t) => INSET + t);
  const pillW = useTransform(() => Math.max(head.get() + KNOB - tail.get(), 0));
  const knobX = useTransform(head, (h) => INSET + h);
  const sentSpring = spring(0.4, 0.75);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div style={{ position: "relative", width: TRACK, height: KNOB + INSET * 2, flexShrink: 0 }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: 999, background: Palette.labelAlpha(0.07) }} />
        <div
          style={{
            position: "absolute",
            inset: 0,
            paddingLeft: KNOB,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 17,
            fontWeight: 600,
            color: Palette.secondaryLabel,
            opacity: sent ? 0 : Math.max(1 - progress * 2, 0),
            transition: sent ? "opacity 0.3s" : undefined,
            whiteSpace: "nowrap",
          }}
        >
          {ctx.t("Slide to send", "滑动发送")}
        </div>
        {/* Pill: from the lagging tail to the leading head. */}
        <motion.div
          style={{
            position: "absolute",
            top: INSET,
            left: 0,
            x: pillX,
            width: pillW,
            height: KNOB,
            borderRadius: KNOB / 2,
            overflow: "hidden",
            boxShadow: `0 5px 10px ${hex(Palette.violet, 0.35)}`,
            pointerEvents: "none",
          }}
        >
          <div style={{ position: "absolute", inset: 0, background: Palette.primary }} />
          <motion.div initial={false} animate={{ opacity: sent ? 1 : 0 }} transition={sent ? sentSpring : spring(0.5, 0.86)} style={{ position: "absolute", inset: 0, background: colorGradient(Palette.green) }} />
        </motion.div>
        <motion.div
          {...pan}
          style={{ ...pan.style, position: "absolute", top: INSET, left: 0, x: knobX, width: KNOB, height: KNOB, borderRadius: "50%", display: "grid", placeItems: "center", color: "#fff", cursor: "grab" }}
        >
          <motion.span
            initial={false}
            animate={{ x: planeGone.gone ? 60 : 0, y: planeGone.gone ? -60 : 0, opacity: planeGone.gone ? 0 : 1 }}
            transition={planeGone.t}
            style={{ gridArea: "1 / 1", display: "grid" }}
          >
            <Send size={21} fill="currentColor" strokeWidth={1.6} strokeLinejoin="round" />
          </motion.span>
          <AnimatePresence>
            {sent && (
              <motion.span
                initial={{ scale: 0.3, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.3, opacity: 0 }}
                transition={sentSpring}
                style={{ gridArea: "1 / 1", display: "grid" }}
              >
                <Check size={22} strokeWidth={3.4} />
              </motion.span>
            )}
          </AnimatePresence>
        </motion.div>
        <AnimatePresence>
          {sent && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              transition={sentSpring}
              style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 17, fontWeight: 600, color: "#fff", pointerEvents: "none" }}
            >
              {ctx.t("Sent", "已发送")}
            </motion.div>
          )}
        </AnimatePresence>
        <div style={{ position: "absolute", inset: 0, borderRadius: 999, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Drag the knob to the end" zh="把滑块拖到最右端" />
    </div>
  );
}
