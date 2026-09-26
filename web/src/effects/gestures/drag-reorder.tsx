/** gestures.drag-reorder · 拖拽排序 (Gestures+DragReorder.swift) */
import { animate, motion, motionValue, type MotionValue, type Transition } from "motion/react";
import { Archive, Calendar, Inbox, Layers, Menu, Star } from "lucide-react";
import { useRef, useState, type ReactNode } from "react";
import { DemoHint, Palette, anim, black, clamp, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { colorGradient, useScript } from "./_a-common";

interface Item {
  id: number;
  title: [string, string];
  icon: ReactNode;
  tint: string;
}

const SEED: Item[] = [
  { id: 0, title: ["Inbox", "收件箱"], icon: <Inbox size={14} strokeWidth={2.6} />, tint: Palette.blue },
  { id: 1, title: ["Today", "今天"], icon: <Star size={14} strokeWidth={2} fill="currentColor" />, tint: Palette.amber },
  { id: 2, title: ["Upcoming", "计划"], icon: <Calendar size={14} strokeWidth={2.6} />, tint: Palette.coral },
  { id: 3, title: ["Projects", "项目"], icon: <Layers size={14} strokeWidth={2} fill="currentColor" />, tint: Palette.violet },
  { id: 4, title: ["Archive", "归档"], icon: <Archive size={14} strokeWidth={2.2} fill="currentColor" />, tint: Palette.mint },
];

const ROW = 50;
const SPACING = 8;
const SLOT = ROW + SPACING;

export default function DragReorder({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const [order, setOrder] = useState(SEED);
  const [draggingID, setDraggingID] = useState<number | null>(null);
  const ys = useRef(new Map<number, MotionValue<number>>(SEED.map((item, i) => [item.id, motionValue(i * SLOT)]))).current;
  const st = useRef({ order: SEED, dragging: null as number | null, from: 0, target: 0, held: false });
  const s = st.current;

  /** Where row `index` sits while row `from` is being dragged over slot `target`. */
  const restY = (index: number) => {
    let y = index * SLOT;
    if (s.dragging === null) return y;
    if (s.from < index && index <= s.target) y -= SLOT;
    if (s.target <= index && index < s.from) y += SLOT;
    return y;
  };
  const layoutOthers = (t: Transition) => {
    s.order.forEach((item, index) => {
      if (item.id !== s.dragging) animate(ys.get(item.id)!, restY(index), t);
    });
  };

  const changed = (id: number, index: number, dy: number, drive: "set" | Transition = "set") => {
    if (s.dragging === null) {
      s.from = index;
      s.target = index;
      s.dragging = id;
      setDraggingID(id);
      haptics.tap("light");
    }
    const y = ys.get(id)!;
    if (drive === "set") {
      y.stop();
      y.set(s.from * SLOT + dy);
    } else animate(y, s.from * SLOT + dy, drive);
    const raw = (s.from * SLOT + dy) / SLOT;
    const next = clamp(Math.round(raw), 0, s.order.length - 1);
    if (next !== s.target) {
      s.target = next;
      layoutOthers(drive === "set" ? spring(ctx.n("response"), 0.8) : drive);
      haptics.selection();
    }
  };

  const ended = () => {
    if (s.dragging === null) return;
    const list = [...s.order];
    const [item] = list.splice(s.from, 1);
    list.splice(s.target, 0, item);
    s.order = list;
    s.dragging = null;
    setOrder(list);
    setDraggingID(null);
    const t = spring(ctx.n("response") + 0.08, 0.78);
    list.forEach((it, index) => animate(ys.get(it.id)!, index * SLOT, t));
  };

  const userChanged = (id: number, dy: number) => {
    if (!s.held) {
      s.held = true;
      if (script.active) {
        script.cancel();
        ended();
      }
    }
    if (s.dragging !== null && s.dragging !== id) return;
    const index = s.order.findIndex((i) => i.id === id);
    if (index < 0) return;
    changed(id, index, dy);
  };
  const userEnded = () => {
    if (!s.held) return;
    s.held = false;
    ended();
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (s.order.length < 2 || s.held || s.dragging !== null) return;
      const n = s.order.length;
      const from = Math.floor(Math.random() * n);
      let to = Math.floor(Math.random() * n);
      if (to === from) to = (from + 2) % n;
      const id = s.order[from].id;
      changed(id, from, 0);
      const ease = anim.easeInOut(0.7);
      animate(ys.get(id)!, to * SLOT, ease);
      s.target = to;
      layoutOthers(ease);
      script.cancel();
      script.after(0.8, ended);
    },
    { every: 2.2, delay: 0.4 },
  );

  const zh = ctx.lang === "zh";
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ position: "relative", width: 280, height: SEED.length * SLOT - SPACING, flexShrink: 0 }}>
        {order.map((item) => (
          <Row
            key={item.id}
            item={item}
            title={zh ? item.title[1] : item.title[0]}
            y={ys.get(item.id)!}
            isLifted={draggingID === item.id}
            lift={ctx.n("lift")}
            onChanged={(dy) => userChanged(item.id, dy)}
            onEnded={userEnded}
          />
        ))}
      </div>
      <DemoHint ctx={ctx} en="Drag a row by its handle" zh="按住右侧把手拖动" />
    </div>
  );
}

function Row({
  item,
  title,
  y,
  isLifted,
  lift,
  onChanged,
  onEnded,
}: {
  item: Item;
  title: string;
  y: MotionValue<number>;
  isLifted: boolean;
  lift: number;
  onChanged: (dy: number) => void;
  onEnded: () => void;
}) {
  const pan = usePan({ onChange: ({ translation }) => onChanged(translation.y), onEnd: onEnded });
  return (
    <motion.div style={{ position: "absolute", left: 0, top: 0, width: 280, height: ROW, y, zIndex: isLifted ? 1 : 0 }}>
      <motion.div
        initial={false}
        animate={{
          scale: isLifted ? lift : 1,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 ${isLifted ? 12 : 2}px ${isLifted ? 18 : 4}px ${black(isLifted ? 0.18 : 0.05)}`,
        }}
        transition={isLifted ? spring(0.25, 0.75) : spring(0.38, 0.78)}
        style={{ height: ROW, display: "flex", alignItems: "center", gap: 12, paddingLeft: 10, borderRadius: 16, background: Palette.elevated }}
      >
        <div style={{ width: 30, height: 30, borderRadius: 9, background: colorGradient(item.tint), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
          {item.icon}
        </div>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{title}</span>
        <div style={{ flex: 1 }} />
        <div
          {...pan}
          style={{ ...pan.style, width: 48, height: ROW, display: "grid", placeItems: "center", cursor: "grab", color: isLifted ? item.tint : Palette.tertiaryLabel }}
        >
          <Menu size={17} strokeWidth={2.6} />
        </div>
      </motion.div>
    </motion.div>
  );
}
