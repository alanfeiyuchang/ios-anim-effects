/** feedback.tip-popover · 锚点提示气泡 (Feedback+OverlayVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Mountain, PenTool, Share, Type, WandSparkles, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, delayed, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";

const TOOLS: LucideIcon[] = [PenTool, Type, WandSparkles, Share];
const BUBBLE_W = 240;

export default function TipPopover({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpenState] = useState(false);
  const openRef = useRef(false);
  const zh = ctx.lang === "zh";
  const target = Math.min(Math.max(ctx.i("target") + 1, 1), 3);
  const arrowShift = target * 56 + 28 - 112;
  const anchorX = (BUBBLE_W / 2 + arrowShift) / BUBBLE_W;
  const t = open ? spring(ctx.n("response"), ctx.n("damping")) : anim.easeIn(0.25);

  const toggle = () => {
    if (openRef.current) {
      openRef.current = false;
      setOpenState(false);
    } else {
      haptics.tap();
      openRef.current = true;
      setOpenState(true);
    }
  };

  useAutoplay(ctx.isPreview, toggle, { every: 2.4, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", left: 45, top: 20, width: 250, height: 180, borderRadius: 22, overflow: "hidden", background: `linear-gradient(${alpha(Palette.sky, 0.22)}, ${alpha(Palette.violet, 0.12)})`, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }}>
        <div style={{ position: "absolute", right: 22, top: 22, width: 30, height: 30, borderRadius: "50%", background: alpha(Palette.amber, 0.4) }} />
        <div style={{ position: "absolute", left: 0, right: 0, bottom: -26, display: "flex", justifyContent: "center", color: alpha(Palette.indigo, 0.2) }}>
          <Mountain size={110} fill="currentColor" strokeWidth={0} />
        </div>
      </div>
      <div style={{ position: "absolute", inset: 0, paddingBottom: 24, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "flex-end", gap: 12 }}>
        <motion.div
          initial={false}
          animate={{ scale: open ? 1 : 0.1, opacity: open ? 1 : 0 }}
          transition={t}
          style={{ transformOrigin: `${anchorX * 100}% 100%`, pointerEvents: open ? "auto" : "none", display: "flex", flexDirection: "column", alignItems: "center", filter: "drop-shadow(0 8px 8px rgb(0 0 0 / 0.16))" }}
        >
          <div style={{ width: BUBBLE_W, padding: 14, borderRadius: 18, background: Palette.elevated }}>
            <motion.div initial={false} animate={{ opacity: open ? 1 : 0 }} transition={open ? delayed(anim.easeOut(0.2), 0.1) : anim.easeIn(0.08)} style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
              <WandSparkles size={21} strokeWidth={2} color={Palette.violet} />
              <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 4 }}>
                <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "一键美化" : "Magic Enhance"}</span>
                <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{zh ? "自动调整光线与色彩。" : "Fixes light and color in one tap."}</span>
                <button type="button" onClick={toggle} style={{ marginTop: 2, fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.accent }}>
                  {zh ? "知道了" : "Got it"}
                </button>
              </div>
            </motion.div>
          </div>
          <svg width={24} height={14} viewBox="0 0 24 14" style={{ transform: `translateX(${arrowShift}px)`, marginTop: -0.5 }}>
            <path d="M0 0 Q9 4 12 14 Q15 4 24 0 Z" fill="var(--ml-elevated)" />
          </svg>
        </motion.div>
        <div style={{ display: "flex", borderRadius: 999, ...glass("regular"), boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 6px 12px rgb(0 0 0 / 0.1)` }}>
          {TOOLS.map((Icon, i) => {
            const isTarget = i === target;
            const lit = isTarget && open;
            return (
              <div key={i} onClick={() => isTarget && toggle()} style={{ position: "relative", width: 56, height: 56, display: "grid", placeItems: "center", cursor: isTarget ? "pointer" : undefined }}>
                {lit && (
                  <motion.div
                    initial={{ scale: 1, opacity: 0.8 }}
                    animate={{ scale: [1, 1.7], opacity: [0.8, 0] }}
                    transition={{ duration: 1.2, ease: [0, 0, 0.58, 1], repeat: Infinity, repeatDelay: 0.01 }}
                    style={{ position: "absolute", left: 8, top: 8, width: 40, height: 40, borderRadius: "50%", boxShadow: `inset 0 0 0 2px ${Palette.violet}` }}
                  />
                )}
                <motion.span initial={false} animate={{ color: lit ? Palette.violet : "var(--ml-label)", filter: `drop-shadow(0 0 5px ${alpha(Palette.violet, lit ? 0.6 : 0)})` }} transition={t} style={{ display: "grid" }}>
                  <Icon size={20} strokeWidth={2.3} />
                </motion.span>
                <AnimatePresence>
                  {isTarget && !open && (
                    <motion.div key="dot" initial={{ scale: 0.2, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.2, opacity: 0 }} transition={t} style={{ position: "absolute", left: 28 + 11 - 3, top: 28 - 15 - 3 }}>
                      <motion.div
                        animate={{ scale: [0.85, 1.25], opacity: [0.6, 1] }}
                        transition={{ duration: 1, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
                        style={{ width: 6, height: 6, borderRadius: "50%", background: Palette.violet }}
                      />
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>
        <DemoHint ctx={ctx} en="Tap the violet-marked tool" zh="点击紫色标记的工具" />
      </div>
    </div>
  );
}
