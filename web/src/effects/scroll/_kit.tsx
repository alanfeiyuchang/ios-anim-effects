/**
 * Shared pieces of the Scroll & Lists category: `ScrollKit` sample content (Scroll+Shared.swift),
 * `ScrollKitRow` / `ScrollKitIcon` / `ScrollKitArt`, SF Symbol stand-ins, the frame-rate independent
 * `ScrollVelocityTracker`, and `useScroller`, the web twin of a SwiftUI `ScrollView` with
 * `ScrollPosition`, `onScrollGeometryChange`, `onScrollPhaseChange` and a `ScrollTargetBehavior`.
 */
import { AnimatePresence, animate, motion, type Transition } from "motion/react";
import {
  ArrowUp,
  Bell,
  Bird,
  Blend,
  Bolt,
  Book,
  CircleUser,
  Cloud,
  CloudRain,
  Contrast,
  Crown,
  Diamond,
  Earth,
  Film,
  Flame,
  Globe,
  Heart,
  House,
  Leaf,
  Moon,
  MoonStar,
  Mountain,
  Music2,
  Plus,
  RotateCw,
  Search,
  Snowflake,
  Sparkles,
  SquarePlus,
  Star,
  Sun,
  Triangle,
  Waves,
  X,
  Zap,
  type LucideIcon,
} from "lucide-react";
import { useCallback, useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { Palette, clamp, elementScale, fonts, rubberBand, spring, useHaptics, useLatest, white, black, type Lang } from "../../kit";
import "./scroll.css";

// MARK: - Sample content

const titles: [string, string][] = [
  ["Aurora", "极光"], ["Nebula", "星云"], ["Lagoon", "泻湖"], ["Ember", "余烬"],
  ["Tundra", "冻原"], ["Monsoon", "季风"], ["Solstice", "至日"], ["Cirrus", "卷云"],
  ["Meridian", "子午线"], ["Halcyon", "翠鸟"], ["Zenith", "天顶"], ["Drift", "漂流"],
];

const symbols = [
  "sparkles", "moon.stars.fill", "water.waves", "flame.fill", "snowflake", "cloud.rain.fill",
  "sun.max.fill", "cloud.fill", "globe.europe.africa.fill", "bird.fill", "star.fill", "leaf.fill",
];

export const wrap = (index: number, count: number) => ((index % count) + count) % count;

export const ScrollKit = {
  title(index: number, lang: Lang) {
    const t = titles[wrap(index, titles.length)];
    return lang === "zh" ? t[1] : t[0];
  },
  subtitle(index: number, lang: Lang) {
    const count = 6 + ((wrap(index, 97) * 7) % 30);
    return lang === "zh" ? `${count} 项 · 今日更新` : `${count} items · Updated today`;
  },
  symbol(index: number) {
    return symbols[wrap(index, symbols.length)];
  },
  colors(index: number): [string, string] {
    const s = Palette.spectrum;
    const k = wrap(index, s.length);
    return [s[k], s[(k + 1) % s.length]];
  },
  /** `LinearGradient(colors: ScrollKit.colors(i), startPoint: .topLeading, endPoint: .bottomTrailing)` */
  gradient(index: number) {
    const [a, b] = ScrollKit.colors(index);
    return `linear-gradient(135deg, ${a}, ${b})`;
  },
  time(index: number) {
    const i = wrap(index, 997);
    return `${8 + (i % 4)}:${String((i * 13) % 60).padStart(2, "0")}`;
  },
};

// MARK: - SF Symbols

const SYMBOLS: Record<string, { icon: LucideIcon; fill?: boolean; rotate?: number }> = {
  sparkles: { icon: Sparkles, fill: true },
  "moon.stars.fill": { icon: MoonStar, fill: true },
  "water.waves": { icon: Waves },
  "flame.fill": { icon: Flame, fill: true },
  snowflake: { icon: Snowflake },
  "cloud.rain.fill": { icon: CloudRain, fill: true },
  "sun.max.fill": { icon: Sun, fill: true },
  "cloud.fill": { icon: Cloud, fill: true },
  "globe.europe.africa.fill": { icon: Earth },
  "bird.fill": { icon: Bird },
  "star.fill": { icon: Star, fill: true },
  "leaf.fill": { icon: Leaf, fill: true, rotate: 40 },
  "music.note": { icon: Music2 },
  plus: { icon: Plus },
  globe: { icon: Globe },
  magnifyingglass: { icon: Search },
  "house.fill": { icon: House, fill: true },
  "plus.app.fill": { icon: SquarePlus },
  "bell.fill": { icon: Bell, fill: true },
  "person.crop.circle": { icon: CircleUser },
  "arrow.up": { icon: ArrowUp },
  "book.fill": { icon: Book, fill: true },
  xmark: { icon: X },
  "arrow.clockwise": { icon: RotateCw },
  "heart.fill": { icon: Heart, fill: true },
  "bolt.fill": { icon: Zap, fill: true },
  "moon.fill": { icon: Moon, fill: true },
  "crown.fill": { icon: Crown, fill: true },
  "diamond.fill": { icon: Diamond, fill: true },
  "film.fill": { icon: Film },
  "mountain.2.fill": { icon: Mountain, fill: true },
  "camera.filters": { icon: Blend },
  "circle.lefthalf.filled": { icon: Contrast },
  "triangle.fill": { icon: Triangle, fill: true },
  gear: { icon: Bolt },
};

/**
 * `Image(systemName:).font(.system(size:weight:))` stand-in. `size` is the font's point size; the
 * glyph is drawn about as large as the SF Symbol would be.
 */
export function Sym({
  name,
  size,
  weight = 600,
  color = "currentColor",
  style,
}: {
  name: string;
  size: number;
  weight?: number;
  color?: string;
  style?: CSSProperties;
}) {
  const entry = SYMBOLS[name] ?? { icon: Star, fill: true };
  const Icon = entry.icon;
  const px = size * 1.2;
  const stroke = weight >= 800 ? 2.9 : weight >= 700 ? 2.6 : weight >= 600 ? 2.35 : weight >= 500 ? 2.1 : 1.9;
  return (
    <Icon
      size={px}
      color={color}
      strokeWidth={entry.fill ? Math.min(stroke, 2) : stroke}
      fill={entry.fill ? color : "none"}
      style={{ display: "block", flexShrink: 0, transform: entry.rotate ? `rotate(${entry.rotate}deg)` : undefined, ...style }}
    />
  );
}

// MARK: - Rows, icons, artwork

/** Rounded-square gradient icon with a symbol (`ScrollKitIcon`). */
export function ScrollKitIcon({ index, size = 44, circle = false, style }: { index: number; size?: number; circle?: boolean; style?: CSSProperties }) {
  return (
    <div
      style={{
        width: size,
        height: size,
        flexShrink: 0,
        borderRadius: circle ? "50%" : size * 0.28,
        background: ScrollKit.gradient(index),
        display: "grid",
        placeItems: "center",
        color: "#fff",
        ...style,
      }}
    >
      <Sym name={ScrollKit.symbol(index)} size={size * 0.42} weight={600} />
    </div>
  );
}

export const ROW_HEIGHT = 68;

/** A compact list row: gradient icon tile, title, subtitle and optional timestamp (`ScrollKitRow`). */
export function ScrollKitRow({
  index,
  lang,
  showsMeta = true,
  style,
  children,
}: {
  index: number;
  lang: Lang;
  showsMeta?: boolean;
  style?: CSSProperties;
  children?: ReactNode;
}) {
  return (
    <div
      style={{
        position: "relative",
        height: ROW_HEIGHT,
        display: "flex",
        alignItems: "center",
        gap: 12,
        padding: 12,
        borderRadius: 18,
        background: Palette.elevated,
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
        ...style,
      }}
    >
      <ScrollKitIcon index={index} />
      <div style={{ display: "flex", flexDirection: "column", gap: 3, minWidth: 0 }}>
        <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, whiteSpace: "nowrap" }}>{ScrollKit.title(index, lang)}</div>
        <div style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, whiteSpace: "nowrap" }}>{ScrollKit.subtitle(index, lang)}</div>
      </div>
      <div style={{ flex: 1 }} />
      {showsMeta && (
        <div style={{ fontSize: 12, lineHeight: "16px", color: Palette.tertiaryLabel, fontVariantNumeric: "tabular-nums" }}>{ScrollKit.time(index)}</div>
      )}
      {children}
    </div>
  );
}

