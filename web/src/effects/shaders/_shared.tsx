/**
 * Shared pieces of the Shaders category (ShaderEffects.swift + MotionLab/Shaders/Shaders.metal):
 *
 * - `LIB`: the Metal helpers (`mlHash`, `mlNoise`, `mlFbm`) in GLSL ES 1.0, plus `S(p)`, SwiftUI's
 *   `layer.sample(p)` in points (transparent outside the layer, like the padded Metal layer).
 * - `useLayer(w, h)`: the offscreen 2D canvas a `.layerEffect` / `.colorEffect` samples (the SwiftUI view
 *   underneath), drawn in points at 2–3 px per point and passed to `ShaderCanvas` as `source`.
 * - `drawArtwork`: `ShaderArtwork(variant:)`, the colourful sample card, drawn on that canvas.
 * - `drawGridArtwork`: `ShaderGridArtwork`.
 * - `SpeedClock`: `ShaderClock`'s accumulated, speed-scaled time.
 * - `useStageTouch`: `backgroundsTouch` (horizontal-first drag + tap-to-poke).
 */
import { renderToStaticMarkup } from "react-dom/server";
import { createElement, useMemo, useRef, type ComponentType } from "react";
import { Droplet, Flag, Flame, Scan, Sparkles, Tornado, Waves, Zap } from "lucide-react";
import { Palette, fonts, localPoint, type Point } from "../../kit";

// MARK: - GLSL

export const LIB = `
float mlHash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float mlNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = mlHash(i);
  float b = mlHash(i + vec2(1.0, 0.0));
  float c = mlHash(i + vec2(0.0, 1.0));
  float d = mlHash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float mlFbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int k = 0; k < 4; k++) {
    value += amplitude * mlNoise(p);
    p *= 2.0;
    amplitude *= 0.5;
  }
  return value;
}
vec4 S(vec2 p) {
  vec2 uv = p / u_size;
  if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return vec4(0.0);
  return texture2D(u_tex, uv);
}
`;

/** `Color(hex:)` → [r, g, b] in 0…1 (sRGB, like the Metal `half4` colour arguments). */
export function rgb(hex: number | string): [number, number, number] {
  const n = typeof hex === "string" ? parseInt(hex.replace("#", ""), 16) : hex;
  return [((n >> 16) & 0xff) / 255, ((n >> 8) & 0xff) / 255, (n & 0xff) / 255];
}
export function rgba(hex: number | string, a = 1): string {
  const [r, g, b] = rgb(hex);
  return `rgba(${Math.round(r * 255)},${Math.round(g * 255)},${Math.round(b * 255)},${a})`;
}

// MARK: - Layer canvas

export interface Layer {
  canvas: HTMLCanvasElement;
  /** Clears the canvas and runs `draw` in point space. */
  paint(draw: (g: CanvasRenderingContext2D, k: number) => void): void;
}

/** Offscreen canvas of `w × h` points (the layer a shader samples). */
export function useLayer(w: number, h: number): Layer {
  return useMemo(() => {
    const canvas = document.createElement("canvas");
    const k = Math.min(3, Math.max(2, Math.ceil((window.devicePixelRatio || 1) * 1.25)));
    canvas.width = Math.round(w * k);
    canvas.height = Math.round(h * k);
    const g = canvas.getContext("2d")!;
    return {
      canvas,
      paint(draw) {
        g.setTransform(1, 0, 0, 1, 0, 0);
        g.globalAlpha = 1;
        g.globalCompositeOperation = "source-over";
        g.clearRect(0, 0, canvas.width, canvas.height);
        g.setTransform(k, 0, 0, k, 0, 0);
        g.save();
        draw(g, k);
        g.restore();
      },
    };
  }, [w, h]);
}

// MARK: - Icons (SF Symbols → lucide, rasterised for canvas drawing)

const iconCache = new Map<string, HTMLImageElement>();

