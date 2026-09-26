/** gestures.pinch-open · 捏合展开 (Gestures+PinchOpen.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useTransform } from "motion/react";
import { Images } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, black, clamp, delayed, rubberBand, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { useScript } from "./_a-common";

export default function PinchOpen({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const [expanded, setExpanded] = useState(false);
  const expandedRef = useRef(false);
  const live = useMotionValue(1);
  const tilt = useMotionValue(0);
  /** The state value of `live` (what SwiftUI's body reads), for `armed`. */
  const [liveState, setLiveState] = useState(1);
  const scripted = useRef(false);
  const held = useRef(false);
  const card = useRef<HTMLDivElement>(null);
  const threshold = ctx.n("threshold");
  const armed = expanded ? liveState < 0.8 : liveState > threshold;
  const lastArmed = useRef(armed);
  useEffect(() => {
    if (armed !== lastArmed.current) {
      lastArmed.current = armed;
      if (armed && !scripted.current) haptics.tap("light");
    }
  }, [armed, haptics]);

  const setLive = (v: number, t?: ReturnType<typeof spring>) => {
    setLiveState(v);
    if (t) animate(live, v, t);
    else {
      live.stop();
      live.set(v);
    }
  };
  const setTilt = (v: number, t?: ReturnType<typeof spring>) => {
    if (t) animate(tilt, v, t);
    else {
      tilt.stop();
      tilt.set(v);
    }
  };

  const toggle = (haptic: boolean) => {
    const s = spring(ctx.n("response"), ctx.n("damping"));
    expandedRef.current = !expandedRef.current;
    setExpanded(expandedRef.current);
    setLive(1, s);
    setTilt(0, s);
    if (haptic) haptics.tap("medium");
  };

  const springBack = () => {
    const s = spring(0.35, 0.72);
    setLive(1, s);
    setTilt(0, s);
  };

  /** `MagnifyGesture.onChanged` with magnification `m` and the start anchor's unit x. */
  const change = (m: number, anchorX: number) => {
    if (!held.current) {
      held.current = true;
      script.cancel();
    }
    scripted.current = false;
    if (expandedRef.current) setLive(clamp(m, 0.55, 1) + rubberBand(Math.max(m - 1, 0), 0.05, 1));
    else setLive(m > 1.6 ? 1.6 + rubberBand(m - 1.6, 0.3, 1) : Math.max(m, 0.55));
    setTilt(expandedRef.current ? 0 : (anchorX - 0.5) * 4 * clamp(m - 1, 0, 1));
  };
  const end = () => {
    if (!held.current) return;
    held.current = false;
    const v = live.get();
    const isArmed = expandedRef.current ? v < 0.8 : v > ctx.n("threshold");
    if (isArmed) toggle(true);
    else springBack();
  };

  // Two-pointer pinch, ctrl + wheel on desktop, double tap.
  const pointers = useRef(new Map<number, { x: number; y: number }>());
  const pinch = useRef<{ d0: number; ax: number } | null>(null);
  const moved = useRef(false);
  const lastTap = useRef<{ t: number; x: number; y: number } | null>(null);
  const pair = () => {
    const [a, b] = [...pointers.current.values()];
    return { mid: { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 }, d: Math.max(Math.hypot(b.x - a.x, b.y - a.y), 1) };
  };
  const unitX = (clientX: number) => {
    const r = card.current!.getBoundingClientRect();
    return clamp((clientX - r.left) / r.width);
  };
  const onDown = (e: React.PointerEvent<HTMLDivElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pointers.current.size === 1) moved.current = false;
    if (pointers.current.size === 2) {
      const { mid, d } = pair();
      pinch.current = { d0: d, ax: unitX(mid.x) };
      moved.current = true;
    }
  };
  const onMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!pointers.current.has(e.pointerId)) return;
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pinch.current && pointers.current.size >= 2) change(pair().d / pinch.current.d0, pinch.current.ax);
  };
  const onUp = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!pointers.current.has(e.pointerId)) return;
    pointers.current.delete(e.pointerId);
    if (pinch.current) {
      if (pointers.current.size < 2) {
        pinch.current = null;
        if (e.type === "pointercancel") {
          if (held.current) {
            held.current = false;
            springBack();
          }
        } else end();
      }
      return;
    }
    if (moved.current || e.type === "pointercancel") return;
    const now = performance.now() / 1000;
    const prev = lastTap.current;
    if (prev && now - prev.t < 0.3 && Math.hypot(e.clientX - prev.x, e.clientY - prev.y) < 30) {
      lastTap.current = null;
      script.cancel();
      toggle(true);
    } else lastTap.current = { t: now, x: e.clientX, y: e.clientY };
  };
  useEffect(() => {
    const el = card.current;
    if (!el) return;
    let wheel = 1;
    let ax = 0.5;
    let timer = 0;
    const onWheel = (e: WheelEvent) => {
      if (!e.ctrlKey) return;
      e.preventDefault();
      if (!held.current) {
        wheel = 1;
        ax = unitX(e.clientX);
      }
      wheel *= Math.exp(-e.deltaY * 0.01);
      change(wheel, ax);
      window.clearTimeout(timer);
      timer = window.setTimeout(end, 160);
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
      scripted.current = true;
      const e = anim.easeInOut(0.45);
      setLive(expandedRef.current ? 0.74 : ctx.n("threshold") + 0.12, e);
      setTilt(expandedRef.current ? 0 : 2, e);
      script.cancel();
      script.after(0.5, () => toggle(false));
    },
    { every: 2.4, delay: 0.6 },
  );

  const s = spring(ctx.n("response"), ctx.n("damping"));
  const lift = useTransform(live, (v) => (expanded ? 20 : 10 + 16 * clamp((v - 1) / 0.5)));
  const shadow = useTransform(lift, (l) => `0 ${l * 0.5}px ${l}px ${black(0.16)}`);

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <motion.div
        ref={card}
        onPointerDown={onDown}
        onPointerMove={onMove}
        onPointerUp={onUp}
        onPointerCancel={onUp}
        initial={false}
        animate={{ width: expanded ? 300 : 170, height: expanded ? 320 : 128, padding: expanded ? 16 : 10 }}
        transition={s}
        style={{
          position: "relative",
          scale: live,
          rotate: tilt,
          borderRadius: 22,
          background: Palette.elevated,
          boxShadow: shadow,
          display: "flex",
          flexDirection: "column",
          gap: 10,
          overflow: "hidden",
          touchAction: "none",
          cursor: "zoom-in",
        }}
      >
        <motion.div
          initial={false}
          animate={{ height: expanded ? 150 : 72 }}
          transition={s}
          style={{ flexShrink: 0, borderRadius: 16, background: Palette.aurora, display: "grid", placeItems: "center", color: white(0.9) }}
        >
          <motion.div initial={false} animate={{ scale: expanded ? 40 / 26 : 1 }} transition={s} style={{ display: "grid" }}>
            <Images size={28} strokeWidth={2.2} />
          </motion.div>
        </motion.div>
        <div style={{ fontSize: expanded ? 20 : 15, lineHeight: expanded ? "25px" : "20px", fontWeight: expanded ? 700 : 600, whiteSpace: "nowrap" }}>
          {ctx.t("Summer Trip", "夏日旅行")}
        </div>
        <AnimatePresence>
          {expanded &&
            [0, 1, 2].map((i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 8 }}
                transition={delayed(spring(0.45, 0.85), 0.12 + i * 0.06)}
                style={{ width: 250 - i * 50 }}
              >
                <PlaceholderLines count={1} />
              </motion.div>
            ))}
        </AnimatePresence>
        {/* Border: the aurora ring while armed, the hairline otherwise. */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: 22,
            padding: armed ? 2.5 : 1,
            background: armed ? Palette.aurora : Palette.stroke,
            WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
            WebkitMaskComposite: "xor",
            mask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
            maskComposite: "exclude",
            pointerEvents: "none",
          }}
        />
      </motion.div>
      <AnimatePresence>
        {!expanded && !ctx.isPreview && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={s}
            style={{ position: "absolute", left: 0, right: 0, bottom: 12 }}
          >
            <DemoHint ctx={ctx} en="Spread two fingers on the card, or double-tap" zh="在卡片上双指张开，或双击" />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
