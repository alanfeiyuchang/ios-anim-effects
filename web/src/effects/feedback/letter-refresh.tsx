/** feedback.letter-refresh · 逐字升起下拉刷新 (Feedback+RefreshVariations.swift) */
import { motion } from "motion/react";
import { useLayoutEffect, useRef, useState } from "react";
import { Palette, anim, fonts, useClock, type DemoProps } from "../../kit";
import { refreshElapsed, refreshRamp, type RefreshClock } from "./refresh-host";
import { RefreshVarHost } from "./refresh-vars";

export default function LetterRefresh({ ctx }: DemoProps) {
  const text = ctx.lang === "zh" ? "下拉即可刷新" : "PULL TO REFRESH";
  const fps = ctx.isPreview ? 30 : undefined;
  return (
    <RefreshVarHost
      ctx={ctx}
      indicator={({ progress, refreshing, clock }) => <Letters text={text} progress={progress} refreshing={refreshing} rise={ctx.n("rise")} clock={clock} fps={fps} />}
    />
  );
}

function Letters({ text, progress, refreshing, rise, clock, fps }: { text: string; progress: number; refreshing: boolean; rise: number; clock: RefreshClock; fps?: number }) {
  useClock(refreshing, fps);
  const letters = Array.from(text);
  const armed = progress >= 1 || refreshing;
  const e = refreshElapsed(clock);
  const row = useRef<HTMLDivElement>(null);
  const [geo, setGeo] = useState<{ width: number; lefts: number[] }>({ width: 0, lefts: [] });
  useLayoutEffect(() => {
    const el = row.current;
    if (!el) return;
    const lefts = Array.from(el.children).map((c) => (c as HTMLElement).offsetLeft);
    if (lefts.join() !== geo.lefts.join() || el.offsetWidth !== geo.width) setGeo({ width: el.offsetWidth, lefts });
  });
  const style = (index: number) => {
    const start = (index / Math.max(letters.length, 1)) * 0.75;
    const local = refreshing ? 1 : Math.min(Math.max((progress - start) / 0.25, 0), 1);
    const wave = refreshing ? -4 * Math.sin(e * 7 - index * 0.45) * refreshRamp(e) : 0;
    return { opacity: local, transform: `translateY(${(1 - local) * rise + wave}px) scale(${0.6 + 0.4 * local})` };
  };
  const base = { fontFamily: fonts.rounded, fontSize: 15, fontWeight: 800, letterSpacing: 3, display: "inline-block", whiteSpace: "pre" as const };
  const layer = (gradient: boolean) =>
    letters.map((ch, i) => (
      <span
        key={i}
        style={{
          ...base,
          ...style(i),
          ...(gradient
            ? {
                color: "transparent",
                backgroundImage: `linear-gradient(90deg, ${Palette.indigo}, ${Palette.pink})`,
                backgroundSize: `${geo.width}px 100%`,
                backgroundPosition: `${-(geo.lefts[i] ?? 0)}px 0`,
                WebkitBackgroundClip: "text",
                backgroundClip: "text",
              }
            : { color: Palette.secondaryLabel }),
        }}
      >
        {ch}
      </span>
    ));
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ position: "relative" }}>
        <motion.div ref={row} initial={false} animate={{ opacity: armed ? 0 : 1 }} transition={anim.easeInOut(0.2)} style={{ display: "flex" }}>
          {layer(false)}
        </motion.div>
        <motion.div initial={false} animate={{ opacity: armed ? 1 : 0 }} transition={anim.easeInOut(0.2)} style={{ position: "absolute", inset: 0, display: "flex" }}>
          {layer(true)}
        </motion.div>
      </div>
    </div>
  );
}
