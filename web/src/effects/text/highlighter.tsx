/** text.highlighter · 荧光笔划线 (Text+Highlighter.swift) */
import { animate, useMotionValue, useMotionValueEvent, type MotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, fonts, useAutoplay, type DemoProps } from "../../kit";
import { serifCJK } from "./_text-kit";

export default function Highlighter({ ctx }: DemoProps) {
  const first = useMotionValue(0);
  const second = useMotionValue(0);
  const color = [Palette.amber, Palette.mint, Palette.pink][ctx.i("color")] ?? Palette.amber;
  const style = ctx.i("style");
  const zh = ctx.lang === "zh";
  const sequence = useRef(0);
  const timers = useRef<number[]>([]);

  const replay = () => {
    const duration = ctx.n("duration");
    const run = ++sequence.current;
    timers.current.forEach((t) => window.clearTimeout(t));
    const at = (s: number, fn: () => void) => timers.current.push(window.setTimeout(() => run === sequence.current && fn(), s * 1000));
    animate(first, 0, anim.easeOut(0.25));
    animate(second, 0, anim.easeOut(0.25));
    at(0.35, () => {
      animate(first, 1, anim.easeInOut(duration));
      at(duration * 0.8, () => animate(second, 1, anim.easeInOut(duration)));
    });
  };
  useAutoplay(ctx.isPreview, replay, { every: 3.2, delay: 0.1, intro: false });
  // The detail stage strokes once on appear (the cleanup also stops a running sequence).
  useEffect(() => {
    if (!ctx.isPreview) replay();
    const list = timers;
    return () => {
      sequence.current += 1;
      list.current.forEach((t) => window.clearTimeout(t));
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div onClick={replay} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 8, fontFamily: serifCJK, fontSize: 28, fontWeight: 700 }}>
        <span style={{ color: Palette.secondaryLabel }}>{zh ? "设计不只是" : "Design is not just"}</span>
        <Marked text={zh ? "它看起来怎样，" : "what it looks like —"} progress={first} style={style} color={color} />
        <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
          <span style={{ color: Palette.secondaryLabel }}>{zh ? "而是" : "it's"}</span>
          <Marked text={zh ? "它如何运作。" : "how it works."} progress={second} style={style} color={color} />
        </div>
        <DemoHint ctx={ctx} en="Tap to replay" zh="点击重播" style={{ paddingTop: 16, fontFamily: fonts.text }} />
      </div>
    </div>
  );
}

function Marked({ text, progress, style, color }: { text: string; progress: MotionValue<number>; style: number; color: string }) {
  const [p, setP] = useState(progress.get());
  useMotionValueEvent(progress, "change", setP);
  return (
    <span style={{ position: "relative", display: "inline-block", padding: "0 4px", whiteSpace: "pre" }}>
      {style === 1 ? (
        <span style={{ position: "absolute", left: 0, right: 0, bottom: -2, height: 5, borderRadius: 3, background: color, transform: `scaleX(${p})`, transformOrigin: "left center" }} />
      ) : style === 2 ? (
        <svg
          style={{ position: "absolute", left: -4, top: -4, width: "calc(100% + 8px)", height: "calc(100% + 8px)", overflow: "visible", transform: "rotate(-1deg)" }}
        >
          <rect
            x="0"
            y="0"
            width="100%"
            height="100%"
            rx={10}
            fill="none"
            stroke={color}
            strokeWidth={3}
            strokeLinecap="round"
            strokeLinejoin="round"
            pathLength={1}
            strokeDasharray={`${p} 2`}
            opacity={p > 0 ? 1 : 0}
          />
        </svg>
      ) : (
        <span style={{ position: "absolute", left: 0, right: 0, top: 14, bottom: 2, transform: `rotate(-1.5deg)` }}>
          <span
            style={{
              position: "absolute",
              inset: 0,
              borderRadius: 6,
              background: `linear-gradient(to right, ${alpha(color, 0.55)}, ${alpha(color, 0.38)})`,
              transform: `scaleX(${p})`,
              transformOrigin: "left center",
            }}
          />
        </span>
      )}
      <span style={{ position: "relative", color: Palette.label }}>{text}</span>
    </span>
  );
}
