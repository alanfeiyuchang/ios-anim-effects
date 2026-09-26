/** feedback.dots-refresh · 三点下拉刷新 (Feedback+RefreshVariations.swift) */
import { motion } from "motion/react";
import { useEffect, useRef } from "react";
import { Palette, spring, useClock, useHaptics, type DemoProps } from "../../kit";
import { refreshElapsed, type RefreshClock } from "./refresh-host";
import { RefreshVarHost } from "./refresh-vars";

const COLORS = [Palette.indigo, Palette.violet, Palette.pink];

export default function DotsRefresh({ ctx }: DemoProps) {
  return (
    <RefreshVarHost
      ctx={ctx}
      indicator={({ progress, refreshing, clock, userDriven }) => (
        <Dots dim={ctx.scheme === "dark" ? "rgb(235 235 245 / 0.3)" : "rgb(60 60 67 / 0.3)"} progress={progress} refreshing={refreshing} hop={ctx.n("hop")} live={!ctx.isPreview} userDriven={userDriven} clock={clock} />
      )}
    />
  );
}

function Dots({ dim, progress, refreshing, hop, live, userDriven, clock }: { dim: string; progress: number; refreshing: boolean; hop: number; live: boolean; userDriven: boolean; clock: RefreshClock }) {
  const haptics = useHaptics();
  useClock(refreshing, live ? undefined : 30);
  const lit = refreshing ? 3 : Math.min(Math.floor(progress * 3 + 0.0001), 3);
  const prev = useRef(lit);
  useEffect(() => {
    if (lit > prev.current && live && userDriven && !refreshing) haptics.selection();
    prev.current = lit;
  }, [lit, live, userDriven, refreshing, haptics]);
  const t = refreshElapsed(clock) / 0.6;
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
      {[0, 1, 2].map((i) => {
        const on = i < lit;
        const raw = t - i * 0.2;
        const phase = raw - Math.floor(raw);
        const lift = refreshing && phase < 0.5 ? Math.sin(phase * 2 * Math.PI) : 0;
        return (
          <div key={i} style={{ transform: `translateY(${-hop * lift}px)` }}>
            <motion.div
              initial={false}
              animate={{ scale: on ? 1 : 0.3, backgroundColor: on ? COLORS[i] : "rgb(0 0 0 / 0)", boxShadow: `inset 0 0 0 1.5px ${on ? "rgb(0 0 0 / 0)" : dim}` }}
              transition={spring(0.3, 0.5)}
              style={{ width: 10, height: 10, borderRadius: "50%" }}
            />
          </div>
        );
      })}
    </div>
  );
}
