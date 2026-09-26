/** feedback.alert-pop · 弹窗浮现 (Feedback+Dialogs.swift) */
import { motion } from "motion/react";
import { BellDot, ChevronRight, CircleUser, Lock, Trash2, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, demoCard, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { separator } from "./shared";

export default function AlertPop({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [presented, setPresented] = useState(false);
  const [closing, setClosing] = useState(false);
  const presentedRef = useRef(false);
  const pop = ctx.i("style") === 1;
  const hiddenScale = closing ? 0.94 : pop ? 0.6 : 1.12;
  const t = presented ? (pop ? spring(0.42, 0.62) : spring(0.35, 0.82)) : anim.easeOut(0.2);
  const sep = separator(ctx.scheme);
  const zh = ctx.lang === "zh";

  const present = () => {
    setClosing(false);
    haptics.tap("medium");
    presentedRef.current = true;
    setPresented(true);
  };
  const dismiss = () => {
    setClosing(true);
    presentedRef.current = false;
    setPresented(false);
  };

  useAutoplay(ctx.isPreview, () => (presentedRef.current ? dismiss() : present()), { every: 1.8, delay: 0.6 });

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <motion.div
        initial={false}
        animate={{ filter: `blur(${presented ? ctx.n("blur") : 0}px)`, scale: presented ? 0.96 : 1 }}
        transition={t}
        style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}
      >
        <div style={{ ...demoCard(20), width: 290, overflow: "hidden" }}>
          <Row Icon={CircleUser} tint={Palette.blue} title={zh ? "个人资料" : "Profile"} />
          <div style={{ height: 0.5, marginLeft: 52, background: sep }} />
          <Row Icon={Lock} tint={Palette.green} title={zh ? "隐私与安全" : "Privacy & Security"} />
          <div style={{ height: 0.5, marginLeft: 52, background: sep }} />
          <Row Icon={BellDot} tint={Palette.coral} title={zh ? "通知" : "Notifications"} />
          <div style={{ height: 0.5, background: sep }} />
          <button type="button" onClick={present} style={{ width: "100%", height: 50, fontSize: 17, fontWeight: 600, color: Palette.red }}>
            {zh ? "删除账户" : "Delete Account"}
          </button>
        </div>
      </motion.div>
      <motion.div
        initial={false}
        animate={{ opacity: presented ? ctx.n("dim") : 0 }}
        transition={t}
        onClick={dismiss}
        style={{ position: "absolute", inset: 0, background: "#000", pointerEvents: presented ? "auto" : "none" }}
      />
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", pointerEvents: "none" }}>
        <motion.div
          initial={false}
          animate={{ scale: presented ? 1 : hiddenScale, opacity: presented ? 1 : 0 }}
          transition={t}
          style={{ width: 270, borderRadius: 22, overflow: "hidden", ...glass("thick"), boxShadow: "0 16px 30px rgb(0 0 0 / 0.22)", pointerEvents: presented ? "auto" : "none" }}
        >
          <div style={{ padding: "20px 18px", display: "flex", flexDirection: "column", alignItems: "center", gap: 8, textAlign: "center" }}>
            <div style={{ width: 46, height: 46, borderRadius: "50%", marginBottom: 4, background: `linear-gradient(rgb(255 255 255 / 0.14), transparent), ${Palette.red}`, display: "grid", placeItems: "center", color: "#fff" }}>
              <Trash2 size={21} strokeWidth={2.4} />
            </div>
            <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{zh ? "删除账户？" : "Delete account?"}</div>
            <div style={{ fontSize: 13, lineHeight: "18px", color: Palette.secondaryLabel }}>
              {zh ? "你的所有数据将被永久移除，且无法恢复。" : "All of your data will be permanently removed. This can't be undone."}
            </div>
          </div>
          <div style={{ height: 0.5, background: sep }} />
          <div style={{ display: "flex", height: 46 }}>
            <button type="button" onClick={dismiss} style={{ flex: 1, fontSize: 17 }}>
              {zh ? "取消" : "Cancel"}
            </button>
            <div style={{ width: 0.5, background: sep }} />
            <button type="button" onClick={dismiss} style={{ flex: 1, fontSize: 17, fontWeight: 600, color: Palette.red }}>
              {zh ? "删除" : "Delete"}
            </button>
          </div>
        </motion.div>
      </div>
      <motion.div
        initial={false}
        animate={{ opacity: presented ? 0 : 1 }}
        transition={t}
        style={{ position: "absolute", left: 0, right: 0, bottom: 14, display: "flex", justifyContent: "center", pointerEvents: "none" }}
      >
        <DemoHint ctx={ctx} en="Tap Delete Account" zh="点击“删除账户”" />
      </motion.div>
    </div>
  );
}

function Row({ Icon, tint, title }: { Icon: LucideIcon; tint: string; title: string }) {
  return (
    <div style={{ height: 48, padding: "0 12px", display: "flex", alignItems: "center", gap: 12 }}>
      <div style={{ width: 28, height: 28, borderRadius: 7, background: tint, display: "grid", placeItems: "center", color: "#fff" }}>
        <Icon size={16} strokeWidth={2.4} />
      </div>
      <span style={{ fontSize: 17 }}>{title}</span>
      <span style={{ flex: 1 }} />
      <ChevronRight size={14} strokeWidth={3} color={Palette.tertiaryLabel} />
    </div>
  );
}
