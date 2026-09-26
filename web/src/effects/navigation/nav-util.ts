/**
 * Small helpers for the Navigation demos (drawers, sheets, menus).
 */
import { useMotionValueEvent, type MotionValue } from "motion/react";
import { useCallback, useRef, useState } from "react";
import { elementScale, localPoint, type PanState, type Point } from "../../kit";

/** Re-renders the component whenever `mv` changes and returns its current value (SwiftUI `Animatable`). */
export function useMotionNumber(mv: MotionValue<number>): number {
  const [v, setV] = useState(() => mv.get());
  useMotionValueEvent(mv, "change", setV);
  return v;
}

/** `DragGesture.Value.predictedEndTranslation`, approximated from the release velocity. */
export const predicted = (s: PanState): Point => ({
  x: s.translation.x + s.velocity.x * 0.25,
  y: s.translation.y + s.velocity.y * 0.25,
});

type Dir = "down" | "up" | "right" | "left";

/**
 * `DragGesture(minimumDistance:)` that only grabs the pointer once it engages, so taps on buttons
 * inside the dragged area still click (the kit's `usePan` captures on pointer-down, which sends the
 * click to the container instead of the button).
 *
 * - `axis: "horizontal"`: `pageSafeHorizontalDrag` (engages on mostly horizontal travel).
 * - `directions`: `PageSafePan(directions:)` (engages when the first movement heads that way;
 *   translations then start from zero like the UIKit pan).
 * `onEnd` receives `null` for a cancelled drag (Swift's `onEnded(nil)`).
 */
export function useNavPan(
  handlers: {
    onStart?: (s: PanState) => void;
    onChange?: (s: PanState) => void;
    onEnd?: (s: PanState | null) => void;
  },
  opts: { minimumDistance?: number; axis?: "horizontal" | "any"; directions?: Dir[]; enabled?: boolean } = {},
) {
  const { minimumDistance = 10, axis = "any", directions, enabled = true } = opts;
  const latest = useRef(handlers);
  latest.current = handlers;
  const cfg = useRef({ minimumDistance, axis, directions, enabled });
  cfg.current = { minimumDistance, axis, directions, enabled };
  const st = useRef<{
    id: number;
    client: Point;
    start: Point;
    origin: Point;
    scale: number;
    last: Point;
    lastTime: number;
    velocity: Point;
    active: boolean;
    failed: boolean;
    el: HTMLElement;
  } | null>(null);

  const make = (s: NonNullable<typeof st.current>, p: Point): PanState => ({
    translation: { x: p.x - s.origin.x, y: p.y - s.origin.y },
    start: s.origin,
    location: p,
    velocity: s.velocity,
  });
  const pointFor = (s: NonNullable<typeof st.current>, e: { clientX: number; clientY: number }): Point => ({
    x: s.start.x + (e.clientX - s.client.x) / s.scale,
    y: s.start.y + (e.clientY - s.client.y) / s.scale,
  });

  const onPointerDown = useCallback((e: React.PointerEvent<HTMLElement>) => {
    if (st.current || !cfg.current.enabled) return;
    if (e.pointerType === "mouse" && e.button !== 0) return;
    const el = e.currentTarget;
    const p = localPoint(e, el);
    st.current = {
      id: e.pointerId,
      client: { x: e.clientX, y: e.clientY },
      start: p,
      origin: p,
      scale: elementScale(el) || 1,
      last: p,
      lastTime: performance.now(),
      velocity: { x: 0, y: 0 },
      active: false,
      failed: false,
      el,
    };
  }, []);

  const onPointerMove = useCallback((e: React.PointerEvent<HTMLElement>) => {
    const s = st.current;
    if (!s || s.id !== e.pointerId || s.failed) return;
    const p = pointFor(s, e);
    const now = performance.now();
    const dt = Math.max((now - s.lastTime) / 1000, 1 / 240);
    s.velocity = { x: s.velocity.x * 0.6 + ((p.x - s.last.x) / dt) * 0.4, y: s.velocity.y * 0.6 + ((p.y - s.last.y) / dt) * 0.4 };
    s.last = p;
    s.lastTime = now;
    if (!s.active) {
      const dx = p.x - s.start.x;
      const dy = p.y - s.start.y;
      if (Math.hypot(dx, dy) < cfg.current.minimumDistance) return;
      const { axis, directions } = cfg.current;
      if (directions) {
        const vertical = Math.abs(dy) > Math.abs(dx);
        const ok =
          (directions.includes("down") && vertical && dy > 0) ||
          (directions.includes("up") && vertical && dy < 0) ||
          (directions.includes("right") && !vertical && dx > 0) ||
          (directions.includes("left") && !vertical && dx < 0);
        if (!ok) {
          s.failed = true;
          return;
        }
        s.origin = p; // UIKit pan: translation starts from zero when it begins
      } else if (axis === "horizontal" && Math.abs(dx) <= Math.abs(dy)) {
        return;
      }
      s.active = true;
      try {
        s.el.setPointerCapture(e.pointerId);
      } catch {
        /* pointer already gone */
      }
      latest.current.onStart?.(make(s, p));
    }
    latest.current.onChange?.(make(s, p));
  }, []);

  const finish = useCallback((e: React.PointerEvent<HTMLElement>) => {
    const s = st.current;
    if (!s || s.id !== e.pointerId) return;
    st.current = null;
    if (!s.active) return;
    if (e.type === "pointercancel") {
      latest.current.onEnd?.(null);
      return;
    }
    if (performance.now() - s.lastTime > 80) s.velocity = { x: 0, y: 0 };
    latest.current.onEnd?.(make(s, pointFor(s, e)));
  }, []);

  return { onPointerDown, onPointerMove, onPointerUp: finish, onPointerCancel: finish };
}

/** SwiftUI `Color.gradient`: the colour with a soft top-to-bottom sheen. */
export const colorGradient = (color: string) =>
  `linear-gradient(180deg, color-mix(in srgb, ${color}, white 14%), color-mix(in srgb, ${color}, black 6%))`;
