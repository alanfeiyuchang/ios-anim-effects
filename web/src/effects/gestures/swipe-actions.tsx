/** gestures.swipe-actions · 滑动操作 (Gestures+SwipeActions.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent, useTransform, type MotionValue } from "motion/react";
import { ListChecks, Paintbrush, Pin, PinOff, Trash2, Undo2, Users } from "lucide-react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { DemoHint, Palette, anim, black, clamp, fonts, mix, rubberBand, spring, useAutoplay, useHaptics, usePan, type DemoContext, type DemoProps } from "../../kit";
import { colorGradient, predictedEnd, useScript } from "./_a-common";

interface SwipeItem {
  id: number;
  title: [string, string];
  subtitle: [string, string];
  time: [string, string];
  icon: ReactNode;
  tint: string;
}

const SEED: SwipeItem[] = [
  { id: 0, title: ["Design review", "设计评审"], subtitle: ["Motion specs v3 are ready", "动效规范 v3 已就绪"], time: ["9:41", "9:41"], icon: <Paintbrush size={17} strokeWidth={2.4} />, tint: Palette.violet },
  { id: 1, title: ["Launch checklist", "发布清单"], subtitle: ["4 items left before ship", "上线前还剩 4 项"], time: ["8:15", "8:15"], icon: <ListChecks size={18} strokeWidth={2.4} />, tint: Palette.mint },
  { id: 2, title: ["Weekly sync", "周会同步"], subtitle: ["Notes and action items", "会议纪要与待办"], time: ["Mon", "周一"], icon: <Users size={17} strokeWidth={2.2} fill="currentColor" />, tint: Palette.sky },
];

const REVEAL = 132;

export default function SwipeActions({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const introClose = useScript();
  const [items, setItems] = useState(SEED);
  const [pinned, setPinned] = useState<Set<number>>(new Set());
  const step = useRef(0);
  const offsets = useRef(new Map<number, MotionValue<number>>());
  const itemsRef = useRef(items);
  itemsRef.current = items;

  const mvFor = (id: number) => offsets.current.get(id)!;
  const rowSpring = () => spring(ctx.n("response"), 0.82);
  const setOffset = (id: number, target: number, t = rowSpring()) => {
    const mv = offsets.current.get(id);
    if (mv) animate(mv, target, t);
  };

  const hasOpenRow = () => [...offsets.current.values()].some((mv) => mv.get() !== 0);
  const closeAll = () => {
    if (!hasOpenRow()) return;
    offsets.current.forEach((_, id) => setOffset(id, 0));
  };

  const togglePin = (id: number) => {
    haptics.selection();
    setPinned((p) => {
      const next = new Set(p);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
    setOffset(id, 0);
  };

  const remove = (id: number) => {
    setItems((list) => list.filter((i) => i.id !== id));
  };

  const restore = () => {
    offsets.current.forEach((mv) => {
      mv.stop();
      mv.set(0);
    });
    setItems(SEED);
    setPinned(new Set());
  };

  const end = (id: number, current: number, predicted: number) => {
    const full = ctx.n("full");
    if (current < -full) {
      remove(id);
      return;
    }
    if (predicted < -full * 1.6) {
      haptics.tap("medium");
      remove(id);
      return;
    }
    const target = predicted < -REVEAL * 0.5 ? -REVEAL : 0;
    offsets.current.forEach((_, other) => setOffset(other, other === id ? target : 0));
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const s = step.current;
      step.current += 1;
      const list = itemsRef.current;
      const first = list[0];
      if (!first) {
        restore();
        return;
      }
      const second = list.length > 1 ? list[1] : first;
      switch (s % 5) {
        case 0:
          setOffset(first.id, -REVEAL);
          if (!ctx.isPreview) {
            introClose.cancel();
            introClose.after(1.2, () => {
              if (mvFor(first.id)?.get() === -REVEAL) setOffset(first.id, 0);
            });
          }
          break;
        case 1:
          togglePin(first.id);
          break;
        case 2:
          setOffset(second.id, -(ctx.n("full") + 30), anim.easeInOut(0.55));
          break;
        case 3:
          remove(second.id);
          break;
        default:
          restore();
      }
    },
    { every: 1.2 },
  );

  return (
    <div
      onClick={closeAll}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}
    >
      <div style={{ width: 300, display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
        <AnimatePresence mode="popLayout" initial={false}>
          {items.map((item) => (
            <motion.div
              key={item.id}
              layout="position"
              initial={{ opacity: 0, scale: 0.96 }}
              animate={{ opacity: 1, scale: 1, x: 0 }}
              exit={{ x: -320, opacity: 0 }}
              transition={spring(0.42, 0.86)}
              style={{ width: 300 }}
            >
              <SwipeRow
                item={item}
                ctx={ctx}
                register={(mv) => offsets.current.set(item.id, mv)}
                unregister={() => offsets.current.delete(item.id)}
                pinned={pinned.has(item.id)}
                onDrag={() => introClose.cancel()}
                onEnd={(current, predicted) => end(item.id, current, predicted)}
                onPin={() => togglePin(item.id)}
                onDelete={() => {
                  haptics.tap("medium");
                  remove(item.id);
                }}
                onTapContent={closeAll}
              />
            </motion.div>
          ))}
          {items.length < SEED.length && (
            <motion.button
              key="restore"
              layout="position"
              type="button"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={spring(0.45, 0.85)}
              onClick={(e) => {
                e.stopPropagation();
                restore();
              }}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 6,
                padding: "8px 14px",
                borderRadius: 999,
                background: Palette.surface,
                color: Palette.secondaryLabel,
                fontSize: 13,
                lineHeight: "18px",
                fontWeight: 600,
              }}
            >
              <Undo2 size={13} strokeWidth={2.6} />
              {ctx.t("Restore", "恢复")}
            </motion.button>
          )}
          {!ctx.isPreview && (
            <motion.div key="hint" layout="position" transition={spring(0.42, 0.86)} style={{ paddingTop: 4 }}>
              <DemoHint ctx={ctx} en="Swipe a row left — all the way to delete" zh="向左滑动某行，滑到底即删除" />
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

function SwipeRow({
  item,
  ctx,
  register,
  unregister,
  pinned,
  onDrag,
  onEnd,
  onPin,
  onDelete,
  onTapContent,
}: {
  item: SwipeItem;
  ctx: DemoContext;
  register: (mv: MotionValue<number>) => void;
  unregister: () => void;
  pinned: boolean;
  onDrag: () => void;
  onEnd: (current: number, predicted: number) => void;
  onPin: () => void;
  onDelete: () => void;
  onTapContent: () => void;
}) {
  const haptics = useHaptics();
  const offset = useMotionValue(0);
  const fullSwipe = ctx.n("full");
  const [isFull, setFull] = useState(false);
  const blend = useMotionValue(0);
  const start = useRef<number | null>(null);
  const dragged = useRef(false);
  const zh = ctx.lang === "zh";

  useEffect(() => {
    register(offset);
    return unregister;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useMotionValueEvent(offset, "change", (v) => {
    const full = v < -fullSwipe;
    if (full !== isFull) {
      setFull(full);
      animate(blend, full ? 1 : 0, anim.snappyD(0.25));
      if (full) haptics.tap("medium");
    }
  });

  const progress = useTransform(offset, (v) => clamp(-v / REVEAL));
  const actionsScale = useTransform(progress, (p) => 0.6 + 0.4 * p);
  const deleteWidth = useTransform(() => mix(56, Math.max(56, -offset.get() - 8), blend.get()));

  const pan = usePan(
    {
      onStart: () => {
        dragged.current = true;
      },
      onChange: ({ translation }) => {
        if (start.current === null) {
          if (!(Math.abs(translation.x) > Math.abs(translation.y))) return;
          offset.stop();
          start.current = offset.get();
        }
        let next = start.current + translation.x;
        if (next > 0) next = rubberBand(next, 40);
        onDrag();
        offset.set(next);
      },
      onEnd: ({ translation, velocity }) => {
        const base = start.current;
        if (base === null) return;
        start.current = null;
        onEnd(offset.get(), base + predictedEnd(translation, velocity).x);
      },
    },
    12,
  );

  return (
    <div style={{ position: "relative", height: 64, display: "flex", justifyContent: "flex-end" }}>
      <motion.div
        style={{ display: "flex", gap: 8, height: 64, scale: actionsScale, opacity: progress, originX: 1, originY: 0.5 }}
      >
        <motion.div
          initial={false}
          animate={{ width: isFull ? 0 : 56, opacity: isFull ? 0 : 1 }}
          transition={anim.snappyD(0.25)}
          style={{ overflow: "hidden" }}
        >
          <ActionTile color={Palette.amber} onClick={onPin}>
            <AnimatePresence mode="popLayout" initial={false}>
              <motion.span
                key={pinned ? "off" : "on"}
                initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                transition={anim.snappyD(0.3)}
                style={{ display: "grid" }}
              >
                {pinned ? <PinOff size={18} strokeWidth={2.4} /> : <Pin size={18} strokeWidth={2.2} fill="currentColor" />}
              </motion.span>
            </AnimatePresence>
          </ActionTile>
        </motion.div>
        <motion.div style={{ width: deleteWidth }}>
          <ActionTile color={Palette.red} onClick={onDelete}>
            <Trash2 size={18} strokeWidth={2.2} />
          </ActionTile>
        </motion.div>
      </motion.div>
      <motion.div
        {...pan}
        onClick={(e) => {
          e.stopPropagation();
          if (dragged.current) {
            dragged.current = false;
            return;
          }
          onTapContent();
        }}
        style={{
          ...pan.style,
          x: offset,
          position: "absolute",
          inset: 0,
          display: "flex",
          alignItems: "center",
          gap: 12,
          padding: "0 12px",
          borderRadius: 18,
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 4px 8px ${black(0.06)}`,
        }}
      >
        <div style={{ width: 38, height: 38, borderRadius: 11, background: colorGradient(item.tint), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
          {item.icon}
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 3, minWidth: 0, flex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 5 }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, whiteSpace: "nowrap" }}>{zh ? item.title[1] : item.title[0]}</span>
            <AnimatePresence>
              {pinned && (
                <motion.span
                  initial={{ scale: 0.2, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  exit={{ scale: 0.2, opacity: 0 }}
                  transition={spring(0.35, 0.7)}
                  style={{ display: "grid", color: Palette.amber, rotate: 35 }}
                >
                  <Pin size={11} strokeWidth={2.6} fill="currentColor" />
                </motion.span>
              )}
            </AnimatePresence>
          </div>
          <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {zh ? item.subtitle[1] : item.subtitle[0]}
          </span>
        </div>
        <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 500, color: Palette.tertiaryLabel, fontFamily: fonts.text, flexShrink: 0 }}>
          {zh ? item.time[1] : item.time[0]}
        </span>
      </motion.div>
    </div>
  );
}

function ActionTile({ color, onClick, children }: { color: string; onClick: () => void; children: ReactNode }) {
  return (
    <button
      type="button"
      onClick={(e) => {
        e.stopPropagation();
        onClick();
      }}
      style={{ width: "100%", height: 64, borderRadius: 18, background: colorGradient(color), display: "grid", placeItems: "center", color: "#fff" }}
    >
      {children}
    </button>
  );
}
