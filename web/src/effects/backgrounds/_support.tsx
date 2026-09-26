/**
 * Shared pieces of the Backgrounds category (BackgroundsSupport.swift): deterministic randoms,
 * the speed-scaled `BackgroundClock`, the frame loop that stands in for `TimelineView(.animation)`,
 * HiDPI 2D canvases, the scroll-friendly `backgroundsTouch`, the sample headline and the hint.
 */
import { useEffect, useLayoutEffect, useRef, type CSSProperties, type ReactNode, type RefObject } from "react";
import { fonts, localPoint, useLatest, type DemoContext, type Point } from "../../kit";

// MARK: - Math (BackgroundMath)

export const TAU = Math.PI * 2;
export const fract = (x: number) => x - Math.floor(x);
/** `BackgroundMath.rand`: stable pseudo-random 0..<1 for an index and a salt. */
export const rand = (index: number, salt = 0) => fract(Math.sin(index * 12.9898 + salt * 78.233 + 0.5) * 43758.5453);
export const clampv = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi);
/** Seconds on the shared clock (taps and frames use the same one, like `Date()` / `timeline.date`). */
export const nowSec = () => performance.now() / 1000;
/** `Double.random(in: a...b)` */
export const randIn = (a: number, b: number) => a + Math.random() * (b - a);

/** `Color(hex:)` → [r, g, b] in 0…1. */
export function rgb01(hex: number): [number, number, number] {
  return [((hex >> 16) & 0xff) / 255, ((hex >> 8) & 0xff) / 255, (hex & 0xff) / 255];
}
/** `Color(hex:).opacity(a)` → CSS string. */
export function rgba(hex: number, a = 1): string {
  return `rgba(${(hex >> 16) & 0xff},${(hex >> 8) & 0xff},${hex & 0xff},${a})`;
}

/** Accumulates speed-scaled time, so changing a speed never makes a loop jump. */
export class BackgroundClock {
  private last: number | null = null;
  phase: number;
  /** Real seconds elapsed during the last `advance` (clamped to 1/20 s). */
  delta = 0;
  constructor(start = 100) {
    this.phase = start;
  }
  advance(now: number, speed: number): number {
    this.delta = this.last === null ? 0 : Math.min(Math.max(now - this.last, 0), 1 / 20);
    this.last = now;
    this.phase += this.delta * speed;
    return this.phase;
  }
  /** Frame-rate independent exponential smoothing factor for the last frame. */
  follow(rate: number): number {
    return 1 - Math.exp(-this.delta * rate);
  }
}

/** A mutable model kept for the component's lifetime (`@State private var model = Model()`). */
export function useModel<T>(make: () => T): T {
  const ref = useRef<T | null>(null);
  if (ref.current === null) ref.current = make();
  return ref.current;
}

// MARK: - Frame loop (TimelineView(.animation))

/**
 * Calls `frame(now)` every animation frame (30 fps in previews, like `MotionFrameRate`), skipping
 * frames while the stage is scrolled out of view. `now` is `nowSec()`.
 */
export function useFrameLoop(root: RefObject<HTMLElement | null>, isPreview: boolean, frame: (now: number) => void) {
  const latest = useLatest(frame);
  useEffect(() => {
    let raf = 0;
    let last = 0;
    let visible = true;
    let first = true;
    const el = root.current;
    const io =
      el && typeof IntersectionObserver !== "undefined"
        ? new IntersectionObserver((entries) => {
            visible = entries[entries.length - 1].isIntersecting;
          })
        : null;
    if (io && el) io.observe(el);
    const cap = isPreview ? 30 : 0;
    const step = (ms: number) => {
      raf = requestAnimationFrame(step);
      if (!visible && !first) return;
      if (cap && ms - last < 1000 / cap - 1) return;
      last = ms;
      first = false;
      latest.current(ms / 1000);
    };
    raf = requestAnimationFrame(step);
    return () => {
      cancelAnimationFrame(raf);
      io?.disconnect();
    };
  }, [root, isPreview, latest]);
}

/** Layout size (authoring points) of an element: 340 × 340 / 400. */
export function sizeOf(el: HTMLElement | null): { w: number; h: number } {
  return { w: el?.offsetWidth || 340, h: el?.offsetHeight || 340 };
}

/** Backing-store scale for a canvas inside the CSS-scaled stage: device pixels per point, 2…3. */
export function pixelRatio(el: HTMLElement | null): number {
  if (!el) return 2;
  const layout = el.offsetWidth || 1;
  const shown = el.getBoundingClientRect().width || layout;
  return clampv((window.devicePixelRatio || 1) * (shown / layout), 2, 3);
}

/**
 * Sizes `canvas` to `w × h` points at `k` pixels per point (only when changed), clears it and returns
 * its context with a point-space transform.
 */
