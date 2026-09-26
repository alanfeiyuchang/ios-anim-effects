/**
 * Shared pieces of the Text category. Most Swift demos here draw with a `TextRenderer` that moves
 * every glyph on its own; on the web the text is split into one inline-block span per character
 * (`Glyphs`), and a gradient `foregroundStyle` spanning the whole line is kept continuous by giving
 * each span the same background, offset to where the span sits in the line.
 */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { Fragment, useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";

/** Grapheme-ish split (code points; enough for the Latin and CJK copy used here). */
export const chars = (text: string) => Array.from(text);

/** Number of glyphs a `TextRenderer` would see (line breaks are not drawn). */
export const glyphCount = (text: string) => chars(text).filter((c) => c !== "\n").length;

interface Box {
  x: number;
  y: number;
}

/** Measures every glyph span's layout offset inside the container (transforms ignored). */
function useGlyphOffsets(enabled: boolean, deps: unknown[]) {
  const container = useRef<HTMLSpanElement>(null);
  const [layout, setLayout] = useState<{ w: number; h: number; boxes: Box[] } | null>(null);
  useLayoutEffect(() => {
    if (!enabled) return;
    const measure = () => {
      const el = container.current;
      if (!el) return;
      const boxes: Box[] = [];
      el.querySelectorAll<HTMLElement>("[data-glyph]").forEach((g) => boxes.push({ x: g.offsetLeft, y: g.offsetTop }));
      setLayout({ w: el.offsetWidth, h: el.offsetHeight, boxes });
    };
    measure();
    void document.fonts?.ready.then(measure);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enabled, ...deps]);
  return { container, layout };
}

/**
 * A line (or several, split on "\n") of per-glyph spans.
 * `glyph(i, n, ch)` returns the style of glyph `i` of `n` (line breaks excluded from the count).
 * `fill` is a CSS background (gradient) painted through the text across the whole block.
 */
export function Glyphs({
  text,
  style,
  glyph,
  fill,
  align = "center",
  lineStyle,
}: {
  text: string;
  style?: CSSProperties;
  glyph?: (i: number, n: number, ch: string) => CSSProperties | undefined;
  fill?: string;
  align?: CSSProperties["textAlign"];
  lineStyle?: CSSProperties;
}) {
  const lines = text.split("\n");
  const n = glyphCount(text);
  const { container, layout } = useGlyphOffsets(!!fill, [text, fill, style?.fontSize, style?.fontFamily, style?.fontWeight, style?.letterSpacing]);
  let index = 0;
  return (
    <span ref={container} style={{ display: "inline-block", position: "relative", textAlign: align, whiteSpace: "pre", ...style }}>
      {lines.map((line, li) => (
        <Fragment key={li}>
          <span style={{ display: "block", ...lineStyle }}>
            {chars(line).map((ch) => {
              const i = index++;
              const box = layout?.boxes[i];
              const paint: CSSProperties | undefined = fill
                ? {
                    backgroundImage: fill,
                    backgroundSize: layout ? `${layout.w}px ${layout.h}px` : "100% 100%",
                    backgroundPosition: box ? `${-box.x}px ${-box.y}px` : "0 0",
                    backgroundRepeat: "no-repeat",
                    WebkitBackgroundClip: "text",
                    backgroundClip: "text",
                    color: "transparent",
                    WebkitTextFillColor: "transparent",
                  }
                : undefined;
              return (
                <span key={i} data-glyph="" style={{ display: "inline-block", whiteSpace: "pre", ...paint, ...glyph?.(i, n, ch) }}>
                  {ch}
                </span>
              );
            })}
          </span>
        </Fragment>
      ))}
    </span>
  );
}

/** Text painted with a gradient (`.foregroundStyle(LinearGradient…)` on a whole `Text`). */
export function GradientText({ children, fill, style }: { children: ReactNode; fill: string; style?: CSSProperties }) {
  return (
    <span
      style={{
        display: "inline-block",
        backgroundImage: fill,
        WebkitBackgroundClip: "text",
        backgroundClip: "text",
        color: "transparent",
        WebkitTextFillColor: "transparent",
        whiteSpace: "pre",
        ...style,
      }}
    >
      {children}
    </span>
  );
}

/**
 * `.contentTransition(.numericText(value:))` with the transition of the surrounding
 * `withAnimation` (the kit's `NumericText` always uses one fixed spring).
 */
export function RollingText({
  value,
  text,
  transition,
  style,
  charStyle,
}: {
  value: number;
  text?: string;
  transition: Transition;
  style?: CSSProperties;
  charStyle?: CSSProperties;
}) {
  const shown = text ?? String(value);
  const previous = useRef(value);
  const direction = value >= previous.current ? 1 : -1;
  useEffect(() => {
    previous.current = value;
  }, [value]);
  const list = chars(shown);
  return (
    <span style={{ display: "inline-flex", fontVariantNumeric: "tabular-nums", ...style }}>
      <AnimatePresence initial={false} mode="popLayout">
        {list.map((c, i) => (
          <motion.span
            layout="position"
            key={list.length - i}
            transition={transition}
            style={{ position: "relative", display: "inline-block" }}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <AnimatePresence initial={false} mode="popLayout" custom={direction}>
              <motion.span
                key={c}
                custom={direction}
                variants={{
                  enter: (d: number) => ({ y: `${60 * d}%`, opacity: 0, scale: 0.9, filter: "blur(3px)" }),
                  center: { y: "0%", opacity: 1, scale: 1, filter: "blur(0px)" },
                  exit: (d: number) => ({ y: `${-60 * d}%`, opacity: 0, scale: 0.9, filter: "blur(3px)" }),
                }}
                initial="enter"
                animate="center"
                exit="exit"
                transition={transition}
                style={{ display: "inline-block", whiteSpace: "pre", ...charStyle }}
              >
                {c}
              </motion.span>
            </AnimatePresence>
          </motion.span>
        ))}
      </AnimatePresence>
    </span>
  );
}

/** `Color.gradient` (AnyGradient): the colour, a touch lighter at the top. */
export const colorGradient = (color: string) => `linear-gradient(color-mix(in srgb, ${color}, white 14%), ${color})`;
/** The same lift as a layer over an animated `backgroundColor`: `backgroundImage: SHEEN`. */
export const SHEEN = "linear-gradient(rgb(255 255 255 / 0.14), rgb(255 255 255 / 0))";

/** Cancellable `Task.sleep` loop: `useTask(key, async (sleep, alive) => { … })`. */
export function useTask(key: unknown, body: (sleep: (seconds: number) => Promise<boolean>, alive: () => boolean) => Promise<void> | void) {
  const latest = useRef(body);
  latest.current = body;
  useEffect(() => {
    let cancelled = false;
    const timers = new Set<number>();
    const sleep = (seconds: number) =>
      new Promise<boolean>((resolve) => {
        const id = window.setTimeout(() => {
          timers.delete(id);
          resolve(!cancelled);
        }, Math.max(seconds, 0) * 1000);
        timers.add(id);
      });
    void latest.current(sleep, () => !cancelled);
    return () => {
      cancelled = true;
      timers.forEach((id) => window.clearTimeout(id));
    };
  }, [key]);
}

/** Swift's `Int.random(in: lo...hi)`. */
export const randInt = (lo: number, hi: number) => lo + Math.floor(Math.random() * (hi - lo + 1));
/** Swift's `Double.random(in: lo...hi)`. */
export const randIn = (lo: number, hi: number) => lo + Math.random() * (hi - lo);

/** `Double.formatted(.number.precision(.fractionLength(n)))` (en-US grouping, which zh-Hans shares). */
export const formatNumber = (value: number, fraction = 0) =>
  value.toLocaleString("en-US", { minimumFractionDigits: fraction, maximumFractionDigits: fraction });

/** `design: .serif` as iOS renders it: New York for Latin, PingFang (not Songti) for CJK. */
export const serifCJK = `ui-serif, "New York", Georgia, "Times New Roman", system-ui, -apple-system, "PingFang SC", "Microsoft YaHei", serif`;

/**
 * SwiftUI `LinearGradient(stops, startPoint: UnitPoint, endPoint: UnitPoint)` drawn in a `w`×`h`
 * box, as a CSS `linear-gradient` (the same axis and colour positions; unit points may lie outside
 * 0…1, like the moving bands of a shimmer).
 */
export function unitGradient(
  w: number,
  h: number,
  start: { x: number; y: number },
  end: { x: number; y: number },
  stops: { color: string; location: number }[],
): string {
  const sx = start.x * w, sy = start.y * h;
  const ex = end.x * w, ey = end.y * h;
  let dx = ex - sx, dy = ey - sy;
  if (dx === 0 && dy === 0) dy = 1;
  // CSS angle: 0deg points up, 90deg right; direction (sin θ, −cos θ).
  const theta = Math.atan2(dx, -dy);
  const dirX = Math.sin(theta), dirY = -Math.cos(theta);
  const length = Math.abs(w * dirX) + Math.abs(h * dirY) || 1;
  const along = (px: number, py: number) => ((px - w / 2) * dirX + (py - h / 2) * dirY) / length + 0.5;
  const t0 = along(sx, sy);
  const t1 = along(ex, ey);
  const list = stops.map((s) => `${s.color} ${((t0 + s.location * (t1 - t0)) * 100).toFixed(3)}%`).join(", ");
  return `linear-gradient(${((theta * 180) / Math.PI).toFixed(3)}deg, ${list})`;
}

/** Evenly spaced stops (SwiftUI `colors:`). */
export const evenStops = (colors: string[]) => colors.map((color, i) => ({ color, location: colors.length > 1 ? i / (colors.length - 1) : 0 }));

/** Measures an element's layout size (`offsetWidth/Height`), re-measured after fonts load. */
export function useSize<T extends HTMLElement>(deps: unknown[] = []) {
  const ref = useRef<T>(null);
  const [size, setSize] = useState({ w: 0, h: 0 });
  useLayoutEffect(() => {
    const measure = () => {
      const el = ref.current;
      if (el) setSize((s) => (s.w === el.offsetWidth && s.h === el.offsetHeight ? s : { w: el.offsetWidth, h: el.offsetHeight }));
    };
    measure();
    void document.fonts?.ready.then(measure);
    const el = ref.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
  return [ref, size] as const;
}

let measureCanvas: CanvasRenderingContext2D | null = null;
/** Natural width of `text` in a CSS font shorthand (for `.minimumScaleFactor` fitting). */
export function measureText(text: string, font: string): number {
  if (!measureCanvas) measureCanvas = document.createElement("canvas").getContext("2d");
  if (!measureCanvas) return 0;
  measureCanvas.font = font;
  return measureCanvas.measureText(text).width;
}

/** `.lineLimit(1).minimumScaleFactor(min)`: the font size that fits `text` into `width`. */
export function fittedSize(text: string, size: number, width: number, font: (size: number) => string, min = 0.6): number {
  const natural = measureText(text, font(size));
  if (!natural || natural <= width) return size;
  return size * Math.max(min, width / natural);
}
