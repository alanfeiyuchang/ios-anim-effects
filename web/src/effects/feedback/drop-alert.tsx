/** feedback.drop-alert · 重力坠落弹窗 (Feedback+OverlayVariations.swift) */
import { motion } from "motion/react";
import { RefreshCw } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, glass, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { PrimaryCapsule, SPRINGS, track } from "./shared";

export default function DropAlert({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [shown, setShown] = useState(false);
  const [leaving, setLeaving] = useState(false);
  const [drops, setDrops] = useState(0);
  const state = useRef({ shown: false, leaving: false });
  const zh = ctx.lang === "zh";
  const bounce = ctx.n("bounce");
  const fall = ctx.n("fall");

  const present = (buzz = true) => {
    if (state.current.shown) return;
    clearAll();
    state.current = { shown: true, leaving: false };
    setLeaving(false);
    setShown(true);
    setDrops((d) => d + 1);
    if (buzz) after(fall, () => haptics.tap("rigid"));
  };
  const dismiss = () => {
    if (!state.current.shown || state.current.leaving) return;
    clearAll();
    state.current.leaving = true;
    setLeaving(true);
    after(0.42, () => {
      state.current = { shown: false, leaving: false };
      setShown(false);
      setLeaving(false);
    });
  };

  useAutoplay(ctx.isPreview, () => (state.current.shown ? dismiss() : present(false)), { every: 2.4, delay: 0.5 });

  const e = useElapsed(drops, fall + 1, true);
  const idle = e < 0;
  const y = idle ? 0 : track(e, 0, [{ move: -380 }, { cubic: 0, d: fall }, { cubic: -bounce, d: 0.14 }, { cubic: 0, d: 0.14 }, { cubic: -bounce * 0.27, d: 0.08 }, { cubic: 0, d: 0.08 }]);
  const sx = idle ? 1 : track(e, 1, [{ move: 0.96 }, { linear: 0.97, d: fall }, { cubic: 1.04, d: 0.05 }, { spring: 1, d: 0.3, ...SPRINGS.bouncy }]);
  const sy = idle ? 1 : track(e, 1, [{ move: 1.04 }, { linear: 1.03, d: fall }, { cubic: 0.92, d: 0.05 }, { spring: 1, d: 0.3, ...SPRINGS.bouncy }]);
  const leaveT = anim.easeIn(0.4);

  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
        <PrimaryCapsule onClick={() => present()} paddingX={24} style={{ boxShadow: "none" }}>
          <RefreshCw size={17} strokeWidth={2.6} />
          {zh ? "同步" : "Sync now"}
        </PrimaryCapsule>
        <DemoHint ctx={ctx} en="Tap Sync now" zh="点击同步" />
      </div>
      <motion.div
        initial={false}
        animate={{ opacity: shown && !leaving ? 0.3 : 0 }}
        transition={anim.easeInOut(0.3)}
        onClick={dismiss}
        style={{ position: "absolute", inset: 0, background: "#000", pointerEvents: shown ? "auto" : "none" }}
      />
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", pointerEvents: "none" }}>
        <motion.div
          initial={false}
          animate={{ y: leaving ? 420 : 0, rotate: leaving ? 10 : 0 }}
          transition={leaving ? leaveT : { duration: 0 }}
          style={{ transformOrigin: "0% 100%", opacity: shown ? 1 : 0, pointerEvents: shown && !leaving ? "auto" : "none" }}
        >
          <div style={{ transform: `translateY(${y}px) scale(${sx}, ${sy})`, transformOrigin: "50% 100%" }}>
            <div style={{ width: 270, padding: 20, borderRadius: 24, ...glass("regular"), boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 12px 24px rgb(0 0 0 / 0.2)`, display: "flex", flexDirection: "column", alignItems: "center", gap: 10, textAlign: "center" }}>
              <WifiAlert />
              <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{zh ? "连接已断开" : "Connection lost"}</span>
              <span style={{ fontSize: 13, lineHeight: "18px", color: Palette.secondaryLabel }}>{zh ? "你的更改会在恢复连接后同步。" : "Your changes will sync when you're back online."}</span>
              <div style={{ display: "flex", gap: 10, paddingTop: 6, alignSelf: "stretch" }}>
                <button type="button" onClick={dismiss} style={{ flex: 1, height: 42, borderRadius: 21, background: Palette.labelAlpha(0.08), fontSize: 15, fontWeight: 600 }}>
                  {zh ? "取消" : "Cancel"}
                </button>
                <button type="button" onClick={dismiss} style={{ flex: 1, height: 42, borderRadius: 21, background: Palette.primary, color: "#fff", fontSize: 15, fontWeight: 600 }}>
                  {zh ? "重试" : "Retry"}
                </button>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}

/** SF Symbol `wifi.exclamationmark`. */
function WifiAlert() {
  return (
    <svg width={34} height={28} viewBox="0 0 34 28" fill="none" stroke={Palette.coral} strokeWidth={3.4} strokeLinecap="round">
      <path d="M3 10.5 A20 20 0 0 1 13.5 4.3" />
      <path d="M31 10.5 A20 20 0 0 0 20.5 4.3" />
      <path d="M8.2 15.6 A12.5 12.5 0 0 1 13 12.3" />
      <path d="M25.8 15.6 A12.5 12.5 0 0 0 21 12.3" />
      <path d="M17 5 V17.5" />
      <circle cx={17} cy={23.5} r={1.4} fill={Palette.coral} stroke="none" />
    </svg>
  );
}