/** Flexible gradient artwork used by carousels (`ScrollKitArt`); the caller sizes and clips it. */
export function ScrollKitArt({ index, lang, showsTitle = true, style }: { index: number; lang: Lang; showsTitle?: boolean; style?: CSSProperties }) {
  return (
    <div style={{ position: "absolute", inset: 0, background: ScrollKit.gradient(index), overflow: "hidden", ...style }}>
      <ArtDecor index={index} />
      {showsTitle && (
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            bottom: 0,
            padding: 14,
            display: "flex",
            flexDirection: "column",
            gap: 2,
            color: "#fff",
            background: `linear-gradient(transparent, ${black(0.28)})`,
          }}
        >
          <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 700, whiteSpace: "nowrap" }}>{ScrollKit.title(index, lang)}</div>
          <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, opacity: 0.85, whiteSpace: "nowrap" }}>{ScrollKit.subtitle(index, lang)}</div>
        </div>
      )}
    </div>
  );
}

/** Centred decor: blurred light blob, ring and the big symbol. */
function ArtDecor({ index }: { index: number }) {
  const centred = (w: number, x: number, y: number): CSSProperties => ({
    position: "absolute",
    left: "50%",
    top: "50%",
    width: w,
    height: w,
    marginLeft: -w / 2 + x,
    marginTop: -w / 2 + y,
    borderRadius: "50%",
  });
  return (
    <>
      <div style={{ ...centred(150, 50, -60), background: white(0.22), filter: "blur(22px)" }} />
      <div style={{ ...centred(120, -60, 70), boxShadow: `inset 0 0 0 14px ${white(0.16)}` }} />
      <div
        style={{
          position: "absolute",
          left: "50%",
          top: "50%",
          transform: "translate(-50%, -50%) translateY(-12px)",
          color: white(0.95),
          filter: `drop-shadow(0 4px 8px ${black(0.15)})`,
        }}
      >
        <Sym name={ScrollKit.symbol(index)} size={50} weight={600} />
      </div>
    </>
  );
}

