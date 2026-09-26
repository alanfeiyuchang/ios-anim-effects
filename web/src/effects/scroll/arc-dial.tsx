/** scroll.arc-dial · 弧形转盘选择器 (Scroll+ArcDial.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useRef, useState } from "react";
import { Palette, alpha, black, clamp, spring, useAutoplay, white, type DemoProps } from "../../kit";
import { FadeText, SnapMarkers, Sym, strideSnap, useScroller, useSelectionTick } from "./_kit";

interface Filter {
  name: [string, string];
  symbol: string;
  colors: [string, string];
}

const FILTERS: Filter[] = [
  { name: ["Vivid", "鲜明"], symbol: "sun.max.fill", colors: [Palette.amber, Palette.coral] },
  { name: ["Warm", "暖调"], symbol: "flame.fill", colors: [Palette.coral, Palette.pink] },
  { name: ["Dream", "梦境"], symbol: "cloud.fill", colors: [Palette.pink, Palette.violet] },
  { name: ["Dusk", "暮色"], symbol: "moon.stars.fill", colors: [Palette.violet, Palette.indigo] },
  { name: ["Cool", "冷调"], symbol: "snowflake", colors: [Palette.sky, Palette.blue] },
  { name: ["Fresh", "清新"], symbol: "leaf.fill", colors: [Palette.mint, Palette.sky] },
  { name: ["Mono", "黑白"], symbol: "circle.lefthalf.filled", colors: ["#8E93A6", "#2B2F45"] },
  { name: ["Neon", "霓虹"], symbol: "bolt.fill", colors: [Palette.mint, Palette.violet] },
  { name: ["Film", "胶片"], symbol: "film.fill", colors: ["#E9C98A", "#6E4B2A"] },
];

const SIDE = 64;
const SPACING = 18;
const PITCH = SIDE + SPACING;
const WIDTH = 340;
const INITIAL = 3;

export default function ArcDial({ ctx }: DemoProps) {
  const count = FILTERS.length;
  const [current, setCurrent] = useState(INITIAL);
  const direction = useRef(1);
  const scripted = useRef(false);
  const sc = useScroller({
    axis: "x",
    initial: INITIAL * PITCH,
    snap: strideSnap(PITCH),
    onScroll: (o) => setCurrent(clamp(Math.round(o / PITCH), 0, count - 1)),
    onPhase: (p) => {
      if (p === "interacting") scripted.current = false;
    },
  });
  useSelectionTick(current, ctx.isPreview, scripted);

  const select = (i: number) => {
    scripted.current = false;
    sc.scrollTo(i * PITCH, spring(0.5, 0.86));
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      scripted.current = true;
      if (current + direction.current >= count || current + direction.current < 0) direction.current = -direction.current;
      sc.scrollTo((current + direction.current) * PITCH, spring(0.55, 0.86));
    },
    { every: 1.2 },
  );

  const zh = ctx.lang === "zh";
  const filter = FILTERS[current];
  const step = (ctx.n("curve") * Math.PI) / 180;
  // Radius chosen so neighbouring items keep their spacing along the arc.
  const radius = step > 0.001 ? PITCH / Math.sin(step) : 0;
  const focus = ctx.n("focus");
  const tilt = ctx.b("tilt");
  const pad = (WIDTH - SIDE) / 2;
  const contentWidth = pad * 2 + count * SIDE + (count - 1) * SPACING;
  const ring = SIDE * focus + 12;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <Preview filter={filter} zh={zh} />
      <div style={{ position: "relative", width: WIDTH, height: 132, flexShrink: 0 }}>
        <div
          style={{
            position: "absolute",
            left: (WIDTH - ring) / 2,
            top: (132 - ring) / 2 - 12,
            width: ring,
            height: ring,
            borderRadius: "50%",
            boxShadow: `inset 0 0 0 1.5px ${Palette.labelAlpha(0.35)}`,
          }}
        />
        <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
          <div ref={sc.contentRef} style={{ position: "relative", width: contentWidth, height: 132 }}>
            <SnapMarkers count={count} pitch={PITCH} />
            {FILTERS.map((f, i) => {
              const t = (i * PITCH - sc.offset) / PITCH;
              const angle = t * step;
              const arcX = radius > 0 ? radius * Math.sin(angle) - t * PITCH : 0;
              const arcY = radius > 0 ? radius * (1 - Math.cos(angle)) : 0;
              const near = Math.max(1 - Math.abs(t), 0);
              return (
                <div
                  key={i}
                  onClick={() => select(i)}
                  style={{
                    position: "absolute",
                    left: pad + i * PITCH,
                    top: (132 - SIDE) / 2,
                    width: SIDE,
                    height: SIDE,
                    borderRadius: "50%",
                    cursor: "pointer",
                    background: `linear-gradient(135deg, ${f.colors[0]}, ${f.colors[1]})`,
                    boxShadow: `inset 0 0 0 1px ${white(0.35)}, 0 4px 8px ${black(0.14)}`,
                    color: "#fff",
                    display: "grid",
                    placeItems: "center",
                    transform: `translate(${arcX}px, ${arcY - 12}px) rotate(${tilt ? angle : 0}rad) scale(${1 - Math.min(Math.abs(t), 3) * 0.1 + (focus - 1) * near})`,
                    opacity: 1 - clamp(Math.abs(t) - 2, 0, 1),
                  }}
                >
                  <Sym name={f.symbol} size={SIDE * 0.36} weight={600} />
                </div>
              );
            })}
          </div>
        </div>
      </div>
      <FadeText text={zh ? filter.name[1] : filter.name[0]} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }} />
    </div>
  );
}

/** The "viewfinder" above the dial, tinted by the selected filter. */
function Preview({ filter, zh }: { filter: Filter; zh: boolean }) {
  return (
    <motion.div
      animate={{ boxShadow: `0 8px 16px ${alpha(filter.colors[0], 0.3)}` }}
      transition={spring(0.5, 0.85)}
      style={{ position: "relative", width: 280, height: 118, borderRadius: 22, flexShrink: 0 }}
    >
      <div style={{ position: "absolute", inset: 0, borderRadius: 22, overflow: "hidden" }}>
        <AnimatePresence initial={false}>
          <motion.div
            key={filter.name[0]}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={spring(0.5, 0.85)}
            style={{ position: "absolute", inset: 0, background: `linear-gradient(135deg, ${filter.colors[0]}, ${filter.colors[1]})` }}
          />
        </AnimatePresence>
        {/* mountain.2.fill */}
        <svg viewBox="0 0 38 26" width={76} height={52} style={{ position: "absolute", left: 16, bottom: -6 }}>
          <path d="M1 26 L13 6.5 Q14 5 15 6.5 L20.5 15 L24.5 9 Q25.5 7.6 26.5 9 L37 26 Z" fill={white(0.3)} />
        </svg>
        <div style={{ position: "absolute", right: 18, top: 18, width: 26, height: 26, borderRadius: "50%", background: white(0.5), filter: "blur(1.5px)" }} />
        <div
          style={{
            position: "absolute",
            left: 12,
            top: 12,
            display: "flex",
            alignItems: "center",
            gap: 5,
            padding: "5px 10px",
            borderRadius: 999,
            background: black(0.18),
            color: "#fff",
            fontSize: 12,
            lineHeight: "16px",
            fontWeight: 700,
          }}
        >
          <Sym name="camera.filters" size={12} weight={700} />
          <FadeText text={zh ? filter.name[1] : filter.name[0]} />
        </div>
      </div>
    </motion.div>
  );
}
