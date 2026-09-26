/** inputs.expanding-stepper (Inputs+ExpandingStepper.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Minus, Plus } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, demoCard, fonts, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { CupSaucer, PressScale } from "./_a-common";

const COLLAPSED = 38;
const EXPANDED_W = 120;
const SCRIPT = [1, 1, 1, 0, 0, 0, 0, 2, 0, -1, -1, -1, 0, 0];

export default function ExpandingStepper({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [count, setCountState] = useState(0);
  const [expanded, setExpanded] = useState(false);
  const countRef = useRef(0);
  const generation = useRef(0);
  const step = useRef(0);
  const t = spring(ctx.n("response"), ctx.n("damping"));

  const scheduleCollapse = () => {
    generation.current += 1;
    const current = generation.current;
    after(ctx.n("idle"), () => {
      if (current === generation.current) setExpanded(false);
    });
  };
  const change = (delta: number) => {
    const target = Math.max(countRef.current + delta, 0);
    haptics.tap();
    countRef.current = target;
    setCountState(target);
    setExpanded(target > 0);
    scheduleCollapse();
  };
  const reopen = () => {
    haptics.tap();
    setExpanded(true);
    scheduleCollapse();
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const action = SCRIPT[step.current % SCRIPT.length];
      step.current += 1;
      if (action === 1) change(1);
      else if (action === -1) {
        if (countRef.current > 0) change(-1);
      } else if (action === 2 && countRef.current > 0) reopen();
    },
    { every: 0.6, delay: 0.4 },
  );

  const zh = ctx.lang === "zh";
  const moveIn = { initial: { x: 50, opacity: 0 }, animate: { x: 0, opacity: 1 }, exit: { x: 50, opacity: 0 } };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 316, padding: 16, display: "flex", alignItems: "center", gap: 12 }}>
        <div
          style={{
            width: 56,
            height: 56,
            borderRadius: 14,
            flexShrink: 0,
            background: "linear-gradient(#C89B6D, #8A5A3B)",
            display: "grid",
            placeItems: "center",
            color: "#fff",
          }}
        >
          <CupSaucer size={22} color="#fff" />
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 3, flex: 1, minWidth: 0 }}>
          <span style={{ ...textStyle.headline }}>{zh ? "燕麦拿铁" : "Oat Latte"}</span>
          <span style={{ ...textStyle.subheadline, fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>{zh ? "¥28" : "$4.80"}</span>
        </div>
        <motion.div
          initial={false}
          animate={{ width: expanded ? EXPANDED_W : COLLAPSED, boxShadow: `0 4px 8px ${alpha(Palette.indigo, expanded ? 0 : 0.3)}` }}
          transition={t}
          style={{ position: "relative", height: COLLAPSED, borderRadius: COLLAPSED / 2, flexShrink: 0 }}
        >
          <div style={{ position: "absolute", inset: 0, borderRadius: COLLAPSED / 2, overflow: "hidden" }}>
            <motion.div initial={false} animate={{ opacity: expanded ? 0 : 1 }} transition={t} style={{ position: "absolute", inset: 0, background: Palette.primary }} />
            <motion.div initial={false} animate={{ opacity: expanded ? 1 : 0 }} transition={t} style={{ position: "absolute", inset: 0, background: alpha(Palette.indigo, 0.12) }} />
            <div style={{ position: "absolute", right: 0, top: 0, bottom: 0, width: EXPANDED_W }}>
              <AnimatePresence initial={false}>
                {expanded ? (
                  <motion.div key="open" style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center" }}>
                    <motion.div {...moveIn} transition={t}>
                      <PressScale scale={0.86} onClick={() => change(-1)} style={{ width: COLLAPSED, height: COLLAPSED, color: Palette.indigo }}>
                        <Minus size={15} strokeWidth={3.2} />
                      </PressScale>
                    </motion.div>
                    <motion.div {...moveIn} transition={t} style={{ flex: 1, display: "flex", justifyContent: "center" }}>
                      <NumericText value={count} style={{ fontFamily: fonts.rounded, fontSize: 17, fontWeight: 700, lineHeight: "22px" }} />
                    </motion.div>
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={t}>
                      <PressScale scale={0.86} onClick={() => change(1)} style={{ width: COLLAPSED, height: COLLAPSED }}>
                        <div style={{ width: 30, height: 30, borderRadius: "50%", background: Palette.primary, display: "grid", placeItems: "center", color: "#fff" }}>
                          <Plus size={15} strokeWidth={3.2} />
                        </div>
                      </PressScale>
                    </motion.div>
                  </motion.div>
                ) : count > 0 ? (
                  <motion.div
                    key={`count`}
                    initial={{ scale: 0.3, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    exit={{ scale: 0.3, opacity: 0 }}
                    transition={t}
                    onClick={reopen}
                    style={{
                      position: "absolute",
                      right: 0,
                      top: 0,
                      width: COLLAPSED,
                      height: COLLAPSED,
                      display: "grid",
                      placeItems: "center",
                      color: "#fff",
                      cursor: "pointer",
                      fontFamily: fonts.rounded,
                      fontSize: 16,
                      fontWeight: 700,
                      fontVariantNumeric: "tabular-nums",
                    }}
                  >
                    {count}
                  </motion.div>
                ) : (
                  <motion.div
                    key="plus"
                    initial={{ scale: 0.5, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    exit={{ scale: 0.5, opacity: 0 }}
                    transition={t}
                    onClick={() => change(1)}
                    style={{ position: "absolute", right: 0, top: 0, width: COLLAPSED, height: COLLAPSED, display: "grid", placeItems: "center", color: "#fff", cursor: "pointer" }}
                  >
                    <Plus size={18} strokeWidth={3.2} />
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>
        </motion.div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap +, then wait" zh="点击 +，然后稍等" style={{ paddingBottom: 18 }} />
    </div>
  );
}
