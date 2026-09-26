/** gestures.magnifier-loupe · 放大镜 (Gestures+MagnifierLoupe.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, clamp, demoCard, fonts, glass, spring, useAutoplay, useHaptics, useLatest, type DemoProps, type Point } from "../../kit";
import { useScript } from "./_a-common";

const COLUMNS = 12;
const ROWS = 9;
const SIZE = { w: 300, h: 225 };
const CELL = SIZE.w / COLUMNS;

function hsbToRGB(h: number, s: number, v: number): [number, number, number] {
  const scaled = (h - Math.floor(h)) * 6;
  const sector = Math.floor(scaled) % 6;
  const f = scaled - Math.floor(scaled);
  const p = v * (1 - s);
  const q = v * (1 - f * s);
  const t = v * (1 - (1 - f) * s);
  switch (sector) {
    case 0: return [v, t, p];
    case 1: return [q, v, p];
    case 2: return [p, v, t];
    case 3: return [p, q, v];
    case 4: return [t, p, v];
    default: return [v, p, q];
  }
}

function components(column: number, row: number) {
  const hue = column / COLUMNS;
  const saturation = 0.45 + (0.5 * row) / (ROWS - 1);
  const brightness = 1 - (0.55 * row) / (ROWS - 1);
  return hsbToRGB(hue, saturation, brightness).map((c) => Math.round(c * 255));
}
const cellColor = (c: number, r: number) => {
  const [R, G, B] = components(c, r);
  return `rgb(${R} ${G} ${B})`;
};
const cellHex = (c: number, r: number) => "#" + components(c, r).map((v) => v.toString(16).toUpperCase().padStart(2, "0")).join("");

function cellIndex(p: Point) {
  return { column: clamp(Math.floor(p.x / CELL), 0, COLUMNS - 1), row: clamp(Math.floor(p.y / CELL), 0, ROWS - 1) };
}

/** `SwatchScene.draw`: rounded swatches with their 3 pt hex labels. */
function drawScene(ctx: CanvasRenderingContext2D, visible?: { x: number; y: number; w: number; h: number }) {
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.font = `600 3px ${fonts.mono}`;
  for (let row = 0; row < ROWS; row++) {
    for (let column = 0; column < COLUMNS; column++) {
      const x = column * CELL + 1.5;
      const y = row * CELL + 1.5;
      const s = CELL - 3;
      if (visible && (x > visible.x + visible.w || x + s < visible.x || y > visible.y + visible.h || y + s < visible.y)) continue;
      ctx.fillStyle = cellColor(column, row);
      ctx.beginPath();
      ctx.roundRect(x, y, s, s, 4);
      ctx.fill();
      ctx.fillStyle = "rgb(255 255 255 / 0.9)";
      ctx.fillText(cellHex(column, row), x + s / 2, y + s - 3.5);
    }
  }
}

function SceneCanvas() {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const dpr = Math.max(2, window.devicePixelRatio || 1) * 1.5;
    el.width = SIZE.w * dpr;
    el.height = SIZE.h * dpr;
    const c = el.getContext("2d")!;
    c.scale(dpr, dpr);
    drawScene(c);
  }, []);
  return <canvas ref={ref} style={{ width: SIZE.w, height: SIZE.h, display: "block" }} />;
}

