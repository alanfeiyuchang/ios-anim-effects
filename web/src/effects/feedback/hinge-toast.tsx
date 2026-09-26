/** feedback.hinge-toast · 铰链摆动横幅 (Feedback+ToastVariations.swift) */
import { motion, useTransform } from "motion/react";
import { Bell } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, SymbolBounce, alpha, anim, glass, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { useAnimated } from "./shared";

export default function HingeToast({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [shown, shownTo] = useAnimated(0);
  const [rings, setRings] = useState(0);
  const [isShown, setIsShown] = useState(false);
  const shownRef = useRef(false);
  const zh = ctx.lang === "zh";

  const hide = () => {
    clearAll();
    shownRef.current = false;
    setIsShown(false);
    shownTo(0, anim.easeIn(0.3));
  };
  const show = () => {
    clearAll();
    haptics.tap("medium");
    shownRef.current = true;
    setIsShown(true);
    shownTo(1, spring(ctx.n("response"), ctx.n("damping")));
    after(0.35, () => {
      setRings((r) => r + 1);
      after(ctx.n("hold"), hide);
    });
  };

  useAutoplay(ctx.isPreview, show, { every: ctx.n("hold") + 1.8, delay: 0.4 });

  const transform = useTransform(shown, (p) => `perspective(520px) rotateX(${-90 * (1 - p)}deg)`);
  const opacity = useTransform(shown, (p) => (p > 0 ? Math.min(0.001 + p, 1) : 0.001));

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 26, display: "flex", justifyContent: "center", zIndex: 1 }}>
        <motion.div
          onClick={() => shownRef.current && hide()}
          style={{ transform, opacity, transformOrigin: "50% 0%", pointerEvents: isShown ? "auto" : "none", cursor: "pointer" }}
        >
          <div
            style={{
              width: 290,
              height: 64,
              padding: "0 14px",
              display: "flex",
              alignItems: "center",
              gap: 12,
              borderRadius: 20,
              ...glass("regular"),
              boxShadow: `inset 0 0 0 1px ${Palette.stroke}${isShown ? ", 0 10px 18px rgb(0 0 0 / 0.18)" : ""}`,
              transition: "box-shadow 0.3s",
            }}
          >
            <div style={{ width: 34, height: 34, flexShrink: 0, borderRadius: 10, background: `linear-gradient(rgb(255 255 255 / 0.14), transparent), ${Palette.coral}`, display: "grid", placeItems: "center", color: "#fff" }}>
              <SymbolBounce trigger={rings} kind="wiggle">
                <Bell size={16} fill="currentColor" strokeWidth={2} />
              </SymbolBounce>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "提醒" : "Reminder"}</span>
              <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{zh ? "5 分钟后开站会" : "Stand-up in 5 minutes"}</span>
            </div>
            <span style={{ flex: 1 }} />
            <span style={{ fontSize: 11, lineHeight: "13px", color: Palette.tertiaryLabel }}>{zh ? "现在" : "now"}</span>
          </div>
        </motion.div>
      </div>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14, pointerEvents: "none" }}>
        <button
          type="button"
          onClick={show}
          style={{ pointerEvents: "auto", display: "flex", alignItems: "center", gap: 8, height: 50, padding: "0 22px", borderRadius: 25, background: Palette.sunset, color: "#fff", fontSize: 17, fontWeight: 600, boxShadow: `0 6px 12px ${alpha(Palette.coral, 0.35)}` }}
        >
          <Bell size={17} strokeWidth={2.4} />
          {zh ? "设置提醒" : "Set Reminder"}
        </button>
        <DemoHint ctx={ctx} en="Tap Set Reminder" zh="点击“设置提醒”" />
      </div>
    </div>
  );
}
