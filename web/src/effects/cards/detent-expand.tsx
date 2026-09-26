/** cards.detent-expand · 档位下拉卡片 (Cards+DetentExpand.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { Building2, CircleCheck, House, Package, Truck, type LucideIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, black, clamp, fonts, rubberBand, spring, useAutoplay, useHaptics, usePan, type DemoContext, type DemoProps } from "../../kit";
import { Stage, predictEnd, useMV } from "./shared";

const DETENTS = [112, 196, 280];
const ROWS: { Icon: LucideIcon; title: [string, string]; value: string }[] = [
  { Icon: CircleCheck, title: ["Packed", "已打包"], value: "08:12" },
  { Icon: Truck, title: ["Shipped", "已发货"], value: "10:40" },
  { Icon: Building2, title: ["At local hub", "到达本地中转"], value: "18:05" },
  { Icon: House, title: ["Out for delivery", "派送中"], value: "—" },
];

export default function DetentExpand({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const heightMV = useMotionValue(112);
  const [grabbed, setGrabbed] = useState(false);
  const startHeight = useRef<number | null>(null);
  const detent = useRef(0);
  const step = useRef(0);
  const script = useRef(0);
  useEffect(() => () => window.clearTimeout(script.current), []);

  const resisted = (raw: number) => {
    const low = DETENTS[0];
    const high = DETENTS[DETENTS.length - 1];
    if (!ctx.b("rubber")) return clamp(raw, low, high);
    if (raw < low) return low + rubberBand(raw - low, 60);
    if (raw > high) return high + rubberBand(raw - high, 60);
    return raw;
  };
  const nearest = (value: number) => DETENTS.reduce((best, c, i) => (Math.abs(c - value) < Math.abs(DETENTS[best] - value) ? i : best), 0);
  const snap = (index: number, silent: boolean) => {
    if (index !== detent.current && !silent) haptics.tap("rigid");
    detent.current = index;
    animate(heightMV, DETENTS[index], spring(ctx.n("response"), ctx.n("damping")));
  };

  const pan = usePan(
    {
      onStart: ({ translation }) => {
        // Only the directions the card can move from its detent.
        const down = translation.y > 0;
        const allowed = detent.current <= 0 ? down : detent.current >= DETENTS.length - 1 ? !down : true;
        if (!allowed) return;
        startHeight.current = heightMV.get();
        window.clearTimeout(script.current);
        setGrabbed(true);
      },
      onChange: ({ translation }) => {
        if (startHeight.current === null) return;
        heightMV.jump(resisted(startHeight.current + translation.y));
      },
      onEnd: ({ translation, velocity }) => {
        const start = startHeight.current;
        if (start === null) return;
        startHeight.current = null;
        setGrabbed(false);
        snap(nearest(start + predictEnd(translation.y, velocity.y)), false);
      },
    },
    8,
  );

  useAutoplay(
    ctx.isPreview,
    () => {
      if (startHeight.current !== null) return;
      const sequence = [1, 2, 0, 2, 1, 0];
      const next = sequence[step.current % sequence.length];
      step.current += 1;
      const overshoot = next === 2 ? 26 : next === 0 ? -20 : 0;
      animate(heightMV, resisted(DETENTS[next] + overshoot), anim.easeOut(0.3));
      window.clearTimeout(script.current);
      script.current = window.setTimeout(() => snap(next, true), 320);
    },
    { every: 1.4 },
  );

  const height = useMV(heightMV);
  const content = Math.max(height - 24, 60);

  return (
    <Stage gap={14}>
      <div style={{ height: 330, width: 280, flexShrink: 0 }}>
        <div
          {...pan}
          style={{
            ...pan.style,
            position: "relative",
            width: 280,
            height: content + 24,
            borderRadius: 24,
            background: Palette.elevated,
            boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 10px 18px ${black(0.12)}`,
            cursor: "grab",
          }}
        >
          <div style={{ width: 280, height: content, overflow: "hidden", display: "flex", flexDirection: "column" }}>
            <Summary ctx={ctx} />
            {ROWS.map((_, i) => {
              const rowBottom = 76 + (i + 1) * 42;
              const reveal = clamp((height - 24 - rowBottom) / 20 + 1);
              return (
                <div key={i} style={{ opacity: reveal, transform: `translateY(${(1 - reveal) * -8}px)` }}>
                  <Row index={i} ctx={ctx} />
                </div>
              );
            })}
          </div>
          <div style={{ position: "absolute", left: 80, top: content - 4, width: 120, height: 24, display: "grid", placeItems: "center" }}>
            <motion.div
              initial={false}
              animate={{ width: grabbed ? 48 : 36, opacity: grabbed ? 0.35 : 0.2 }}
              transition={spring(0.3, 0.7)}
              style={{ height: 5, borderRadius: 3, background: Palette.label }}
            />
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag the card up or down" zh="上下拖动卡片" />
    </Stage>
  );
}

function Summary({ ctx }: { ctx: DemoContext }) {
  return (
    <div style={{ height: 76, flexShrink: 0, display: "flex", alignItems: "center", gap: 12, padding: "0 16px" }}>
      <div style={{ width: 42, height: 42, borderRadius: 12, background: Palette.ocean, display: "grid", placeItems: "center", color: "#fff" }}>
        <Package size={21} strokeWidth={2.4} />
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{ctx.t("Order #4821", "订单 #4821")}</span>
        <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{ctx.t("Arriving tomorrow, 9–11 am", "明天上午 9–11 点送达")}</span>
      </div>
    </div>
  );
}

function Row({ index, ctx }: { index: number; ctx: DemoContext }) {
  const row = ROWS[index];
  const { Icon } = row;
  return (
    <div style={{ height: 42, flexShrink: 0, display: "flex", alignItems: "center", gap: 10, padding: "0 18px" }}>
      <div style={{ width: 22, display: "grid", placeItems: "center", color: index < 3 ? Palette.green : Palette.secondaryLabel }}>
        {/* SF `.fill` symbols: a solid glyph with its details cut out in the card colour. */}
        <Icon size={17} fill="currentColor" stroke={Palette.elevated} strokeWidth={1.6} />
      </div>
      <span style={{ fontSize: 13, lineHeight: "18px", fontWeight: 500 }}>{ctx.t(row.title[0], row.title[1])}</span>
      <span style={{ flex: 1 }} />
      <span style={{ fontFamily: fonts.text, fontSize: 13, lineHeight: "18px", fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>{row.value}</span>
    </div>
  );
}
