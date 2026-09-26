/**
 * Icons category kit: SF Symbol stand-ins drawn as layered SVG (so by-layer symbol effects can move
 * each layer on its own) and the motion of the SF Symbols effects (bounce, replace, variable colour,
 * wiggle, rotate, breathe, pulse, appear/disappear, draw on/off) re-created frame by frame.
 */
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useId, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { clamp, ease, mix, springAt } from "../../kit";

// MARK: - Path helpers (24 × 24 symbol grid)

/** A circle as a closed path. */
export const circ = (cx: number, cy: number, r: number) =>
  `M${cx - r} ${cy}a${r} ${r} 0 1 0 ${2 * r} 0a${r} ${r} 0 1 0 ${-2 * r} 0Z`;

/** A rounded rectangle as a closed path. */
export const rrect = (x: number, y: number, w: number, h: number, r: number) => {
  const q = Math.min(r, w / 2, h / 2);
  return `M${x + q} ${y}h${w - 2 * q}a${q} ${q} 0 0 1 ${q} ${q}v${h - 2 * q}a${q} ${q} 0 0 1 ${-q} ${q}h${-(w - 2 * q)}a${q} ${q} 0 0 1 ${-q} ${-q}v${-(h - 2 * q)}a${q} ${q} 0 0 1 ${q} ${-q}Z`;
};

/** An arc of radius r around (cx, cy) from angle a0 to a1 (degrees, 0 = right, clockwise). */
export const arc = (cx: number, cy: number, r: number, a0: number, a1: number) => {
  const p = (a: number) => [cx + r * Math.cos((a * Math.PI) / 180), cy + r * Math.sin((a * Math.PI) / 180)];
  const [x0, y0] = p(a0);
  const [x1, y1] = p(a1);
  const large = Math.abs(a1 - a0) > 180 ? 1 : 0;
  const sweep = a1 > a0 ? 1 : 0;
  return `M${x0.toFixed(3)} ${y0.toFixed(3)}A${r} ${r} 0 ${large} ${sweep} ${x1.toFixed(3)} ${y1.toFixed(3)}`;
};

/** A toothed gear with a centre hole (evenodd). */
export function gear(cx: number, cy: number, rOuter: number, rInner: number, teeth: number, hole: number, phase = 0) {
  const pts: string[] = [];
  const step = (Math.PI * 2) / teeth;
  for (let i = 0; i < teeth; i++) {
    const a = i * step + phase;
    const ang = [a - step * 0.28, a - step * 0.16, a + step * 0.16, a + step * 0.28];
    const rad = [rInner, rOuter, rOuter, rInner];
    ang.forEach((g, k) => pts.push(`${(cx + rad[k] * Math.cos(g)).toFixed(3)} ${(cy + rad[k] * Math.sin(g)).toFixed(3)}`));
  }
  return `M${pts.join("L")}Z` + (hole > 0 ? circ(cx, cy, hole) : "");
}

// MARK: - Layered glyphs

export interface LayerDef {
  d: string;
  /** "fill": solid shape (slightly fattened by a thin stroke); "stroke": outlined; "solid": fill only. */
  mode?: "fill" | "stroke" | "solid";
  /** Stroke width in grid units (default 2 for strokes, 0.9 for fills). */
  sw?: number;
  /** Knocked out of this layer (a gap around another layer), stroked or filled. */
  cut?: { d: string; sw?: number; fill?: boolean };
  /** Hierarchical rendering: secondary layers are drawn at a lower opacity. */
  alpha?: number;
  color?: string;
  evenodd?: boolean;
}

export type GlyphDef = LayerDef[];

export interface GlyphProps {
  def: GlyphDef;
  size: number;
  color?: string;
  /** Multiplies every stroke width (symbol weight). */
  weight?: number;
  /** Per-layer style (transforms run around the layer's own box centre unless the style sets an origin). */
  layerStyle?: (index: number, count: number) => CSSProperties | undefined;
  style?: CSSProperties;
  /** An SVG paint server for every layer (e.g. a gradient `url(#id)`), drawn with `defs`. */
  paint?: string;
  defs?: ReactNode;
}

