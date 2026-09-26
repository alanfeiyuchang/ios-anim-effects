/** cards.rewind-swipe · 可撤回滑卡 (Cards+RewindSwipe.swift) */
import { animate, motion, useMotionValue, type Transition } from "motion/react";
import { Undo2 } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, clamp, delayed, spring, useAutoplay, useHaptics, usePan, type DemoProps } from "../../kit";
import { DeckFace, Stage, predictEnd, useMV } from "./shared";

const IDS = [1, 2, 3, 4, 5];
const PATTERN = [1, -1, 0, 1, -1, 1, -1, 1];

export default function RewindSwipe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [exits, setExits] = useState<Record<number, number>>({});
  const [history, setHistory] = useState<number[]>([]);
  const [rewinds, setRewinds] = useState(0);
  const [transitions, setTransitions] = useState<Record<number, Transition>>({});
  const dx = useMotionValue(0);
  const dy = useMotionValue(0);
  const held = useRef(false);
  /** The card the drag offset is applied to: the top card, and after a fling the flung card until its offset has sprung home. */
  const [owner, setOwner] = useState(IDS[0]);
  const step = useRef(0);
  const state = useRef({ exits, history });
  state.current = { exits, history };
  const timer = useRef(0);
  useEffect(() => () => window.clearTimeout(timer.current), []);

  const deckOf = (e: Record<number, number>) => IDS.filter((id) => (e[id] ?? 0) === 0);
  const deck = deckOf(exits);
  const rewindSpring = () => spring(ctx.n("rewindResponse"), ctx.n("rewindDamping"));
  const allWith = (t: Transition) => Object.fromEntries(IDS.map((id) => [id, t]));

  const restoreAll = () => {
    const h = state.current.history;
    const next: Record<number, Transition> = allWith(rewindSpring());
    [...h].reverse().forEach((id, i) => (next[id] = delayed(rewindSpring(), i * 0.07)));
    setTransitions(next);
    setExits({});
    setRewinds((r) => r + 1);
    setHistory([]);
  };

  const fling = (direction: number) => {
    const { exits: e, history: h } = state.current;
    const top = deckOf(e)[0];
    if (top === undefined) return;
    haptics.tap("medium");
    const t = spring(0.4, 0.85);
    setTransitions(allWith(t));
    const nextExits = { ...e, [top]: direction };
    state.current = { exits: nextExits, history: [...h, top] };
    setExits(nextExits);
    setHistory([...h, top]);
    animate(dx, 0, t);
    animate(dy, 0, t);
    if (deckOf(nextExits).length === 0) {
      timer.current = window.setTimeout(() => {
        if (deckOf(state.current.exits).length === 0) restoreAll();
      }, 600);
    }
  };

  const rewind = () => {
    const { exits: e, history: h } = state.current;
    const last = h[h.length - 1];
    if (last === undefined) return;
    haptics.tap("soft");
    setRewinds((r) => r + 1);
    setTransitions(allWith(rewindSpring()));
    const nextExits = { ...e, [last]: 0 };
    state.current = { exits: nextExits, history: h.slice(0, -1) };
    setExits(nextExits);
    setHistory(h.slice(0, -1));
  };

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (!held.current) setOwner(deckOf(state.current.exits)[0]);
        held.current = true;
        dx.jump(translation.x);
        dy.jump(translation.y);
      },
      onEnd: ({ translation, velocity }) => {
        if (!held.current) return;
        held.current = false;
        const predicted = predictEnd(translation.x, velocity.x);
        if (Math.abs(translation.x) > 100 || Math.abs(predicted) > 200) fling(predicted >= 0 ? 1 : -1);
        else {
          const t = spring(0.45, 0.65);
          animate(dx, 0, t);
          animate(dy, 0, t);
        }
      },
    },
    10,
  );

  useAutoplay(
    ctx.isPreview,
    () => {
      const move = PATTERN[step.current % PATTERN.length];
      step.current += 1;
      if (held.current || deckOf(state.current.exits).length === 0) return;
      if (move === 0) rewind();
      else fling(move);
    },
    { every: 1.1 },
  );

  const drag = { x: useMV(dx), y: useMV(dy) };
  const spin = ctx.n("spin");

  return (
    <Stage gap={18}>
      <div style={{ position: "relative", width: 190, height: 262, flexShrink: 0 }}>
        {IDS.map((id, order) => {
          const exit = exits[id] ?? 0;
          const depth = Math.max(deck.indexOf(id), 0);
          const isTop = exit === 0 && depth === 0;
          const isOwner = id === owner;
          const tilt = isOwner ? clamp((drag.x / 110) * 12, -12, 12) : 0;
          return (
            <motion.div
              key={id}
              initial={false}
              animate={{
                x: exit !== 0 ? exit * 440 : 0,
                y: exit !== 0 ? 40 : isTop ? 0 : depth * 14,
                rotate: exit * spin,
                opacity: exit === 0 && depth > 2 ? 0 : 1,
              }}
              transition={transitions[id] ?? spring(0.4, 0.85)}
              style={{ position: "absolute", left: 0, top: 11, zIndex: IDS.length - order, transformOrigin: "50% 100%", pointerEvents: isTop ? "auto" : "none" }}
            >
              <div
                {...(isTop ? pan : {})}
                style={{
                  transformOrigin: "50% 100%",
                  transform: isOwner ? `translate(${drag.x}px, ${drag.y * 0.4}px) rotate(${tilt}deg)` : undefined,
                  touchAction: "none",
                  cursor: isTop ? "grab" : undefined,
                }}
              >
                <motion.div
                  initial={false}
                  animate={{ scale: exit !== 0 || isTop ? 1 : 1 - depth * 0.05 }}
                  transition={transitions[id] ?? spring(0.4, 0.85)}
                  style={{ borderRadius: 24, boxShadow: `0 8px 14px ${black(0.15)}` }}
                >
                  <DeckFace index={id} ctx={ctx} />
                </motion.div>
              </div>
            </motion.div>
          );
        })}
      </div>
      <button
        type="button"
        onClick={rewind}
        disabled={history.length === 0}
        style={{
          width: 48,
          height: 48,
          borderRadius: "50%",
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 4px 8px ${black(0.1)}`,
          display: "grid",
          placeItems: "center",
          color: history.length === 0 ? Palette.secondaryLabel : Palette.amber,
          cursor: history.length === 0 ? "default" : "pointer",
        }}
      >
        <motion.span initial={false} animate={{ rotate: rewinds * -360 }} transition={spring(0.6, 0.75)} style={{ display: "grid" }}>
          <Undo2 size={20} strokeWidth={3} />
        </motion.span>
      </button>
      <DemoHint ctx={ctx} en="Swipe a card, then tap rewind" zh="滑走卡片，再点撤回" />
    </Stage>
  );
}
