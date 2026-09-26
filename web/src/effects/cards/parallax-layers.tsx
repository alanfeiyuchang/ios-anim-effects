/** cards.parallax-layers · 分层视差卡片 (Cards+ParallaxLayers.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { DemoHint, black, clamp, fonts, spring, useClock, usePan, white, type DemoProps } from "../../kit";
import { Stage, StrokeBorder, persp, useMV } from "./shared";

const W = 240;
const H = 300;
const STARS = [
  [-90, -120], [-30, -135], [40, -110], [95, -128], [-60, -85], [70, -80], [10, -95],
];

export default function ParallaxLayers({ ctx }: DemoProps) {
  const px = useMotionValue(0);
  const py = useMotionValue(0);
  const [touched, setTouched] = useState(false);
  const touchedRef = useRef(false);
  const held = useRef(false);

  useClock(!touched, ctx.isPreview ? 30 : undefined);
  const sway = (t: number) => {
    const amount = ctx.isPreview ? 1 : 0.6;
    return { x: Math.sin(t * 0.8) * 0.9 * amount, y: Math.cos(t * 1.1) * 0.5 * amount };
  };
  const x = useMV(px);
  const y = useMV(py);
  const point = touched ? { x, y } : sway(Date.now() / 1000);

  const pan = usePan({
    onChange: ({ location }) => {
      held.current = true;
      if (!touchedRef.current) {
        const s = sway(Date.now() / 1000);
        px.jump(s.x);
        py.jump(s.y);
        touchedRef.current = true;
        setTouched(true);
      }
      const t = spring(0.3, 0.85);
      animate(px, clamp((location.x / W - 0.5) * 2, -1, 1), t);
      animate(py, clamp((location.y / H - 0.5) * 2, -1, 1), t);
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      const t = spring(ctx.n("response"), 0.7);
      animate(px, 0, t);
      animate(py, 0, t);
    },
  });

  const amount = ctx.n("depth");
  const tilt = ctx.n("tilt");
  const response = ctx.n("response");
  const p = persp(W, H, 0.5);
  const layer = (depth: number, children: ReactNode, style?: CSSProperties) => (
    <Layer depth={depth} x={-point.x * amount * depth} y={-point.y * amount * depth} response={response} style={style}>
      {children}
    </Layer>
  );

  return (
    <Stage gap={18}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: W, height: H, cursor: "grab" }}>
        <div style={{ position: "absolute", inset: 0, filter: `drop-shadow(${-point.x * 12}px 16px 24px rgb(91 59 255 / 0.3))` }}>
          <div style={{ position: "absolute", inset: 0, transform: `${p} rotateY(${point.x * tilt}deg)` }}>
            <div style={{ position: "absolute", inset: 0, transform: `${p} rotateX(${-point.y * tilt}deg)` }}>
              <div style={{ position: "absolute", inset: 0, borderRadius: 28, overflow: "hidden" }}>
                <div style={{ position: "absolute", inset: 0, transform: "scale(1.15)", background: "linear-gradient(#2B2F77, #8A5CFF, #FF8A7A, #FFC58A)" }} />
                {layer(
                  0.1,
                  STARS.map(([sx, sy], i) => {
                    const size = i % 3 === 0 ? 3 : 2;
                    return (
                      <div
                        key={i}
                        style={{ position: "absolute", left: W / 2 + sx - size / 2, top: H / 2 + sy - size / 2, width: size, height: size, borderRadius: "50%", background: white(i % 2 === 0 ? 0.9 : 0.5) }}
                      />
                    );
                  }),
                )}
                {layer(
                  0.25,
                  <div
                    style={{
                      position: "absolute",
                      left: W / 2 - 32,
                      top: H / 2 - 32 + 10,
                      width: 64,
                      height: 64,
                      borderRadius: "50%",
                      background: "radial-gradient(circle 34px, #FFF3C4 2px, #FFB36B 34px)",
                      boxShadow: "0 0 24px rgb(255 179 107 / 0.8)",
                    }}
                  />,
                )}
                {layer(0.55, <Ridge heights={[0.35, 0.62, 0.42, 0.78, 0.5, 0.68, 0.38]} width={320} height={170} fill="rgb(107 79 216 / 0.75)" id="far" />)}
                {layer(0.9, <Ridge heights={[0.3, 0.5, 0.34, 0.58, 0.38, 0.52, 0.26]} width={330} height={156} fill="url(#pl-near)" id="near" drop={28} />)}
                {layer(
                  1.5,
                  <div
                    style={{
                      position: "absolute",
                      left: 20,
                      bottom: 24,
                      display: "flex",
                      flexDirection: "column",
                      gap: 4,
                      color: "#fff",
                      filter: `drop-shadow(0 4px 10px ${black(0.35)})`,
                    }}
                  >
                    <span style={{ fontFamily: fonts.rounded, fontSize: 26, fontWeight: 800, letterSpacing: 2, lineHeight: "31px" }}>{ctx.t("DOLOMITES", "多洛米蒂")}</span>
                    <span style={{ fontSize: 13, lineHeight: "18px", fontWeight: 600, opacity: 0.85 }}>{ctx.t("Alta Via 1 · 7 days", "高山一号线 · 7 天")}</span>
                  </div>,
                )}
              </div>
              <StrokeBorder radius={28} color={white(0.25)} />
            </div>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag the card" zh="拖动卡片" />
    </Stage>
  );
}

/** One depth layer: its offset follows the target on its own spring (`.animation(lag(depth), value: point)`). */
function Layer({ depth, x, y, response, style, children }: { depth: number; x: number; y: number; response: number; style?: CSSProperties; children: ReactNode }) {
  const mx = useMotionValue(x);
  const my = useMotionValue(y);
  useEffect(() => {
    const t = spring(response * (0.5 + 0.5 * depth), 0.7);
    const a = animate(mx, x, t);
    const b = animate(my, y, t);
    return () => {
      // A new target takes over the running animation (keeping its velocity), so nothing is stopped here.
      void a;
      void b;
    };
  }, [x, y, response, depth, mx, my]);
  return <motion.div style={{ position: "absolute", inset: 0, x: mx, y: my, ...style }}>{children}</motion.div>;
}

function Ridge({ heights, width, height, fill, id, drop = 0 }: { heights: number[]; width: number; height: number; fill: string; id: string; drop?: number }) {
  const steps = heights.length - 1;
  const pts = [`0,${height}`, ...heights.map((h, i) => `${(width * i) / steps},${height - height * h}`), `${width},${height}`].join(" ");
  return (
    <svg
      width={width}
      height={height}
      style={{ position: "absolute", left: (W - width) / 2, top: H - height + drop, overflow: "visible" }}
    >
      {id === "near" && (
        <defs>
          <linearGradient id="pl-near" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2={height}>
            <stop offset="0" stopColor="#2A1E5C" />
            <stop offset="1" stopColor="#120D2E" />
          </linearGradient>
        </defs>
      )}
      <polygon points={pts} fill={fill} />
    </svg>
  );
}
