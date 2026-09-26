/** text.variable-weight · 可变字重 (Text+VariableWeight.swift) */
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, fonts, useClock, useHaptics, usePan, type DemoProps } from "../../kit";
import { chars } from "./_text-kit";

const WORD = chars("MOTION");
const FONT_SIZE = 60;
const TOUCH_W = 300;
const secs = () => performance.now() / 1000;

export default function VariableWeight({ ctx }: DemoProps) {
  const haptics = useHaptics();
  useClock(true, ctx.isPreview ? 30 : undefined);
  const [touchX, setTouchX] = useState<number | null>(null);
  const lastX = useRef(0.5);
  const touchChanged = useRef(-Infinity);
  const touching = useRef(false);

  const speed = ctx.n("speed");
  const cycleShift = useRef(0);
  const lastSpeed = useRef(speed);
  useEffect(() => {
    cycleShift.current += secs() * (lastSpeed.current - speed);
    lastSpeed.current = speed;
  }, [speed]);

  const pan = usePan(
    {
      onChange: ({ location }) => {
        const x = Math.min(Math.max(location.x / TOUCH_W, 0), 1);
        if (!touching.current) {
          touching.current = true;
          touchChanged.current = secs();
          haptics.tap("soft");
        }
        lastX.current = x;
        setTouchX(x);
      },
      onEnd: () => {
        if (!touching.current) return;
        touching.current = false;
        touchChanged.current = secs();
        setTouchX(null);
      },
    },
    6,
  );

  const now = secs();
  const cycles = now * speed + cycleShift.current;
  const since = now - touchChanged.current;
  const hold = touchX === null ? Math.max(1 - since / 0.4, 0) : Math.min(since / 0.25, 1);
  const focus = touchX ?? lastX.current;
  const count = WORD.length;
  const spread = ctx.n("spread");
  const weights = WORD.map((_, i) => {
    const wave = 0.5 + 0.5 * Math.sin(cycles * 2 * Math.PI - i * spread);
    const distance = ((i + 0.5) / count - focus) * count;
    const finger = Math.exp(-(distance * distance) / 2.2);
    return wave + (finger - wave) * hold;
  });

  const contrast = ctx.n("contrast");
  const css = (unit: number) => Math.min(Math.max(500 + (unit - 0.5) * 800 * contrast, 100), 900);
  // The app quantises the weight axis to 64 steps.
  const quantised = (unit: number) => {
    const w = css(unit);
    return Math.round(100 + Math.round(((w - 100) / 800) * 63) * (800 / 63));
  };
  const tint = ctx.b("tint");
  const color = (unit: number) =>
    tint ? `color-mix(in oklab, ${Palette.indigo}, ${Palette.coral} ${Math.min(Math.max(unit, 0), 1) * 100}%)` : Palette.label;
  const average = weights.reduce((a, b) => a + b, 0) / Math.max(weights.length, 1);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        {...pan}
        style={{ ...pan.style, width: TOUCH_W, height: 130, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10, cursor: "ew-resize" }}
      >
        <div style={{ height: 80, display: "flex", alignItems: "center" }}>
          {WORD.map((ch, i) => {
            const w = quantised(weights[i]);
            return (
              <span
                key={i}
                style={{
                  fontFamily: fonts.text,
                  fontSize: FONT_SIZE,
                  lineHeight: "72px",
                  fontWeight: w,
                  fontVariationSettings: `"wght" ${w}`,
                  color: color(weights[i]),
                }}
              >
                {ch}
              </span>
            );
          })}
        </div>
        <div style={{ display: "flex", gap: 6, fontFamily: fonts.mono, fontSize: 13, lineHeight: "18px", fontWeight: 600 }}>
          <span style={{ color: Palette.tertiaryLabel }}>wght</span>
          <span style={{ width: 34, color: Palette.secondaryLabel, fontVariantNumeric: "tabular-nums" }}>{Math.round(500 + (average - 0.5) * 800 * contrast)}</span>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag across the word" zh="在单词上拖动" />
    </div>
  );
}
