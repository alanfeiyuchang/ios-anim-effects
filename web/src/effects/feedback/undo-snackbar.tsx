/** feedback.undo-snackbar · 撤销提示条 (Feedback+Dialogs.swift) */
import { AnimatePresence, motion, useTransform } from "motion/react";
import { Trash } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, anim, demoCard, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { separator, useAnimated } from "./shared";

export default function UndoSnackbar({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [deleted, setDeleted] = useState(false);
  const [snack, setSnack] = useState(false);
  const [snackT, setSnackT] = useState(spring(0.45, 0.85));
  const [seconds, setSeconds] = useState(5);
  const [remaining, remainingTo, remainingSet] = useAnimated(1);
  const state = useRef({ deleted: false, snack: false });
  const sp = spring(ctx.n("response"), 0.85);
  const zh = ctx.lang === "zh";
  const dark = ctx.scheme === "dark";

  const del = () => {
    if (state.current.deleted) return;
    clearAll();
    const total = Math.max(ctx.i("duration"), 1);
    haptics.tap("medium");
    remainingSet(1);
    setSeconds(total);
    state.current = { deleted: true, snack: true };
    setSnackT(sp);
    setDeleted(true);
    setSnack(true);
    remainingTo(0, anim.linear(total));
    for (let k = 1; k <= total; k++) {
      after(k, () => {
        setSeconds(total - k);
        if (k === total) {
          setSnackT(anim.smoothD(0.35));
          state.current.snack = false;
          setSnack(false);
        }
      });
    }
  };

  const undo = () => {
    clearAll();
    if (state.current.snack) haptics.success();
    state.current = { deleted: false, snack: false };
    setSnackT(sp);
    setDeleted(false);
    setSnack(false);
    remainingTo(1, sp);
  };

  useAutoplay(ctx.isPreview, () => (state.current.deleted ? undo() : del()), { every: 2.2, delay: 0.6 });

  const C = 2 * Math.PI * 11.75;
  const dash = useTransform(remaining, (r) => `${Math.max(r, 0) * C} ${C}`);
  const ink = Palette.background;

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
        <motion.div layout transition={sp} style={{ ...demoCard(20), width: 300, overflow: "hidden" }}>
          <AnimatePresence initial={false}>
            {!deleted && (
              <motion.div key="first" initial={{ height: 0 }} animate={{ height: 64.5 }} exit={{ height: 0 }} transition={sp} style={{ overflow: "hidden" }}>
                <motion.div initial={{ x: -300, opacity: 0 }} animate={{ x: 0, opacity: 1 }} exit={{ x: -300, opacity: 0 }} transition={sp}>
                  <MailRow tint={Palette.violet} initials="LS" title={zh ? "周报汇总" : "Weekly Digest"} subtitle={zh ? "本周设计进展已整理好" : "Your design recap is ready"} onDelete={del} />
                  <div style={{ height: 0.5, marginLeft: 64, background: separator(ctx.scheme) }} />
                </motion.div>
              </motion.div>
            )}
          </AnimatePresence>
          <MailRow tint={Palette.sky} initials="AK" title={zh ? "旅行计划" : "Trip Plans"} subtitle={zh ? "机票已确认，周五出发" : "Flights confirmed for Friday"} />
        </motion.div>
        <div style={{ display: "grid", placeItems: "center" }}>
          <AnimatePresence initial={false}>
            {!deleted && (
              <motion.div key="hint" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={sp} style={{ gridArea: "1/1" }}>
                <DemoHint ctx={ctx} en="Tap the trash to delete the email" zh="点击垃圾桶删除邮件" />
              </motion.div>
            )}
            {deleted && !snack && (
              <motion.button
                key="reset"
                type="button"
                onClick={undo}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={sp}
                style={{ gridArea: "1/1", fontSize: 13, lineHeight: "18px", fontWeight: 600, color: Palette.accent }}
              >
                {zh ? "重置演示" : "Reset demo"}
              </motion.button>
            )}
          </AnimatePresence>
        </div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 22, display: "flex", justifyContent: "center", pointerEvents: snack ? "auto" : "none" }}>
        <motion.div
          initial={false}
          animate={{ y: snack ? 0 : 120, opacity: snack ? 1 : 0 }}
          transition={snackT}
          style={{
            width: 300,
            height: 52,
            borderRadius: 16,
            background: Palette.labelAlpha(0.92),
            boxShadow: "0 8px 16px rgb(0 0 0 / 0.2)",
            color: ink,
            display: "flex",
            alignItems: "center",
            gap: 12,
            padding: "0 10px 0 14px",
          }}
        >
          <div style={{ position: "relative", width: 26, height: 26, flexShrink: 0, display: "grid", placeItems: "center" }}>
            <svg width={26} height={26} style={{ position: "absolute", inset: 0 }}>
              <circle cx={13} cy={13} r={11.75} fill="none" stroke={ink} strokeOpacity={0.2} strokeWidth={2.5} />
              <motion.circle cx={13} cy={13} r={11.75} fill="none" stroke={ink} strokeWidth={2.5} strokeLinecap="round" transform="rotate(-90 13 13)" style={{ strokeDasharray: dash }} />
            </svg>
            <NumericText value={-seconds} text={String(seconds)} style={{ fontSize: 12, fontWeight: 700 }} />
          </div>
          <span style={{ fontSize: 15, fontWeight: 500, whiteSpace: "nowrap" }}>{zh ? "会话已删除" : "Conversation deleted"}</span>
          <span style={{ flex: 1, minWidth: 8 }} />
          <button type="button" onClick={undo} style={{ height: 36, padding: "0 6px", fontSize: 15, fontWeight: 700, color: dark ? "#2A6DF4" : "#3AC4FF" }}>
            {zh ? "撤销" : "Undo"}
          </button>
        </motion.div>
      </div>
    </div>
  );
}

function MailRow({ tint, initials, title, subtitle, onDelete }: { tint: string; initials: string; title: string; subtitle: string; onDelete?: () => void }) {
  return (
    <div style={{ height: 64, padding: "0 12px", display: "flex", alignItems: "center", gap: 12, background: Palette.elevated }}>
      <div style={{ width: 40, height: 40, flexShrink: 0, borderRadius: "50%", background: `linear-gradient(rgb(255 255 255 / 0.14), transparent), ${tint}`, display: "grid", placeItems: "center", color: "#fff", fontSize: 12, fontWeight: 700 }}>
        {initials}
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 2, minWidth: 0 }}>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{title}</span>
        <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{subtitle}</span>
      </div>
      <span style={{ flex: 1, minWidth: 4 }} />
      {onDelete && (
        <button type="button" onClick={onDelete} style={{ width: 36, height: 36, flexShrink: 0, borderRadius: "50%", background: alpha(Palette.red, 0.12), display: "grid", placeItems: "center", color: Palette.red }}>
          <Trash size={16} strokeWidth={2.4} />
        </button>
      )}
    </div>
  );
}