/** A white lucide icon as an image (null until it has loaded). */
export function iconImage(Icon: ComponentType<Record<string, unknown>>, key: string, props: Record<string, unknown>): HTMLImageElement | null {
  let img = iconCache.get(key);
  if (!img) {
    const svg = renderToStaticMarkup(createElement(Icon, { size: 96, color: "#fff", ...props }));
    img = new Image();
    img.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
    iconCache.set(key, img);
  }
  return img.complete && img.naturalWidth > 0 ? img : null;
}

/** Draws a lucide icon image centred at (x, y), `size` points square (the 24-unit viewBox). */
export function drawIcon(g: CanvasRenderingContext2D, img: HTMLImageElement | null, x: number, y: number, size: number) {
  if (img) g.drawImage(img, x - size / 2, y - size / 2, size, size);
}

type IconSpec = { Icon: ComponentType<Record<string, unknown>>; fill: boolean; size: number };
const I = (Icon: unknown, fill: boolean, size: number): IconSpec => ({ Icon: Icon as ComponentType<Record<string, unknown>>, fill, size });

// MARK: - ShaderArtwork

interface Look {
  colors: string[];
  accent: string;
  icon: IconSpec;
  word: string;
  disc: Point;
  dot: Point;
}

const LOOKS: Look[] = [
  { colors: [Palette.indigo, Palette.violet, Palette.pink], accent: Palette.amber, icon: I(Sparkles, true, 74), word: "MOTION", disc: { x: 80, y: -100 }, dot: { x: -86, y: 84 } },
  { colors: [Palette.mint, Palette.sky, Palette.blue], accent: Palette.pink, icon: I(Droplet, true, 70), word: "SHADER", disc: { x: 80, y: -100 }, dot: { x: -86, y: 84 } },
  { colors: [Palette.sky, Palette.blue, Palette.indigo], accent: Palette.mint, icon: I(Waves, false, 74), word: "RIPPLE", disc: { x: -70, y: -110 }, dot: { x: 90, y: 96 } },
  { colors: ["#1E1B4B", Palette.indigo, Palette.violet], accent: Palette.sky, icon: I(Flame, true, 70), word: "EMBER", disc: { x: 86, y: 110 }, dot: { x: -84, y: -96 } },
  { colors: [Palette.violet, Palette.pink, Palette.coral], accent: Palette.amber, icon: I(Tornado, false, 72), word: "TWIRL", disc: { x: -90, y: 90 }, dot: { x: 88, y: -104 } },
  { colors: [Palette.pink, Palette.violet, Palette.sky], accent: Palette.mint, icon: I(Zap, true, 70), word: "SPEED", disc: { x: 70, y: 104 }, dot: { x: -92, y: -70 } },
  { colors: ["#14B8A6", Palette.blue, "#312E81"], accent: Palette.amber, icon: I(Scan, false, 70), word: "SCAN", disc: { x: -84, y: -96 }, dot: { x: 90, y: 90 } },
  { colors: [Palette.coral, Palette.amber, Palette.pink], accent: Palette.sky, icon: I(Flag, true, 70), word: "BREEZE", disc: { x: -76, y: 104 }, dot: { x: 94, y: -92 } },
];

export const ART_W = 260;
export const ART_H = 300;

function rrect(g: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  g.beginPath();
  g.roundRect(x, y, w, h, r);
}