export default function MagnifierLoupe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const tuck = useScript();
  const px = useMotionValue(150);
  const py = useMotionValue(110);
  const [point, setPoint] = useState<Point>({ x: 150, y: 110 });
  useMotionValueEvent(px, "change", (x) => setPoint((p) => ({ ...p, x })));
  useMotionValueEvent(py, "change", (y) => setPoint((p) => ({ ...p, y })));
  const [active, setActive] = useState<{ on: boolean; t: ReturnType<typeof spring> }>({ on: false, t: spring(0.3, 0.7) });
  const st = useRef({ touching: false, pending: 0, last: { x: 0, y: 0 } as Point, down: null as null | { id: number; start: Point; client: Point; scale: number } });
  const s = st.current;
  const activeRef = useLatest(active.on);

  useEffect(() => {
    if (ctx.isPreview) setActive({ on: true, t: spring(0.3, 0.7) });
  }, [ctx.isPreview]);
  useEffect(() => () => window.clearTimeout(s.pending), [s]);

  const pressChanged = (location: Point) => {
    if (!s.touching) {
      s.touching = true;
      tuck.cancel();
    }
    px.stop();
    py.stop();
    px.set(clamp(location.x, 0, SIZE.w));
    py.set(clamp(location.y, 0, SIZE.h));
    if (!activeRef.current) {
      setActive({ on: true, t: spring(0.3, 0.7) });
      haptics.tap("light");
    }
  };
  const endHold = () => {
    window.clearTimeout(s.pending);
    s.down = null;
    if (!s.touching) return;
    s.touching = false;
    setActive({ on: false, t: spring(0.3, 0.85) });
  };

  const locate = (e: React.PointerEvent) => {
    const d = s.down!;
    return { x: d.start.x + (e.clientX - d.client.x) / d.scale, y: d.start.y + (e.clientY - d.client.y) / d.scale };
  };
  const onPointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    if (s.down) return;
    const el = e.currentTarget;
    el.setPointerCapture(e.pointerId);
    const rect = el.getBoundingClientRect();
    const scale = rect.width / el.offsetWidth || 1;
    s.down = { id: e.pointerId, client: { x: e.clientX, y: e.clientY }, start: { x: (e.clientX - rect.left) / scale, y: (e.clientY - rect.top) / scale }, scale };
    s.last = s.down.start;
    s.pending = window.setTimeout(() => pressChanged(s.last), 200);
  };
  const onPointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!s.down || s.down.id !== e.pointerId) return;
    const p = locate(e);
    if (s.touching) pressChanged(p);
    else if (Math.hypot(p.x - s.down.start.x, p.y - s.down.start.y) > 10) {
      window.clearTimeout(s.pending);
      s.down = null;
    } else s.last = p;
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (s.touching) return;
      if (!activeRef.current) setActive({ on: true, t: spring(0.3, 0.7) });
      animate(px, 30 + Math.random() * (SIZE.w - 60), spring(0.7, 0.82));
      animate(py, 40 + Math.random() * (SIZE.h - 60), spring(0.7, 0.82));
      if (ctx.isPreview) return;
      tuck.cancel();
      tuck.after(1.2, () => {
        if (!s.touching) setActive({ on: false, t: spring(0.3, 0.85) });
      });
    },
    { every: 1.0, delay: 0.3 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ ...demoCard(24), padding: 10, flexShrink: 0 }}>
        <div
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={endHold}
          onPointerCancel={endHold}
          style={{ position: "relative", width: SIZE.w, height: SIZE.h, touchAction: "none", cursor: "crosshair" }}
        >
          <SceneCanvas />
          <Loupe x={point.x} y={point.y} zoom={ctx.n("zoom")} diameter={ctx.n("size")} visible={active.on} transition={active.t} />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Touch and hold, then drag" zh="按住后拖动" />
    </div>
  );
}

const CAPSULE_H = 21;

function Loupe({ x, y, zoom, diameter, visible, transition }: { x: number; y: number; zoom: number; diameter: number; visible: boolean; transition: ReturnType<typeof spring> }) {
  const lensRef = useRef<HTMLCanvasElement>(null);
  const half = diameter / 2;
  const lift = half + 28;
  const above = y - lift;
  const flipped = above < half;
  const centerY = flipped ? y + lift : above;
  const lensX = clamp(x, Math.min(half, SIZE.w / 2), Math.max(SIZE.w - half, SIZE.w / 2));
  const cell = cellIndex({ x, y });
  const stackH = diameter + 8 + CAPSULE_H;
  const top = centerY + 16 - stackH / 2;

  useEffect(() => {
    const el = lensRef.current;
    if (!el) return;
    const dpr = Math.max(2, window.devicePixelRatio || 1) * 1.5;
    const px = Math.round(diameter * dpr);
    if (el.width !== px) {
      el.width = px;
      el.height = px;
    }
    const c = el.getContext("2d")!;
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    c.clearRect(0, 0, diameter, diameter);
    c.translate(diameter / 2 - zoom * x, diameter / 2 - zoom * y);
    c.scale(zoom, zoom);
    const reach = diameter / 2 / Math.max(zoom, 0.1) + CELL;
    drawScene(c, { x: x - reach, y: y - reach, w: reach * 2, h: reach * 2 });
  }, [x, y, zoom, diameter]);

  return (
    <motion.div
      initial={false}
      animate={{ scale: visible ? 1 : 0.4, opacity: visible ? 1 : 0 }}
      transition={transition}
      style={{
        position: "absolute",
        left: lensX - 80,
        top,
        width: 160,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 8,
        pointerEvents: "none",
        originY: flipped ? 0 : 1,
      }}
    >
      <div style={{ position: "relative", width: diameter, height: diameter, borderRadius: "50%", boxShadow: `0 8px 14px ${black(0.28)}`, flexShrink: 0 }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", overflow: "hidden", background: Palette.surface }}>
          <canvas ref={lensRef} style={{ width: diameter, height: diameter, display: "block" }} />
        </div>
        <div style={{ position: "absolute", left: "50%", top: "50%", width: 1, height: 14, margin: "-7px 0 0 -0.5px", background: "#fff", boxShadow: `0 0 1px ${black(0.5)}` }} />
        <div style={{ position: "absolute", left: "50%", top: "50%", width: 14, height: 1, margin: "-0.5px 0 0 -7px", background: "#fff", boxShadow: `0 0 1px ${black(0.5)}` }} />
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: "inset 0 0 0 3px #fff" }} />
      </div>
      <div
        style={{
          height: CAPSULE_H,
          display: "flex",
          alignItems: "center",
          gap: 6,
          padding: "0 8px",
          borderRadius: 999,
          ...glass("regular"),
          fontFamily: fonts.mono,
          fontSize: 11,
          fontWeight: 600,
          whiteSpace: "nowrap",
        }}
      >
        <span style={{ width: 10, height: 10, borderRadius: "50%", background: cellColor(cell.column, cell.row) }} />
        {cellHex(cell.column, cell.row)}
      </div>
    </motion.div>
  );
}
