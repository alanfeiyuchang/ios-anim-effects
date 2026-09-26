/**
 * Shared sport helpers of the showcase category (SportEffects.swift): the eyebrow row, the pulsing
 * live dot, the press style of tappable cards and the procedural hash.
 */
import { motion } from "motion/react";
import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { pressHandlers, spring, useClock } from "../../kit";
import { Signature, signatureEyebrow } from "./signature";

/** `sportHash(x)`: deterministic pseudo-random value in 0..<1. */
export function sportHash(x: number): number {
  const n = Math.sin(x * 12.9898 + 78.233) * 43758.5453;
  return n - Math.floor(n);
}

/** `SportEyebrowRow`: optional orange glyph, uppercase title, optional trailing caption (fills its row). */
export function SportEyebrowRow({ title, icon, trailing, style }: { title: string; icon?: ReactNode; trailing?: ReactNode; style?: CSSProperties }) {
  return (
    <div style={{ ...signatureEyebrow(), display: "flex", alignItems: "center", gap: 6, flex: 1, minWidth: 0, ...style }}>
      {icon && <span style={{ display: "grid", color: Signature.accent }}>{icon}</span>}
      <span style={{ whiteSpace: "nowrap" }}>{title}</span>
      <span style={{ flex: 1 }} />
      {trailing != null && <span style={{ whiteSpace: "nowrap" }}>{trailing}</span>}
    </div>
  );
}

/** `SportLiveDot`: a dot with a ring that keeps pulsing outward (frame = size × 3). */
export function SportLiveDot({ color = Signature.accent, size = 8, period = 1.4, preview = false }: { color?: string; size?: number; period?: number; preview?: boolean }) {
  const t = useClock(true, preview ? 30 : undefined);
  const p = (t % period) / period;
  return (
    <span style={{ position: "relative", width: size * 3, height: size * 3, display: "grid", placeItems: "center", flexShrink: 0 }}>
      <span
        style={{
          position: "absolute",
          width: size,
          height: size,
          borderRadius: "50%",
          boxShadow: `inset 0 0 0 1.5px ${color}`,
          opacity: 1 - p,
          transform: `scale(${1 + p * 1.8})`,
        }}
      />
      <span style={{ position: "absolute", width: size, height: size, borderRadius: "50%", background: color, boxShadow: `0 0 4px ${color}cc` }} />
    </span>
  );
}

/**
 * `SportPressStyle(scale:dim:)` as a wrapper: sinks and dims while pressed with a spring(0.3, 0.7).
 * `forced` shows the pressed look (autoplay).
 */
export function SportPress({
  scale = 0.96,
  dim = 0.08,
  onClick,
  children,
  style,
  forced = false,
  radius,
}: {
  scale?: number;
  dim?: number;
  onClick?: () => void;
  children: ReactNode;
  style?: CSSProperties;
  forced?: boolean;
  radius?: number;
}) {
  const [pressed, setPressed] = useState(false);
  const down = pressed || forced;
  return (
    <motion.button
      type="button"
      {...pressHandlers(setPressed)}
      onClick={onClick}
      animate={{ scale: down ? scale : 1, filter: `brightness(${down ? 1 - dim : 1})` }}
      transition={spring(0.3, 0.7)}
      style={{ display: "block", padding: 0, border: 0, background: "none", color: "inherit", font: "inherit", textAlign: "inherit", cursor: "pointer", borderRadius: radius, ...style }}
    >
      {children}
    </motion.button>
  );
}

/**
 * `TimelineView(.animation) { Canvas { … } }`: a 2D canvas redrawn every frame (30 fps in previews).
 * `draw(g, t, w, h)` gets a context scaled to canvas points and `t`, seconds since an arbitrary epoch.
 */
export function CanvasLayer({
  width,
  height,
  draw,
  fps,
  running = true,
  style,
}: {
  /** Omit both to fill the positioned parent (measured on mount). */
  width?: number;
  height?: number;
  draw: (g: CanvasRenderingContext2D, t: number, w: number, h: number) => void;
  fps?: number;
  running?: boolean;
  style?: CSSProperties;
}) {
  const ref = useRef<HTMLCanvasElement>(null);
  const latest = useRef(draw);
  latest.current = draw;
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const dpr = Math.max(2, window.devicePixelRatio || 1);
    const w = width ?? el.offsetWidth;
    const h = height ?? el.offsetHeight;
    el.width = Math.round(w * dpr);
    el.height = Math.round(h * dpr);
    const g = el.getContext("2d");
    if (!g) return;
    let raf = 0;
    let last = 0;
    const frame = (now: number) => {
      if (!fps || now - last >= 1000 / fps - 1) {
        last = now;
        g.setTransform(dpr, 0, 0, dpr, 0, 0);
        g.clearRect(0, 0, w, h);
        latest.current(g, 1000 + now / 1000, w, h);
      }
      if (running) raf = requestAnimationFrame(frame);
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [width, height, fps, running]);
  return <canvas ref={ref} style={{ position: "absolute", left: 0, top: 0, width: width ?? "100%", height: height ?? "100%", pointerEvents: "none", ...style }} />;
}

/** `mountain.2.fill` at eyebrow size. */
export function MountainGlyph({ size = 12 }: { size?: number }) {
  return (
    <svg width={size * 1.4} height={size} viewBox="0 0 38 24" fill="currentColor">
      <path d="M27 8.5 Q28 7.3 29 8.5 L37.4 20 Q38.5 22 36.4 22 H26.8 L19.2 13.6 Z" />
      <path d="M12 2.5 Q13 1.3 14 2.5 L25 20 Q26 22 23.8 22 H1.2 Q-0.8 22 0.4 20 Z" />
    </svg>
  );
}
