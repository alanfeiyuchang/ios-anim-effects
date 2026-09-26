/** feedback.sun-refresh · 日出下拉刷新 (Feedback+RefreshVariations.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { Palette, alpha, spring, useClock, type DemoProps } from "../../kit";
import { refreshElapsed, refreshRamp, type RefreshClock } from "./refresh-host";
import { RefreshVarHost } from "./refresh-vars";

export default function SunRefresh({ ctx }: DemoProps) {
  const rays = Math.max(ctx.i("rays"), 3);
  const fps = ctx.isPreview ? 30 : undefined;
  return (
    <RefreshVarHost
      ctx={ctx}
      indicator={({ progress, pull, refreshing, clock }) => (
        <Sunrise progress={refreshing ? Math.max(progress, 1) : progress} pull={pull} refreshing={refreshing} rays={rays} clock={clock} fps={fps} />
      )}
    />
  );
}

function Sunrise({ progress, refreshing, rays, clock, fps }: { progress: number; pull: number; refreshing: boolean; rays: number; clock: RefreshClock; fps?: number }) {
  useClock(refreshing, fps);
  const p = Math.min(Math.max(progress, 0), 1);
  const pitch = 360 / rays;
  const spinMV = useMotionValue(0);
  const [spin, setSpin] = useState(0);
  useMotionValueEvent(spinMV, "change", setSpin);
  const wasRefreshing = useRef(refreshing);
  if (refreshing) {
    const s = (refreshElapsed(clock) / 2) * 360;
    if (spinMV.get() !== s) spinMV.jump(s);
  }
  useEffect(() => {
    if (wasRefreshing.current && !refreshing) {
      const ran = (Math.max(clock.end - clock.start, 0) / 2) * 360;
      animate(spinMV, Math.ceil(ran / pitch) * pitch, spring(0.5, 0.84));
    }
    wasRefreshing.current = refreshing;
  }, [refreshing, clock, pitch, spinMV]);
  const e = refreshElapsed(clock);
  const pulse = refreshing ? 1 - 0.2 * refreshRamp(e) * (0.5 - 0.5 * Math.sin(e * 5)) : 1;
  const length = (2 + 8 * p) * pulse;
  const angle = refreshing ? (refreshElapsed(clock) / 2) * 360 : spin;
  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", inset: 0, opacity: p, background: `linear-gradient(${alpha(Palette.sky, 0.55)}, ${alpha(Palette.amber, 0.55)})` }} />
      <div style={{ position: "absolute", left: 115, bottom: 0, width: 70, height: 70, transform: `translateY(${30 - 40 * p}px)` }}>
        <div style={{ position: "absolute", inset: 0, transform: `rotate(${p * 90 + angle}deg)` }}>
          {Array.from({ length: rays }, (_, i) => (
            <div
              key={i}
              style={{ position: "absolute", left: 33.5, top: 35 - length / 2, width: 3, height: length, borderRadius: 1.5, background: Palette.amber, transform: `rotate(${(i / rays) * 360}deg) translateY(${-(19 + length / 2)}px)` }}
            />
          ))}
        </div>
        <div style={{ position: "absolute", left: 22, top: 22, width: 26, height: 26, borderRadius: "50%", background: `linear-gradient(${Palette.amber}, ${Palette.coral})`, boxShadow: `0 0 8px ${alpha(Palette.amber, 0.6)}` }} />
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 10, height: 1, background: alpha(Palette.coral, 0.5) }} />
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 10, background: Palette.elevated }} />
    </div>
  );
}
