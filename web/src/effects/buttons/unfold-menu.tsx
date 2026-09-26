/** buttons.unfold-menu · 折纸展开菜单 (Buttons+UnfoldMenu.swift) */
import { motion } from "motion/react";
import { CopyPlus, Ellipsis, Pencil, Share, Trash2, X } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, delayed, demoCard, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BlurReplace, CheckCircleFill, PressButton, SymbolReplace } from "./_a-kit";

const ROWS = [
  { Icon: Share, title: ["Share", "分享"], done: ["Link copied", "链接已复制"], destructive: false },
  { Icon: Pencil, title: ["Rename", "重命名"], done: ["Renamed", "已重命名"], destructive: false },
  { Icon: CopyPlus, title: ["Duplicate", "复制副本"], done: ["Copy created", "已创建副本"], destructive: false },
  { Icon: Trash2, title: ["Delete", "删除"], done: ["Moved to Trash", "已移到废纸篓"], destructive: true },
] as const;

function DocFill() {
  return (
    <svg viewBox="0 0 24 24" width={22} height={22}>
      <path d="M6.5 2h7.2c.5 0 1 .2 1.4.6l4.3 4.3c.4.4.6.9.6 1.4V20a2 2 0 0 1-2 2H6.5a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2Z" fill="#fff" />
      <path d="M8 12h8M8 15.5h8M8 8.5h3.5" stroke="rgb(79 124 255)" strokeWidth={1.6} strokeLinecap="round" />
    </svg>
  );
}

export default function UnfoldMenu({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [open, setOpen] = useState(false);
  const openRef = useRef(false);
  const [toast, setToast] = useState<number | null>(null);
  const step = useRef(0);
  const intro = useRef<(() => void) | null>(null);
  const toastTimer = useRef<(() => void) | null>(null);

  const cancelIntro = () => {
    intro.current?.();
    intro.current = null;
  };
  useEffect(() => () => cancelIntro(), []);

  const toggle = (silent = false) => {
    openRef.current = !openRef.current;
    setOpen(openRef.current);
    if (!silent) haptics.tap();
    if (openRef.current) {
      toastTimer.current?.();
      setToast(null);
    }
  };
  const choose = (index: number, silent = false) => {
    if (!openRef.current) return;
    openRef.current = false;
    setOpen(false);
    if (!silent) haptics.success();
    toastTimer.current?.();
    toastTimer.current = after(0.2, () => setToast(index));
  };

  useAutoplay(ctx.isPreview, () => {
    if (ctx.isPreview) {
      const s = step.current % 3;
      if (s === 0) toggle();
      else if (s === 1) choose(0);
      else setToast(null);
      step.current += 1;
      return;
    }
    cancelIntro();
    if (!openRef.current) toggle(true);
    intro.current = after(1.3, () => {
      intro.current = null;
      choose(1, true);
    });
  }, { every: 1.3, delay: 0.4 });

  const count = ROWS.length;
  const persp = 190 / Math.max(ctx.n("perspective"), 0.05);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), position: "relative", width: 300, height: 250, padding: 16, display: "flex", flexDirection: "column", gap: 14, flexShrink: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 44, height: 44, borderRadius: 12, background: Palette.ocean, display: "grid", placeItems: "center", flexShrink: 0 }}>
            <DocFill />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2, flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{ctx.t("Launch plan.pdf", "发布计划.pdf")}</div>
            <div style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{ctx.t("2.4 MB · Edited 3 min ago", "2.4 MB · 3 分钟前编辑")}</div>
          </div>
          <PressButton
            scale={0.9}
            dim={0.04}
            onClick={() => {
              cancelIntro();
              toggle();
            }}
            style={{
              width: 44,
              height: 44,
              borderRadius: "50%",
              background: Palette.labelAlpha(open ? 0.12 : 0.06),
              transition: "background 0.3s",
              display: "grid",
              placeItems: "center",
              color: Palette.label,
              flexShrink: 0,
            }}
          >
            <SymbolReplace id={open ? "x" : "more"}>{open ? <X size={19} strokeWidth={2.8} /> : <Ellipsis size={21} strokeWidth={3} />}</SymbolReplace>
          </PressButton>
        </div>
        <motion.div initial={false} animate={{ opacity: open ? 0.6 : 1 }} transition={anim.smoothD(0.3)}>
          <PlaceholderLines count={4} />
        </motion.div>
        <BlurReplace id={toast === null ? "none" : String(toast)} align="leading" style={{ fontSize: 13, lineHeight: "18px", fontWeight: 600, color: Palette.label }}>
          {toast === null ? (
            <span />
          ) : (
            <span style={{ display: "flex", alignItems: "center", gap: 6 }}>
              <CheckCircleFill size={15} color={Palette.green} />
              {ctx.t(ROWS[toast].done[0], ROWS[toast].done[1])}
            </span>
          )}
        </BlurReplace>
        <div
          style={{
            position: "absolute",
            top: 68,
            right: 14,
            width: 190,
            pointerEvents: open ? "auto" : "none",
            filter: open ? "drop-shadow(0 10px 16px rgb(0 0 0 / 0.18))" : "none",
          }}
        >
          {ROWS.map((row, index) => {
            const order = open ? index : count - 1 - index;
            const delay = order * ctx.n("stagger");
            const r = (on: boolean) => (on ? 16 : 0);
            return (
              <motion.button
                key={index}
                type="button"
                onClick={() => {
                  cancelIntro();
                  choose(index);
                }}
                initial={false}
                animate={{ opacity: open ? 1 : 0, rotateX: open ? 0 : 90, filter: open ? "brightness(1)" : "brightness(0.6)" }}
                transition={delayed(spring(ctx.n("response"), 0.72), delay)}
                style={{
                  position: "relative",
                  width: 190,
                  height: 46,
                  padding: "0 16px",
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  background: Palette.elevated,
                  borderRadius: `${r(index === 0)}px ${r(index === 0)}px ${r(index === count - 1)}px ${r(index === count - 1)}px`,
                  color: row.destructive ? Palette.red : Palette.label,
                  transformOrigin: "50% 0%",
                  transformPerspective: persp,
                  fontSize: 15,
                  fontWeight: 500,
                }}
              >
                <span style={{ width: 20, display: "grid", placeItems: "center" }}>
                  <row.Icon size={17} strokeWidth={2.4} />
                </span>
                {ctx.t(row.title[0], row.title[1])}
                {index < count - 1 && <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 1, background: Palette.stroke }} />}
              </motion.button>
            );
          })}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the … button" zh="点击“…”按钮" style={{ paddingBottom: 14 }} />
    </div>
  );
}