// MARK: - Velocity

/** `ScrollVelocityTracker`: smoothed pt/s from offset samples, 25 ms time constant. */
export class ScrollVelocityTracker {
  velocity = 0;
  private lastOffset: number | null = null;
  private lastTime = 0;

  sample(offset: number, limit: number): number {
    const now = performance.now() / 1000;
    if (this.lastOffset === null) {
      this.lastOffset = offset;
      this.lastTime = now;
      return this.velocity;
    }
    const dt = now - this.lastTime;
    if (dt < 0.004) return this.velocity;
    const previous = this.lastOffset;
    this.lastOffset = offset;
    this.lastTime = now;
    if (dt > 0.1) this.velocity = 0;
    const raw = clamp((offset - previous) / dt, -limit, limit);
    const alpha = 1 - Math.exp(-dt / 0.025);
    this.velocity += (raw - this.velocity) * alpha;
    return this.velocity;
  }

  reset() {
    this.velocity = 0;
  }
}

// MARK: - Scroller

export type ScrollPhase = "idle" | "interacting" | "decelerating" | "animating";

export interface ScrollerOptions {
  axis?: "x" | "y";
  /**
   * `ScrollTargetBehavior`: maps a proposed resting offset to the snapped one. Also turns on CSS
   * scroll snapping (give the snap targets `scrollSnapAlign`, or render `<SnapMarkers>`).
   */
  snap?: (proposed: number) => number;
  /** Rubber-band past the ends when dragged with a mouse, pulled at an edge by touch, or wheeled. */
  bounce?: boolean;
  /** Starting offset (the app's `onAppear { position.scrollTo(...) }`). */
  initial?: number;
  /** `.scrollDisabled(_:)` */
  disabled?: boolean;
  onPhase?: (phase: ScrollPhase, previous: ScrollPhase) => void;
  /** Every offset change (`onScrollGeometryChange`), including overscroll. */
  onScroll?: (offset: number) => void;
}