export function Glyph({ def, size, color = "currentColor", weight = 1, layerStyle, style, paint, defs }: GlyphProps) {
  const uid = useId().replace(/:/g, "");
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ overflow: "visible", display: "block", ...style }}>
      {defs && <defs>{defs}</defs>}
      {def.map((layer, i) => {
        const mode = layer.mode ?? "fill";
        const c = paint ?? layer.color ?? color;
        const sw = (layer.sw ?? (mode === "stroke" ? 2 : 0.9)) * weight;
        const maskId = layer.cut ? `${uid}-m${i}` : undefined;
        return (
          <g
            key={i}
            opacity={layer.alpha}
            style={{ transformBox: "fill-box", transformOrigin: "center", ...layerStyle?.(i, def.length) }}
          >
            {layer.cut && (
              <mask id={maskId} maskUnits="userSpaceOnUse" x={-12} y={-12} width={48} height={48}>
                <rect x={-12} y={-12} width={48} height={48} fill="#fff" />
                <path
                  d={layer.cut.d}
                  fill={layer.cut.fill ? "#000" : "none"}
                  stroke="#000"
                  strokeWidth={(layer.cut.sw ?? (layer.cut.fill ? 0 : 3)) * weight}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </mask>
            )}
            <path
              d={layer.d}
              mask={maskId ? `url(#${maskId})` : undefined}
              fill={mode === "stroke" ? "none" : c}
              fillRule={layer.evenodd ? "evenodd" : undefined}
              stroke={mode === "solid" ? "none" : c}
              strokeWidth={mode === "solid" ? 0 : sw}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </g>
        );
      })}
    </svg>
  );
}

// MARK: - Symbol definitions

const bellBody =
  "M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326Z";
const bellClapper = "M9.7 19h4.6a2.3 2.3 0 0 1-4.6 0Z" + rrect(10.7, 0.9, 2.6, 2.6, 1.3);
const slash = "M3.2 3.2 20.8 20.8";

