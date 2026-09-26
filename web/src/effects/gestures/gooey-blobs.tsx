/** gestures.gooey-blobs · 黏液拖拽 (Gestures+GooeyBlobs.swift) */
import { useId, useRef, useState } from "react";
import { DemoHint, Palette, hex, useAutoplay, useHaptics, usePan, type DemoProps, type Point } from "../../kit";
import { useFrameLoop, useScript } from "./_a-common";

const AREA = 300;
const HOME = { x: 62, y: 0 };

/** Spring pair integrated per frame (the Swift `GooModel`). */
class GooModel {
  droplet = { ...HOME };
  dropletV = { x: 0, y: 0 };
  satellite = { ...HOME };
  satelliteV = { x: 0, y: 0 };
  target: Point = { ...HOME };

  get isSettled() {
    const still = (p: Point, v: Point) => Math.abs(p.x - HOME.x) < 0.3 && Math.abs(p.y - HOME.y) < 0.3 && Math.abs(v.x) < 0.5 && Math.abs(v.y) < 0.5;
    return this.target.x === HOME.x && this.target.y === HOME.y && still(this.droplet, this.dropletV) && still(this.satellite, this.satelliteV);
  }

  step(raw: number, response: number, damping: number) {
    const dt = Math.min(Math.max(raw, 0), 1 / 30);
    if (dt <= 0) return;
    const omega = (2 * Math.PI) / Math.max(response, 0.05);
    const stiffness = omega * omega;
    const friction = 2 * damping * omega;
    const h = dt / 4;
    for (let k = 0; k < 4; k++) {
      integrate(this.droplet, this.dropletV, this.target, stiffness, friction, h);
      integrate(this.satellite, this.satelliteV, this.droplet, stiffness * 0.45, friction * 0.7, h);
    }
  }
}

function integrate(p: Point, v: Point, goal: Point, stiffness: number, friction: number, h: number) {
  v.x += (stiffness * (goal.x - p.x) - friction * v.x) * h;
  v.y += (stiffness * (goal.y - p.y) - friction * v.y) * h;
  p.x += v.x * h;
  p.y += v.y * h;
}

export default function GooeyBlobs({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const model = useRef(new GooModel()).current;
  const [awake, setAwake] = useState(true);
  const held = useRef(false);
  const uid = useId().replace(/:/g, "");
  const goo = ctx.n("goo");

  useFrameLoop(
    (dt) => {
      model.step(dt, ctx.n("response"), ctx.n("damping"));
      if (!held.current && model.isSettled) setAwake(false);
    },
    awake,
    ctx.isPreview ? 30 : undefined,
  );

  const pan = usePan({
    onStart: ({ start }) => {
      const d = Math.hypot(start.x - (AREA / 2 + model.droplet.x), start.y - (AREA / 2 + model.droplet.y));
      if (d > 58) return;
      held.current = true;
      script.cancel();
    },
    onChange: ({ location }) => {
      if (!held.current) return;
      setAwake(true);
      const dx = location.x - AREA / 2;
      const dy = location.y - AREA / 2;
      const distance = Math.hypot(dx, dy);
      const scale = distance > 100 ? 100 / distance : 1;
      model.target = { x: dx * scale, y: dy * scale };
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      model.target = { ...HOME };
      setAwake(true);
      haptics.tap("soft");
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (held.current) return;
      setAwake(true);
      const angle = -0.8 + Math.random() * 1.6;
      model.target = { x: Math.cos(angle) * 100, y: Math.sin(angle) * 100 };
      script.cancel();
      script.after(0.75, () => {
        model.target = { ...HOME };
        setAwake(true);
      });
    },
    { every: 2.2, delay: 0.3 },
  );

  const blobs: [Point, number][] = [
    [{ x: 0, y: 0 }, 56],
    [model.droplet, 36],
    [model.satellite, 17],
  ];
  const c = AREA / 2;
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: AREA, height: AREA, cursor: "grab" }}>
        <svg width={AREA} height={AREA} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <defs>
            <filter id={`${uid}-glow`} x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation={18} />
            </filter>
            <filter id={`${uid}-goo`} x="-50%" y="-50%" width="200%" height="200%" colorInterpolationFilters="sRGB">
              <feGaussianBlur stdDeviation={goo} />
              <feComponentTransfer>
                <feFuncA type="linear" slope={24} intercept={-11.5} />
              </feComponentTransfer>
            </filter>
            <mask id={`${uid}-mask`} maskUnits="userSpaceOnUse" x={-AREA} y={-AREA} width={AREA * 3} height={AREA * 3}>
              <g filter={`url(#${uid}-goo)`}>
                {blobs.map(([p, r], i) => (
                  <circle key={i} cx={c + p.x} cy={c + p.y} r={r} fill="#fff" />
                ))}
              </g>
            </mask>
            <linearGradient id={`${uid}-grad`} x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Palette.mint} />
              <stop offset="0.5" stopColor={Palette.sky} />
              <stop offset="1" stopColor={Palette.violet} />
            </linearGradient>
          </defs>
          <g filter={`url(#${uid}-glow)`}>
            {blobs.map(([p, r], i) => (
              <circle key={i} cx={c + p.x} cy={c + 8 + p.y} r={r + 4} fill={hex(Palette.sky, 0.35)} />
            ))}
          </g>
          <rect x={0} y={0} width={AREA} height={AREA} fill={`url(#${uid}-grad)`} mask={`url(#${uid}-mask)`} />
        </svg>
      </div>
      <DemoHint ctx={ctx} en="Pull the droplet away" zh="把液滴拉出来" style={{ position: "absolute", left: 0, right: 0, bottom: 14 }} />
    </div>
  );
}