/** Tunes a SwiftUI animation for scroll offsets (points, not unit progress). */
function forOffsets(t: Transition): Transition {
  return { ...t, restDelta: 0.05, restSpeed: 2 } as Transition;
}

/** UIScrollView's bounce-back after a pull. */
const bounceBack = spring(0.45, 1);

/**
 * A native overflow scroll view (touch and wheel scroll natively; a mouse can drag it like a finger)
 * with the parts of SwiftUI's scroll API the demos use. `offset` is `contentOffset` along the axis:
 * negative when pulled past the start, larger than `max()` past the end.
 *
 *     const sc = useScroller({ axis: "y" });
 *     <div {...sc.props} style={{ ...sc.props.style, height: 300 }}><div ref={sc.contentRef}>…</div></div>
 *     sc.scrollTo(200, anim.smoothD(1.2));
 */
export function useScroller(options: ScrollerOptions = {}) {
  const axis = options.axis ?? "y";
  const opts = useLatest(options);
  const ref = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const [offset, setOffset] = useState(options.initial ?? 0);
  const [phase, setPhaseState] = useState<ScrollPhase>("idle");
  /** The scroll view's own size (`containerSize`), measured before the first paint. */
  const [size, setSize] = useState({ width: 0, height: 0 });
  const s = useRef({
    over: 0,
    phase: "idle" as ScrollPhase,
    anim: null as null | { stop(): void },
    idleTimer: 0,
    wheelTimer: 0,
    wheelOver: 0,
    touching: false,
    /** Manual drag (mouse, or a touch that started pulling at an edge). */
    drag: null as null | {
      startPos: number;
      origin: number;
      scale: number;
      last: number;
      lastTime: number;
      velocity: number;
    },
    suppressClick: false,
    /** Last position set in code: its scroll event is not a user scroll. */
    expect: NaN,
  });

  const el = () => ref.current;
  const pos = () => {
    const e = el();
    return e ? (axis === "y" ? e.scrollTop : e.scrollLeft) : 0;
  };
  const max = useCallback(() => {
    const e = ref.current;
    if (!e) return 0;
    return Math.max(axis === "y" ? e.scrollHeight - e.clientHeight : e.scrollWidth - e.clientWidth, 0);
  }, [axis]);
  const viewport = useCallback(() => {
    const e = ref.current;
    if (!e) return 1;
    return Math.max(axis === "y" ? e.clientHeight : e.clientWidth, 1);
  }, [axis]);
  const get = useCallback(() => {
    const e = ref.current;
    return (e ? (axis === "y" ? e.scrollTop : e.scrollLeft) : 0) + s.current.over;
  }, [axis]);

  const sync = () => {
    const o = pos() + s.current.over;
    setOffset(o);
    opts.current.onScroll?.(o);
  };
  const applyOver = (v: number) => {
    s.current.over = v;
    const c = contentRef.current;
    if (c) c.style.transform = Math.abs(v) < 0.01 ? "" : axis === "y" ? `translate3d(0, ${-v}px, 0)` : `translate3d(${-v}px, 0, 0)`;
  };
  const setPhase = (p: ScrollPhase) => {
    const prev = s.current.phase;
    if (prev === p) return;
    s.current.phase = p;
    setPhaseState(p);
    opts.current.onPhase?.(p, prev);
  };
  const cssSnap = (on: boolean) => {
    const e = el();
    if (!e) return;
    e.style.scrollSnapType = on && opts.current.snap ? `${axis} mandatory` : "none";
  };
  /** Puts the content at `v` (overscroll beyond either end is shown by translating the content). */
  const place = (v: number) => {
    const e = el();
    if (!e) return;
    const m = max();
    const c = clamp(v, 0, m);
    if (axis === "y") e.scrollTop = c;
    else e.scrollLeft = c;
    s.current.expect = pos();
    // Browsers round scroll positions: keep the exact value in the overscroll translation.
    applyOver(v - pos());
    sync();
  };
  const stop = () => {
    s.current.anim?.stop();
    s.current.anim = null;
  };
  const scheduleIdle = () => {
    window.clearTimeout(s.current.idleTimer);
    s.current.idleTimer = window.setTimeout(() => {
      if (!s.current.touching && !s.current.anim && !s.current.drag) {
        cssSnap(true);
        setPhase("idle");
      }
    }, 150);
  };
  const run = (from: number, to: number, transition: Transition, p: ScrollPhase) => {
    stop();
    cssSnap(false);
    setPhase(p);
    const controls = animate(from, to, {
      ...(forOffsets(transition) as object),
      onUpdate: (v: number) => place(v),
      onComplete: () => {
        if (s.current.anim !== controls) return;
        s.current.anim = null;
        cssSnap(true);
        setPhase("idle");
      },
    } as never);
    s.current.anim = controls;
  };

  /** `position.scrollTo(...)` inside `withAnimation(transition)`; `null` jumps without animation. */
  const scrollTo = useCallback(
    (target: number | "end", transition: Transition | null = null) => {
      const m = max();
      const to = target === "end" ? m : clamp(target, 0, m);
      if (!transition) {
        stop();
        place(to);
        return;
      }
      run(get(), to, transition, "animating");
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [max, get],
  );

  // Manual drags (mouse; touch pulls at an edge).
  const beginDrag = (client: number, scale: number) => {
    stop();
    cssSnap(false);
    const now = performance.now();
    s.current.drag = { startPos: get(), origin: client, scale, last: client, lastTime: now, velocity: 0 };
    setPhase("interacting");
  };
  const moveDrag = (client: number) => {
    const d = s.current.drag;
    if (!d) return;
    const now = performance.now();
    const dt = Math.max((now - d.lastTime) / 1000, 1 / 240);
    const v = -(client - d.last) / d.scale / dt;
    d.velocity = d.velocity * 0.6 + v * 0.4;
    d.last = client;
    d.lastTime = now;
    const raw = d.startPos - (client - d.origin) / d.scale;
    const m = max();
    const vp = viewport();
    const bounce = opts.current.bounce ?? true;
    const v2 = raw < 0 ? (bounce ? rubberBand(raw, vp) : 0) : raw > m ? m + (bounce ? rubberBand(raw - m, vp) : 0) : raw;
    place(v2);
  };
  const endDrag = () => {
    const d = s.current.drag;
    if (!d) return;
    s.current.drag = null;
    const velocity = performance.now() - d.lastTime > 80 ? 0 : d.velocity;
    const cur = get();
    const m = max();
    if (cur < 0 || cur > m) {
      run(cur, clamp(cur, 0, m), bounceBack, "decelerating");
      return;
    }
    const snapFn = opts.current.snap;
    if (!snapFn && Math.abs(velocity) < 20) {
      cssSnap(true);
      setPhase("idle");
      return;
    }
    stop();
    setPhase("decelerating");
    const controls = animate(cur, cur, {
      type: "inertia",
      velocity,
      power: 0.4995,
      timeConstant: 499.5,
      min: 0,
      max: m,
      bounceStiffness: 195,
      bounceDamping: 28,
      restDelta: 0.1,
      modifyTarget: snapFn ? (t: number) => clamp(snapFn(clamp(t, 0, m)), 0, m) : undefined,
      onUpdate: (v: number) => place(v),
      onComplete: () => {
        if (s.current.anim !== controls) return;
        s.current.anim = null;
        cssSnap(true);
        setPhase("idle");
      },
    } as never);
    s.current.anim = controls;
  };

  // Native listeners: scroll, wheel (edge bounce), touch (edge pulls).
  useEffect(() => {
    const e = ref.current;
    if (!e) return;
    const state = s.current;
    const along = (t: Touch) => (axis === "y" ? t.clientY : t.clientX);
    const across = (t: Touch) => (axis === "y" ? t.clientX : t.clientY);
    let touchStart: { a: number; c: number; mode: "pending" | "native" | "manual" } | null = null;

    const onScroll = () => {
      if (state.anim || state.drag) return;
      sync();
      if (Math.abs(pos() - state.expect) < 0.5) return;
      state.expect = NaN;
      if (state.phase === "idle" || state.phase === "animating") setPhase(state.touching ? "interacting" : "decelerating");
      scheduleIdle();
    };
    const onWheel = (ev: WheelEvent) => {
      if (opts.current.disabled) return;
      const delta = (axis === "y" ? ev.deltaY : ev.deltaX || (ev.shiftKey ? ev.deltaY : 0)) * (ev.deltaMode === 1 ? 16 : 1);
      if (delta === 0) return;
      if (state.anim) {
        stop();
        cssSnap(true);
      }
      setPhase("interacting");
      scheduleIdle();
      if (!(opts.current.bounce ?? true)) return;
      const p = pos();
      const m = max();
      const atStart = p <= 0.5 && (delta < 0 || state.wheelOver < 0);
      const atEnd = p >= m - 0.5 && (delta > 0 || state.wheelOver > 0);
      if (!atStart && !atEnd) return;
      const next = state.wheelOver + delta;
      state.wheelOver = atStart ? Math.min(next, 0) : Math.max(next, 0);
      applyOver(rubberBand(state.wheelOver, viewport()) * 0.8);
      sync();
      window.clearTimeout(state.wheelTimer);
      state.wheelTimer = window.setTimeout(() => {
        state.wheelOver = 0;
        const cur = get();
        if (cur < 0 || cur > max()) run(cur, clamp(cur, 0, max()), bounceBack, "decelerating");
      }, 110);
    };
    const onTouchStart = (ev: TouchEvent) => {
      if (opts.current.disabled || ev.touches.length !== 1) return;
      state.touching = true;
      if (state.anim) {
        stop();
        cssSnap(true);
      }
      setPhase("interacting");
      const t = ev.touches[0];
      touchStart = { a: along(t), c: across(t), mode: "pending" };
    };
    const onTouchMove = (ev: TouchEvent) => {
      if (opts.current.disabled) {
        if (ev.cancelable) ev.preventDefault();
        return;
      }
      if (!touchStart || ev.touches.length !== 1) return;
      const t = ev.touches[0];
      if (touchStart.mode === "pending") {
        const da = along(t) - touchStart.a;
        const dc = across(t) - touchStart.c;
        if (Math.abs(da) < 3 && Math.abs(dc) < 3) return;
        const p = pos();
        const pulling = (p <= 0.5 && da > 0) || (p >= max() - 0.5 && da < 0);
        if (Math.abs(da) > Math.abs(dc) && pulling && (opts.current.bounce ?? true) && ev.cancelable) {
          touchStart.mode = "manual";
          beginDrag(touchStart.a, elementScale(e) || 1);
        } else {
          touchStart.mode = "native";
        }
      }
      if (touchStart.mode === "manual") {
        if (ev.cancelable) ev.preventDefault();
        moveDrag(along(t));
      }
    };
    const onTouchEnd = () => {
      if (!state.touching) return;
      state.touching = false;
      if (touchStart?.mode === "manual") endDrag();
      else {
        setPhase("decelerating");
        scheduleIdle();
      }
      touchStart = null;
    };
    e.addEventListener("scroll", onScroll, { passive: true });
    e.addEventListener("wheel", onWheel, { passive: true });
    e.addEventListener("touchstart", onTouchStart, { passive: true });
    e.addEventListener("touchmove", onTouchMove, { passive: false });
    e.addEventListener("touchend", onTouchEnd);
    e.addEventListener("touchcancel", onTouchEnd);
    return () => {
      e.removeEventListener("scroll", onScroll);
      e.removeEventListener("wheel", onWheel);
      e.removeEventListener("touchstart", onTouchStart);
      e.removeEventListener("touchmove", onTouchMove);
      e.removeEventListener("touchend", onTouchEnd);
      e.removeEventListener("touchcancel", onTouchEnd);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [axis]);

  useLayoutEffect(() => {
    const e = ref.current;
    if (!e) return;
    const measure = () => setSize((old) => (old.width === e.clientWidth && old.height === e.clientHeight ? old : { width: e.clientWidth, height: e.clientHeight }));
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(e);
    return () => observer.disconnect();
  }, []);

  // Initial position (`onAppear { position.scrollTo(...) }`) and snapping.
  useLayoutEffect(() => {
    cssSnap(true);
    if (options.initial) place(options.initial);
    const state = s.current;
    return () => {
      state.anim?.stop();
      state.anim = null;
      window.clearTimeout(state.idleTimer);
      window.clearTimeout(state.wheelTimer);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const onPointerDown = (ev: React.PointerEvent<HTMLDivElement>) => {
    if (ev.pointerType !== "mouse" || ev.button !== 0 || opts.current.disabled) return;
    const e = ev.currentTarget;
    const scale = elementScale(e) || 1;
    const read = (m: PointerEvent | React.PointerEvent) => (axis === "y" ? m.clientY : m.clientX);
    const start = read(ev);
    const startCross = axis === "y" ? ev.clientX : ev.clientY;
    let dragging = false;
    const move = (m: PointerEvent) => {
      if (!dragging) {
        const moved = Math.hypot(read(m) - start, (axis === "y" ? m.clientX : m.clientY) - startCross) / scale;
        if (moved < 4) return;
        dragging = true;
        beginDrag(start, scale);
      }
      moveDrag(read(m));
    };
    const up = () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", up);
      if (dragging) {
        s.current.suppressClick = true;
        window.setTimeout(() => (s.current.suppressClick = false), 0);
        endDrag();
      }
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
  };
  const onClickCapture = (ev: React.MouseEvent) => {
    if (s.current.suppressClick) {
      ev.stopPropagation();
      ev.preventDefault();
      s.current.suppressClick = false;
    }
  };

  const style: CSSProperties = {
    position: "relative",
    overflowX: axis === "x" && !options.disabled ? "auto" : "hidden",
    overflowY: axis === "y" && !options.disabled ? "auto" : "hidden",
    touchAction: options.disabled ? "none" : axis === "y" ? "pan-y" : "pan-x",
  };

  return {
    ref,
    contentRef,
    offset,
    phase,
    size,
    phaseRef: s,
    scrollTo,
    get,
    max,
    viewport,
    stop,
    props: { ref, className: "ml-scroller", onPointerDown, onClickCapture, style },
  };
}

export type Scroller = ReturnType<typeof useScroller>;

/**
 * Invisible CSS snap targets every `pitch` points (`ScrollStrideSnap`): at offset `i * pitch` the
 * marker `i` sits at the scroll view's leading edge. Place inside the (position: relative) content.
 */
export function SnapMarkers({ count, pitch, axis = "x" }: { count: number; pitch: number; axis?: "x" | "y" }) {
  return (
    <>
      {Array.from({ length: count }, (_, i) => (
        <div
          key={i}
          aria-hidden
          style={{
            position: "absolute",
            pointerEvents: "none",
            scrollSnapAlign: "start",
            ...(axis === "x" ? { left: i * pitch, top: 0, width: 1, height: 1 } : { top: i * pitch, left: 0, width: 1, height: 1 }),
          }}
        />
      ))}
    </>
  );
}

/** `ScrollStrideSnap(pitch:)` */
export const strideSnap = (pitch: number) => (v: number) => Math.round(v / pitch) * pitch;

/** SwiftUI's `rotation3DEffect(perspective:)`: CSS perspective distance for a view of this size. */
export const perspectivePx = (width: number, height: number, perspective: number) => Math.max(width, height) / Math.max(perspective, 0.01);

/** SwiftUI `.blur(radius:)` as a CSS blur length (SwiftUI's radius reads softer than CSS's). */
export const swiftBlur = (radius: number) => (radius > 0.01 ? `blur(${(radius * 0.75).toFixed(2)}px)` : undefined);

/** `.brightness(x)` (additive in SwiftUI) as a CSS filter factor. */
export const brightness = (x: number) => `brightness(${Math.max(0, 1 + x * 1.6)})`;

export { fonts };

/** `Text(...).contentTransition(.interpolate / .opacity).animation(.snappy, value:)`: a quick cross-fade. */
export function FadeText({ text, style, duration = 0.3 }: { text: string; style?: CSSProperties; duration?: number }) {
  return (
    <div style={{ position: "relative", display: "grid", placeItems: "center", ...style }}>
      <AnimatePresence initial={false} mode="popLayout">
        <motion.span
          key={text}
          initial={{ opacity: 0, filter: "blur(2px)" }}
          animate={{ opacity: 1, filter: "blur(0px)" }}
          exit={{ opacity: 0, filter: "blur(2px)" }}
          transition={{ duration, ease: [0.25, 0.1, 0.25, 1] }}
          style={{ gridArea: "1 / 1", whiteSpace: "nowrap" }}
        >
          {text}
        </motion.span>
      </AnimatePresence>
    </div>
  );
}

/**
 * A number animated like a `@State` changed inside `withAnimation`: `const [v, to] = useAnimated(0)`,
 * `to(80, spring(0.55, 0.85))`; `to(x, null)` jumps. Re-renders every frame while it moves.
 */
export function useAnimated(initial: number): [number, (target: number, transition?: Transition | null) => void, () => number] {
  const [value, setValue] = useState(initial);
  const current = useRef(initial);
  const controls = useRef<{ stop(): void } | null>(null);
  useEffect(() => () => controls.current?.stop(), []);
  const to = useCallback((target: number, transition: Transition | null = null) => {
    controls.current?.stop();
    if (!transition) {
      current.current = target;
      setValue(target);
      return;
    }
    controls.current = animate(current.current, target, {
      ...(transition as object),
      onUpdate: (v: number) => {
        current.current = v;
        setValue(v);
      },
    } as never);
  }, []);
  const get = useCallback(() => current.current, []);
  return [value, to, get];
}

/** `.scrollTransition(.interactive)` phase: 0 fully visible, −1 / +1 once fully past the top / bottom edge. */
export function edgePhase(top: number, height: number, viewport: number): number {
  if (top < 0) return Math.max(top / height, -1);
  if (top + height > viewport) return Math.min((top + height - viewport) / height, 1);
  return 0;
}

/**
 * `.onChange(of: value) { if !ctx.isPreview && !scripted { Haptics.selection() } }`: a selection tick
 * whenever `value` changes by a real scroll (not while `scripted` is set by autoplay).
 */
export function useSelectionTick(value: unknown, preview: boolean, scripted: { current: boolean }) {
  const haptics = useHaptics();
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    if (!preview && !scripted.current) haptics.selection();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);
}
