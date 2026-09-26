/** gestures.swipe-complete · 右滑完成任务 (Gestures+SwipeComplete.swift) */
import { animate, motion, useMotionValue, useTransform, type MotionValue, type Transition } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, SymbolBounce, alpha, anim, black, clamp, rubberBand, spring, textStyle, useAutoplay, useHaptics, usePan, type DemoContext, type DemoProps } from "../../kit";
import { CircleFillCutout, CircleOutlineGlyph, glyphs } from "./_b-icons";

interface Task {
  id: number;
  en: string;
  zh: string;
  tint: string;
  done: boolean;
}

const SEED: Task[] = [
  { id: 0, en: "Book flights", zh: "订机票", tint: Palette.sky, done: false },
  { id: 1, en: "Review designs", zh: "评审设计稿", tint: Palette.violet, done: false },
  { id: 2, en: "Water the plants", zh: "给植物浇水", tint: Palette.mint, done: false },
  { id: 3, en: "Call the bank", zh: "给银行打电话", tint: Palette.coral, done: false },
];

const BACK = spring(0.35, 0.75);

export default function SwipeComplete({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [items, setItems] = useState(SEED);
  const itemsRef = useRef(items);
  itemsRef.current = items;
  const [layoutT, setLayoutT] = useState<Transition>(spring(0.5, 0.82));
  const [doneT, setDoneT] = useState<Transition>(BACK);
  // Per-row offset: the state value (drives `armed`, like Swift's offsets[id]) and the drawn value.
  const [targets, setTargets] = useState<Record<number, number>>({});
  const targetsRef = useRef<Record<number, number>>({});
  const mv0 = useMotionValue(0);
  const mv1 = useMotionValue(0);
  const mv2 = useMotionValue(0);
  const mv3 = useMotionValue(0);
  const mvs = [mv0, mv1, mv2, mv3];
  const [scripted, setScripted] = useState(false);
  const script = useRef<{ timer: number; row: number } | null>(null);
  const sinks = useRef<Record<number, number>>({});

  useEffect(
    () => () => {
      if (script.current) window.clearTimeout(script.current.timer);
      Object.values(sinks.current).forEach((t) => window.clearTimeout(t));
    },
    [],
  );

  const setOffset = (id: number, value: number, t?: Transition) => {
    targetsRef.current = { ...targetsRef.current, [id]: value };
    setTargets(targetsRef.current);
    if (t) animate(mvs[id], value, t);
    else {
      mvs[id].stop();
      mvs[id].set(value);
    }
  };

  const resort = (id: number) => {
    setItems((list) => {
      const index = list.findIndex((x) => x.id === id);
      if (index < 0) return list;
      const next = list.slice();
      const [item] = next.splice(index, 1);
      if (item.done) next.push(item);
      else next.unshift(item);
      return next;
    });
  };

  const finish = (id: number, haptic = true) => {
    const armed = (targetsRef.current[id] ?? 0) >= ctx.n("threshold");
    setDoneT(BACK);
    setOffset(id, 0, BACK);
    if (armed) setItems((list) => list.map((x) => (x.id === id ? { ...x, done: !x.done } : x)));
    if (!armed) return;
    if (haptic) haptics.success();
    const delay = ctx.n("sinkDelay");
    if (sinks.current[id]) window.clearTimeout(sinks.current[id]);
    sinks.current[id] = window.setTimeout(() => {
      delete sinks.current[id];
      setLayoutT(spring(0.5, 0.82));
      resort(id);
    }, delay * 1000);
  };

  const stopScript = () => {
    if (script.current) window.clearTimeout(script.current.timer);
    script.current = null;
  };

  const takeOver = (id: number) => {
    if (!script.current) return;
    const row = script.current.row;
    stopScript();
    if (row !== id) setOffset(row, 0, BACK);
  };

  const autoStep = () => {
    const next = itemsRef.current.find((x) => !x.done);
    if (!next) {
      setLayoutT(spring(0.5, 0.85));
      setDoneT(spring(0.5, 0.85));
      setItems(SEED);
      return;
    }
    setScripted(true);
    setOffset(next.id, ctx.n("threshold") + 18, anim.easeOut(0.45));
    stopScript();
    script.current = {
      row: next.id,
      timer: window.setTimeout(() => {
        script.current = null;
        finish(next.id, false);
      }, 500),
    };
  };
  useAutoplay(ctx.isPreview, autoStep, { every: 1.8 });

  const threshold = ctx.n("threshold");

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ width: 300, display: "flex", flexDirection: "column", gap: 10 }}>
        {items.map((item) => (
          <motion.div key={item.id} layout="position" transition={layoutT}>
            <CompleteRow
              item={item}
              offset={mvs[item.id]}
              target={targets[item.id] ?? 0}
              threshold={threshold}
              ctx={ctx}
              scripted={scripted}
              doneT={doneT}
              onDrag={(v) => {
                takeOver(item.id);
                setScripted(false);
                setOffset(item.id, v);
              }}
              onEnd={() => finish(item.id)}
              haptics={haptics}
            />
          </motion.div>
        ))}
        <DemoHint ctx={ctx} en="Swipe a task to the right" zh="把任务向右滑" style={{ paddingTop: 6 }} />
      </div>
    </div>
  );
}

