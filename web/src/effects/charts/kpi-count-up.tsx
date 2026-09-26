/** charts.kpi-count-up · KPI 卡片数字滚动 (Charts+KPICount.swift) */
import { motion } from "motion/react";
import { DollarSign, GitBranch, Users, Zap, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, delayed, demoCard, fonts, hex, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { randomIn, useAnimatedNumbers, useChartEntrance } from "./_shared";

interface Kind {
  en: string;
  zh: string;
  icon: LucideIcon;
  filled: boolean;
  tint: string;
  range: [number, number];
}

const kinds: Kind[] = [
  { en: "Revenue", zh: "营收", icon: DollarSign, filled: false, tint: Palette.indigo, range: [48_000, 96_000] },
  { en: "Active users", zh: "活跃用户", icon: Users, filled: true, tint: Palette.mint, range: [8_000, 24_000] },
  { en: "Conversion", zh: "转化率", icon: GitBranch, filled: false, tint: Palette.coral, range: [2.4, 7.8] },
  { en: "Latency", zh: "延迟", icon: Zap, filled: true, tint: Palette.sky, range: [38, 140] },
];

/** Lower latency is better, so its "goal" fraction is inverted. */
function fraction(index: number, value: number): number {
  if (value === 0) return 0;
  const [lo, hi] = kinds[index].range;
  const f = Math.min(Math.max((value - lo) / (hi - lo), 0), 1);
  return index === 3 ? 1 - f * 0.7 : 0.3 + f * 0.7;
}

function format(index: number, value: number): string {
  switch (index) {
    case 0:
      return "$" + Math.round(value).toLocaleString("en-US");
    case 1:
      return Math.round(value).toLocaleString("en-US");
    case 2:
      return `${value.toFixed(1)}%`;
    default:
      return `${Math.round(value)} ms`;
  }
}

const gradient = (c: string) => `linear-gradient(180deg, color-mix(in srgb, ${c} 82%, white), ${c})`;

export default function KPICountUp({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const values = useAnimatedNumbers(4, 0);
  const bars = useAnimatedNumbers(4, 0);
  const targets = useRef([0, 0, 0, 0]);
  const [deltas, setDeltas] = useState([8.4, 3.1, -2.2, -6.5]);
  const [shown, setShown] = useState(false);

  const refresh = (fromZero: boolean) => {
    const duration = ctx.n("duration");
    const stagger = ctx.n("stagger");
    const old = targets.current;
    const next = kinds.map((k) => randomIn(k.range[0], k.range[1]));
    if (!fromZero) haptics.tap("light");
    setShown(true);
    setDeltas(
      next.map((t, i) => {
        // From zero there is no real previous value, so invent a varied baseline per card.
        const previous = old[i] === 0 ? t * randomIn(0.78, 1.12) : old[i];
        return ((t - previous) / previous) * 100;
      }),
    );
    targets.current = next;
    next.forEach((t, i) => {
      const curve = delayed(anim.curve(0.16, 1, 0.3, 1, duration), i * stagger);
      values.to(i, t, curve);
      bars.to(i, fraction(i, t), curve);
    });
  };

  const replay = () => {
    targets.current = [0, 0, 0, 0];
    setShown(false);
    for (let i = 0; i < 4; i++) {
      values.to(i, 0, anim.easeOut(0.3));
      bars.to(i, 0, anim.easeOut(0.3));
    }
    after(0.35, () => refresh(true));
  };

  useChartEntrance(() => refresh(true));
  useAutoplay(ctx.isPreview, replay, { every: ctx.n("duration") + 2.0, delay: ctx.n("duration") + 1.6, intro: false });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div onClick={() => refresh(false)} style={{ display: "grid", gridTemplateColumns: "143px 143px", gap: 12, cursor: "pointer" }}>
        {kinds.map((kind, i) => {
          const Icon = kind.icon;
          return (
            <div key={i} style={{ ...demoCard(20), width: 143, height: 124, padding: 12, display: "flex", flexDirection: "column", gap: 8 }}>
              <div style={{ display: "flex", alignItems: "center" }}>
                <div style={{ width: 24, height: 24, borderRadius: 7, background: gradient(kind.tint), display: "grid", placeItems: "center", color: "#fff" }}>
                  <Icon size={13} strokeWidth={kind.filled ? 1.5 : 3} fill={kind.filled ? "currentColor" : "none"} />
                </div>
                <div style={{ flex: 1 }} />
                <motion.div
                  initial={false}
                  animate={{ opacity: shown ? 1 : 0, y: shown ? 0 : 6 }}
                  transition={shown ? delayed(spring(0.5, 0.8), 0.2) : anim.easeOut(0.3)}
                >
                  <DeltaPill delta={deltas[i]} invert={i === 3} />
                </motion.div>
              </div>
              <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, color: Palette.secondaryLabel }}>{ctx.t(kind.en, kind.zh)}</div>
              <div style={{ fontFamily: fonts.rounded, fontSize: 21, lineHeight: "25px", fontWeight: 700, fontVariantNumeric: "tabular-nums", whiteSpace: "nowrap" }}>
                {format(i, Math.max(values.get(i), 0))}
              </div>
              <div style={{ position: "relative", height: 4, borderRadius: 2, background: Palette.labelAlpha(0.08) }}>
                <div style={{ position: "absolute", left: 0, top: 0, height: 4, width: 119 * Math.max(bars.get(i), 0), borderRadius: 2, background: gradient(kind.tint) }} />
              </div>
            </div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap to refresh" zh="点击刷新" style={{ position: "absolute", left: 0, right: 0, bottom: 10 }} />
    </div>
  );
}

function DeltaPill({ delta, invert }: { delta: number; invert: boolean }) {
  const good = invert ? delta <= 0 : delta >= 0;
  const color = good ? Palette.green : Palette.red;
  const arrow = delta >= 0 ? "▲" : "▼";
  return (
    <div style={{ padding: "3px 6px", borderRadius: 999, background: hex(color, 0.14), color, fontFamily: fonts.rounded, fontSize: 10, lineHeight: "12px", fontWeight: 700 }}>
      <NumericText value={delta} text={`${arrow} ${Math.abs(delta).toFixed(1)}%`} />
    </div>
  );
}
