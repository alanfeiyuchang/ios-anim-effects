/** text.scribble-circle · 手绘圈注 (Text+ScribbleCircle.swift) */
import { animate, useMotionValue, useMotionValueEvent, type MotionValue } from "motion/react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { DemoHint, Palette, anim, fonts, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { useSize } from "./_text-kit";

/** A slightly wobbly ellipse that runs past a full turn, like a marker loop. */
function loopPath(w: number, h: number, turns: number) {
  const steps = 90;
  const total = turns * 2 * Math.PI;
  const start = -Math.PI * 0.35;
  const pts: string[] = [];
  for (let step = 0; step <= steps; step++) {
    const t = (total * step) / steps;
    const wobble = 1 + 0.035 * Math.sin(t * 3) + (0.05 * t) / total;
    const angle = start + t;
    pts.push(`${(w / 2 + (w / 2) * wobble * Math.cos(angle)).toFixed(2)},${(h / 2 + (h / 2) * wobble * Math.sin(angle) * 0.95).toFixed(2)}`);
  }
  return "M" + pts.join("L");
}

/** Four crests of a sine wave across the rect. */
function squigglePath(w: number, h: number) {
  const pts: string[] = [];
  for (let step = 0; step <= 60; step++) {
    const p = step / 60;
    pts.push(`${(w * p).toFixed(2)},${(h / 2 + Math.sin(p * Math.PI * 8) * h * 0.38).toFixed(2)}`);
  }
  return "M" + pts.join("L");
}

function useMV(mv: MotionValue<number>) {
  const [v, setV] = useState(mv.get());
  useMotionValueEvent(mv, "change", setV);
  return v;
}

export default function ScribbleCircle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const loop = useMotionValue(1);
  const underline = useMotionValue(1);
  const [marked, setMarked] = useState(true);
  const [markInstant, setMarkInstant] = useState(false);
  const timers = useRef<number[]>([]);
  useEffect(() => () => timers.current.forEach((t) => window.clearTimeout(t)), []);
  const width = ctx.n("width");
  const duration = ctx.n("duration");

  const replay = () => {
    timers.current.forEach((t) => window.clearTimeout(t));
    loop.jump(0);
    underline.jump(0);
    setMarkInstant(true);
    setMarked(false);
    timers.current = [
      window.setTimeout(() => {
        haptics.tap("light");
        animate(loop, 1, anim.easeInOut(duration));
      }, 200),
      window.setTimeout(() => {
        haptics.tap("light");
        setMarkInstant(false);
        setMarked(true);
        animate(underline, 1, anim.easeInOut(0.5));
      }, (0.3 + duration) * 1000),
    ];
  };
  useAutoplay(ctx.isPreview, replay, { every: duration + 2.0 });

  const zh = ctx.lang === "zh";
  return (
    <div onClick={replay} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 6, fontFamily: fonts.text, fontSize: 30, fontWeight: 700, lineHeight: "36px", color: Palette.label, whiteSpace: "pre" }}>
        <span>{zh ? "好的设计" : "Great design"}</span>
        <div style={{ display: "flex" }}>
          <span>{zh ? "是" : "is "}</span>
          <Keyword progress={loop} turns={ctx.n("turns")} width={width} marked={marked} instant={markInstant}>
            {zh ? "隐形" : "invisible"}
          </Keyword>
          <span>{zh ? "的，" : ","}</span>
        </div>
        <div style={{ display: "flex" }}>
          <span>{zh ? "直到它" : "until it "}</span>
          <Underlined progress={underline} width={width}>
            {zh ? "动起来" : "moves"}
          </Underlined>
          <span>{zh ? "。" : "."}</span>
        </div>
        <DemoHint ctx={ctx} en="Tap to annotate" zh="点击批注" style={{ paddingTop: 24, fontFamily: fonts.text }} />
      </div>
    </div>
  );
}

function Keyword({ progress, turns, width, marked, instant, children }: { progress: MotionValue<number>; turns: number; width: number; marked: boolean; instant: boolean; children: ReactNode }) {
  const p = useMV(progress);
  const [ref, { w, h }] = useSize<HTMLSpanElement>();
  const bw = w + 28;
  const bh = h + 16;
  return (
    <span ref={ref} style={{ position: "relative", color: marked ? Palette.coral : Palette.label, transition: instant ? "none" : "color 0.25s ease-out" }}>
      {children}
      {w > 0 && (
        <svg width={bw} height={bh} style={{ position: "absolute", left: -14, top: -8, overflow: "visible", pointerEvents: "none" }}>
          <path
            d={loopPath(bw, bh, turns)}
            fill="none"
            stroke={Palette.coral}
            strokeWidth={width}
            strokeLinecap="round"
            strokeLinejoin="round"
            pathLength={1}
            strokeDasharray={`${p} 2`}
            opacity={p > 0.0005 ? 1 : 0}
          />
        </svg>
      )}
    </span>
  );
}

function Underlined({ progress, width, children }: { progress: MotionValue<number>; width: number; children: ReactNode }) {
  const p = useMV(progress);
  const [ref, { w, h }] = useSize<HTMLSpanElement>();
  return (
    <span ref={ref} style={{ position: "relative" }}>
      {children}
      {w > 0 && (
        <svg width={w} height={8} style={{ position: "absolute", left: 0, top: h - 8 + 8, overflow: "visible", pointerEvents: "none" }}>
          <path
            d={squigglePath(w, 8)}
            fill="none"
            stroke={Palette.indigo}
            strokeWidth={width}
            strokeLinecap="round"
            strokeLinejoin="round"
            pathLength={1}
            strokeDasharray={`${p} 2`}
            opacity={p > 0.0005 ? 1 : 0}
          />
        </svg>
      )}
    </span>
  );
}