/** `ShaderArtwork(variant:)`: 260 × 300, gradient, two discs, symbol + word, clipped to radius 30. */
export function drawArtwork(g: CanvasRenderingContext2D, k: number, variant: number, x = 0, y = 0, alpha = 1) {
  const look = LOOKS[variant] ?? LOOKS[0];
  const w = ART_W;
  const h = ART_H;
  g.save();
  g.globalAlpha = alpha;
  g.translate(x, y);
  rrect(g, 0, 0, w, h, 30);
  g.clip();
  const grad = g.createLinearGradient(0, 0, w, h);
  look.colors.forEach((c, i) => grad.addColorStop(i / (look.colors.length - 1), c));
  g.fillStyle = grad;
  g.fillRect(0, 0, w, h);
  g.fillStyle = "rgba(255,255,255,0.22)";
  g.beginPath();
  g.arc(w / 2 + look.disc.x, h / 2 + look.disc.y, 95, 0, Math.PI * 2);
  g.fill();
  g.fillStyle = rgba(look.accent, 0.75);
  g.beginPath();
  g.arc(w / 2 + look.dot.x, h / 2 + look.dot.y, 48, 0, Math.PI * 2);
  g.fill();
  // Symbol (≈ 64 pt tall) + word (32 pt heavy rounded, tracking 4), VStack(spacing: 10) centred.
  g.shadowColor = "rgba(0,0,0,0.18)";
  g.shadowBlur = 8 * k;
  g.shadowOffsetY = 4 * k;
  const spec = look.icon;
  const img = iconImage(spec.Icon, `art-${variant}`, spec.fill ? { fill: "#fff", strokeWidth: 2 } : { strokeWidth: 2.2 });
  drawIcon(g, img, w / 2, h / 2 - 24, spec.size);
  g.fillStyle = "#fff";
  g.font = `800 32px ${fonts.rounded}`;
  g.textAlign = "center";
  g.textBaseline = "middle";
  (g as CanvasRenderingContext2D & { letterSpacing: string }).letterSpacing = "4px";
  g.fillText(look.word, w / 2 + 2, h / 2 + 32);
  (g as CanvasRenderingContext2D & { letterSpacing: string }).letterSpacing = "0px";
  g.restore();
}

/** `ShaderGridArtwork`: dark gradient, 22 pt grid, "Aa 永" and a mono line in a sky → violet → pink gradient. */
export function drawGridArtwork(g: CanvasRenderingContext2D, w: number, h: number) {
  const bg = g.createLinearGradient(0, 0, 0, h);
  bg.addColorStop(0, "#14162B");
  bg.addColorStop(1, "#2A2360");
  g.fillStyle = bg;
  g.fillRect(0, 0, w, h);
  g.strokeStyle = "rgba(255,255,255,0.18)";
  g.lineWidth = 1;
  g.beginPath();
  for (let x = 0; x <= w; x += 22) {
    g.moveTo(x, 0);
    g.lineTo(x, h);
  }
  for (let y = 0; y <= h; y += 22) {
    g.moveTo(0, y);
    g.lineTo(w, y);
  }
  g.stroke();
  g.textAlign = "center";
  g.textBaseline = "middle";
  g.font = `700 64px ${fonts.serif}`;
  const big = "Aa 永";
  g.font = `500 13px ${fonts.mono}`;
  const small = "The quick brown fox · 动效词典";
  const smallW = g.measureText(small).width;
  g.font = `700 64px ${fonts.serif}`;
  const bigW = g.measureText(big).width;
  const blockW = Math.max(smallW, bigW);
  // VStack(spacing: 6): 64 pt serif line (≈ 76) + 13 pt mono line (≈ 16).
  const top = h / 2 - (76 + 6 + 16) / 2;
  const grad = g.createLinearGradient(w / 2 - blockW / 2, 0, w / 2 + blockW / 2, 0);
  grad.addColorStop(0, Palette.sky);
  grad.addColorStop(0.5, Palette.violet);
  grad.addColorStop(1, Palette.pink);
  g.fillStyle = grad;
  g.fillText(big, w / 2, top + 38);
  g.font = `500 13px ${fonts.mono}`;
  g.globalAlpha = 0.8;
  g.fillText(small, w / 2, top + 76 + 6 + 8);
  g.globalAlpha = 1;
}

// MARK: - Clock

/** `ShaderClock`: accumulates `speed`-scaled seconds, clamping frame gaps to 1/20 s. */
export class SpeedClock {
  private last: number | null = null;
  phase = 0;
  delta = 0;
  advance(now: number, speed: number) {
    this.delta = this.last === null ? 0 : Math.min(Math.max(now - this.last, 0), 1 / 20);
    this.last = now;
    this.phase += this.delta * speed;
    return this.phase;
  }
  follow(rate: number) {
    return 1 - Math.exp(-this.delta * rate);
  }
}