export const SYM = {
  bellFill: [{ d: bellBody + bellClapper }] as GlyphDef,
  bellBadgeFill: [
    { d: bellBody + bellClapper, cut: { d: circ(18.6, 5, 4.9), fill: true } },
    { d: circ(18.6, 5, 3.3) },
  ] as GlyphDef,
  trayArrowDownFill: [
    { d: rrect(4, 8.8, 16, 13.4, 3.4), cut: { d: "M12 3v11.4M8.4 11 12 14.6l3.6-3.6", sw: 4.6 } },
    { d: "M12 3v11.4M8.4 11 12 14.6l3.6-3.6", mode: "stroke", sw: 1.7 },
  ] as GlyphDef,
  personCircleBadgePlus: [
    {
      d: circ(13.2, 10.8, 8.9),
      mode: "stroke",
      sw: 1.8,
      cut: { d: circ(5.8, 17.6, 6.3), fill: true },
    },
    {
      d: circ(13.2, 8.6, 3.3) + "M6.9 17.1A8.9 8.9 0 0 0 19.5 17.1c-1.5-2.4-3.7-3.7-6.3-3.7s-4.8 1.3-6.3 3.7Z",
      cut: { d: circ(5.8, 17.6, 6.3), fill: true },
    },
    { d: circ(5.8, 17.6, 4.6) + "M5.8 15v5.2M3.2 17.6h5.2", mode: "stroke", sw: 1.8 },
  ] as GlyphDef,
  paperplaneFill: [
    {
      d: "M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z",
      cut: { d: "m21.854 2.147-10.94 10.939", sw: 1.5 },
    },
  ] as GlyphDef,
  paperplane: [
    {
      d: "M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11zm7.318-19.539-10.94 10.939",
      mode: "stroke",
    },
  ] as GlyphDef,
  heart: [
    {
      d: "M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5Z",
      mode: "stroke",
    },
  ] as GlyphDef,
  heartFill: [
    {
      d: "M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5Z",
    },
  ] as GlyphDef,
  // Control toggles (replace)
  micFill: [{ d: rrect(8.4, 1.8, 7.2, 12.6, 3.6) }, { d: "M5.2 10.2v.9a6.8 6.8 0 0 0 13.6 0v-.9M12 18v3.6M8.4 21.6h7.2", mode: "stroke", sw: 2 }] as GlyphDef,
  lockFill: [{ d: rrect(4.2, 10.4, 15.6, 11.8, 2.6) }, { d: "M7.6 10.4V7.2a4.4 4.4 0 0 1 8.8 0v3.2", mode: "stroke", sw: 2.3 }] as GlyphDef,
  lockOpenFill: [{ d: rrect(2.4, 10.4, 14.6, 11.8, 2.6) }, { d: "M13.2 10.4V6.4a3.9 3.9 0 0 1 7.8 0v1.8", mode: "stroke", sw: 2.3 }] as GlyphDef,
  videoFill: [
    { d: rrect(1.4, 6, 14.4, 12, 3) },
    { d: "M17.2 10.1l4-2.6a.8.8 0 0 1 1.3.7v7.6a.8.8 0 0 1-1.3.7l-4-2.6Z" },
  ] as GlyphDef,
  // Variable colour (layer 0 = the base, then waves inner → outer)
  speakerWave3Fill: [
    { d: "M1.2 9.3a1 1 0 0 1 1-1h2.7l3.9-3.4a.9.9 0 0 1 1.5.7v12.8a.9.9 0 0 1-1.5.7l-3.9-3.4H2.2a1 1 0 0 1-1-1Z" },
    { d: arc(10.6, 12, 3.6, -48, 48), mode: "stroke", sw: 1.9 },
    { d: arc(10.6, 12, 7.1, -52, 52), mode: "stroke", sw: 1.9 },
    { d: arc(10.6, 12, 10.6, -55, 55), mode: "stroke", sw: 1.9 },
  ] as GlyphDef,
  dotRadiowaves: [
    { d: circ(12, 12, 1.9) },
    { d: arc(12, 12, 4.5, -42, 42) + arc(12, 12, 4.5, 138, 222), mode: "stroke", sw: 1.8 },
    { d: arc(12, 12, 7.8, -44, 44) + arc(12, 12, 7.8, 136, 224), mode: "stroke", sw: 1.8 },
    { d: arc(12, 12, 11.1, -46, 46) + arc(12, 12, 11.1, 134, 226), mode: "stroke", sw: 1.8 },
  ] as GlyphDef,
  antennaRadiowaves: [
    { d: circ(12, 9.4, 2) + "M12 11v11", mode: "fill", sw: 1.9 },
    { d: arc(12, 9.4, 5, -44, 44) + arc(12, 9.4, 5, 136, 224), mode: "stroke", sw: 1.9 },
    { d: arc(12, 9.4, 8.8, -46, 46) + arc(12, 9.4, 8.8, 134, 226), mode: "stroke", sw: 1.9 },
  ] as GlyphDef,
  // Ambient trio
  phoneConnectionFill: [
    {
      d: "M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384Z",
    },
    { d: "M13.6 9.4l1.6-1.6M14.6 11.6l2.6-2.6M16.8 12.6l3.6-3.6", mode: "stroke", sw: 1.9 },
  ] as GlyphDef,
  gearshape2Fill: [
    { d: gear(9, 14.2, 8.2, 6.1, 9, 2.6), mode: "solid", evenodd: true },
    { d: gear(18.4, 5.6, 5, 3.6, 7, 1.5, 0.2), mode: "solid", evenodd: true },
  ] as GlyphDef,
  boltHeartFill: [
    {
      d: "M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5Z",
      cut: { d: "M13.2 6.6 9.4 12.4h3.2l-1.6 5 4.4-6.4h-3.3Z", fill: true, sw: 0.8 },
    },
  ] as GlyphDef,
  musicNote: [
    { d: "M3.8 18.4a3.3 2.6 0 1 0 6.6 0a3.3 2.6 0 1 0 -6.6 0Z", mode: "solid" },
    { d: "M10.4 18.4V3.2c2.2 1.6 3.4 2.4 5.2 3.6 1.4 1 2 2.6 1.6 4.6", mode: "stroke", sw: 2.4 },
  ] as GlyphDef,
  // Status row
  waveform: [{ d: "M2 10v4M6 6.5v11M10 3.5v17M14 8v8M18 5v14M22 10v4", mode: "stroke", sw: 2.2 }] as GlyphDef,
  pauseCircleFill: [{ d: circ(12, 12, 10), cut: { d: "M9.7 8.5v7M14.3 8.5v7", sw: 2.4 } }] as GlyphDef,
};

