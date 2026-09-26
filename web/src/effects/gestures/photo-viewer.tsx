/** gestures.photo-viewer · 照片查看缩放 (Gestures+PhotoViewer.swift) */
import { animate, motion, useMotionValue, type Transition } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, anim, black, clamp, fonts, rubberBand, spring, useAutoplay, useHaptics, type DemoProps, type Point } from "../../kit";
import { useScript } from "./_a-common";

const VW = 300;
const VH = 340;

// MARK: - Scene (a dusk mountain lake drawn from vector shapes)

function drawScene(c: CanvasRenderingContext2D, w: number, h: number) {
  const sky = c.createLinearGradient(0, 0, 0, h * 0.62);
  sky.addColorStop(0, "#1D2B64");
  sky.addColorStop(0.5, "#6B4EA8");
  sky.addColorStop(1, "#F8A488");
  c.fillStyle = sky;
  c.fillRect(0, 0, w, h);
  c.fillStyle = "rgb(255 255 255 / 0.85)";
  for (let i = 0; i < 24; i++) {
    const sx = (((i * 73) % 97) / 97) * w;
    const sy = (((i * 41) % 53) / 53) * h * 0.34;
    const r = i % 5 === 0 ? 1.1 : 0.6;
    c.beginPath();
    c.arc(sx, sy, r, 0, Math.PI * 2);
    c.fill();
  }
  c.fillStyle = "#FFE3A3";
  c.beginPath();
  c.arc(w * 0.62 + 22, h * 0.3 + 22, 22, 0, Math.PI * 2);
  c.fill();
  ridge(c, w, h, 0.5, [0.1, 0.34, 0.2, 0.4, 0.16], 0.22, "#7A6AB8");
  ridge(c, w, h, 0.6, [0.3, 0.1, 0.36, 0.14, 0.28, 0.08], 0.2, "#3E3A78");
  const top = h * 0.62;
  const lake = c.createLinearGradient(0, top, 0, h);
  lake.addColorStop(0, "#5A4E9A");
  lake.addColorStop(1, "#1B1F4B");
  c.fillStyle = lake;
  c.fillRect(0, top, w, h * 0.38);
  c.fillStyle = "rgb(255 227 163 / 0.5)";
  for (let i = 0; i < 6; i++) {
    const ly = top + 10 + i * 14;
    const lx = w * (0.55 + 0.05 * (i % 2));
    c.beginPath();
    c.roundRect(lx, ly, 40 - i * 5, 1.5, 0.75);
    c.fill();
  }
  c.fillStyle = "#14173A";
  for (let i = 0; i < 9; i++) {
    const tx = i * 36 + 8;
    const th = 26 + ((i * 7) % 5) * 5;
    const base = h * 0.63;
    c.beginPath();
    c.moveTo(tx, base - th);
    c.lineTo(tx + th * 0.32, base);
    c.lineTo(tx - th * 0.32, base);
    c.closePath();
    c.fill();
  }
  // Cabin
  const cx = w * 0.68;
  const cy = h * 0.63;
  c.fillStyle = "#2A1E3F";
  c.fillRect(cx, cy - 12, 18, 12);
  c.fillStyle = "#1A1230";
  c.beginPath();
  c.moveTo(cx - 2, cy - 12);
  c.lineTo(cx + 9, cy - 19);
  c.lineTo(cx + 20, cy - 12);
  c.closePath();
  c.fill();
  c.fillStyle = "#FFD27A";
  for (const dx of [3, 11]) c.fillRect(cx + dx, cy - 9, 3.5, 3.5);
  // Sign
  const sx = w * 0.3;
  const sy = h * 0.66;
  c.fillStyle = "#2A1E3F";
  c.fillRect(sx + 9, sy - 10, 1.2, 10);
  c.fillStyle = "#E9D8B4";
  c.beginPath();
  c.roundRect(sx, sy - 15, 20, 6, 1);
  c.fill();
  c.fillStyle = "#3A2A1A";
  c.font = `700 2.2px ${fonts.rounded}`;
  c.textAlign = "center";
  c.textBaseline = "middle";
  c.fillText("LAKE 2.4 km", sx + 10, sy - 12);
}

