/** morph.fab-menu · 悬浮按钮变菜单 (Morph+FabMenu.swift) */
import { motion } from "motion/react";
import { Camera, FolderPlus, ListChecks, Mic, Plus, SquarePen, Users, WandSparkles } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, alpha, anim, delayed, hex, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";

const ROW_H = 46;
const OPEN_W = 224;

export default function FabMenu({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpen] = useState(false);
  const zh = ctx.lang === "zh";
  const spr = spring(ctx.n("response"), ctx.n("damping"));

  const toggle = () => {
    haptics.tap(open ? "light" : "medium");
    setOpen((o) => !o);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.8 });

  const dark = ctx.scheme === "dark";
  const primary = dark ? "#ffffff" : "#000000";
  const ink = dark ? "#000000" : "#ffffff";
  const actions: [typeof Camera, string][] = [
    [SquarePen, zh ? "新建笔记" : "New note"],
    [Camera, zh ? "扫描文稿" : "Scan document"],
    [Mic, zh ? "语音备忘" : "Voice memo"],
    [FolderPlus, zh ? "新建文件夹" : "New folder"],
  ];
  const openH = 10 + actions.length * ROW_H + 64;

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <Backdrop zh={zh} />
      <motion.div
        initial={false}
        animate={{ opacity: open ? 0 : 1 }}
        transition={spr}
        style={{ position: "absolute", left: 24, bottom: 44, pointerEvents: "none" }}
      >
        <DemoHint ctx={ctx} en="Tap the + button" zh="点击“+”按钮" style={{ textAlign: "left" }} />
      </motion.div>
      <motion.div
        initial={false}
        animate={{ opacity: open ? 0.16 : 0 }}
        transition={spr}
        onClick={toggle}
        style={{ position: "absolute", inset: 0, background: "#000", pointerEvents: open ? "auto" : "none" }}
      />
      <motion.div
        initial={false}
        animate={{
          width: open ? OPEN_W : 60,
          height: open ? openH : 60,
          borderRadius: open ? 24 : 30,
          backgroundColor: open ? primary : Palette.indigo,
          boxShadow: `0 10px ${open ? 24 : 14}px ${hex(Palette.indigo, open ? 0.15 : 0.4)}`,
        }}
        transition={spr}
        style={{ position: "absolute", right: 22, bottom: 22, overflow: "hidden" }}
      >
        <div style={{ position: "absolute", right: 0, bottom: 0, width: OPEN_W, paddingTop: 10, display: "flex", flexDirection: "column" }}>
          {actions.map(([Icon, title], index) => {
            const fromBottom = actions.length - 1 - index;
            return (
              <motion.button
                key={index}
                type="button"
                onClick={toggle}
                initial={false}
                animate={{ opacity: open ? 1 : 0, x: open ? 0 : 16, filter: `blur(${open ? 0 : 5}px)` }}
                transition={open ? delayed(spring(0.42, 0.85), 0.06 + fromBottom * ctx.n("stagger")) : anim.easeOut(0.12)}
                style={{ height: ROW_H, padding: "0 12px", display: "flex", alignItems: "center", gap: 12, color: ink, textAlign: "left", pointerEvents: open ? "auto" : "none" }}
              >
                <span style={{ width: 32, height: 32, borderRadius: 16, background: alpha(ink, 0.14), display: "grid", placeItems: "center" }}>
                  <Icon size={16} strokeWidth={2.3} />
                </span>
                <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500 }}>{title}</span>
              </motion.button>
            );
          })}
          <div style={{ height: 64 }} />
        </div>
        <button
          type="button"
          onClick={toggle}
          style={{ position: "absolute", right: 0, bottom: 0, width: 60, height: 60, display: "grid", placeItems: "center" }}
        >
          <motion.span
            initial={false}
            animate={{ rotate: open ? 135 : 0, color: open ? ink : "#ffffff" }}
            transition={spr}
            style={{ display: "grid" }}
          >
            <Plus size={25} strokeWidth={2.6} />
          </motion.span>
        </button>
      </motion.div>
    </div>
  );
}

function Backdrop({ zh }: { zh: boolean }) {
  const notes: [typeof Users, string, string, string, boolean][] = [
    [ListChecks, Palette.coral, zh ? "发布清单" : "Launch checklist", zh ? "今天 · 6 项" : "Today · 6 items", false],
    [WandSparkles, Palette.violet, zh ? "动效规范 v2" : "Motion specs v2", zh ? "昨天" : "Yesterday", false],
    [Users, Palette.sky, zh ? "周会纪要" : "Weekly sync notes", zh ? "周一" : "Monday", true],
  ];
  return (
    <div style={{ position: "absolute", inset: 0, padding: "22px 22px 0", display: "flex", flexDirection: "column", gap: 18, pointerEvents: "none" }}>
      {notes.map(([Icon, color, title, sub, fill], i) => (
        <div key={i} style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 38, height: 38, borderRadius: 10, background: alpha(color, 0.14), display: "grid", placeItems: "center", color }}>
            <Icon size={17} strokeWidth={2.4} fill={fill ? "currentColor" : "none"} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{title}</span>
            <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{sub}</span>
          </div>
        </div>
      ))}
    </div>
  );
}