/** The slashed variant of a glyph: the base layers knock out a gap along the slash. */
export const SLASH = slash;

// MARK: - Symbol effect motion (seconds since the trigger, speed already applied)

/**
 * `.bounce.up` / `.bounce.down`: a brief squash, then an elastic scale (up: grows ~15 % and hops a
 * little; down: dips to ~80 %) that settles on a spring. Returns scale and a vertical offset (fraction
 * of the symbol size).
 */
export function bounceAt(t: number, down = false): { scale: number; y: number } {
  if (t <= 0) return { scale: 1, y: 0 };
  if (down) {
    if (t < 0.12) return { scale: mix(1, 0.8, ease.out(t / 0.12)), y: mix(0, 0.04, ease.out(t / 0.12)) };
    const s = springAt(t - 0.12, 0.34, 0.5);
    return { scale: mix(0.8, 1, s), y: mix(0.04, 0, s) };
  }
  if (t < 0.08) return { scale: mix(1, 0.9, ease.out(t / 0.08)), y: 0 };
  if (t < 0.22) {
    const p = ease.out((t - 0.08) / 0.14);
    return { scale: mix(0.9, 1.16, p), y: mix(0, -0.1, p) };
  }
  const s = springAt(t - 0.22, 0.36, 0.55);
  return { scale: mix(1.16, 1, s), y: mix(-0.1, 0, s) };
}
export const BOUNCE_DURATION = 1.1;

/** `.wiggle` repeating (isActive): three shrinking swings, then a rest. Degrees. */
export function wiggleAt(t: number, period = 1.5): number {
  const c = ((t % period) + period) % period;
  const active = 0.75;
  if (c > active) return 0;
  const p = c / active;
  return 11 * Math.sin(p * Math.PI * 3) * (1 - p) * Math.min(1, p * 6);
}

/** `.wiggle` once (value trigger). */
export function wiggleOnce(t: number): number {
  if (t <= 0 || t >= 0.75) return 0;
  return wiggleAt(t, 10);
}

/** `.rotate` repeating: clockwise turns, each eased in and out. Degrees. */
export function rotateAt(t: number, period = 1.25): number {
  const turns = Math.floor(t / period);
  const p = (t % period) / period;
  return (turns + ease.inOut(p)) * 360;
}

/** `.rotate` once (value trigger): one eased clockwise turn in 0.9 s. */
export function rotateOnce(t: number): number {
  if (t <= 0) return 0;
  return 360 * ease.inOut(clamp(t / 0.9));
}

/** `.breathe` repeating: a slow swell and fade. */
export function breatheAt(t: number, period = 2): { scale: number; opacity: number } {
  const w = 0.5 - 0.5 * Math.cos((t / period) * Math.PI * 2);
  return { scale: 1 + 0.12 * w, opacity: 1 - 0.3 * w };
}

