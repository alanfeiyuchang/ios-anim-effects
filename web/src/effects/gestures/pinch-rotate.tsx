/** gestures.pinch-rotate · 双指缩放旋转 (Gestures+PinchRotate.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { Maximize2, RotateCw, Sun } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, clamp, glass, hex, rubberBand, spring, useAutoplay, useDoubleTap, useHaptics, white, type DemoProps, type Point } from "../../kit";
import { useScript } from "./_a-common";

const MIN_SCALE = 0.6;
const MAX_SCALE = 2.5;

function displayScale(raw: number) {
  if (raw > MAX_SCALE) return MAX_SCALE + rubberBand(raw - MAX_SCALE, 0.6);
  if (raw < MIN_SCALE) return MIN_SCALE - rubberBand(MIN_SCALE - raw, 0.25);
  return raw;
}

type Pinch = { d0: number; a0: number };

export default function PinchRotate({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const scale = useMotionValue(1);
  const degrees = useMotionValue(0);
  const base = useRef({ scale: 1, degrees: 0 });
  const [isActive, setActive] = useState(false);
  const held = useRef(false);
  const pointers = useRef(new Map<number, Point>());
  const pinch = useRef<Pinch | null>(null);
  const wheelEnd = useRef(0);
  const card = useRef<HTMLDivElement>(null);
  const [readout, setReadout] = useState({ s: 1, d: 0 });

  const update = () => setReadout({ s: displayScale(scale.get()), d: degrees.get() });
  useMotionValueEvent(scale, "change", update);
  useMotionValueEvent(degrees, "change", update);

  const settleSpring = () => spring(ctx.n("response"), ctx.n("damping"));

  const settle = (fromScale: number, fromDegrees: number, haptic: boolean) => {
    const snap = ctx.i("mode") === 1;
    const finalScale = snap ? clamp(displayScale(fromScale), 1, MAX_SCALE) : 1;
    const finalDegrees = snap ? Math.round(fromDegrees / 90) * 90 : 0;
    animate(scale, finalScale, settleSpring());
    animate(degrees, finalDegrees, settleSpring());
    setActive(false);
    base.current = { scale: finalScale, degrees: finalDegrees };
    if (haptic) haptics.tap("soft");
  };

  /** `MagnifyGesture().simultaneously(with: RotateGesture()).onChanged`. */
  const change = (magnification: number, rotation: number) => {
    if (!held.current) {
      held.current = true;
      script.cancel();
      scale.stop();
      degrees.stop();
    }
    setActive(true);
    scale.set(base.current.scale * magnification);
    degrees.set(base.current.degrees + rotation);
  };
  const end = () => {
    if (!held.current) return;
    held.current = false;
    settle(scale.get(), degrees.get(), true);
  };

  const measure = (): Pinch | null => {
    const pts = [...pointers.current.values()];
    if (pts.length < 2) return null;
    const [a, b] = pts;
    return { d0: Math.max(Math.hypot(b.x - a.x, b.y - a.y), 1), a0: (Math.atan2(b.y - a.y, b.x - a.x) * 180) / Math.PI };
  };

  const onPointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pointers.current.size === 2) pinch.current = measure();
  };
  const onPointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!pointers.current.has(e.pointerId)) return;
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    const start = pinch.current;
    const now = measure();
    if (!start || !now) return;
    let rotation = now.a0 - start.a0;
    rotation = ((((rotation + 180) % 360) + 360) % 360) - 180;
    change(now.d0 / start.d0, rotation);
  };
  const onPointerUp = (e: React.PointerEvent<HTMLDivElement>) => {
    pointers.current.delete(e.pointerId);
    if (pinch.current && pointers.current.size < 2) {
      pinch.current = null;
      if (e.type === "pointercancel") {
        if (held.current) {
          held.current = false;
          settle(base.current.scale, base.current.degrees, false);
        }
      } else end();
    }
  };

  // Trackpad pinch (ctrl + wheel) and Safari's gesture events (pinch + rotate) on desktop.
  useEffect(() => {
    const el = card.current;
    if (!el) return;
    let wheelMag = 1;
    const onWheel = (e: WheelEvent) => {
      if (!e.ctrlKey) return;
      e.preventDefault();
      if (!held.current) wheelMag = 1;
      wheelMag *= Math.exp(-e.deltaY * 0.01);
      change(wheelMag, 0);
      window.clearTimeout(wheelEnd.current);
      wheelEnd.current = window.setTimeout(end, 160);
    };
    type GestureEvt = Event & { scale: number; rotation: number };
    const onGesture = (e: Event) => {
      e.preventDefault();
      const g = e as GestureEvt;
      change(g.scale, g.rotation);
    };
    const onGestureEnd = (e: Event) => {
      e.preventDefault();
      end();
    };
    const prevent = (e: Event) => e.preventDefault();
    el.addEventListener("wheel", onWheel, { passive: false });
    el.addEventListener("gesturestart", prevent);
    el.addEventListener("gesturechange", onGesture);
    el.addEventListener("gestureend", onGestureEnd);
    return () => {
      el.removeEventListener("wheel", onWheel);
      el.removeEventListener("gesturestart", prevent);
      el.removeEventListener("gesturechange", onGesture);
      el.removeEventListener("gestureend", onGestureEnd);
      window.clearTimeout(wheelEnd.current);
    };
  });

  const doubleTap = useDoubleTap(() => {
    animate(scale, 1, settleSpring());
    animate(degrees, 0, settleSpring());
    base.current = { scale: 1, degrees: 0 };
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (isActive || held.current) return;
      animate(scale, 1.35, spring(0.6, 0.85));
      animate(degrees, 18, spring(0.6, 0.85));
      setActive(true);
      base.current = { scale: 1.35, degrees: 18 };
      script.cancel();
      script.after(0.7, () => {
        if (held.current) return;
        animate(scale, 1, spring(0.5, 0.62));
        animate(degrees, 0, spring(0.5, 0.62));
        setActive(false);
        base.current = { scale: 1, degrees: 0 };
      });
    },
    { every: 1.7 },
  );

  const transform = useTransform(() => `scale(${displayScale(scale.get())}) rotate(${degrees.get()}deg)`);

  return (
    <div style={{ position: "absolute", inset: 0, padding: "16px 0", display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
      <div style={{ flex: 1, minHeight: 0, display: "grid", placeItems: "center", zIndex: 1 }}>
        <motion.div
          ref={card}
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={(e) => {
            onPointerUp(e);
            if (pointers.current.size === 0 && !held.current) doubleTap(e);
          }}
          onPointerCancel={onPointerUp}
          style={{ transform, width: 210, height: 150, touchAction: "none", cursor: "zoom-in" }}
        >
          <PhotoCard showGrid={isActive} />
        </motion.div>
      </div>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 10,
          padding: "8px 14px",
          borderRadius: 999,
          ...glass("regular"),
          fontSize: 13,
          lineHeight: "18px",
          fontWeight: 600,
          fontVariantNumeric: "tabular-nums",
          color: Palette.secondaryLabel,
        }}
      >
        <span style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <Maximize2 size={13} strokeWidth={2.4} />×{readout.s.toFixed(2)}
        </span>
        <span style={{ width: 1, height: 14, background: Palette.labelAlpha(0.18) }} />
        <span style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <RotateCw size={13} strokeWidth={2.4} />
          {readout.d.toFixed(0) === "-0" ? "0" : readout.d.toFixed(0)}°
        </span>
      </div>
      <DemoHint ctx={ctx} en="Pinch and twist with two fingers" zh="双指捏合并旋转" />
    </div>
  );
}

