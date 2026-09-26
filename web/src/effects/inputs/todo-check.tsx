/** inputs.todo-check · 待办勾选 (Inputs+TodoCheck.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, delayed, demoCard, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";

interface TodoItem {
  id: number;
  title: [string, string];
  done: boolean;
  finishedAt: number;
}

const PREVIEW_TAPS = [0, 3, 1, 1, 0, 3];

export default function TodoCheck({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [items, setItems] = useState<TodoItem[]>([
    { id: 0, title: ["Book flights", "订机票"], done: false, finishedAt: 0 },
    { id: 1, title: ["Renew passport", "续签护照"], done: false, finishedAt: 0 },
    { id: 2, title: ["Pack chargers", "带好充电器"], done: true, finishedAt: 1 },
    { id: 3, title: ["Water the plants", "给植物浇水"], done: false, finishedAt: 0 },
  ]);
  const [order, setOrder] = useState([0, 1, 3, 2]);
  const itemsRef = useRef(items);
  itemsRef.current = items;
  const counter = useRef(2);
  const step = useRef(0);

  const sortedOrder = () => {
    const list = itemsRef.current;
    const open = list.filter((i) => !i.done).map((i) => i.id);
    const finished = list
      .filter((i) => i.done)
      .sort((a, b) => a.finishedAt - b.finishedAt)
      .map((i) => i.id);
    return [...open, ...finished];
  };

  const toggle = (id: number) => {
    const next = itemsRef.current.map((i) => ({ ...i }));
    const item = next.find((i) => i.id === id);
    if (!item) return;
    item.done = !item.done;
    if (item.done) {
      counter.current += 1;
      item.finishedAt = counter.current;
      if (!ctx.isPreview) {
        if (next.every((i) => i.done)) haptics.success();
        else haptics.tap();
      }
    } else if (!ctx.isPreview) haptics.tap("soft");
    itemsRef.current = next;
    setItems(next);
    if (!ctx.b("reorder")) return;
    after(ctx.n("pause"), () => setOrder(sortedOrder()));
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const id = PREVIEW_TAPS[step.current % PREVIEW_TAPS.length];
      step.current += 1;
      toggle(id);
    },
    { every: 1.5, delay: 0.4 },
  );

  const doneCount = items.filter((i) => i.done).length;
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 300, padding: 18, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "center" }}>
          <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{ctx.t("Trip prep", "出行准备")}</span>
          <span style={{ flex: 1 }} />
          <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel, display: "inline-flex", whiteSpace: "pre" }}>
            {zh ? "已完成 " : ""}
            <NumericText value={doneCount} />
            {zh ? `/${items.length}` : ` of ${items.length} done`}
          </span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          {order.map((id) => {
            const item = items.find((i) => i.id === id)!;
            return (
              <motion.div key={id} layout="position" transition={spring(0.5, 0.85)}>
                <TodoRow item={item} wash={ctx.n("wash")} title={ctx.t(item.title[0], item.title[1])} onTap={() => toggle(id)} />
              </motion.div>
            );
          })}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tick a task" zh="勾选一项任务" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function TodoRow({ item, wash, title, onTap }: { item: TodoItem; wash: number; title: string; onTap: () => void }) {
  const done = item.done;
  return (
    <div
      onClick={onTap}
      style={{ position: "relative", height: 46, padding: "0 12px", display: "flex", alignItems: "center", gap: 12, cursor: "pointer" }}
    >
      <div style={{ position: "absolute", inset: 0, borderRadius: 12, overflow: "hidden" }}>
        <div style={{ position: "absolute", inset: 0, background: Palette.surface, opacity: 0.6 }} />
        <motion.div
          initial={false}
          animate={{ scaleX: done ? 1 : 0 }}
          transition={delayed(anim.easeInOut(wash), done ? 0.08 : 0)}
          style={{ position: "absolute", inset: 0, originX: 0, background: "rgb(33 212 168 / 0.14)" }}
        />
      </div>
      {/* Checkbox */}
      <div style={{ position: "relative", width: 24, height: 24, flexShrink: 0 }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: `inset 0 0 0 1.5px ${Palette.labelAlpha(0.25)}`, opacity: done ? 0 : 1 }} />
        <motion.div
          initial={false}
          animate={{ opacity: done ? 1 : 0, boxShadow: `inset 0 0 0 ${done ? 12 : 12 * (1 - 0.86)}px ${Palette.mint}` }}
          transition={spring(0.35, 0.75)}
          style={{ position: "absolute", inset: 0, borderRadius: "50%" }}
        />
        <motion.svg
          initial={false}
          width={11}
          height={9}
          viewBox="0 0 11 9"
          animate={{ scale: done ? 1 : 1.8, opacity: done ? 1 : 0 }}
          transition={done ? delayed(spring(0.28, 0.6), 0.18) : anim.easeOut(0.15)}
          style={{ position: "absolute", left: 6.5, top: 7.5, overflow: "visible" }}
        >
          <path d="M0 4.5 L4.18 9 L11 0" fill="none" stroke="#fff" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round" />
        </motion.svg>
      </div>
      <motion.span
        initial={false}
        animate={{ opacity: done ? 0.45 : 1 }}
        transition={anim.easeOut(0.25)}
        style={{ position: "relative", fontSize: 15, lineHeight: "20px", fontWeight: 500, color: Palette.label }}
      >
        {title}
      </motion.span>
    </div>
  );
}
