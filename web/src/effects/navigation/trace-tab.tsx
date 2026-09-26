/** navigation.trace-tab · 描边追踪标签 (Navigation+TraceTab.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, type MotionValue } from "motion/react";
import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, fonts, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { primaryCorner } from "./groupA-kit";

const TABS: [string, string][] = [
  ["Day", "日"],
  ["Week", "周"],
  ["Month", "月"],
  ["Year", "年"],
];
const SEG_W = 64;
const SEG_H = 36;

const barHeight = (bar: number, selected: number) => {
  const seed = bar * 7 + selected * 13;
  const wave = (Math.sin(seed * 1.7) + 1) / 2;
  return 28 + wave * 100;
};

export default function TraceTab({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(1);

  const select = (index: number) => {
    if (index === selected) return;
    haptics.selection();
    setSelected(index);
  };

  useAutoplay(ctx.isPreview, () => select((selected + 1) % TABS.length), { every: 1.4 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 26 }}>
      <div style={{ display: "flex", gap: 6, padding: 5, borderRadius: 999, background: Palette.surface, flexShrink: 0 }}>
        {TABS.map(([en, zh], index) => (
          <Segment
            key={index}
            label={ctx.t(en, zh)}
            isSelected={index === selected}
            duration={ctx.n("duration")}
            line={ctx.n("line")}
            fill={ctx.b("fill")}
            onTap={() => select(index)}
          />
        ))}
      </div>
      <div style={{ height: 130, display: "flex", alignItems: "flex-end", gap: 12, flexShrink: 0 }}>
        {Array.from({ length: 7 }, (_, bar) => (
          <motion.div
            key={bar}
            initial={false}
            animate={{ height: barHeight(bar, selected) }}
            transition={delayed(spring(0.45, 0.62), bar * 0.03)}
            style={{ width: 22, borderRadius: 6, background: bar === 4 ? primaryCorner : "rgb(110 123 255 / 0.22)" }}
          />
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap a range" zh="点击任一范围" />
    </div>
  );
}

function Segment({
  label,
  isSelected,
  duration,
  line,
  fill,
  onTap,
}: {
  label: string;
  isSelected: boolean;
  duration: number;
  line: number;
  fill: boolean;
  onTap: () => void;
}) {
  const progress = useMotionValue(isSelected ? 1 : 0);
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    const controls = animate(progress, isSelected ? 1 : 0, isSelected ? delayed(anim.easeInOut(duration), 0.2) : anim.easeIn(duration * 0.5));
    return () => controls.stop();
  }, [isSelected, duration, progress]);

  return (
    <div
      onClick={onTap}
      style={{
        position: "relative",
        width: SEG_W,
        height: SEG_H,
        flexShrink: 0,
        display: "grid",
        placeItems: "center",
        cursor: "pointer",
        fontFamily: fonts.text,
        fontSize: 15,
        lineHeight: "20px",
        fontWeight: 600,
        whiteSpace: "nowrap",
        color: isSelected ? Palette.indigo : Palette.secondaryLabel,
        transition: "color 0.25s ease-in-out",
      }}
    >
      <motion.div
        initial={false}
        animate={{ opacity: isSelected && fill ? 1 : 0 }}
        transition={isSelected ? delayed(anim.easeOut(0.25), 0.2 + duration * 0.85) : anim.easeOut(0.15)}
        style={{ position: "absolute", inset: 0, borderRadius: SEG_H / 2, background: "rgb(110 123 255 / 0.12)" }}
      />
      <span style={{ position: "relative" }}>{label}</span>
      <TraceStroke progress={progress} line={line} />
    </div>
  );
}

const MARGIN = 6;

/**
 * `TracePill().trim(from: 0.5 − p/2, to: 0.5 + p/2).stroke(AngularGradient(...), lineCap: .round)`: the capsule
 * outline starts at the top centre and runs clockwise, so it grows out of the bottom centre towards the top.
 */
function TraceStroke({ progress, line }: { progress: MotionValue<number>; line: number }) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const w = SEG_W + MARGIN * 2;
  const h = SEG_H + MARGIN * 2;

  const draw = () => {
    const el = canvas.current;
    const c = el?.getContext("2d");
    if (!el || !c) return;
    const dpr = Math.max(2, window.devicePixelRatio || 1);
    if (el.width !== w * dpr) {
      el.width = w * dpr;
      el.height = h * dpr;
    }
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    c.clearRect(0, 0, w, h);
    const p = progress.get();
    if (p <= 0.0005) return;
    const r = SEG_H / 2;
    const x0 = MARGIN;
    const y0 = MARGIN;
    const straight = SEG_W - 2 * r;
    const total = 2 * straight + 2 * Math.PI * r;
    c.beginPath();
    c.moveTo(x0 + SEG_W / 2, y0);
    c.lineTo(x0 + SEG_W - r, y0);
    c.arc(x0 + SEG_W - r, y0 + r, r, -Math.PI / 2, Math.PI / 2, false);
    c.lineTo(x0 + r, y0 + SEG_H);
    c.arc(x0 + r, y0 + r, r, Math.PI / 2, (Math.PI * 3) / 2, false);
    c.closePath();
    const from = (0.5 - p / 2) * total;
    const length = p * total;
    c.setLineDash([Math.max(length, 0.001), total + 1]);
    c.lineDashOffset = -from;
    const g = c.createConicGradient(0, x0 + SEG_W / 2, y0 + SEG_H / 2);
    g.addColorStop(0, Palette.indigo);
    g.addColorStop(1 / 3, Palette.violet);
    g.addColorStop(2 / 3, Palette.pink);
    g.addColorStop(1, Palette.indigo);
    c.strokeStyle = g;
    c.lineWidth = line;
    c.lineCap = "round";
    c.stroke();
  };

  useLayoutEffect(draw);
  useMotionValueEvent(progress, "change", draw);

  return (
    <canvas
      ref={canvas}
      style={{ position: "absolute", left: -MARGIN, top: -MARGIN, width: w, height: h, pointerEvents: "none" }}
    />
  );
}