export function useSpeedClock() {
  const ref = useRef<SpeedClock | null>(null);
  if (!ref.current) ref.current = new SpeedClock();
  return ref.current;
}

export const nowSec = () => performance.now() / 1000;
export const randIn = (a: number, b: number) => a + Math.random() * (b - a);

// MARK: - backgroundsTouch

/**
 * `backgroundsTouch(onChanged:onEnded:)`: a drag that engages after 10 pt of mostly horizontal travel (then
 * follows in any direction), plus a tap that pokes: reports the point, then ends 0.45 s later.
 * Spread the returned handlers on the element; locations are in its own points.
 */
export function useStageTouch(onChanged: (p: Point) => void, onEnded: () => void) {
  const latest = useRef({ onChanged, onEnded });
  latest.current = { onChanged, onEnded };
  const state = useRef<{ id: number; start: Point; client: Point; scale: number; engaged: boolean; moved: boolean } | null>(null);
  const token = useRef(0);
  const point = (s: NonNullable<typeof state.current>, e: { clientX: number; clientY: number }): Point => ({
    x: s.start.x + (e.clientX - s.client.x) / s.scale,
    y: s.start.y + (e.clientY - s.client.y) / s.scale,
  });
  return {
    onPointerDown: (e: React.PointerEvent<HTMLElement>) => {
      if (state.current) return;
      const el = e.currentTarget;
      el.setPointerCapture(e.pointerId);
      const rect = el.getBoundingClientRect();
      const scale = el.offsetWidth ? rect.width / el.offsetWidth : 1;
      state.current = { id: e.pointerId, start: localPoint(e, el), client: { x: e.clientX, y: e.clientY }, scale: scale || 1, engaged: false, moved: false };
    },
    onPointerMove: (e: React.PointerEvent<HTMLElement>) => {
      const s = state.current;
      if (!s || s.id !== e.pointerId) return;
      const p = point(s, e);
      const dx = p.x - s.start.x;
      const dy = p.y - s.start.y;
      if (!s.moved && Math.hypot(dx, dy) < 10) return;
      s.moved = true;
      if (!s.engaged) {
        if (Math.abs(dx) <= Math.abs(dy)) return;
        s.engaged = true;
      }
      token.current += 1;
      latest.current.onChanged(p);
    },
    onPointerUp: (e: React.PointerEvent<HTMLElement>) => {
      const s = state.current;
      if (!s || s.id !== e.pointerId) return;
      state.current = null;
      if (s.engaged) {
        latest.current.onEnded();
        return;
      }
      if (s.moved) return;
      token.current += 1;
      const t = token.current;
      latest.current.onChanged(s.start);
      window.setTimeout(() => {
        if (t === token.current && !state.current?.engaged) latest.current.onEnded();
      }, 450);
    },
    onPointerCancel: (e: React.PointerEvent<HTMLElement>) => {
      const s = state.current;
      if (!s || s.id !== e.pointerId) return;
      state.current = null;
      if (s.engaged) latest.current.onEnded();
    },
    style: { touchAction: "none" as const },
  };
}

/**
 * `LongPressGesture(minimumDuration:).sequenced(before: DragGesture(minimumDistance: 0))`: `onArm` fires once the
 * finger has stayed within 10 pt for `hold` seconds, then `onDrag` follows every move until the finger lifts
 * (`onEnd`). A touch that moves first (a swipe) never arms.
 */
