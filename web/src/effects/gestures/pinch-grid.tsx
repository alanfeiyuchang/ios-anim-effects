/** gestures.pinch-grid · 捏合切换网格密度 (Gestures+PinchGrid.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { Camera, Cloud, Droplet, Flame, Grid3x3, Leaf, MoonStar, Star, Sun, type LucideIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, clamp, delayed, rubberBand, spring, useAutoplay, useHaptics, type DemoProps, type Point } from "../../kit";
import { useScript } from "./_a-common";

const TILES = 16;
const SIDE = 288;
const GUTTER = 6;
const SYMBOLS: [LucideIcon, boolean][] = [
  [Leaf, true],
  [Sun, true],
  [MoonStar, true],
  [Cloud, true],
  [Flame, true],
  [Droplet, true],
  [Camera, false],
  [Star, true],
];

export default function PinchGrid({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const [columns, setColumns] = useState(3);
  const columnsRef = useRef(3);
  const live = useMotionValue(1);
  const [anchor, setAnchor] = useState<Point>({ x: 0.5, y: 0.5 });
  const zoomingIn = useRef(true);
  const held = useRef(false);
  const frame = useRef<HTMLDivElement>(null);
  const pointers = useRef(new Map<number, Point>());
  const pinch = useRef<{ d0: number } | null>(null);
  const lastTap = useRef<{ t: number; p: Point } | null>(null);
  const moved = useRef(false);

  const commit = (target: number, haptic = true) => {
    const next = clamp(target, 2, 4);
    const changed = next !== columnsRef.current;
    animate(live, 1, spring(ctx.n("response"), 0.8));
    columnsRef.current = next;
    setColumns(next);
    if (changed && haptic) haptics.tap("medium");
  };
  const cycle = () => commit(columnsRef.current === 2 ? 4 : columnsRef.current - 1);

  const change = (magnification: number, startAnchor?: Point) => {
    if (!held.current) {
      held.current = true;
      script.cancel();
      live.stop();
    }
    if (startAnchor) setAnchor(startAnchor);
    live.set(1 + rubberBand(magnification - 1, 0.25, 1));
  };
  const end = (magnification: number) => {
    if (!held.current) return;
    held.current = false;
    if (magnification > 1.15) commit(columnsRef.current - 1);
    else if (magnification < 0.87) commit(columnsRef.current + 1);
    else animate(live, 1, spring(0.35, 0.75));
  };

  const local = (p: Point): Point => {
    const el = frame.current!;
    const r = el.getBoundingClientRect();
    return { x: clamp((p.x - r.left) / r.width), y: clamp((p.y - r.top) / r.height) };
  };
  const pair = () => {
    const [a, b] = [...pointers.current.values()];
    return { mid: { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 }, d: Math.max(Math.hypot(b.x - a.x, b.y - a.y), 1) };
  };
  const magnification = useRef(1);

  const onDown = (e: React.PointerEvent<HTMLDivElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pointers.current.size === 1) moved.current = false;
    if (pointers.current.size === 2) {
      const { mid, d } = pair();
      pinch.current = { d0: d };
      moved.current = true;
      magnification.current = 1;
      change(1, local(mid));
    }
  };
  const onMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!pointers.current.has(e.pointerId)) return;
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pinch.current && pointers.current.size >= 2) {
      magnification.current = pair().d / pinch.current.d0;
      change(magnification.current);
    }
  };
  const onUp = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!pointers.current.has(e.pointerId)) return;
    pointers.current.delete(e.pointerId);
    if (pinch.current) {
      if (pointers.current.size < 2) {
        pinch.current = null;
        if (e.type === "pointercancel") {
          held.current = false;
          animate(live, 1, spring(0.35, 0.75));
        } else end(magnification.current);
      }
      return;
    }
    if (moved.current || e.type === "pointercancel") return;
    const now = performance.now() / 1000;
    const p = { x: e.clientX, y: e.clientY };
    const prev = lastTap.current;
    if (prev && now - prev.t < 0.3 && Math.hypot(p.x - prev.p.x, p.y - prev.p.y) < 30) {
      lastTap.current = null;
      cycle();
    } else lastTap.current = { t: now, p };
  };

  // Trackpad pinch (ctrl + wheel).
  useEffect(() => {
    const el = frame.current;
    if (!el) return;
    let wheel = 1;
    let timer = 0;
    const onWheel = (e: WheelEvent) => {
      if (!e.ctrlKey) return;
      e.preventDefault();
      const first = !held.current;
      if (first) wheel = 1;
      wheel *= Math.exp(-e.deltaY * 0.01);
      change(wheel, first ? local({ x: e.clientX, y: e.clientY }) : undefined);
      window.clearTimeout(timer);
      timer = window.setTimeout(() => end(wheel), 160);
    };
    el.addEventListener("wheel", onWheel, { passive: false });
    return () => {
      el.removeEventListener("wheel", onWheel);
      window.clearTimeout(timer);
    };
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (held.current) return;
      if (columnsRef.current === 2) zoomingIn.current = false;
      if (columnsRef.current === 4) zoomingIn.current = true;
      setAnchor({ x: 0.3 + Math.random() * 0.4, y: 0.3 + Math.random() * 0.4 });
      animate(live, zoomingIn.current ? 1.16 : 0.86, anim.easeInOut(0.35));
      script.cancel();
      script.after(0.4, () => commit(zoomingIn.current ? columnsRef.current - 1 : columnsRef.current + 1, false));
    },
    { every: 2.0, delay: 0.6 },
  );

  const tile = (SIDE - GUTTER * (columns - 1)) / columns;
  const stagger = ctx.n("stagger");
  const tileSpring = spring(ctx.n("response"), 0.8);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 6,
          padding: "7px 14px",
          borderRadius: 999,
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
          fontSize: 15,
          lineHeight: "20px",
          fontWeight: 600,
        }}
      >
        <Grid3x3 size={15} strokeWidth={2.6} />
        <NumericText value={columns} />
        <span>{ctx.t("columns", "列")}</span>
      </div>
      <div
        ref={frame}
        onPointerDown={onDown}
        onPointerMove={onMove}
        onPointerUp={onUp}
        onPointerCancel={onUp}
        style={{ position: "relative", width: SIDE, height: SIDE, flexShrink: 0, borderRadius: 28, overflow: "hidden", touchAction: "none", cursor: "zoom-in" }}
      >
        <motion.div style={{ position: "absolute", inset: 0, scale: live, originX: anchor.x, originY: anchor.y }}>
          {Array.from({ length: TILES }, (_, index) => {
            const column = index % columns;
            const row = Math.floor(index / columns);
            const colors = Palette.spectrum;
            const a = colors[index % colors.length];
            const b = colors[(index + 2) % colors.length];
            const [Icon, filled] = SYMBOLS[index % SYMBOLS.length];
            const t = delayed(tileSpring, index * stagger);
            return (
              <motion.div
                key={index}
                initial={false}
                animate={{ x: column * (tile + GUTTER), y: row * (tile + GUTTER), width: tile, height: tile }}
                transition={t}
                style={{
                  position: "absolute",
                  left: 0,
                  top: 0,
                  borderRadius: 10,
                  background: `linear-gradient(135deg, ${a}, ${b})`,
                  display: "grid",
                  placeItems: "center",
                  color: "rgb(255 255 255 / 0.9)",
                }}
              >
                <motion.div initial={false} animate={{ scale: tile / 96 }} transition={t} style={{ display: "grid" }}>
                  <Icon size={30} strokeWidth={filled ? 1.6 : 2.2} fill={filled ? "currentColor" : "none"} />
                </motion.div>
              </motion.div>
            );
          })}
        </motion.div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 28, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Pinch the grid, or double-tap" zh="捏合网格，或双击" />
    </div>
  );
}
