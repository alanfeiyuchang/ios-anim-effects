/** gestures.staged-swipe · 分段滑动操作 (Gestures+StagedSwipe.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useTransform, type MotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, SymbolBounce, anim, black, fonts, rubberBand, spring, textStyle, useAutoplay, useHaptics, usePan, type DemoContext, type DemoProps } from "../../kit";
import { ArchiveBoxFill, ClockFill, TrashFill } from "./_b-icons";

type Stage = 0 | 1 | 2 | 3; // none, archive, snooze, delete

const STAGE_COLOR = ["rgb(142 142 147 / 0.35)", Palette.indigo, Palette.amber, Palette.red];
const STAGE_LABEL: [string, string][] = [
  ["Archive", "归档"],
  ["Archive", "归档"],
  ["Snooze", "稍后"],
  ["Delete", "删除"],
];
const STAGE_DONE: [string, string][] = [
  ["Archived", "已归档"],
  ["Archived", "已归档"],
  ["Snoozed until 6 PM", "已推迟到 18:00"],
  ["Deleted", "已删除"],
];

function StageSymbol({ stage, size }: { stage: Stage; size: number }) {
  if (stage === 2) return <ClockFill size={size} />;
  if (stage === 3) return <TrashFill size={size} />;
  return <ArchiveBoxFill size={size} />;
}
const symbolKey = (s: Stage) => (s === 2 ? "clock" : s === 3 ? "trash" : "archive");

interface Mail {
  id: number;
  sender: [string, string];
  preview: [string, string];
  tint: string;
}

const SEED: Mail[] = [
  { id: 0, sender: ["Ava Chen", "陈安娜"], preview: ["Slides for Thursday", "周四的演示文稿"], tint: Palette.pink },
  { id: 1, sender: ["Studio", "工作室"], preview: ["Your order has shipped", "你的订单已发货"], tint: Palette.mint },
  { id: 2, sender: ["Leo Park", "朴乐"], preview: ["Dinner on Friday?", "周五一起吃饭吗？"], tint: Palette.sky },
];

function stageFor(offset: number, first: number, step: number): Stage {
  const distance = -offset;
  if (distance < first) return 0;
  const steps = Math.floor((distance - first) / Math.max(step, 1));
  return Math.min(steps + 1, 3) as Stage;
}

export default function StagedSwipe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [items, setItems] = useState(SEED);
  const itemsRef = useRef(items);
  itemsRef.current = items;
  const [targets, setTargets] = useState<Record<number, number>>({});
  const targetsRef = useRef<Record<number, number>>({});
  const [committed, setCommitted] = useState<Record<number, Stage>>({});
  const committedRef = useRef<Record<number, Stage>>({});
  const [chip, setChip] = useState<Stage | null>(null);
  const [scripted, setScripted] = useState(false);
  const [layoutT, setLayoutT] = useState(spring(0.4, 0.85));
  const autoIndex = useRef(0);
  const script = useRef<{ timer: number; row: number } | null>(null);
  const releases = useRef<Record<number, number[]>>({});
  const mv0 = useMotionValue(0);
  const mv1 = useMotionValue(0);
  const mv2 = useMotionValue(0);
  const mvs = [mv0, mv1, mv2];
  const first = ctx.n("first");
  const step = ctx.n("step");

  useEffect(
    () => () => {
      if (script.current) window.clearTimeout(script.current.timer);
      Object.values(releases.current).flat().forEach((t) => window.clearTimeout(t));
    },
    [],
  );

  const setOffset = (id: number, value: number, t?: Parameters<typeof animate>[2]) => {
    targetsRef.current = { ...targetsRef.current, [id]: value };
    setTargets(targetsRef.current);
    if (t) animate(mvs[id], value, t as never);
    else {
      mvs[id].stop();
      mvs[id].set(value);
    }
  };
  const setCommit = (id: number, s: Stage | null) => {
    const next = { ...committedRef.current };
    if (s === null) delete next[id];
    else next[id] = s;
    committedRef.current = next;
    setCommitted(next);
  };

  const release = (id: number, haptic = true) => {
    const current = stageFor(targetsRef.current[id] ?? 0, ctx.n("first"), ctx.n("step"));
    if (current === 0) {
      setOffset(id, 0, spring(0.4, 0.8));
      return;
    }
    setCommit(id, current);
    setOffset(id, -420, anim.easeIn(0.25));
    if (haptic) haptics.tap(current === 3 ? "rigid" : "medium");
    (releases.current[id] ?? []).forEach((t) => window.clearTimeout(t));
    releases.current[id] = [
      window.setTimeout(() => {
        setLayoutT(spring(0.4, 0.85));
        setItems((list) => list.filter((x) => x.id !== id));
        setCommit(id, null);
        targetsRef.current = { ...targetsRef.current, [id]: 0 };
        setTargets(targetsRef.current);
        setChip(current);
      }, 250),
      window.setTimeout(() => {
        delete releases.current[id];
        setLayoutT(spring(0.45, 0.8));
        setChip(null);
        mvs[id].stop();
        mvs[id].set(0);
        setItems((list) => {
          const original = SEED.find((x) => x.id === id)!;
          if (list.some((x) => x.id === id)) return list;
          const position = Math.min(SEED.indexOf(original), list.length);
          const next = list.slice();
          next.splice(position, 0, original);
          return next;
        });
      }, 1550),
    ];
  };

  const stopScript = () => {
    if (script.current) window.clearTimeout(script.current.timer);
    script.current = null;
  };

  const takeOver = (id: number) => {
    if (!script.current) return;
    const row = script.current.row;
    stopScript();
    if (row !== id && committedRef.current[row] === undefined) setOffset(row, 0, spring(0.4, 0.8));
  };

  const autoStep = () => {
    const target = itemsRef.current.find((x) => committedRef.current[x.id] === undefined);
    if (!target) return;
    const stageIndex = autoIndex.current % 3;
    autoIndex.current += 1;
    setScripted(true);
    const f = ctx.n("first");
    const s = ctx.n("step");
    const distance = f + s * stageIndex + s * 0.5;
    setOffset(target.id, -distance, anim.easeInOut(0.8));
    stopScript();
    script.current = {
      row: target.id,
      timer: window.setTimeout(() => {
        script.current = null;
        release(target.id, false);
      }, 900),
    };
  };
  useAutoplay(ctx.isPreview, autoStep, { every: 2.4, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ width: 300, display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
        <AnimatePresence mode="popLayout" initial={false}>
          {items.map((item) => (
            <motion.div
              key={item.id}
              layout="position"
              initial={{ scale: 0.92, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={layoutT}
              style={{ width: 300 }}
            >
              <StagedRow
                mail={item}
                offset={mvs[item.id]}
                target={targets[item.id] ?? 0}
                locked={committed[item.id]}
                first={first}
                step={step}
                ctx={ctx}
                scripted={scripted}
                haptics={haptics}
                onDrag={(v) => {
                  if (committedRef.current[item.id] !== undefined) return;
                  takeOver(item.id);
                  setScripted(false);
                  setOffset(item.id, v);
                }}
                onEnd={() => {
                  if (committedRef.current[item.id] === undefined) release(item.id);
                }}
              />
            </motion.div>
          ))}
          <motion.div key="chip" layout="position" transition={layoutT} style={{ height: 34, display: "grid", placeItems: "center" }}>
            <AnimatePresence>
              {chip !== null && (
                <motion.div
                  key="c"
                  initial={{ scale: 0.6, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  exit={{ scale: 0.6, opacity: 0 }}
                  transition={chip !== null ? spring(0.4, 0.85) : spring(0.45, 0.8)}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 6,
                    padding: "8px 14px",
                    borderRadius: 999,
                    background: STAGE_COLOR[chip],
                    color: "#fff",
                    ...textStyle.footnote,
                    fontWeight: 600,
                    whiteSpace: "nowrap",
                  }}
                >
                  <StageSymbol stage={chip} size={15} />
                  {ctx.t(...STAGE_DONE[chip])}
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
          <motion.div key="hint" layout="position" transition={layoutT}>
            <DemoHint ctx={ctx} en="Swipe a row left — further for more" zh="向左滑动某行，越远操作越强" />
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}

function StagedRow({
  mail,
  offset,
  target,
  locked,
  first,
  step,
  ctx,
  scripted,
  haptics,
  onDrag,
  onEnd,
}: {
  mail: Mail;
  offset: MotionValue<number>;
  target: number;
  locked: Stage | undefined;
  first: number;
  step: number;
  ctx: DemoContext;
  scripted: boolean;
  haptics: ReturnType<typeof useHaptics>;
  onDrag: (v: number) => void;
  onEnd: () => void;
}) {
  const current = locked ?? stageFor(target, first, step);
  const revealed = useTransform(offset, (o) => Math.max(-o, 0));
  const progress = useTransform(revealed, (r) => Math.min(r / Math.max(first, 1), 1));
  const labelWidth = useTransform(revealed, (r) => Math.max(r, 60));
  const labelScale = useTransform(progress, (p) => 0.7 + 0.3 * p);
  const tracking = useRef(false);
  const last = useRef(current);
  useEffect(() => {
    if (current !== last.current) {
      last.current = current;
      if (!scripted && locked === undefined) haptics.selection();
    }
  }, [current, scripted, locked, haptics]);

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (!tracking.current) {
          if (!(Math.abs(translation.x) > Math.abs(translation.y))) return;
          tracking.current = true;
        }
        const raw = translation.x;
        onDrag(raw > 0 ? rubberBand(raw, 24) : Math.max(raw, -270));
      },
      onEnd: () => {
        if (!tracking.current) return;
        tracking.current = false;
        onEnd();
      },
    },
    12,
  );

  const name = ctx.t(...mail.sender);
  return (
    <div style={{ position: "relative", height: 62 }}>
      <motion.div
        initial={false}
        animate={{ backgroundColor: STAGE_COLOR[current] }}
        transition={anim.easeInOut(0.2)}
        style={{ position: "absolute", inset: 0, borderRadius: 18 }}
      />
      <motion.div
        style={{
          position: "absolute",
          right: 0,
          top: 0,
          bottom: 0,
          width: labelWidth,
          opacity: progress,
          scale: labelScale,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 3,
          color: "#fff",
        }}
      >
        <SymbolBounce trigger={current}>
          <span style={{ position: "relative", display: "grid", width: 20, height: 20, placeItems: "center" }}>
            <AnimatePresence mode="popLayout" initial={false}>
              <motion.span
                key={symbolKey(current)}
                initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                transition={anim.snappyD(0.2)}
                style={{ display: "grid" }}
              >
                <StageSymbol stage={current} size={20} />
              </motion.span>
            </AnimatePresence>
          </span>
        </SymbolBounce>
        <span style={{ ...textStyle.caption2, fontWeight: 700, whiteSpace: "nowrap" }}>{ctx.t(...STAGE_LABEL[current])}</span>
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
          padding: "0 14px",
          borderRadius: 18,
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 4px 8px ${black(0.06)}`,
          touchAction: "none",
          cursor: "grab",
        }}
      >
        <div
          style={{
            width: 36,
            height: 36,
            flexShrink: 0,
            borderRadius: "50%",
            background: `linear-gradient(color-mix(in srgb, ${mail.tint} 88%, white), ${mail.tint})`,
            display: "grid",
            placeItems: "center",
            fontFamily: fonts.rounded,
            fontSize: 15,
            fontWeight: 700,
            color: "#fff",
          }}
        >
          {Array.from(name)[0]}
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 3, minWidth: 0, whiteSpace: "nowrap" }}>
          <span style={{ ...textStyle.subheadline, fontWeight: 600 }}>{name}</span>
          <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{ctx.t(...mail.preview)}</span>
        </div>
      </motion.div>
    </div>
  );
}