function PhotoCard({ showGrid }: { showGrid: boolean }) {
  return (
    <div
      style={{
        position: "relative",
        width: 210,
        height: 150,
        borderRadius: 24,
        overflow: "hidden",
        background: Palette.sunset,
        boxShadow: `0 12px 22px ${hex(Palette.coral, 0.35)}`,
      }}
    >
      <Sun size={30} fill="currentColor" strokeWidth={2.2} style={{ position: "absolute", right: 16, top: 16, color: white(0.9) }} />
      <svg width={74} height={50} viewBox="0 0 74 50" style={{ position: "absolute", left: 18, bottom: 10, color: "#fff", opacity: 0.85 }}>
        <path d="M24 48 L47 11 Q50 6.5 53 11 L74 48 Z" fill="currentColor" />
        <path d="M0 48 L21 9 Q24 3.5 27 9 L50 48 Z" fill="currentColor" />
      </svg>
      <motion.svg
        width={210}
        height={150}
        initial={false}
        animate={{ opacity: showGrid ? 1 : 0 }}
        transition={anim.easeOut(0.2)}
        style={{ position: "absolute", inset: 0, pointerEvents: "none" }}
      >
        {[1, 2].map((i) => (
          <g key={i} stroke={white(0.6)} strokeWidth={0.75}>
            <line x1={(210 * i) / 3} y1={0} x2={(210 * i) / 3} y2={150} />
            <line x1={0} y1={(150 * i) / 3} x2={210} y2={(150 * i) / 3} />
          </g>
        ))}
      </motion.svg>
    </div>
  );
}

