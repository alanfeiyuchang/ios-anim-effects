/** navigation.spotlight-tab · 聚光灯标签 (Navigation+SpotlightTab.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, black, ease, fonts, hex, mix, progress, spring, springAt, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { useSince } from "./groupA-kit";

const TABS: [string, string][] = [
  ["Live", "直播"],
  ["Music", "音乐"],
  ["Talks", "讲座"],
  ["Kids", "少儿"],
];
const STAGE_W = 300;
const STAGE_H = 210;
const PIVOT_Y = 26;
const FLOOR_Y = 176;
const WARM = 0xffe3a3;

const tabX = (index: number) => (index + 0.5) * (STAGE_W / TABS.length);
const beamAngle = (index: number) => (-Math.atan2(tabX(index) - STAGE_W / 2, FLOOR_Y - PIVOT_Y) * 180) / Math.PI;

export default function SpotlightTab({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(1);
  const response = ctx.n("response");

  const select = (index: number) => {
    if (index === selected) return;
    haptics.tap("soft");
    setSelected(index);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const next = selected === 0 ? 3 : selected === 3 ? 1 : selected === 1 ? 2 : 0;
      select(next);
    },
    { every: 1.5 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ width: STAGE_W, height: STAGE_H, borderRadius: 28, boxShadow: `0 10px 18px ${black(0.25)}`, flexShrink: 0 }}>
        <div
          style={{
            position: "relative",
            width: "100%",
            height: "100%",
            borderRadius: 28,
            overflow: "hidden",
            isolation: "isolate",
            background: `linear-gradient(180deg, ${hex(0x1b1a2e)}, ${hex(0x0d0c17)})`,
          }}
        >
          <FloorPool selected={selected} response={response} />
          {/* beam */}
          <motion.div
            initial={false}
            animate={{ rotate: beamAngle(selected) }}
            transition={spring(response, ctx.n("damping"))}
            style={{
              position: "absolute",
              left: STAGE_W / 2 - 60,
              top: PIVOT_Y,
              width: 120,
              height: 200,
              transformOrigin: "50% 0%",
              mixBlendMode: "screen",
              filter: "blur(3px)",
            }}
          >
            <BeamCone topWidth={12} bottomWidth={ctx.n("beam")} />
          </motion.div>
          {/* fixture */}
          <div style={{ position: "absolute", left: STAGE_W / 2 - 15, top: PIVOT_Y - 26, width: 30, display: "flex", flexDirection: "column", alignItems: "center" }}>
            <div style={{ width: 2, height: 14, background: white(0.25) }} />
            <div
              style={{
                position: "relative",
                width: 30,
                height: 14,
                borderRadius: 7,
                background: `linear-gradient(180deg, ${hex(0x5a5870)}, ${hex(0x2e2c3e)})`,
              }}
            >
              <div style={{ position: "absolute", left: 7, bottom: 0, width: 16, height: 3, borderRadius: 1.5, background: hex(WARM) }} />
            </div>
          </div>
          {/* labels */}
          <div style={{ position: "absolute", left: 0, top: FLOOR_Y - 34, width: STAGE_W, display: "flex" }}>
            {TABS.map(([en, zh], index) => {
              const lit = index === selected;
              const t = lit ? "0.3s ease-in-out 0.12s" : "0.3s ease-in-out";
              return (
                <div
                  key={index}
                  onClick={() => select(index)}
                  style={{
                    flex: 1,
                    height: 44,
                    display: "grid",
                    placeItems: "center",
                    cursor: "pointer",
                    fontFamily: fonts.text,
                    fontSize: 15,
                    lineHeight: "20px",
                    fontWeight: 700,
                    whiteSpace: "nowrap",
                    color: lit ? "#fff" : white(0.4),
                    textShadow: `0 0 8px ${hex(WARM, lit ? 0.9 : 0)}`,
                    transition: `color ${t}, text-shadow ${t}`,
                  }}
                >
                  {ctx.t(en, zh)}
                </div>
              );
            })}
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap a label" zh="点击任一标签" />
    </div>
  );
}

/** A trapezoid pointing down from its top edge's centre, filled warm → transparent. */
function BeamCone({ topWidth, bottomWidth }: { topWidth: number; bottomWidth: number }) {
  const w = 120;
  const h = 200;
  const m = w / 2;
  return (
    <svg width={w} height={h} style={{ overflow: "visible" }} aria-hidden>
      <defs>
        <linearGradient id="spotlight-beam" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={hex(WARM)} stopOpacity={0.75} />
          <stop offset="1" stopColor={hex(WARM)} stopOpacity={0.05} />
        </linearGradient>
      </defs>
      <path
        d={`M${m - topWidth / 2} 0 L${m + topWidth / 2} 0 L${m + bottomWidth / 2} ${h} L${m - bottomWidth / 2} ${h} Z`}
        fill="url(#spotlight-beam)"
      />
    </svg>
  );
}

/** The pool of light on the floor: slides under the lit label, narrowing on the way and widening as it lands. */
function FloorPool({ selected, response }: { selected: number; response: number }) {
  const travel = response * 0.7;
  const e = useSince(selected, 0.15 + travel + 0.4);
  let widen = 1;
  if (e >= 0) {
    if (e < 0.15) widen = mix(1, 0.85, ease.inOut(progress(e, 0, 0.15)));
    else if (e < 0.15 + travel) widen = mix(0.85, 1.12, ease.inOut(progress(e, 0.15, travel)));
    else if (e < 0.15 + travel + 0.4) widen = mix(1.12, 1, springAt(e - 0.15 - travel, 0.5, 1));
  }
  return (
    <motion.div
      initial={false}
      animate={{ x: tabX(selected) - 60 }}
      transition={spring(response * 1.3, 0.85)}
      style={{ position: "absolute", left: 0, top: FLOOR_Y - 17, width: 120, height: 34 }}
    >
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: "50%",
          background: `radial-gradient(circle 60px at 50% 50%, ${hex(WARM, 0.55)}, ${hex(WARM, 0)})`,
          filter: "blur(4px)",
          transform: `scaleX(${widen})`,
        }}
      />
    </motion.div>
  );
}