/** `.pulse` repeating: opacity dips and recovers. */
export function pulseAt(t: number, period = 1.3): number {
  const w = 0.5 - 0.5 * Math.cos((t / period) * Math.PI * 2);
  return 1 - 0.65 * w;
}

/**
 * `.variableColor` on `n` variable layers: which layers are lit at time `t`.
 * Cumulative lights layers one after another (and, reversing, turns them off outer-first);
 * iterative lights one at a time.
 */
export function variableColorLit(t: number, n: number, cumulative: boolean, reversing: boolean, step = 0.22): boolean[] {
  const seq: number[] = [];
  if (cumulative) {
    for (let k = 0; k <= n; k++) seq.push(k);
    if (reversing) for (let k = n - 1; k >= 1; k--) seq.push(k);
  } else {
    seq.push(-1);
    for (let k = 0; k < n; k++) seq.push(k);
    if (reversing) for (let k = n - 2; k >= 1; k--) seq.push(k);
  }
  const k = seq[Math.floor(t / step) % seq.length];
  return Array.from({ length: n }, (_, i) => (cumulative ? i < k : i === k));
}

// MARK: - Replace transition

export type ReplaceStyle = "downUp" | "upUp" | "offUp";

/**
 * `.contentTransition(.symbolEffect(.replace))`: the outgoing symbol scales away (down, or up for
 * `.upUp`, or vanishes at once for `.offUp`) and blurs out while the incoming one grows in from small
 * on a snappy spring. Keyed children overlap in one grid cell.
 */
export function Replace({
  k,
  children,
  kind = "downUp",
  speed = 1,
  style,
}: {
  k: string | number;
  children: ReactNode;
  kind?: ReplaceStyle;
  speed?: number;
  style?: CSSProperties;
}) {
  const s = Math.max(speed, 0.1);
  const exitScale = kind === "upUp" ? 1.3 : 0.35;
  return (
    <span style={{ display: "inline-grid", placeItems: "center", ...style }}>
      <AnimatePresence initial={false}>
        <motion.span
          key={k}
          initial={{ scale: 0.35, opacity: 0, filter: "blur(3px)" }}
          animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
          exit={
            kind === "offUp"
              ? { opacity: 0, transition: { duration: 0 } }
              : { scale: exitScale, opacity: 0, filter: "blur(3px)", transition: { duration: 0.2 / s, ease: [0.3, 0, 0.8, 0.6] } }
          }
          transition={{
            scale: { type: "spring", stiffness: (2 * Math.PI / (0.38 / s)) ** 2, damping: (4 * Math.PI * 0.62) / (0.38 / s), delay: 0.08 / s },
            opacity: { duration: 0.16 / s, delay: 0.08 / s },
            filter: { duration: 0.2 / s, delay: 0.08 / s },
          }}
          style={{ gridArea: "1 / 1", display: "grid", placeItems: "center" }}
        >
          {children}
        </motion.span>
      </AnimatePresence>
    </span>
  );
}

// MARK: - Stage layout

/** `VStack(spacing:)` centred in `.frame(maxWidth: .infinity, maxHeight: .infinity)`. */
export function Centered({ gap = 0, children, style, onClick }: { gap?: number; children: ReactNode; style?: CSSProperties; onClick?: () => void }) {
  return (
    <div
      onClick={onClick}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap, ...style }}
    >
      {children}
    </div>
  );
}

/** SF Symbol point size → glyph box size for the 24-unit symbol drawings. */
export const sym = (points: number) => Math.round(points * 1.25);

// MARK: - Keyframe tracks (`keyframeAnimator`)

/** SwiftUI's `.snappy` / `.bouncy` / `.smooth` springs as (response, dampingFraction). */
export const SPRINGS = {
  snappy: [0.5, 0.85] as [number, number],
  bouncy: [0.5, 0.7] as [number, number],
  smooth: [0.5, 1] as [number, number],
};

export type Keyframe =
  | { kind: "linear"; to: number; d: number }
  | { kind: "cubic"; to: number; d: number }
  | { kind: "spring"; to: number; d: number; spring?: [number, number] }
  | { kind: "move"; to: number };

