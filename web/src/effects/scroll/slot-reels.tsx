/** scroll.slot-reels · 老虎机滚轮 (Scroll+SlotReels.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { Palette, alpha, black, clamp, spring, springDB, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { SnapMarkers, Sym, perspectivePx, strideSnap, useScroller, wrap, type Scroller } from "./_kit";

const SYMBOLS = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "moon.fill", "flame.fill", "crown.fill", "diamond.fill"];
const COLORS = [Palette.amber, Palette.pink, Palette.sky, Palette.mint, Palette.violet, Palette.coral, Palette.amber, Palette.blue];
const CELLS = 96;
const CELL = 64;
const VIEWPORT = CELL * 3;
const START = [10, 13, 18];

const isLine = (cells: number[]) => {
  const s = cells.map((c) => wrap(c, SYMBOLS.length));
  return s.every((x) => x === s[0]);
};

export default function SlotReels({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [spinning, setSpinning] = useState(false);
  const [win, setWin] = useState(false);
  const spinningRef = useRef(false);
  const winRef = useRef(false);
  winRef.current = win;
  const spins = useRef(0);
  const targets = useRef([...START]);
  // The cell each reel actually rests on, including hand flicks (spins start from here).
  const resting = useRef([...START]);

  const handSettled = () => {
    if (spinningRef.current) return;
    const lined = isLine(resting.current);
    if (lined && !winRef.current && !ctx.isPreview) haptics.success();
    setWin(lined);
  };
  const reel = (k: number) =>
    // eslint-disable-next-line react-hooks/rules-of-hooks
    useScroller({
      axis: "y",
      initial: START[k] * CELL,
      snap: strideSnap(CELL),
      disabled: spinning,
      onScroll: (o) => (resting.current[k] = Math.round(o / CELL)),
      onPhase: (p, prev) => {
        // Only a finger ends in .interacting or .decelerating; programmatic spins end from .animating.
        if (p === "idle" && (prev === "interacting" || prev === "decelerating")) handSettled();
      },
    });
  const reels = [reel(0), reel(1), reel(2)];

  const spin = (muted = false) => {
    if (spinningRef.current) return;
    spinningRef.current = true;
    setSpinning(true);
    setWin(false);
    spins.current += 1;
    haptics.tap("medium");
    const quiet = muted || ctx.isPreview;
    const count = SYMBOLS.length;
    // Recenter each reel by whole symbol cycles so it never reaches the end.
    const starts = resting.current.map((c) => clamp(c, 0, CELLS - 1));
    for (let k = 0; k < 3; k++) if (starts[k] > count * 5) starts[k] -= count * Math.floor((starts[k] - count * 2) / count);
    starts.forEach((s, k) => reels[k].scrollTo(s * CELL, null));
    // Every third spin lines up for the demo's payoff.
    const jackpot = spins.current % 3 === 0;
    const jackpotSymbol = Math.floor(Math.random() * count);
    const next = starts.map((s, k) => {
      let target = s + 16 + Math.floor(Math.random() * 9) + k * 3;
      if (jackpot) target += (jackpotSymbol - wrap(target, count) + count) % count;
      return Math.min(target, CELLS - 1);
    });
    targets.current = next;
    requestAnimationFrame(() => {
      for (let k = 0; k < 3; k++) {
        const duration = ctx.n("duration") + k * 0.45;
        reels[k].scrollTo(next[k] * CELL, springDB(duration, ctx.n("bounce")));
        after(duration * 0.8, () => {
          if (!quiet) haptics.tap("rigid");
          if (k === 2) {
            spinningRef.current = false;
            setSpinning(false);
            if (isLine(targets.current)) {
              setWin(true);
              if (!quiet) haptics.success();
            }
          }
        });
      }
    });
  };

  useAutoplay(ctx.isPreview, () => spin(true), { every: 2.8 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div
        style={{
          position: "relative",
          display: "flex",
          gap: 8,
          padding: 10,
          borderRadius: 24,
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 16px ${black(0.12)}`,
          flexShrink: 0,
        }}
      >
        {reels.map((sc, k) => (
          <Reel key={k} sc={sc} />
        ))}
        <motion.div
          animate={{
            boxShadow: win
              ? `inset 0 0 0 3px ${Palette.amber}, 0 0 12px ${alpha(Palette.amber, 0.8)}`
              : `inset 0 0 0 1.5px ${alpha(Palette.amber, 0.55)}, 0 0 12px ${alpha(Palette.amber, 0)}`,
          }}
          transition={spring(0.35, 0.5)}
          style={{ position: "absolute", left: 4, right: 4, top: "50%", height: CELL + 4, marginTop: -(CELL + 4) / 2, borderRadius: 12, pointerEvents: "none" }}
        />
      </div>
      <button
        type="button"
        onClick={() => spin()}
        disabled={spinning}
        style={{
          width: 150,
          height: 46,
          borderRadius: 23,
          background: Palette.sunset,
          color: "#fff",
          fontSize: 17,
          fontWeight: 600,
          boxShadow: `0 5px 10px ${alpha(Palette.coral, 0.4)}`,
          opacity: spinning ? 0.6 : 1,
          flexShrink: 0,
        }}
      >
        {ctx.t("Spin", "旋转")}
      </button>
    </div>
  );
}

function Reel({ sc }: { sc: Scroller }) {
  const mask = `linear-gradient(transparent, ${black(1)} 28%, ${black(1)} 72%, transparent)`;
  const first = Math.max(0, Math.floor(sc.offset / CELL) - 2);
  const last = Math.min(CELLS - 1, Math.ceil(sc.offset / CELL) + 3);
  return (
    <div
      style={{
        position: "relative",
        width: 84,
        height: VIEWPORT,
        borderRadius: 14,
        background: Palette.labelAlpha(0.04),
        WebkitMaskImage: mask,
        maskImage: mask,
        flexShrink: 0,
      }}
    >
      <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
        <div ref={sc.contentRef} style={{ position: "relative", height: CELLS * CELL + CELL * 2 }}>
          <SnapMarkers count={CELLS} pitch={CELL} axis="y" />
          {Array.from({ length: last - first + 1 }, (_, n) => {
            const i = first + n;
            const symbol = i % SYMBOLS.length;
            const t = clamp((i * CELL - sc.offset) / (VIEWPORT / 2), -1, 1);
            return (
              <div
                key={i}
                style={{
                  position: "absolute",
                  left: 0,
                  right: 0,
                  top: CELL + i * CELL,
                  height: CELL,
                  display: "grid",
                  placeItems: "center",
                  color: COLORS[symbol],
                  transform: `perspective(${perspectivePx(84, CELL, 0.5)}px) rotateX(${-t * 50}deg)`,
                  opacity: 1 - Math.abs(t) * 0.55,
                }}
              >
                <Sym name={SYMBOLS[symbol]} size={30} weight={700} />
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
