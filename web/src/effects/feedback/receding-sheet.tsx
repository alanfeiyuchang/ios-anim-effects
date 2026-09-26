/** feedback.receding-sheet · 后退式确认面板 (Feedback+OverlayVariations.swift) */
import { AnimatePresence, motion, useMotionValueEvent } from "motion/react";
import { Trash, Undo2 } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, glass, rubberBand, spring, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";
import { predicted, useAnimated } from "./shared";

const SHEET_H = 200;
const TINTS = [Palette.coral, Palette.sky, Palette.mint, Palette.violet, Palette.amber, Palette.pink, Palette.blue, Palette.green, Palette.indigo];
const SELECTED = new Set([1, 3, 7]);

export default function RecedingSheet({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [pres, presTo] = useAnimated(0);
  const [drag, dragTo, dragSet] = useAnimated(0);
  const [, force] = useState(0);
  useMotionValueEvent(pres, "change", () => force((n) => n + 1));
  useMotionValueEvent(drag, "change", () => force((n) => n + 1));
  const [presented, setPresentedState] = useState(false);
  const [deleted, setDeleted] = useState(false);
  const presentedRef = useRef(false);
  const zh = ctx.lang === "zh";
  const setPresented = (v: boolean) => {
    presentedRef.current = v;
    setPresentedState(v);
  };

  const present = () => {
    if (presentedRef.current) return;
    haptics.tap();
    const t = spring(ctx.n("response"), ctx.n("damping"));
    dragTo(0, t);
    setDeleted(false);
    setPresented(true);
    presTo(1, t);
  };
  const dismiss = () => {
    const t = spring(ctx.n("response"), 0.95);
    setPresented(false);
    presTo(0, t);
    dragTo(0, t);
  };
  const confirm = (buzz = true) => {
    if (!presentedRef.current) return;
    if (buzz) haptics.tap("rigid");
    dismiss();
    setDeleted(true);
  };
  const trashTapped = () => {
    if (!deleted) return present();
    haptics.tap();
    setDeleted(false);
  };

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (!presentedRef.current) return;
        const dy = translation.y;
        dragSet(dy > 0 ? dy : rubberBand(dy, 30));
      },
      onEnd: ({ translation, velocity }) => {
        if (!presentedRef.current) return;
        if (translation.y > 60 || predicted(translation.y, velocity.y) > 160) dismiss();
        else dragTo(0, spring(0.35, 0.8));
      },
    },
    0,
  );
  // Like a UIKit pan, the drag only takes the touch once it moves, so taps still reach the sheet's buttons.
  const pending = useRef<{ x: number; y: number } | null>(null);
  const sheetPointer = {
    onPointerDown: (e: React.PointerEvent<HTMLDivElement>) => {
      pending.current = { x: e.clientX, y: e.clientY };
    },
    onPointerMove: (e: React.PointerEvent<HTMLDivElement>) => {
      const p0 = pending.current;
      if (p0 && Math.hypot(e.clientX - p0.x, e.clientY - p0.y) > 4) {
        pending.current = null;
        pan.onPointerDown(e);
      }
      pan.onPointerMove(e);
    },
    onPointerUp: (e: React.PointerEvent<HTMLDivElement>) => {
      pending.current = null;
      pan.onPointerUp(e);
    },
    onPointerCancel: (e: React.PointerEvent<HTMLDivElement>) => {
      pending.current = null;
      pan.onPointerCancel(e);
    },
  };

  useAutoplay(ctx.isPreview, () => {
    if (!presentedRef.current) return present();
    clearAll();
    dragTo(80, anim.easeInOut(0.45));
    after(0.5, () => {
      if (!presentedRef.current) return;
      dragTo(0, spring(0.35, 0.8));
      after(0.45, () => confirm(false));
    });
  }, { every: 2.6, delay: 0.5 });

  const p = pres.get();
  const d = drag.get();
  const open = p * Math.max(0, 1 - d / SHEET_H);
  const depth = ctx.n("depth");
  const scale = 1 - (1 - depth) * open;
  const radius = 18 + 12 * open;
  const sheetY = (1 - p) * (SHEET_H + 30) + p * Math.max(d, -12);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10 }}>
      <div style={{ position: "relative", width: 300, height: 320, flexShrink: 0, borderRadius: 30, overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, transform: `translateY(${10 * open}px) scale(${scale})`, borderRadius: radius, overflow: "hidden" }}>
          <div style={{ position: "absolute", inset: 0, background: Palette.elevated, padding: 14, display: "flex", flexDirection: "column", gap: 12 }}>
            <div style={{ display: "flex", alignItems: "center" }}>
              <span style={{ display: "grid" }}>
                <AnimatePresence initial={false}>
                  <motion.span key={deleted ? "r" : "s"} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={anim.smoothD(0.3)} style={{ gridArea: "1/1", fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>
                    {zh ? (deleted ? "最近项目" : "已选 3 项") : deleted ? "Recents" : "3 Selected"}
                  </motion.span>
                </AnimatePresence>
              </span>
              <span style={{ flex: 1 }} />
              <button type="button" onClick={trashTapped} style={{ position: "relative", width: 40, height: 40, borderRadius: "50%", overflow: "hidden", color: "#fff" }}>
                <motion.div initial={false} animate={{ backgroundColor: deleted ? Palette.blue : Palette.red }} transition={anim.smoothD(0.3)} style={{ position: "absolute", inset: 0, backgroundImage: "linear-gradient(rgb(255 255 255 / 0.14), transparent)" }} />
                <AnimatePresence initial={false}>
                  <motion.span
                    key={deleted ? "undo" : "trash"}
                    initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                    animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                    exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                    transition={anim.snappyD(0.3)}
                    style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}
                  >
                    {deleted ? <Undo2 size={18} strokeWidth={2.6} /> : <Trash size={18} strokeWidth={2.4} />}
                  </motion.span>
                </AnimatePresence>
              </button>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 6 }}>
              {TINTS.map((tint, i) => {
                const sel = SELECTED.has(i);
                const gone = sel && deleted;
                return (
                  <motion.div
                    key={i}
                    initial={false}
                    animate={{ scale: gone ? 0.2 : sel ? 0.92 : 1, opacity: gone ? 0 : 1 }}
                    transition={delayed(spring(0.4, 0.7), gone ? 0.15 + i * 0.03 : 0)}
                    style={{ position: "relative", aspectRatio: "1.2", borderRadius: 10, background: `linear-gradient(rgb(255 255 255 / 0.14), transparent), ${tint}` }}
                  >
                    {sel && (
                      <svg width={18} height={18} viewBox="0 0 18 18" style={{ position: "absolute", right: 5, bottom: 5 }}>
                        <circle cx={9} cy={9} r={8.5} fill={Palette.blue} />
                        <path d="M5.4 9.3l2.4 2.3 4.6-4.9" fill="none" stroke="#fff" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round" />
                      </svg>
                    )}
                  </motion.div>
                );
              })}
            </div>
          </div>
        </div>
        <div onClick={dismiss} style={{ position: "absolute", inset: 0, background: "#000", opacity: 0.25 * open, pointerEvents: presented ? "auto" : "none" }} />
        <div
          {...sheetPointer}
          style={{ touchAction: "none", position: "absolute", left: 0, bottom: -20, width: 300, height: SHEET_H + 20, transform: `translateY(${sheetY}px)`, pointerEvents: presented ? "auto" : "none", borderRadius: "26px 26px 0 0", ...glass("regular"), display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}
        >
          <div style={{ width: 36, height: 5, borderRadius: 3, background: ctx.scheme === "dark" ? "rgb(235 235 245 / 0.3)" : "rgb(60 60 67 / 0.3)", marginTop: 8 }} />
          <Cascade shown={presented} index={0}>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3 }}>
              <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{zh ? "删除 3 张照片？" : "Delete 3 photos?"}</span>
              <span style={{ fontSize: 13, lineHeight: "18px", color: Palette.secondaryLabel }}>{zh ? "它们将从你的所有设备中移除。" : "They'll be removed from all your devices."}</span>
            </div>
          </Cascade>
          <Cascade shown={presented} index={1} full>
            <ActionRow title={zh ? "删除" : "Delete"} destructive onClick={() => confirm()} />
          </Cascade>
          <Cascade shown={presented} index={2} full>
            <ActionRow title={zh ? "取消" : "Cancel"} onClick={dismiss} />
          </Cascade>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap the trash, then drag the sheet down" zh="点击删除按钮，再向下拖动面板" />
    </div>
  );
}

function Cascade({ shown, index, full, children }: { shown: boolean; index: number; full?: boolean; children: React.ReactNode }) {
  return (
    <motion.div
      initial={false}
      animate={{ y: shown ? 0 : 18, opacity: shown ? 1 : 0 }}
      transition={delayed(spring(0.4, 0.75), shown ? 0.1 + index * 0.05 : 0)}
      style={{ alignSelf: full ? "stretch" : undefined, padding: full ? "0 16px" : undefined }}
    >
      {children}
    </motion.div>
  );
}

function ActionRow({ title, destructive, onClick }: { title: string; destructive?: boolean; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{ width: "100%", height: 42, borderRadius: 14, background: Palette.labelAlpha(0.07), fontSize: 17, fontWeight: destructive ? 600 : 400, color: destructive ? Palette.red : Palette.label }}
    >
      {title}
    </button>
  );
}
