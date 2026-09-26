/** morph.sort-hop · 排序跳跃 (Morph+SortHop.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, anim, black, ease, springAt, spring, useAutoplay, useElapsed, useHaptics, type DemoProps } from "../../kit";
import { diag, sheen } from "./_shared";

const values = [62, 24, 88, 45, 71, 33];
const SPACING = 42;

export default function SortHop({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [order, setOrder] = useState([0, 1, 2, 3, 4, 5]);
  const [travel, setTravel] = useState([0, 0, 0, 0, 0, 0]);
  const [moves, setMoves] = useState(0);
  const [sorted, setSorted] = useState(false);

  const shuffleOrSort = () => {
    let next: number[];
    if (sorted) {
      next = [...order].sort(() => Math.random() - 0.5);
      if (next.every((v, i) => v === order[i])) next = [...order].reverse();
    } else next = [...order].sort((a, b) => values[a] - values[b]);
    const newTravel = values.map((_, bar) => next.indexOf(bar) - order.indexOf(bar));
    haptics.tap("medium");
    setTravel(newTravel);
    setMoves((m) => m + 1);
    setSorted((s) => !s);
    setOrder(next);
  };
  useAutoplay(ctx.isPreview, shuffleOrSort, { every: 1.6 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 26 }}>
      <div style={{ position: "relative", width: 280, height: 190, flexShrink: 0 }}>
        <div style={{ position: "absolute", left: 5, bottom: 0, width: 270, height: 2, borderRadius: 1, background: Palette.labelAlpha(0.1) }} />
        {values.map((value, bar) => (
          <Bar
            key={bar}
            bar={bar}
            value={value}
            x={(order.indexOf(bar) - 2.5) * SPACING}
            delta={travel[bar]}
            moves={moves}
            perSlot={ctx.n("lift")}
            split={ctx.b("split")}
            response={ctx.n("response")}
          />
        ))}
      </div>
      <button
        type="button"
        onClick={shuffleOrSort}
        style={{ position: "relative", width: 140, height: 46, borderRadius: 23, overflow: "hidden", background: diag(Palette.indigo, Palette.violet), color: "#fff", flexShrink: 0 }}
      >
        <AnimatePresence initial={false}>
          <motion.span
            key={String(sorted)}
            initial={{ y: 46 }}
            animate={{ y: 0 }}
            exit={{ y: -46 }}
            transition={anim.snappy}
            style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", fontSize: 17, fontWeight: 600 }}
          >
            {sorted ? ctx.t("Shuffle", "打乱") : ctx.t("Sort", "排序")}
          </motion.span>
        </AnimatePresence>
      </button>
      <DemoHint ctx={ctx} en="Tap the button" zh="点击按钮" />
    </div>
  );
}

function Bar({
  bar,
  value,
  x,
  delta,
  moves,
  perSlot,
  split,
  response,
}: {
  bar: number;
  value: number;
  x: number;
  delta: number;
  moves: number;
  perSlot: number;
  split: boolean;
  response: number;
}) {
  const t = useElapsed(moves, 0.64, true);
  const direction = split && delta < 0 ? 1 : -1;
  const arc = delta === 0 ? -4 : direction * perSlot * Math.abs(delta);
  const peak = delta === 0 ? 1 : 1.08;
  // KeyframeTrack: CubicKeyframe(arc, 0.22) then SpringKeyframe(0, 0.42, .bouncy).
  let y = 0;
  let scale = 1;
  if (t >= 0) {
    if (t < 0.22) {
      const k = ease.inOut(t / 0.22);
      y = arc * k;
      scale = 1 + (peak - 1) * k;
    } else {
      const k = t >= 0.64 ? 1 : springAt(t - 0.22, 0.5, 0.7);
      y = arc * (1 - k);
      scale = peak + (1 - peak) * k;
    }
  }
  const lift = Math.max(scale - 1, 0);
  const color = Palette.spectrum[bar % Palette.spectrum.length];
  return (
    <motion.div
      initial={false}
      animate={{ x }}
      transition={spring(response, 0.78)}
      style={{ position: "absolute", left: 140 - 16, bottom: 0, width: 32 }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 6,
          transformOrigin: "50% 100%",
          transform: `translateY(${y}px) scale(${scale})`,
        }}
      >
        <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 700, fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>{value}</span>
        <div style={{ width: 32, height: value * 1.6, borderRadius: 10, background: sheen(color), boxShadow: `0 3px ${4 + lift * 100}px ${black(0.1 + lift * 2.5)}` }} />
      </div>
    </motion.div>
  );
}
