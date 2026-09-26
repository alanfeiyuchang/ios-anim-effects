/** inputs.segmented-slider (Inputs+SegmentedSlider.swift) */
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, clamp, demoCard, fonts, textStyle, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";

const WIDTH = 280;
const LEVELS = [0.9, 0.35, 0.7, 0.2, 1.0, 0.55];

export default function SegmentedSlider({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const count = Math.max(ctx.i("segments"), 4);
  const [s, setS] = useState({ lit: 12, previous: 12, peak: 12 });
  const ref = useRef(s);
  ref.current = s;
  const peakCancel = useRef<() => void>(() => {});
  const step = useRef(0);
  const segW = (WIDTH - (count - 1) * 4) / count;

  useEffect(() => {
    const lit = Math.min(ref.current.lit, count);
    setS({ lit, previous: lit, peak: lit });
  }, [count]);

  const setLevel = (n: number) => {
    const v = clamp(n, 0, count);
    const cur = ref.current;
    if (v === cur.lit) return;
    haptics.selection();
    const next = { lit: v, previous: cur.lit, peak: Math.max(cur.peak, v) };
    ref.current = next;
    setS(next);
    peakCancel.current();
    peakCancel.current = after(0.6, () => setS((x) => ({ ...x, peak: x.lit })));
  };

  const pan = usePan({ onChange: ({ location }) => setLevel(Math.ceil(clamp(location.x / WIDTH) * count)) });

  useAutoplay(
    ctx.isPreview,
    () => {
      setLevel(Math.round(LEVELS[step.current % LEVELS.length] * count));
      step.current += 1;
    },
    { every: 1.1, delay: 0.3 },
  );

  const { lit, previous, peak } = s;
  const db = Math.round(-60 + (lit / count) * 60);
  const colorFor = (i: number) => {
    const f = i / Math.max(count - 1, 1);
    return f > 0.82 ? Palette.red : f > 0.6 ? Palette.amber : Palette.mint;
  };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: WIDTH + 36, padding: 18, display: "flex", flexDirection: "column", gap: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, ...textStyle.subheadline, fontWeight: 600 }}>
          <svg width={13} height={18} viewBox="0 0 13 18" style={{ color: Palette.mint }}>
            <rect x={3} y={0} width={7} height={11.5} rx={3.5} fill="currentColor" />
            <path d="M1 8.2a5.5 5.5 0 0 0 11 0M6.5 13.8V17" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" />
          </svg>
          <span>{ctx.t("Mic gain", "麦克风增益")}</span>
          <div style={{ flex: 1 }} />
          <NumericText value={db} text={`${db} dB`} style={{ fontFamily: fonts.mono, fontWeight: 600, color: Palette.secondaryLabel }} />
        </div>
        <div {...pan} style={{ ...pan.style, width: WIDTH, height: 56, display: "flex", alignItems: "flex-end", gap: 4, cursor: "pointer" }}>
          {Array.from({ length: count }, (_, i) => {
            const on = i < lit;
            const isPeak = ctx.b("peak") && i === peak - 1 && peak > lit;
            const f = i / Math.max(count - 1, 1);
            const distance = on ? Math.max(i - previous, 0) : Math.max(previous - 1 - i, 0);
            const delay = distance * ctx.n("stagger");
            const c = colorFor(i);
            return (
              <div
                key={i}
                style={{
                  position: "relative",
                  width: segW,
                  height: 14 + 32 * f,
                  borderRadius: 3,
                  background: on ? c : Palette.labelAlpha(0.08),
                  transform: `scaleY(${on ? 1.04 : 1})`,
                  transformOrigin: "50% 100%",
                  boxShadow: on ? `0 0 5px ${alpha(c, 0.55)}` : `0 0 0 ${alpha(c, 0)}`,
                  transition: `background-color 0.12s ease-out ${delay}s, transform 0.12s ease-out ${delay}s, box-shadow 0.12s ease-out ${delay}s`,
                }}
              >
                <div
                  style={{
                    position: "absolute",
                    inset: 0,
                    borderRadius: 3,
                    boxShadow: `inset 0 0 0 1.5px ${Palette.labelAlpha(0.75)}`,
                    opacity: isPeak ? 1 : 0,
                    transition: "opacity 0.4s ease-in-out",
                  }}
                />
              </div>
            );
          })}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag across the meter" zh="在电平表上左右拖动" style={{ paddingBottom: 18 }} />
    </div>
  );
}
