/** inputs.checkbox-draw (Inputs+CheckboxDraw.swift) */
import { motion, type Transition } from "motion/react";
import { useId, useLayoutEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, delayed, demoCard, ease, mix, progress, springAt, textStyle, useAutoplay, useElapsed, useHaptics, type DemoProps } from "../../kit";

const TITLES: [string, string][] = [
  ["Sketch onboarding flow", "绘制引导流程草图"],
  ["Tune spring curves", "调整弹簧曲线"],
  ["Ship the prototype", "发布交互原型"],
];

/** Pen-like pacing: a hesitant start, then a quick flick. */
const pen = (d: number): Transition => ({ type: "tween", duration: d, ease: [0.55, 0, 0.25, 1] });

export default function CheckboxDraw({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [checked, setChecked] = useState([true, false, false]);
  const step = useRef(0);

  const toggle = (index: number) => {
    haptics.tap();
    setChecked((c) => c.map((v, i) => (i === index ? !v : v)));
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      toggle((step.current + 1) % 3);
      step.current += 1;
    },
    { every: 1.0, delay: 0.4 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(), width: 290, padding: 22, display: "flex", flexDirection: "column", gap: 18 }}>
        {TITLES.map((t, i) => (
          <Row
            key={i}
            title={ctx.lang === "zh" ? t[1] : t[0]}
            checked={checked[i]}
            draw={ctx.n("draw")}
            squash={ctx.n("squash")}
            strike={ctx.b("strike")}
            onTap={() => toggle(i)}
          />
        ))}
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap a task to check it off" zh="点击任务即可勾选" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Row({ title, checked, draw, squash, strike, onTap }: { title: string; checked: boolean; draw: number; squash: number; strike: boolean; onTap: () => void }) {
  const textRef = useRef<HTMLSpanElement>(null);
  const [w, setW] = useState(0);
  useLayoutEffect(() => {
    if (textRef.current) setW(textRef.current.offsetWidth);
  }, [title]);
  const lineT = checked ? delayed(pen(draw), 0.08) : ({ type: "tween", duration: draw * 0.6, ease: [0.42, 0, 1, 1] } as Transition);
  const mid = 3;
  const scribble = `M-2 ${mid + 1} C${w * 0.15} ${mid - 2.5} ${w * 0.3} ${mid + 2.5} ${w * 0.5} ${mid} C${w * 0.7} ${mid - 2.5} ${w * 0.85} ${mid + 2} ${w + 3} ${mid - 1.5}`;
  return (
    <div onClick={onTap} style={{ display: "flex", alignItems: "center", gap: 14, cursor: "pointer" }}>
      <Box checked={checked} draw={draw} squash={squash} tickT={lineT} />
      <span
        ref={textRef}
        style={{
          position: "relative",
          ...textStyle.body,
          fontWeight: 500,
          whiteSpace: "nowrap",
          color: checked ? Palette.secondaryLabel : Palette.label,
          transition: "color 0.25s ease-out",
        }}
      >
        {title}
        <svg width={w + 8} height={6} style={{ position: "absolute", left: -2, top: "50%", marginTop: -3, overflow: "visible", pointerEvents: "none" }}>
          <motion.path
            d={scribble}
            transform="translate(2 0)"
            fill="none"
            style={{ stroke: Palette.secondaryLabel }}
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
            initial={false}
            animate={{ pathLength: checked && strike ? 1 : 0, opacity: checked && strike ? 1 : 0 }}
            transition={{ pathLength: lineT, opacity: { duration: 0.01, delay: checked && strike ? (lineT.delay ?? 0) : draw * 0.6 } }}
          />
        </svg>
      </span>
    </div>
  );
}

function Box({ checked, draw, squash, tickT }: { checked: boolean; draw: number; squash: number; tickT: Transition }) {
  const id = `a-tick-${useId().replace(/:/g, "")}`;
  const first = useRef(checked);
  const trigger = useRef({ value: checked, count: 0 });
  if (trigger.current.value !== checked) trigger.current = { value: checked, count: trigger.current.count + 1 };
  const changed = trigger.current.count > 0 || first.current !== checked;
  const t = useElapsed(trigger.current.count, 0.48, true);
  let scale = 1;
  if (changed && t >= 0 && t < 0.48) scale = t < 0.08 ? mix(1, squash, ease.inOut(progress(t, 0, 0.08))) : mix(squash, 1, springAt(t - 0.08, 0.4, 0.7));

  // Ink specks: wait delay × 0.8, then fly out over 0.4 s.
  const delay = draw + 0.08;
  const burstStart = 0.001 + delay * 0.8;
  const b = useElapsed(trigger.current.count, burstStart + 0.4, true);
  const bt = b < 0 ? 0 : ease.inOut(progress(b, burstStart, 0.4));

  // Tick in the 28 pt box (it overshoots past the top-right corner).
  const P = (x: number, y: number) => `${x * 28} ${y * 28}`;
  const tick = `M${P(0.2, 0.5)} Q${P(0.3, 0.6)} ${P(0.42, 0.8)} C${P(0.55, 0.5)} ${P(0.85, 0.1)} ${P(1.15, -0.1)}`;
  return (
    <div style={{ position: "relative", width: 28, height: 28, flexShrink: 0 }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 8,
          transform: `scale(${scale})`,
          background: alpha(Palette.indigo, checked ? 0.14 : 0),
          boxShadow: `inset 0 0 0 2px ${checked ? alpha(Palette.indigo, 0.7) : Palette.labelAlpha(0.25)}`,
          transition: "background-color 0.2s ease-out, box-shadow 0.2s ease-out",
        }}
      />
      <svg width={28} height={28} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        <defs>
          <linearGradient id={id} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={Palette.indigo} />
            <stop offset="1" stopColor={Palette.violet} />
          </linearGradient>
        </defs>
        <motion.path
          d={tick}
          fill="none"
          stroke={`url(#${id})`}
          strokeWidth={3.5}
          strokeLinecap="round"
          strokeLinejoin="round"
          initial={false}
          animate={{ pathLength: checked ? 1 : 0, opacity: checked ? 1 : 0 }}
          transition={{ pathLength: tickT, opacity: { duration: 0.01, delay: checked ? (tickT.delay ?? 0) : draw * 0.6 } }}
        />
      </svg>
      <div style={{ position: "absolute", left: 33.75, top: -1.25, width: 0, height: 0, opacity: checked ? 1 : 0, pointerEvents: "none" }}>
        {Array.from({ length: 6 }, (_, i) => {
          const a = ((-120 + i * 36) * Math.PI) / 180;
          const d = 12 * bt;
          const o = bt > 0 && bt < 1 ? 1 - bt : 0;
          return (
            <div
              key={i}
              style={{
                position: "absolute",
                left: -1.75,
                top: -1.75,
                width: 3.5,
                height: 3.5,
                borderRadius: "50%",
                background: i % 2 === 0 ? Palette.indigo : Palette.violet,
                transform: `translate(${Math.cos(a) * d}px, ${Math.sin(a) * d}px) scale(${1 - bt * 0.5})`,
                opacity: o,
              }}
            />
          );
        })}
      </div>
    </div>
  );
}