export function prep(canvas: HTMLCanvasElement | null, w: number, h: number, k: number): CanvasRenderingContext2D | null {
  if (!canvas) return null;
  const pw = Math.max(1, Math.round(w * k));
  const ph = Math.max(1, Math.round(h * k));
  if (canvas.width !== pw || canvas.height !== ph) {
    canvas.width = pw;
    canvas.height = ph;
  }
  const g = canvas.getContext("2d");
  if (!g) return null;
  g.setTransform(1, 0, 0, 1, 0, 0);
  g.globalCompositeOperation = "source-over";
  g.globalAlpha = 1;
  g.clearRect(0, 0, pw, ph);
  g.setTransform(pw / w, 0, 0, ph / h, 0, 0);
  return g;
}

/** Keeps the backing scale fresh (the stage can be resized or zoomed) without measuring every frame. */
export function useRatio(root: RefObject<HTMLElement | null>) {
  const ratio = useRef(2);
  const count = useRef(0);
  return () => {
    if (count.current++ % 45 === 0) ratio.current = pixelRatio(root.current);
    return ratio.current;
  };
}

/** A full-bleed canvas layer. `blur` = CSS blur in points (SwiftUI `.blur(radius:)`), `blend` = CSS mix-blend-mode. */
export function Layer({
  canvasRef,
  blur,
  blend,
  opacity,
  style,
}: {
  canvasRef: RefObject<HTMLCanvasElement | null>;
  blur?: number;
  blend?: CSSProperties["mixBlendMode"];
  opacity?: number;
  style?: CSSProperties;
}) {
  return (
    <canvas
      ref={canvasRef}
      style={{
        position: "absolute",
        left: 0,
        top: 0,
        width: "100%",
        height: "100%",
        display: "block",
        pointerEvents: "none",
        filter: blur ? `blur(${blur}px)` : undefined,
        mixBlendMode: blend,
        opacity,
        ...style,
      }}
    />
  );
}

/** Ellipse path in a rect (`Path(ellipseIn:)`). */
export function ellipse(g: CanvasRenderingContext2D | Path2D, x: number, y: number, w: number, h: number) {
  g.moveTo(x + w, y + h / 2);
  g.ellipse(x + w / 2, y + h / 2, Math.abs(w / 2), Math.abs(h / 2), 0, 0, TAU);
}
/** Circle path (`Path(ellipseIn: CGRect(center ± r))`). */
export function circle(g: CanvasRenderingContext2D | Path2D, x: number, y: number, r: number) {
  g.moveTo(x + r, y);
  g.arc(x, y, Math.abs(r), 0, TAU);
}

/** `GraphicsContext.Shading.radialGradient(Gradient(stops), center:, startRadius:, endRadius:)`. */
export function radial(
  g: CanvasRenderingContext2D,
  x: number,
  y: number,
  r0: number,
  r1: number,
  stops: [number, string][],
): CanvasGradient {
  const gr = g.createRadialGradient(x, y, r0, x, y, r1);
  for (const [at, c] of stops) gr.addColorStop(at, c);
  return gr;
}
export function linear(g: CanvasRenderingContext2D, x0: number, y0: number, x1: number, y1: number, stops: [number, string][]): CanvasGradient {
  const gr = g.createLinearGradient(x0, y0, x1, y1);
  for (const [at, c] of stops) gr.addColorStop(at, c);
  return gr;
}
/** Evenly spaced stops (`Gradient(colors:)`). */
export const even = (colors: string[]): [number, string][] => colors.map((c, i) => [colors.length > 1 ? i / (colors.length - 1) : 0, c]);

// MARK: - Touch (backgroundsTouch)

/**
 * `backgroundsTouch(onChanged:onEnded:)`: a drag that engages after 10 pt of mostly horizontal travel
 * (then follows the finger anywhere), plus tap-to-poke (reported for 0.45 s, then released).
 * Spread the result on the stage root.
 */
