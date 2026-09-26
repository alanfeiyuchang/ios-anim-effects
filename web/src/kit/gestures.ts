/**
 * Pointer helpers. The canvas is CSS-scaled, so pointer positions must be converted back to
 * authoring points; `localPoint` does that for any element inside the canvas.
 *
 * For drags prefer motion's `onPan` / `drag` props or `usePan` below; for taps use `onClick`
 * (or `onPointerDown` when the app reacts on touch-down).
 */
import { useCallback, useRef } from "react";

export interface Point {
  x: number;
  y: number;
}

/** The element's CSS scale (canvas scale × any transforms): rendered width / layout width. */
export function elementScale(el: HTMLElement): number {
  const width = el.offsetWidth;
  if (!width) return 1;
  return el.getBoundingClientRect().width / width;
}

/** Pointer position in the element's own (unscaled) coordinate space. */
export function localPoint(e: { clientX: number; clientY: number }, el: HTMLElement): Point {
  const rect = el.getBoundingClientRect();
  const scale = elementScale(el) || 1;
  return { x: (e.clientX - rect.left) / scale, y: (e.clientY - rect.top) / scale };
}

/**
 * `onTapGesture(count: 2, coordinateSpace: .local)`: works with touch too (browsers do not send
 * `dblclick` for touches reliably). Spread the returned handler on the element:
 * `<div onPointerUp={doubleTap}>`.
 */
export function useDoubleTap(handler: (p: Point) => void, maxDelay = 0.3, maxDistance = 30) {
  const last = useRef<{ time: number; x: number; y: number } | null>(null);
  return useCallback(
    (e: React.PointerEvent<HTMLElement>) => {
      const now = performance.now() / 1000;
      const p = localPoint(e, e.currentTarget);
      const prev = last.current;
      if (prev && now - prev.time < maxDelay && Math.hypot(p.x - prev.x, p.y - prev.y) < maxDistance) {
        last.current = null;
        handler(p);
      } else {
        last.current = { time: now, x: p.x, y: p.y };
      }
    },
    [handler, maxDelay, maxDistance],
  );
}

export interface PanState {
  /** Translation since the pan began, in authoring points (`value.translation`). */
  translation: Point;
  /** Start location in the element (`value.startLocation`). */
  start: Point;
  /** Current location in the element (`value.location`). */
  location: Point;
  /** Velocity in points per second (`value.velocity`). */
  velocity: Point;
}

/**
 * `DragGesture(minimumDistance:)` with `onChanged` / `onEnded`, in authoring points.
 * Spread the returned props on the element that receives the drag.
 */
export function usePan(
  handlers: { onStart?: (s: PanState) => void; onChange?: (s: PanState) => void; onEnd?: (s: PanState) => void },
  minimumDistance = 0,
) {
  const state = useRef<{
    id: number;
    /** Pointer position (client px) and element-local point at touch-down, and the CSS scale then. */
    client: Point;
    start: Point;
    scale: number;
    last: Point;
    lastTime: number;
    velocity: Point;
    active: boolean;
  } | null>(null);
  const latest = useRef(handlers);
  latest.current = handlers;

  const make = (s: NonNullable<typeof state.current>, p: Point): PanState => ({
    translation: { x: p.x - s.start.x, y: p.y - s.start.y },
    start: s.start,
    location: p,
    velocity: s.velocity,
  });

  // Positions are measured from the touch-down point, never from the element's current box: the
  // element being dragged usually moves with the finger.
  const pointFor = (s: NonNullable<typeof state.current>, e: { clientX: number; clientY: number }): Point => ({
    x: s.start.x + (e.clientX - s.client.x) / s.scale,
    y: s.start.y + (e.clientY - s.client.y) / s.scale,
  });

  const onPointerDown = useCallback((e: React.PointerEvent<HTMLElement>) => {
    if (state.current) return;
    const el = e.currentTarget;
    el.setPointerCapture(e.pointerId);
    const p = localPoint(e, el);
    state.current = {
      id: e.pointerId,
      client: { x: e.clientX, y: e.clientY },
      start: p,
      scale: elementScale(el) || 1,
      last: p,
      lastTime: performance.now(),
      velocity: { x: 0, y: 0 },
      active: false,
    };
    if (minimumDistance === 0) {
      state.current.active = true;
      latest.current.onStart?.(make(state.current, p));
      latest.current.onChange?.(make(state.current, p));
    }
  }, [minimumDistance]);

  const onPointerMove = useCallback((e: React.PointerEvent<HTMLElement>) => {
    const s = state.current;
    if (!s || s.id !== e.pointerId) return;
    const p = pointFor(s, e);
    const now = performance.now();
    const dt = Math.max((now - s.lastTime) / 1000, 1 / 240);
    const vx = (p.x - s.last.x) / dt;
    const vy = (p.y - s.last.y) / dt;
    s.velocity = { x: s.velocity.x * 0.6 + vx * 0.4, y: s.velocity.y * 0.6 + vy * 0.4 };
    s.last = p;
    s.lastTime = now;
    if (!s.active) {
      if (Math.hypot(p.x - s.start.x, p.y - s.start.y) < minimumDistance) return;
      s.active = true;
      latest.current.onStart?.(make(s, p));
    }
    latest.current.onChange?.(make(s, p));
  }, [minimumDistance]);

  const finish = useCallback((e: React.PointerEvent<HTMLElement>) => {
    const s = state.current;
    if (!s || s.id !== e.pointerId) return;
    state.current = null;
    // A pointer that rested before lifting has no fling velocity.
    if (performance.now() - s.lastTime > 80) s.velocity = { x: 0, y: 0 };
    if (s.active) latest.current.onEnd?.(make(s, e.type === "pointercancel" ? s.last : pointFor(s, e)));
  }, []);

  return { onPointerDown, onPointerMove, onPointerUp: finish, onPointerCancel: finish, style: { touchAction: "none" as const } };
}

/**
 * Press state for `ButtonStyle`-like pressed looks: `const [pressed, pressProps] = usePress()`.
 */
export function pressHandlers(set: (pressed: boolean) => void) {
  return {
    onPointerDown: () => set(true),
    onPointerUp: () => set(false),
    onPointerLeave: () => set(false),
    onPointerCancel: () => set(false),
  };
}
