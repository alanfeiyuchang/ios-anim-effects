/** buttons.expand-actions · 展开操作 (Buttons+ExpandActions.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Image, ListChecks, Plus, ScanLine, SquarePen, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import {
  DemoHint,
  NumericText,
  Palette,
  alpha,
  anim,
  black,
  delayed,
  demoCard,
  glass,
  pressHandlers,
  spring,
  springDB,
  useAutoplay,
  useHaptics,
  useTimeouts,
  type DemoProps,
} from "../../kit";
import { colorGradient, cub, spr, track, useKeyframes } from "./_b-kit";

type Text = [string, string];
interface Item {
  icon: LucideIcon;
  color: string;
  name: Text;
  newTitle: Text;
}
interface Note {
  id: number;
  icon: LucideIcon;
  color: string;
  title: Text;
  detail: Text;
}

const ITEMS: Item[] = [
  { icon: ScanLine, color: Palette.coral, name: ["Scan", "扫描"], newTitle: ["New scan", "新扫描件"] },
  { icon: Image, color: Palette.mint, name: ["Photo", "照片"], newTitle: ["Photo note", "照片笔记"] },
  { icon: SquarePen, color: Palette.sky, name: ["Note", "笔记"], newTitle: ["Untitled note", "未命名笔记"] },
];

const INITIAL: Note[] = [
  { id: 0, icon: ListChecks, color: Palette.sky, title: ["Packing list", "打包清单"], detail: ["Updated 2 h ago", "2 小时前更新"] },
  { id: 1, icon: Image, color: Palette.mint, title: ["Lake Braies shots", "布拉耶斯湖照片"], detail: ["12 photos", "12 张照片"] },
  { id: 2, icon: ScanLine, color: Palette.coral, title: ["Whiteboard scan", "白板扫描"], detail: ["Yesterday", "昨天"] },
];

export default function ExpandActions({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [open, setOpen] = useState(false);
  const [presses, setPresses] = useState(0);
  const [notes, setNotes] = useState(INITIAL);
  const [freshID, setFreshID] = useState<number | null>(null);
  const [total, setTotal] = useState(24);
  const nextID = useRef(100);
  const step = useRef(0);
  const openRef = useRef(false);
  openRef.current = open;
  const t = (x: Text) => ctx.t(x[0], x[1]);

  const toggle = () => {
    setOpen((o) => !o);
    openRef.current = !openRef.current;
    setPresses((p) => p + 1);
    haptics.tap();
  };

  const perform = (index: number, silent: boolean) => {
    if (!openRef.current) return;
    const item = ITEMS[index];
    const note: Note = { id: nextID.current, icon: item.icon, color: item.color, title: item.newTitle, detail: ["Just now", "刚刚"] };
    nextID.current += 1;
    setOpen(false);
    openRef.current = false;
    setPresses((p) => p + 1);
    if (!silent) haptics.success();
    after(0.12, () => {
      setNotes((list) => [note, ...list].slice(0, 3));
      setFreshID(note.id);
      setTotal((n) => n + 1);
    });
    after(1.2, () => setFreshID((id) => (id === note.id ? null : id)));
  };

  const cancelIntro = () => clearAll();
  const playIntro = () => {
    if (!openRef.current) toggle();
    after(1.4, () => perform(2, true));
  };
  const previewTick = () => {
    if (openRef.current) {
      perform(step.current % ITEMS.length, true);
      step.current += 1;
    } else toggle();
  };
  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? previewTick() : playIntro()), { every: 1.5, delay: 0.4 });

  const kt = useKeyframes(presses, 0.48);
  const pressScale = kt < 0 ? 1 : track(kt, [cub(0.92, 0.08), spr(1, 0.4, 0.5, 0.7)], 1);
  const stagger = ctx.n("stagger");
  const rowSpring = spring(ctx.n("response"), 0.72);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), position: "relative", width: 300, height: 300, flexShrink: 0 }}>
        <motion.div
          onClick={() => {
            cancelIntro();
            if (openRef.current) toggle();
          }}
          animate={{ scale: open ? 0.95 : 1, filter: open ? "blur(6px)" : "blur(0px)", opacity: open ? 0.5 : 1 }}
          transition={springDB(0.35, 0)}
          style={{ position: "absolute", inset: 0, padding: 18, display: "flex", flexDirection: "column", gap: 12 }}
        >
          <div style={{ display: "flex", alignItems: "center" }}>
            <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{ctx.t("Recent notes", "最近笔记")}</span>
            <span style={{ flex: 1 }} />
            <NumericText value={total} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }} />
          </div>
          <AnimatePresence initial={false} mode="popLayout">
            {notes.map((note) => (
              <motion.div
                key={note.id}
                layout
                initial={{ y: -64, opacity: 0 }}
                animate={{ y: 0, opacity: 1, backgroundColor: alpha(note.color, freshID === note.id ? 0.14 : 0) }}
                exit={{ opacity: 0 }}
                transition={{ ...spring(0.45, 0.8), backgroundColor: anim.easeOut(0.6) }}
                style={{ display: "flex", alignItems: "center", gap: 12, padding: 6, borderRadius: 14 }}
              >
                <div style={{ width: 40, height: 40, flexShrink: 0, borderRadius: 10, background: alpha(note.color, 0.18), display: "grid", placeItems: "center", color: note.color }}>
                  <note.icon size={17} strokeWidth={2.4} />
                </div>
                <div style={{ display: "flex", flexDirection: "column", gap: 2, minWidth: 0 }}>
                  <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label, whiteSpace: "nowrap" }}>{t(note.title)}</span>
                  <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{t(note.detail)}</span>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </motion.div>
        {ITEMS.map((item, index) => {
          const order = open ? index : ITEMS.length - 1 - index;
          const delay = order * stagger;
          const lift = (index + 1) * ctx.n("spacing");
          return (
            <motion.div
              key={index}
              initial={false}
              animate={{ y: open ? -lift : 0 }}
              transition={delayed(rowSpring, delay)}
              style={{ position: "absolute", right: 22, bottom: 22, width: 200, height: 48, pointerEvents: open ? "auto" : "none" }}
            >
              <ActionRow
                item={item}
                label={t(item.name)}
                open={open}
                labelTransition={delayed(rowSpring, open ? delay + 0.08 : delay)}
                circleTransition={delayed(rowSpring, delay)}
                onTap={() => {
                  cancelIntro();
                  perform(index, false);
                }}
              />
            </motion.div>
          );
        })}
        <button
          type="button"
          onClick={() => {
            cancelIntro();
            toggle();
          }}
          style={{
            position: "absolute",
            right: 16,
            bottom: 16,
            width: 60,
            height: 60,
            borderRadius: "50%",
            background: Palette.primary,
            boxShadow: `0 7px 14px ${alpha(Palette.indigo, 0.4)}`,
            display: "grid",
            placeItems: "center",
            color: "#fff",
            transform: `scale(${pressScale})`,
          }}
        >
          <motion.span initial={false} animate={{ rotate: open ? 135 : 0 }} transition={spring(0.4, 0.65)} style={{ display: "grid" }}>
            <Plus size={28} strokeWidth={2.6} />
          </motion.span>
        </button>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap +, then pick an action" zh="点击加号，再选一个操作" style={{ paddingBottom: 16 }} />
    </div>
  );
}

function ActionRow({
  item,
  label,
  open,
  labelTransition,
  circleTransition,
  onTap,
}: {
  item: Item;
  label: string;
  open: boolean;
  labelTransition: object;
  circleTransition: object;
  onTap: () => void;
}) {
  const [pressed, setPressed] = useState(false);
  return (
    <motion.button
      type="button"
      {...pressHandlers(setPressed)}
      onClick={onTap}
      animate={{ scale: pressed ? 0.94 : 1, filter: pressed ? "brightness(0.94)" : "brightness(1)" }}
      transition={spring(0.3, 0.7)}
      style={{ position: "absolute", inset: 0, paddingRight: 0, display: "flex", alignItems: "center", justifyContent: "flex-end", gap: 10 }}
    >
      <motion.span
        initial={false}
        animate={{ x: open ? 0 : 16, opacity: open ? 1 : 0 }}
        transition={labelTransition}
        style={{
          height: 32,
          padding: "0 12px",
          display: "flex",
          alignItems: "center",
          borderRadius: 16,
          ...glass("regular"),
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 3px 6px ${black(0.1)}`,
          fontSize: 15,
          fontWeight: 600,
          color: Palette.label,
          whiteSpace: "nowrap",
        }}
      >
        {label}
      </motion.span>
      <motion.span
        initial={false}
        animate={{ scale: open ? 1 : 0.3, opacity: open ? 1 : 0 }}
        transition={circleTransition}
        style={{
          width: 48,
          height: 48,
          flexShrink: 0,
          borderRadius: "50%",
          background: colorGradient(item.color),
          boxShadow: `0 6px 10px ${alpha(item.color, 0.35)}`,
          display: "grid",
          placeItems: "center",
          color: "#fff",
        }}
      >
        <item.icon size={19} strokeWidth={2.4} />
      </motion.span>
    </motion.button>
  );
}
