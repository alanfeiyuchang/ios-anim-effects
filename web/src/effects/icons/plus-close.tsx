/** icons.plus-close · 加号 ↔ 关闭扭转 (Icons+PlusClose.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, anim, spring, textStyle, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { C, S, SPRINGS, track, useSince } from "./_icons-kit";

export default function PlusClose({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpen] = useState(false);
  const [taps, setTaps] = useState(0);
  const turn = ctx.i("turn") === 0 ? 45 : ctx.i("turn") === 2 ? 225 : 135;
  const squeeze = ctx.b("squeeze");

  const t = useSince(taps, 0.6);
  const scale = t < 0 ? 1 : track(t, 1, [C(squeeze ? 0.78 : 1, 0.09), S(squeeze ? 1.1 : 1, 0.16, SPRINGS.snappy), S(1, 0.35, SPRINGS.bouncy)]);

  const toggle = () => {
    haptics.tap("medium");
    setOpen((o) => !o);
    setTaps((n) => n + 1);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.4 });

  const ease = anim.easeInOut(0.3);
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <button type="button" onClick={toggle} style={{ position: "relative", width: 72, height: 72 }}>
        <motion.div
          initial={false}
          animate={{ boxShadow: open ? "0 4px 8px rgb(0 0 0 / 0.2)" : "0 8px 16px rgb(164 107 255 / 0.45)" }}
          transition={ease}
          style={{ position: "absolute", inset: 0, borderRadius: "50%", overflow: "hidden" }}
        >
          <div style={{ position: "absolute", inset: 0, background: Palette.primary }} />
          <motion.div initial={false} animate={{ opacity: open ? 1 : 0 }} transition={ease} style={{ position: "absolute", inset: 0, background: "rgb(41 41 41)" }} />
          <motion.div
            initial={false}
            animate={{ boxShadow: `inset 0 0 0 1px rgb(255 255 255 / ${open ? 0.1 : 0.25})` }}
            transition={ease}
            style={{ position: "absolute", inset: 0, borderRadius: "50%" }}
          />
        </motion.div>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", transform: `scale(${scale})` }}>
          <motion.div initial={false} animate={{ rotate: open ? turn : 0 }} transition={spring(0.45, ctx.n("damping"))} style={{ position: "relative", width: 30, height: 30 }}>
            <div style={{ position: "absolute", left: 0, top: 12.5, width: 30, height: 5, borderRadius: 2.5, background: "#fff" }} />
            <div style={{ position: "absolute", left: 12.5, top: 0, width: 5, height: 30, borderRadius: 2.5, background: "#fff" }} />
          </motion.div>
        </div>
      </button>
      <div style={{ display: "grid", ...textStyle.subheadline, fontWeight: 600, color: Palette.secondaryLabel }}>
        {[false, true].map((state) => (
          <motion.span key={String(state)} initial={false} animate={{ opacity: open === state ? 1 : 0 }} transition={anim.snappy} style={{ gridArea: "1 / 1", textAlign: "center", whiteSpace: "nowrap" }}>
            {state ? ctx.t("Close", "关闭") : ctx.t("New", "新建")}
          </motion.span>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap the button" zh="点击按钮" />
    </div>
  );
}
