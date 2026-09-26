/** loading.tick-ring · 充电刻度环 (Loading+RingVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Zap } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, fonts, spring, useHaptics, type DemoProps } from "../../kit";
import { stopColor } from "./bar-shared";
import { primary, useTask } from "./shared";

const SIZE = 190;
const STOPS = [0x34c77b, 0x21d4a8, 0x3ac4ff];

export default function TickRing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [level, setLevel] = useState(0);
  const [ripple, setRipple] = useState(false);
  const [run, setRun] = useState(0);
  const model = useRef(0);
  const count = Math.max(ctx.i("count"), 8);
  const zh = ctx.lang === "zh";

  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    setRipple(false);
    model.current = 0;
    setLevel(0);
    await task.sleep(0.5);
    const rate = Math.max(ctx.n("rate"), 0.1);
    while (model.current < 1) {
      model.current = Math.min(1, model.current + 0.01);
      setLevel(model.current);
      await task.sleep(0.06 / rate);
    }
    setRipple(true);
    if (live) haptics.success();
    await task.sleep(1.2);
    setRipple(false);
    await task.sleep(1.0);
    if (ctx.isPreview) setRun((r) => r + 1);
  });

  const percent = Math.round(level * 100);
  const full = level >= 1;
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: SIZE, height: SIZE }}>
        {Array.from({ length: count }, (_, index) => {
          const f = index / count;
          const on = level > f;
          const head = on && level < f + 1 / count + 0.001;
          const color = stopColor(STOPS, f);
          return (
            <div key={index} style={{ position: "absolute", inset: 0, transform: `rotate(${f * 360}deg)` }}>
              <motion.div
                initial={false}
                animate={{ height: on ? 16 : 8, y: ripple ? -4 : 0 }}
                transition={{ height: spring(0.35, ctx.n("damping")), y: { ...spring(0.3, 0.5), delay: ripple ? index * 0.008 : 0 } }}
                style={{
                  position: "absolute",
                  left: SIZE / 2 - 1.25,
                  top: 0,
                  width: 2.5,
                  borderRadius: 1.25,
                  background: on ? color : primary(0.12),
                  boxShadow: `0 0 4px ${stopColor(STOPS, f, head ? 0.9 : 0)}`,
                }}
              />
            </div>
          );
        })}
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2 }}>
          <motion.span
            animate={{ scale: [0.92, 1.08] }}
            transition={{ duration: 0.6, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
            style={{ display: "grid", color: Palette.green }}
          >
            <Zap size={22} fill="currentColor" strokeWidth={1.5} />
          </motion.span>
          <span style={{ fontFamily: fonts.rounded, fontSize: 36, lineHeight: "43px", fontWeight: 700 }}>
            <NumericText value={percent} text={`${percent}%`} />
          </span>
        </div>
      </div>
      <span style={{ display: "grid", fontSize: 13, lineHeight: "18px", fontWeight: 500, color: Palette.secondaryLabel }}>
        <AnimatePresence initial={false}>
          <motion.span key={full ? "full" : "charging"} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={anim.easeInOut(0.25)} style={{ gridArea: "1 / 1", textAlign: "center" }}>
            {full ? (zh ? "已充满" : "Fully charged") : zh ? "正在充电" : "Charging"}
          </motion.span>
        </AnimatePresence>
      </span>
      <DemoHint ctx={ctx} en="Tap to restart" zh="点击重新开始" />
    </div>
  );
}
