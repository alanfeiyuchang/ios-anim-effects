/** scroll.wheel-list · 滚轮列表 (Scroll+WheelList.swift) */
import { useRef, useState } from "react";
import { NumericText, Palette, black, clamp, fonts, spring, useAutoplay, type DemoProps } from "../../kit";
import { SnapMarkers, Sym, perspectivePx, strideSnap, useScroller, useSelectionTick } from "./_kit";

const CITIES: [string, string][] = [
  ["Tokyo", "东京"], ["Paris", "巴黎"], ["New York", "纽约"], ["London", "伦敦"],
  ["Shanghai", "上海"], ["Sydney", "悉尼"], ["Berlin", "柏林"], ["Seoul", "首尔"],
  ["Reykjavík", "雷克雅未克"], ["Lisbon", "里斯本"], ["Cairo", "开罗"], ["Toronto", "多伦多"],
  ["Dubai", "迪拜"], ["Rome", "罗马"],
];
const OFFSETS = [9, 1, -5, 0, 8, 10, 1, 9, 0, 0, 2, -5, 4, 1];
const ROW = 44;
const VIEWPORT = 264;
const INITIAL = 4;

export default function WheelList({ ctx }: DemoProps) {
  const count = CITIES.length;
  const [current, setCurrent] = useState(INITIAL);
  const direction = useRef(1);
  const scripted = useRef(false);
  const sc = useScroller({
    axis: "y",
    initial: INITIAL * ROW,
    snap: strideSnap(ROW),
    onScroll: (o) => setCurrent(clamp(Math.round(o / ROW), 0, count - 1)),
    onPhase: (p) => {
      if (p === "interacting") scripted.current = false;
    },
  });
  useSelectionTick(current, ctx.isPreview, scripted);

  const select = (i: number) => {
    scripted.current = false;
    sc.scrollTo(i * ROW, spring(0.45, 0.85));
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      scripted.current = true;
      if (current + direction.current * 2 >= count || current + direction.current * 2 < 0) direction.current = -direction.current;
      sc.scrollTo((current + direction.current * 2) * ROW, spring(0.6, 0.86));
    },
    { every: 1.3 },
  );

  const curve = ctx.n("curve");
  const fade = ctx.n("fade");
  const pad = (VIEWPORT - ROW) / 2;
  const mask = `linear-gradient(transparent, ${black(1)} 22%, ${black(1)} 78%, transparent)`;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <ZoneChip offset={OFFSETS[current]} />
      <div style={{ position: "relative", width: 340, height: VIEWPORT, flexShrink: 0 }}>
        <div
          style={{
            position: "absolute",
            left: 28,
            right: 28,
            top: pad,
            height: ROW,
            borderRadius: 12,
            background: Palette.labelAlpha(0.06),
            boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
          }}
        />
        <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0, WebkitMaskImage: mask, maskImage: mask }}>
          <div ref={sc.contentRef} style={{ position: "relative", padding: `${pad}px 0` }}>
            <SnapMarkers count={count} pitch={ROW} axis="y" />
            {CITIES.map((city, i) => {
              const t = clamp((i * ROW - sc.offset) / (VIEWPORT / 2), -1, 1);
              const on = current === i;
              return (
                <div
                  key={i}
                  onClick={() => select(i)}
                  style={{
                    height: ROW,
                    display: "grid",
                    placeItems: "center",
                    fontFamily: fonts.rounded,
                    fontSize: 22,
                    fontWeight: on ? 600 : 400,
                    color: on ? Palette.label : Palette.secondaryLabel,
                    whiteSpace: "nowrap",
                    cursor: "pointer",
                    transform: `scale(${1 - Math.abs(t) * 0.12}) perspective(${perspectivePx(340, ROW, 0.5)}px) rotateX(${-t * curve}deg)`,
                    opacity: 1 - Math.abs(t) * fade,
                  }}
                >
                  {ctx.lang === "zh" ? city[1] : city[0]}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

/** "UTC+9 · 21:00": the selected city's offset and its local time at 12:00 UTC. */
function ZoneChip({ offset }: { offset: number }) {
  const zone = offset === 0 ? "UTC±0" : offset > 0 ? `UTC+${offset}` : `UTC−${-offset}`;
  const time = `${String((12 + offset + 24) % 24).padStart(2, "0")}:00`;
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 6,
        padding: "6px 12px",
        borderRadius: 999,
        background: Palette.labelAlpha(0.06),
        fontSize: 15,
        lineHeight: "20px",
        fontWeight: 600,
        flexShrink: 0,
      }}
    >
      <span style={{ color: "#8C74FF", display: "grid" }}>
        <Sym name="globe" size={15} weight={600} />
      </span>
      <NumericText value={offset} text={zone} />
      <span style={{ color: Palette.tertiaryLabel }}>·</span>
      <NumericText value={offset} text={time} style={{ color: Palette.secondaryLabel }} />
    </div>
  );
}