export function useBackgroundsTouch(onChanged: (p: Point) => void, onEnded: () => void = () => {}) {
  const handlers = useLatest({ onChanged, onEnded });
  const state = useRef<{ id: number; start: Point; engaged: boolean; moved: boolean } | null>(null);
  const token = useRef(0);
  const timer = useRef(0);
  useEffect(() => () => window.clearTimeout(timer.current), []);
  const release = () => {
    const s = state.current;
    state.current = null;
    if (s?.engaged) handlers.current.onEnded();
  };
  return {
    onPointerDown: (e: React.PointerEvent<HTMLElement>) => {
      if (state.current) return;
      e.currentTarget.setPointerCapture?.(e.pointerId);
      state.current = { id: e.pointerId, start: localPoint(e, e.currentTarget), engaged: false, moved: false };
    },
    onPointerMove: (e: React.PointerEvent<HTMLElement>) => {
      const s = state.current;
      if (!s || s.id !== e.pointerId) return;
      const p = localPoint(e, e.currentTarget);
      const dx = p.x - s.start.x;
      const dy = p.y - s.start.y;
      if (!s.engaged) {
        if (Math.hypot(dx, dy) < 10) return;
        s.moved = true;
        if (Math.abs(dx) <= Math.abs(dy)) return;
        s.engaged = true;
      }
      token.current += 1;
      handlers.current.onChanged(p);
    },
    onPointerUp: (e: React.PointerEvent<HTMLElement>) => {
      const s = state.current;
      if (!s || s.id !== e.pointerId) return;
      if (!s.engaged && !s.moved) {
        state.current = null;
        token.current += 1;
        const mine = token.current;
        handlers.current.onChanged(localPoint(e, e.currentTarget));
        window.clearTimeout(timer.current);
        timer.current = window.setTimeout(() => {
          if (mine === token.current && !state.current?.engaged) handlers.current.onEnded();
        }, 450);
        return;
      }
      release();
    },
    onPointerCancel: (e: React.PointerEvent<HTMLElement>) => {
      if (state.current?.id === e.pointerId) release();
    },
  };
}

/** Tap location in the element (`onTapGesture(coordinateSpace: .local)`), ignoring drags. */
export function useTap(handler: (p: Point) => void) {
  const latest = useLatest(handler);
  const down = useRef<{ id: number; p: Point } | null>(null);
  return {
    onPointerDown: (e: React.PointerEvent<HTMLElement>) => {
      down.current = { id: e.pointerId, p: localPoint(e, e.currentTarget) };
    },
    onPointerUp: (e: React.PointerEvent<HTMLElement>) => {
      const d = down.current;
      down.current = null;
      if (!d || d.id !== e.pointerId) return;
      const p = localPoint(e, e.currentTarget);
      if (Math.hypot(p.x - d.p.x, p.y - d.p.y) < 10) latest.current(p);
    },
    onPointerCancel: () => {
      down.current = null;
    },
  };
}

// MARK: - Text

/** `BackgroundSampleTitle`: a bold rounded headline + subheadline, soft shadow. */
export function SampleTitle({
  title,
  subtitle,
  color = "#fff",
  size = 30,
  top,
  style,
}: {
  title: string;
  subtitle: string;
  color?: string;
  size?: number;
  /** `.frame(maxHeight: .infinity, alignment: .top).padding(.top, top)`; centred when omitted. */
  top?: number;
  style?: CSSProperties;
}) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: top === undefined ? "center" : "flex-start",
        paddingTop: top,
        pointerEvents: "none",
        ...style,
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 6,
          padding: "0 24px",
          color,
          textAlign: "center",
          filter: "drop-shadow(0 4px 24px rgb(0 0 0 / 0.18))",
        }}
      >
        <div style={{ fontFamily: fonts.rounded, fontSize: size, fontWeight: 700, lineHeight: 1.2 }}>{title}</div>
        <div style={{ fontFamily: fonts.text, fontSize: 15, lineHeight: "20px", fontWeight: 500, opacity: 0.78 }}>{subtitle}</div>
      </div>
    </div>
  );
}

/** `backgroundsHint`: the bottom hint, dark-scheme secondary text (light for pale stages), hidden in previews. */
export function BgHint({ ctx, en, zh, light = false }: { ctx: DemoContext; en: string; zh: string; light?: boolean }) {
  if (ctx.isPreview) return null;
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 14,
        textAlign: "center",
        fontFamily: fonts.text,
        fontSize: 13,
        lineHeight: "18px",
        fontWeight: 500,
        color: light ? "rgb(60 60 67 / 0.6)" : "rgb(235 235 245 / 0.6)",
        pointerEvents: "none",
      }}
    >
      {ctx.t(en, zh)}
    </div>
  );
}

/** Full-bleed stage root: clips, isolates blend modes, takes the pointer. */
export function Stage({
  rootRef,
  background,
  children,
  handlers,
  style,
}: {
  rootRef: RefObject<HTMLDivElement | null>;
  background?: string;
  children?: ReactNode;
  handlers?: Record<string, unknown>;
  style?: CSSProperties;
}) {
  return (
    <div
      ref={rootRef}
      {...handlers}
      style={{ position: "absolute", inset: 0, overflow: "hidden", isolation: "isolate", background, touchAction: "none", ...style }}
    >
      {children}
    </div>
  );
}

/** Runs `effect` once the element has its layout size (for models that need the stage size). */
export function useMounted(effect: () => void) {
  const latest = useLatest(effect);
  useLayoutEffect(() => latest.current(), [latest]);
}
