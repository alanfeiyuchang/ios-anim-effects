/** feedback.copy-confirm · 复制确认 (Feedback+Status.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Check, Copy, Link } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, anim, demoCard, fonts, pressHandlers, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";

export default function CopyConfirm({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [copied, setCopied] = useState(false);
  const [pressed, setPressed] = useState(false);
  const [t, setT] = useState(anim.snappyD(0.3, 0.15));

  const copy = () => {
    clearAll();
    haptics.success();
    setT(anim.snappyD(0.3, 0.15));
    setCopied(true);
    after(ctx.n("hold"), () => {
      setT(anim.snappyD(0.3));
      setCopied(false);
    });
  };

  useAutoplay(ctx.isPreview, copy, { every: ctx.n("hold") + 1.0, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div style={{ ...demoCard(18), width: 316, height: 58, flexShrink: 0, display: "flex", alignItems: "center", gap: 10, paddingLeft: 16, paddingRight: 8 }}>
        <Link size={15} strokeWidth={2.6} color={Palette.indigo} />
        <span style={{ fontFamily: fonts.mono, fontSize: 15, whiteSpace: "nowrap" }}>motion.app/k7Qx</span>
        <span style={{ flex: 1, minWidth: 6 }} />
        <div style={{ position: "relative" }}>
          <motion.button
            type="button"
            onClick={copy}
            {...pressHandlers(setPressed)}
            animate={{ scale: pressed ? 0.94 : 1 }}
            transition={spring(0.25, 0.6)}
            style={{ display: "block" }}
          >
            <motion.div
              initial={false}
              animate={{ backgroundColor: copied ? Palette.successStrong : "rgb(var(--ml-label-rgb) / 0.07)", color: copied ? "#fff" : "rgb(var(--ml-label-rgb))" }}
              transition={t}
              style={{ display: "flex", alignItems: "center", gap: 6, height: 40, padding: "0 14px", borderRadius: 20, fontSize: 15, fontWeight: 600, whiteSpace: "nowrap" }}
            >
              <span style={{ position: "relative", display: "grid", width: 16, height: 16, placeItems: "center" }}>
                <AnimatePresence initial={false}>
                  <motion.span
                    key={copied ? "check" : "copy"}
                    initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                    animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                    exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                    transition={anim.snappyD(0.3)}
                    style={{ position: "absolute", display: "grid" }}
                  >
                    {copied ? <Check size={16} strokeWidth={2.8} /> : <Copy size={15} strokeWidth={2.4} />}
                  </motion.span>
                </AnimatePresence>
              </span>
              <span style={{ display: "grid" }}>
                <AnimatePresence initial={false}>
                  <motion.span key={copied ? "y" : "n"} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={t} style={{ gridArea: "1/1" }}>
                    {copied ? ctx.t("Copied", "已复制") : ctx.t("Copy", "复制")}
                  </motion.span>
                </AnimatePresence>
              </span>
            </motion.div>
          </motion.button>
          {ctx.b("tooltip") && (
            <motion.div
              initial={false}
              animate={{ y: copied ? -44 : -34, opacity: copied ? 1 : 0 }}
              transition={t}
              style={{ position: "absolute", top: 0, left: "50%", marginLeft: -60, width: 120, display: "flex", justifyContent: "center", pointerEvents: "none" }}
            >
              <span
                style={{
                  fontSize: 12,
                  lineHeight: "16px",
                  fontWeight: 600,
                  color: Palette.background,
                  background: Palette.label,
                  padding: "6px 10px",
                  borderRadius: 999,
                  whiteSpace: "nowrap",
                  boxShadow: "0 4px 8px rgb(0 0 0 / 0.18)",
                }}
              >
                {ctx.t("Link copied", "链接已复制")}
              </span>
            </motion.div>
          )}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap Copy" zh="点击“复制”" />
    </div>
  );
}
