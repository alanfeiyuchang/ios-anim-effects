/** buttons.hold-segments · 分段长按 (Buttons+HoldSegments.swift) */
import { motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { SNAPPY, SymbolReplace, cubicKF, moveKF, springKF, track, useLongPress, useSince } from "./_a-kit";

function LockGlyph({ open, size }: { open: boolean; size: number }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} fill="none">
      <rect x="4.5" y="10.5" width="15" height="11" rx="2.6" fill="currentColor" />
      <path d={open ? "M8 10.5V7a4 4 0 0 1 7.9-.9" : "M8 10.5V7.2a4 4 0 0 1 8 0v3.3"} stroke="currentColor" strokeWidth={2.4} strokeLinecap="round" />
    </svg>
  );
}

export default function HoldSegments({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const total = Math.min(Math.max(ctx.i("segments"), 3), 8);
  const [lit, setLit] = useState(0);
  const litRef = useRef(0);
  const [unlocked, setUnlocked] = useState(false);
  const unlockedRef = useRef(false);
  const [pressing, setPressing] = useState(false);
  const pressingRef = useRef(false);
  const [pops, setPops] = useState<number[]>(Array(8).fill(0));
  const worker = useRef(0);
  const timer = useRef(0);
  const duration = ctx.n("duration");

  const cancelWorker = () => {
    worker.current += 1;
    window.clearTimeout(timer.current);
  };
  useEffect(() => () => window.clearTimeout(timer.current), []);

  const setLitN = (n: number) => {
    litRef.current = n;
    setLit(n);
  };
  const pop = (index: number) => setPops((p) => p.map((v, i) => (i === index ? v + 1 : v)));

  const unlock = (muted: boolean) => {
    if (unlockedRef.current) return;
    pressingRef.current = false;
    setPressing(false);
    unlockedRef.current = true;
    setUnlocked(true);
    if (!muted) haptics.success();
    cancelWorker();
    const run = worker.current;
    timer.current = window.setTimeout(() => {
      if (run !== worker.current) return;
      unlockedRef.current = false;
      setUnlocked(false);
      setLitN(0);
    }, 1400);
  };

  const begin = (muted = false) => {
    if (unlockedRef.current) return;
    pressingRef.current = true;
    setPressing(true);
    cancelWorker();
    const run = worker.current;
    const step = duration / total;
    const tick = () => {
      if (run !== worker.current) return;
      if (litRef.current >= total) {
        unlock(muted);
        return;
      }
      timer.current = window.setTimeout(() => {
        if (run !== worker.current || litRef.current >= 8) return;
        pop(litRef.current);
        setLitN(litRef.current + 1);
        if (!muted) haptics.selection();
        tick();
      }, step * 1000);
    };
    tick();
  };

  const release = () => {
    pressingRef.current = false;
    setPressing(false);
    if (unlockedRef.current) return;
    cancelWorker();
    const run = worker.current;
    const step = ctx.n("drain");
    const tick = () => {
      if (run !== worker.current || litRef.current <= 0) return;
      timer.current = window.setTimeout(() => {
        if (run !== worker.current) return;
        setLitN(litRef.current - 1);
        haptics.tap("soft");
        tick();
      }, step * 1000);
    };
    tick();
  };

  const finishHold = () => {
    if (unlockedRef.current) return;
    cancelWorker();
    while (litRef.current < total && litRef.current < 8) {
      pop(litRef.current);
      litRef.current += 1;
    }
    setLit(litRef.current);
    unlock(false);
  };

  const longPress = useLongPress({
    duration,
    maximumDistance: 40,
    onComplete: finishHold,
    onPressingChanged: (isPressing) => (isPressing ? begin() : release()),
  });

  useAutoplay(ctx.isPreview, () => {
    if (unlockedRef.current || pressingRef.current) return;
    begin(true);
  }, { every: duration + 2.4, delay: 0.4 });

  const tint = unlocked ? Palette.mint : Palette.amber;
  const baseFill = ctx.scheme === "dark" ? "#2C2C32" : "#1C1C22";
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <motion.div
          {...longPress}
          initial={false}
          animate={{
            scale: pressing && !unlocked ? 0.97 : 1,
            boxShadow: `0px 8px 16px ${alpha(tint, pressing || unlocked ? 0.35 : 0.1)}`,
          }}
          transition={spring(0.3, 0.7)}
          style={{ ...longPress.style, position: "relative", width: 260, height: 64, borderRadius: 32 }}
        >
          <motion.div
            initial={false}
            animate={{ backgroundColor: unlocked ? "rgba(33, 212, 168, 0.9)" : baseFill }}
            transition={anim.smoothD(0.3)}
            style={{ position: "absolute", inset: 0, borderRadius: 32 }}
          />
          <div style={{ position: "absolute", inset: 0, borderRadius: 32, boxShadow: `inset 0 0 0 1px ${alpha(tint, 0.35)}`, transition: "box-shadow 0.3s" }} />
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 10, fontSize: 17, fontWeight: 600 }}>
            <span style={{ color: tint, display: "grid", transition: "color 0.3s" }}>
              <SymbolReplace id={unlocked ? "open" : "closed"}>
                <LockGlyph open={unlocked} size={20} />
              </SymbolReplace>
            </span>
            <span style={{ display: "grid" }}>
              {[false, true].map((u) => (
                <motion.span
                  key={String(u)}
                  initial={false}
                  animate={{ opacity: unlocked === u ? 1 : 0 }}
                  transition={anim.smoothD(0.3)}
                  style={{ gridArea: "1 / 1", color: u ? "#000" : "#fff", whiteSpace: "nowrap" }}
                >
                  {u ? (zh ? "已解锁" : "Unlocked") : zh ? "长按解锁" : "Hold to unlock"}
                </motion.span>
              ))}
            </span>
          </div>
        </motion.div>
        <div style={{ display: "flex", gap: 8 }}>
          {Array.from({ length: total }, (_, i) => (
            <Segment key={i} on={i < lit} color={tint} pop={pops[i]} />
          ))}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Hold the button; let go to drain" zh="按住按钮；松手会回退" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Segment({ on, color, pop }: { on: boolean; color: string; pop: number }) {
  const sx = track(useSince(pop, 0.4), 1, [moveKF(0.6), cubicKF(1.15, 0.1), springKF(1, 0.3, SNAPPY)]);
  return (
    <motion.div
      initial={false}
      animate={{ backgroundColor: on ? color : "rgba(128,128,128,0)", boxShadow: `0px 0px 5px ${alpha(color, on ? 0.7 : 0)}` }}
      transition={anim.snappyD(0.2)}
      style={{ position: "relative", width: 40, height: 8, borderRadius: 4, transform: `scaleX(${sx})`, overflow: "hidden" }}
    >
      <div style={{ position: "absolute", inset: 0, background: Palette.labelAlpha(0.12), opacity: on ? 0 : 1, transition: "opacity 0.2s" }} />
    </motion.div>
  );
}