function CompleteRow({
  item,
  offset,
  target,
  threshold,
  ctx,
  scripted,
  doneT,
  onDrag,
  onEnd,
  haptics,
}: {
  item: Task;
  offset: MotionValue<number>;
  target: number;
  threshold: number;
  ctx: DemoContext;
  scripted: boolean;
  doneT: Transition;
  onDrag: (v: number) => void;
  onEnd: () => void;
  haptics: ReturnType<typeof useHaptics>;
}) {
  const armed = target >= threshold;
  const progress = useTransform(offset, (o) => clamp(o / Math.max(threshold, 1)));
  const color = item.done ? Palette.amber : Palette.green;
  const wellBg = useTransform(progress, (p) => alpha(color, 0.15 + 0.85 * p));
  const iconScale = useTransform(progress, (p) => 0.6 + 0.4 * p);
  const tracking = useRef(false);
  const lastArmed = useRef(armed);
  useEffect(() => {
    if (armed !== lastArmed.current) {
      lastArmed.current = armed;
      if (armed && !scripted) haptics.tap("medium");
    }
  }, [armed, scripted, haptics]);

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (!tracking.current) {
          if (!(Math.abs(translation.x) > Math.abs(translation.y))) return;
          tracking.current = true;
        }
        const raw = translation.x;
        if (raw < 0) onDrag(rubberBand(raw, 24));
        else if (raw > threshold) onDrag(threshold + rubberBand(raw - threshold, 70));
        else onDrag(raw);
      },
      onEnd: () => {
        if (!tracking.current) return;
        tracking.current = false;
        onEnd();
      },
    },
    12,
  );

  return (
    <div style={{ position: "relative", height: 58 }}>
      <motion.div style={{ position: "absolute", inset: 0, borderRadius: 18, background: wellBg, display: "flex", alignItems: "center", paddingLeft: 18, color: "#fff" }}>
        <motion.div style={{ scale: iconScale, display: "grid" }}>
          <SymbolBounce trigger={armed}>
            {item.done ? (
              <CircleFillCutout size={24} glyph={glyphs.uturnBack} strokeWidth={2.2} />
            ) : armed ? (
              <CircleFillCutout size={24} glyph={glyphs.check} strokeWidth={2.4} />
            ) : (
              <CircleOutlineGlyph size={24} glyph={glyphs.check} strokeWidth={2.2} />
            )}
          </SymbolBounce>
        </motion.div>
      </motion.div>
      <motion.div
        {...pan}
        style={{
          position: "absolute",
          inset: 0,
          x: offset,
          display: "flex",
          alignItems: "center",
          gap: 12,
          padding: "0 16px",
          borderRadius: 18,
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 4px 8px ${black(0.06)}`,
          touchAction: "none",
          cursor: "grab",
        }}
      >
        <div style={{ position: "relative", width: 22, height: 22, flexShrink: 0 }}>
          <motion.div
            initial={false}
            animate={{ opacity: item.done ? 0 : 1 }}
            transition={doneT}
            style={{ position: "absolute", inset: 0, borderRadius: "50%", border: `2px solid ${Palette.labelAlpha(0.25)}` }}
          />
          <motion.div
            initial={false}
            animate={{ opacity: item.done ? 1 : 0 }}
            transition={doneT}
            style={{ position: "absolute", inset: 0, borderRadius: "50%", border: `2px solid ${Palette.green}` }}
          />
          <motion.div
            initial={false}
            animate={{ scale: item.done ? 1 : 0.01, opacity: item.done ? 1 : 0 }}
            transition={doneT}
            style={{ position: "absolute", inset: 4, borderRadius: "50%", background: Palette.green }}
          />
        </div>
        <div style={{ position: "relative", ...textStyle.subheadline, fontWeight: 600, whiteSpace: "nowrap" }}>
          <motion.span initial={false} animate={{ opacity: item.done ? 0.4 : 1 }} transition={doneT} style={{ color: Palette.label }}>
            {ctx.t(item.en, item.zh)}
          </motion.span>
          <motion.div
            initial={false}
            animate={{ scaleX: item.done ? 1 : 0.001 }}
            transition={anim.easeInOut(0.3)}
            style={{ position: "absolute", left: 0, right: 0, top: "50%", marginTop: -0.75, height: 1.5, borderRadius: 1, background: Palette.labelAlpha(0.55), transformOrigin: "0 50%" }}
          />
        </div>
        <div style={{ flex: 1, minWidth: 4 }} />
        <div style={{ width: 8, height: 8, borderRadius: "50%", background: item.tint, flexShrink: 0 }} />
      </motion.div>
    </div>
  );
}