function ridge(c: CanvasRenderingContext2D, w: number, h: number, base: number, peaks: number[], height: number, color: string) {
  c.fillStyle = color;
  c.beginPath();
  c.moveTo(0, h * 0.64);
  peaks.forEach((peak, i) => c.lineTo((w * i) / Math.max(peaks.length - 1, 1), h * (base - height * peak * 2.2)));
  c.lineTo(w, h * 0.64);
  c.closePath();
  c.fill();
}

// MARK: - Transform math (offsets relative to the viewport centre)

const bounds = (s: number) => ({ x: Math.max((VW * s - VW) / 2, 0), y: Math.max((VH * s - VH) / 2, 0) });
const clampedOffset = (o: Point, s: number): Point => {
  const l = bounds(s);
  return { x: clamp(o.x, -l.x, l.x), y: clamp(o.y, -l.y, l.y) };
};
const refocused = (focal: Point, offset: Point, from: number, to: number): Point => {
  const ratio = to / Math.max(from, 0.01);
  return { x: focal.x - (focal.x - offset.x) * ratio, y: focal.y - (focal.y - offset.y) * ratio };
};

export default function PhotoViewer({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const canvas = useRef<HTMLCanvasElement>(null);
  const viewport = useRef<HTMLDivElement>(null);
  const scale = useMotionValue(1);
  const ox = useMotionValue(0);
  const oy = useMotionValue(0);
  const live = useRef({ pinch: 1, focal: { x: 0, y: 0 } as Point, pan: { x: 0, y: 0 } as Point, panning: false });
  const [shown, setShown] = useState(1);
  const maxZoom = ctx.n("maxZoom");
  const maxZoomRef = useRef(maxZoom);
  maxZoomRef.current = maxZoom;

  const display = useCallback(() => {
    const l = live.current;
    const s = scale.get();
    const raw = s * l.pinch;
    const mz = maxZoomRef.current;
    const shownScale = raw < 1 ? 1 - rubberBand(1 - raw, 0.35) : raw > mz ? mz + rubberBand(raw - mz, 0.8) : raw;
    const moved = refocused(l.focal, { x: ox.get(), y: oy.get() }, s, shownScale);
    moved.x += l.pan.x;
    moved.y += l.pan.y;
    const lim = bounds(shownScale);
    const band = (v: number, limit: number) => (v > limit ? limit + rubberBand(v - limit, 60) : v < -limit ? -limit + rubberBand(v + limit, 60) : v);
    return { scale: shownScale, offset: { x: band(moved.x, lim.x), y: band(moved.y, lim.y) } };
  }, [scale, ox, oy]);

  // Redraw the vector scene through the transform whenever anything changes (crisp at every zoom).
  const raf = useRef(0);
  const redraw = useCallback(() => {
    if (raf.current) return;
    raf.current = requestAnimationFrame(() => {
      raf.current = 0;
      const el = canvas.current;
      if (!el) return;
      const dpr = Math.max(2, window.devicePixelRatio || 1);
      if (el.width !== VW * dpr) {
        el.width = VW * dpr;
        el.height = VH * dpr;
      }
      const c = el.getContext("2d")!;
      const d = display();
      c.setTransform(dpr, 0, 0, dpr, 0, 0);
      c.clearRect(0, 0, VW, VH);
      c.translate(VW / 2 + d.offset.x, VH / 2 + d.offset.y);
      c.scale(d.scale, d.scale);
      c.translate(-VW / 2, -VH / 2);
      drawScene(c, VW, VH);
      setShown(Math.round(d.scale * 10) / 10);
    });
  }, [display]);
  useEffect(() => {
    redraw();
    const subs = [scale, ox, oy].map((mv) => mv.on("change", redraw));
    return () => {
      subs.forEach((u) => u());
      cancelAnimationFrame(raf.current);
      raf.current = 0;
    };
  }, [scale, ox, oy, redraw]);

  const setCommitted = (s: number, o: Point) => {
    scale.stop();
    ox.stop();
    oy.stop();
    scale.set(s);
    ox.set(o.x);
    oy.set(o.y);
  };
  const animateTo = (s: number, o: Point, t: Transition) => {
    animate(scale, s, t);
    animate(ox, o.x, t);
    animate(oy, o.y, t);
  };

  /** Bakes the live pinch into the committed transform, then springs back inside the limits. */
  const commit = () => {
    const l = live.current;
    const cur = display();
    setCommitted(cur.scale, cur.offset);
    l.pinch = 1;
    l.pan = { x: 0, y: 0 };
    l.focal = { x: 0, y: 0 };
    const target = clamp(cur.scale, 1, maxZoomRef.current);
    let offset = cur.offset;
    if (target !== cur.scale) offset = refocused({ x: 0, y: 0 }, offset, cur.scale, target);
    animateTo(target, clampedOffset(offset, target), spring(0.45, 0.85));
  };

  const endPan = (velocity: Point) => {
    const l = live.current;
    l.panning = false;
    const glide = ctx.n("glide");
    const landed = { x: ox.get() + l.pan.x + velocity.x * glide, y: oy.get() + l.pan.y + velocity.y * glide };
    const cur = display();
    const s = scale.get();
    setCommitted(s, cur.offset);
    l.pan = { x: 0, y: 0 };
    const target = clampedOffset(landed, s);
    const hitEdge = target.x !== landed.x || target.y !== landed.y;
    const t = hitEdge ? spring(0.45, 0.85) : anim.curve(0.15, 0.75, 0.3, 1, glide * 2.2);
    animate(ox, target.x, t);
    animate(oy, target.y, t);
  };

  const doubleTap = (at: Point, haptic = true) => {
    if (haptic) haptics.tap("light");
    const tap = { x: at.x - VW / 2, y: at.y - VH / 2 };
    const t = spring(0.4, 0.82);
    if (scale.get() > 1.05) animateTo(1, { x: 0, y: 0 }, t);
    else {
      const target = ctx.n("tapZoom");
      animateTo(target, clampedOffset(refocused(tap, { x: ox.get(), y: oy.get() }, scale.get(), target), target), t);
    }
  };

  // MARK: Pointers: one finger pans (once zoomed), two pinch, a quick double tap zooms.
  const pointers = useRef(new Map<number, Point>());
  const g = useRef({
    pinchStart: 0,
    down: { x: 0, y: 0 } as Point,
    moved: false,
    blockPan: false,
    last: { x: 0, y: 0 } as Point,
    lastTime: 0,
    velocity: { x: 0, y: 0 } as Point,
    lastTap: null as null | { t: number; p: Point },
  });
  const toLocal = (e: { clientX: number; clientY: number }): Point => {
    const el = viewport.current!;
    const rect = el.getBoundingClientRect();
    const k = rect.width / el.offsetWidth || 1;
    return { x: (e.clientX - rect.left) / k, y: (e.clientY - rect.top) / k };
  };
  const pair = () => {
    const [a, b] = [...pointers.current.values()];
    return { mid: { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 }, dist: Math.max(Math.hypot(b.x - a.x, b.y - a.y), 1) };
  };

  const onPointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    const p = toLocal(e);
    pointers.current.set(e.pointerId, p);
    const s = g.current;
    const l = live.current;
    if (pointers.current.size === 1) {
      s.down = p;
      s.moved = false;
      s.blockPan = false;
      s.last = p;
      s.lastTime = performance.now();
      s.velocity = { x: 0, y: 0 };
    } else if (pointers.current.size === 2) {
      script.cancel();
      if (l.panning) {
        // Fold the pan into the committed offset so nothing jumps.
        l.panning = false;
        setCommitted(scale.get(), { x: ox.get() + l.pan.x, y: oy.get() + l.pan.y });
        l.pan = { x: 0, y: 0 };
      }
      const { mid, dist } = pair();
      s.pinchStart = dist;
      s.moved = true;
      s.blockPan = true;
      l.focal = { x: mid.x - VW / 2, y: mid.y - VH / 2 };
      l.pinch = 1;
    }
  };

  const onPointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!pointers.current.has(e.pointerId)) return;
    const p = toLocal(e);
    pointers.current.set(e.pointerId, p);
    const s = g.current;
    const l = live.current;
    if (pointers.current.size >= 2) {
      l.pinch = pair().dist / s.pinchStart;
      redraw();
      return;
    }
    const now = performance.now();
    const dt = Math.max((now - s.lastTime) / 1000, 1 / 240);
    s.velocity = { x: s.velocity.x * 0.6 + ((p.x - s.last.x) / dt) * 0.4, y: s.velocity.y * 0.6 + ((p.y - s.last.y) / dt) * 0.4 };
    s.last = p;
    s.lastTime = now;
    const t = { x: p.x - s.down.x, y: p.y - s.down.y };
    if (Math.hypot(t.x, t.y) >= 10) s.moved = true;
    if (s.blockPan) return;
    if (!l.panning) {
      if (Math.hypot(t.x, t.y) < 10 || scale.get() <= 1.01) return;
      l.panning = true;
      script.cancel();
      const cur = display();
      setCommitted(scale.get(), cur.offset);
    }
    l.pan = t;
    redraw();
  };

  const onPointerUp = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!pointers.current.has(e.pointerId)) return;
    const p = toLocal(e);
    const before = pointers.current.size;
    pointers.current.delete(e.pointerId);
    const s = g.current;
    const l = live.current;
    if (before === 2) {
      commit();
      return;
    }
    if (before !== 1) return;
    if (l.panning) {
      if (performance.now() - s.lastTime > 80) s.velocity = { x: 0, y: 0 };
      endPan(e.type === "pointercancel" ? { x: 0, y: 0 } : s.velocity);
      return;
    }
    if (s.moved || e.type === "pointercancel") return;
    const now = performance.now() / 1000;
    const prev = s.lastTap;
    if (prev && now - prev.t < 0.3 && Math.hypot(p.x - prev.p.x, p.y - prev.p.y) < 30) {
      s.lastTap = null;
      script.cancel();
      doubleTap(p);
    } else s.lastTap = { t: now, p };
  };

  // Trackpad pinch (ctrl + wheel) zooms around the cursor.
  const wheelEnd = useRef(0);
  useEffect(() => {
    const el = viewport.current;
    if (!el) return;
    let wheel = 1;
    const onWheel = (e: WheelEvent) => {
      if (!e.ctrlKey) return;
      e.preventDefault();
      const l = live.current;
      if (l.pinch === 1 && wheel === 1) {
        script.cancel();
        const p = toLocal(e);
        l.focal = { x: p.x - VW / 2, y: p.y - VH / 2 };
      }
      wheel *= Math.exp(-e.deltaY * 0.01);
      l.pinch = wheel;
      redraw();
      window.clearTimeout(wheelEnd.current);
      wheelEnd.current = window.setTimeout(() => {
        wheel = 1;
        commit();
      }, 160);
    };
    el.addEventListener("wheel", onWheel, { passive: false });
    return () => {
      el.removeEventListener("wheel", onWheel);
      window.clearTimeout(wheelEnd.current);
    };
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      const l = live.current;
      if (l.panning || l.pinch !== 1) return;
      doubleTap({ x: 210, y: 210 }, false);
      script.cancel();
      script.after(1.0, () => {
        const target = clampedOffset({ x: ox.get() + 150, y: oy.get() + 60 }, scale.get());
        const t = anim.curve(0.15, 0.75, 0.3, 1, 0.8);
        animate(ox, target.x, t);
        animate(oy, target.y, t);
        script.after(1.1, () => {
          if (scale.get() > 1.05) doubleTap({ x: 150, y: 170 }, false);
        });
      });
    },
    { every: 3.4, delay: 0.4 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
      <div
        ref={viewport}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        style={{
          position: "relative",
          width: VW,
          height: VH,
          flexShrink: 0,
          borderRadius: 26,
          overflow: "hidden",
          boxShadow: `0 10px 18px ${black(0.16)}`,
          touchAction: "none",
          cursor: shown > 1.01 ? "grab" : "zoom-in",
        }}
      >
        <canvas ref={canvas} style={{ width: VW, height: VH, display: "block" }} />
        <motion.div
          initial={false}
          animate={{ opacity: shown > 1.02 ? 1 : 0 }}
          transition={anim.easeOut(0.2)}
          style={{
            position: "absolute",
            top: 12,
            right: 12,
            padding: "5px 9px",
            borderRadius: 999,
            background: black(0.35),
            color: "#fff",
            fontSize: 12,
            lineHeight: "16px",
            fontWeight: 600,
            pointerEvents: "none",
          }}
        >
          <NumericText value={shown} text={`${shown.toFixed(1)}×`} />
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Pinch, pan or double-tap" zh="捏合、平移或双击" />
    </div>
  );
}
