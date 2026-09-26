/** Shared bits for the gestures-a ports (only used by files this agent created). */
import { useEffect, useRef, useState, type CSSProperties } from "react";
import type { Point } from "../../kit";

/**
 * `DragGesture.Value.predictedEndTranslation`: where the finger would coast to with UIKit's
 * normal deceleration from its lift-off velocity.
 */
export function predictedEnd(translation: Point, velocity: Point): Point {
  return { x: translation.x + velocity.x * 0.25, y: translation.y + velocity.y * 0.25 };
}

/**
 * A frame loop for physics (`TimelineView(.animation)` stepping a model). `step(dt, now)` runs every
 * frame (capped at `fps` when given, like the app's 30 fps previews); it returns true when the view
 * should re-render. Returns a render counter.
 */
export function useFrameLoop(step: (dt: number, now: number) => boolean | void, running = true, fps?: number): number {
  const [frame, setFrame] = useState(0);
  const latest = useRef(step);
  latest.current = step;
  useEffect(() => {
    if (!running) return;
    let raf = 0;
    let last = 0;
    let prev: number | null = null;
    const tick = (now: number) => {
      raf = requestAnimationFrame(tick);
      if (fps && last && now - last < 1000 / fps - 1) return;
      last = now;
      const dt = prev === null ? 0 : (now - prev) / 1000;
      prev = now;
      if (latest.current(dt, now / 1000) !== false) setFrame((f) => (f + 1) % 1_000_000);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [running, fps]);
  return frame;
}

/**
 * `.strokeBorder(color, style: StrokeStyle(lineWidth:, dash:))` on a (rounded) rectangle or circle, as
 * an absolutely positioned SVG that fills its parent box.
 */
export function DashedBorder({
  width,
  height,
  radius,
  color,
  lineWidth = 1,
  dash = [4, 4],
  style,
}: {
  width: number;
  height: number;
  radius: number;
  color: string;
  lineWidth?: number;
  dash?: number[];
  style?: CSSProperties;
}) {
  const inset = lineWidth / 2;
  return (
    <svg width={width} height={height} style={{ position: "absolute", left: 0, top: 0, overflow: "visible", pointerEvents: "none", ...style }}>
      <rect
        x={inset}
        y={inset}
        width={Math.max(width - lineWidth, 0)}
        height={Math.max(height - lineWidth, 0)}
        rx={Math.max(radius - inset, 0)}
        fill="none"
        stroke={color}
        strokeWidth={lineWidth}
        strokeDasharray={dash.join(" ")}
      />
    </svg>
  );
}

/** SwiftUI's `color.gradient` (AnyGradient): a slightly lighter top fading into the colour. */
export function colorGradient(color: string): string {
  return `linear-gradient(180deg, color-mix(in srgb, ${color}, white 16%), ${color})`;
}

/** Cancels scripted steps (autoplay) when a real touch arrives: `const script = useScript()`. */
export function useScript() {
  const timers = useRef<number[]>([]);
  useEffect(() => () => timers.current.forEach((id) => window.clearTimeout(id)), []);
  return useRef({
    cancel() {
      timers.current.forEach((id) => window.clearTimeout(id));
      timers.current = [];
    },
    after(seconds: number, fn: () => void) {
      const id = window.setTimeout(() => {
        timers.current = timers.current.filter((x) => x !== id);
        fn();
      }, seconds * 1000);
      timers.current.push(id);
    },
    get active() {
      return timers.current.length > 0;
    },
  }).current;
}

export const TAU = Math.PI * 2;