export function useHoldDrag(
  hold: number,
  handlers: {
    onArm?: (start: Point) => void;
    onDrag?: (s: { start: Point; location: Point; translation: Point; velocity: Point }) => void;
    onEnd?: () => void;
  },
) {
  const latest = useRef(handlers);
  latest.current = handlers;
  const state = useRef<{
    id: number;
    start: Point;
    client: Point;
    scale: number;
    armed: boolean;
    timer: number;
    last: Point;
    lastTime: number;
    velocity: Point;
  } | null>(null);
  const point = (s: NonNullable<typeof state.current>, e: { clientX: number; clientY: number }): Point => ({
    x: s.start.x + (e.clientX - s.client.x) / s.scale,
    y: s.start.y + (e.clientY - s.client.y) / s.scale,
  });
  const finish = (e: React.PointerEvent<HTMLElement>) => {
    const s = state.current;
    if (!s || s.id !== e.pointerId) return;
    window.clearTimeout(s.timer);
    state.current = null;
    if (s.armed) latest.current.onEnd?.();
  };
  return {
    onPointerDown: (e: React.PointerEvent<HTMLElement>) => {
      if (state.current) return;
      e.stopPropagation();
      const el = e.currentTarget;
      el.setPointerCapture(e.pointerId);
      const rect = el.getBoundingClientRect();
      const scale = (el.offsetWidth ? rect.width / el.offsetWidth : 1) || 1;
      const start = localPoint(e, el);
      const s = {
        id: e.pointerId,
        start,
        client: { x: e.clientX, y: e.clientY },
        scale,
        armed: false,
        timer: 0,
        last: start,
        lastTime: performance.now(),
        velocity: { x: 0, y: 0 },
      };
      s.timer = window.setTimeout(() => {
        if (state.current !== s) return;
        s.armed = true;
        latest.current.onArm?.(s.start);
        latest.current.onDrag?.({ start: s.start, location: s.last, translation: { x: s.last.x - s.start.x, y: s.last.y - s.start.y }, velocity: { x: 0, y: 0 } });
      }, hold * 1000);
      state.current = s;
    },
    onPointerMove: (e: React.PointerEvent<HTMLElement>) => {
      const s = state.current;
      if (!s || s.id !== e.pointerId) return;
      const p = point(s, e);
      const now = performance.now();
      const dt = Math.max((now - s.lastTime) / 1000, 1 / 240);
      s.velocity = { x: s.velocity.x * 0.6 + ((p.x - s.last.x) / dt) * 0.4, y: s.velocity.y * 0.6 + ((p.y - s.last.y) / dt) * 0.4 };
      s.last = p;
      s.lastTime = now;
      if (!s.armed) {
        if (Math.hypot(p.x - s.start.x, p.y - s.start.y) > 10) {
          window.clearTimeout(s.timer);
          state.current = null;
        }
        return;
      }
      latest.current.onDrag?.({ start: s.start, location: p, translation: { x: p.x - s.start.x, y: p.y - s.start.y }, velocity: s.velocity });
    },
    onPointerUp: finish,
    onPointerCancel: finish,
    style: { touchAction: "none" as const },
  };
}

// MARK: - Plain layer display

/** Shows a layer canvas as-is (an unshaded view, e.g. the incoming scene under a transition). */
export function LayerView({ layer, width, height, style }: { layer: Layer; width: number; height: number; style?: React.CSSProperties }) {
  return (
    <div
      ref={(el) => {
        if (!el || layer.canvas.parentElement === el) return;
        layer.canvas.style.width = `${width}px`;
        layer.canvas.style.height = `${height}px`;
        layer.canvas.style.display = "block";
        el.appendChild(layer.canvas);
      }}
      style={{ width, height, ...style }}
    />
  );
}

/** The adaptive system colours for drawing on a canvas (kit.css values). */
export function systemColors(scheme: "dark" | "light") {
  return scheme === "dark"
    ? { label: "#fff", label2: "rgba(235,235,245,0.6)", label3: "rgba(235,235,245,0.3)", elevated: "#2c2c2e" }
    : { label: "#000", label2: "rgba(60,60,67,0.6)", label3: "rgba(60,60,67,0.3)", elevated: "#ffffff" };
}

/** `SwapScenes.variant`: the artwork variants the transitions cycle through. */
export const swapVariant = (i: number) => [1, 5, 7, 3][((i % 4) + 4) % 4];