export const L = (to: number, d: number): Keyframe => ({ kind: "linear", to, d });
export const C = (to: number, d: number): Keyframe => ({ kind: "cubic", to, d });
export const S = (to: number, d: number, spring: [number, number] = SPRINGS.smooth): Keyframe => ({ kind: "spring", to, d, spring });

/** Total duration of a track. */
export const trackDuration = (frames: Keyframe[]) => frames.reduce((sum, f) => sum + (f.kind === "move" ? 0 : f.d), 0);

/**
 * Value of a `KeyframeTrack` at `t` seconds. Cubic keyframes follow a Catmull-Rom spline through
 * their neighbours (zero velocity at the ends), springs run from the previous value and land on
 * their target at the end of the segment, linear keyframes interpolate linearly.
 */
export function track(t: number, initial: number, frames: Keyframe[]): number {
  let start = 0;
  let from = initial;
  const values: number[] = [initial];
  const times: number[] = [0];
  for (const f of frames) {
    const d = f.kind === "move" ? 0 : f.d;
    values.push(f.to);
    times.push(times[times.length - 1] + d);
  }
  for (let k = 0; k < frames.length; k++) {
    const f = frames[k];
    if (f.kind === "move") {
      from = f.to;
      continue;
    }
    const end = start + f.d;
    if (t < end || k === frames.length - 1) {
      const p = f.d <= 0 ? 1 : clamp((t - start) / f.d);
      if (f.kind === "linear") return mix(from, f.to, p);
      if (f.kind === "spring") {
        const [r, z] = f.spring ?? SPRINGS.smooth;
        const endP = springAt(f.d, r, z) || 1;
        return mix(from, f.to, p >= 1 ? 1 : springAt(p * f.d, r, z) / endP);
      }
      // Cubic: Hermite with Catmull-Rom tangents.
      const i = k + 1;
      const tangent = (j: number) => {
        if (j <= 0 || j >= values.length - 1) return 0;
        const prev = frames[j - 1];
        const next = frames[j];
        if (prev?.kind !== "cubic" && next?.kind !== "cubic") return 0;
        const dt = times[j + 1] - times[j - 1];
        return dt > 0 ? (values[j + 1] - values[j - 1]) / dt : 0;
      };
      const m0 = tangent(i - 1) * f.d;
      const m1 = (frames[k + 1]?.kind === "cubic" ? tangent(i) : 0) * f.d;
      const p2 = p * p;
      const p3 = p2 * p;
      return (2 * p3 - 3 * p2 + 1) * from + (p3 - 2 * p2 + p) * m0 + (-2 * p3 + 3 * p2) * f.to + (p3 - p2) * m1;
    }
    from = f.to;
    start = end;
  }
  return from;
}

/** `tint.gradient`: the colour with a soft top-to-bottom sheen. */
export const tintGradient = (c: string) => `linear-gradient(color-mix(in srgb, ${c} 88%, white), color-mix(in srgb, ${c} 92%, black))`;

/**
 * Seconds since `trigger` last changed, re-rendering every frame for `duration` seconds; -1 until
 * the first change. (Like the kit's `useElapsed(trigger, duration, true)`, but it compares against
 * the value seen at mount, so React StrictMode's double-run effects cannot start it early.)
 */
export function useSince(trigger: unknown, duration: number): number {
  const initial = useRef(trigger);
  const started = useRef(false);
  const [elapsed, setElapsed] = useState(-1);
  useEffect(() => {
    if (!started.current && Object.is(trigger, initial.current)) return;
    started.current = true;
    let raf = 0;
    const start = performance.now();
    const step = (now: number) => {
      const e = Math.min((now - start) / 1000, duration);
      setElapsed(e);
      if (e < duration) raf = requestAnimationFrame(step);
    };
    setElapsed(0);
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [trigger, duration]);
  return elapsed;
}
