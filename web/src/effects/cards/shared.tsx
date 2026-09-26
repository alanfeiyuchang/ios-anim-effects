/**
 * Shared artwork of the Cards category (Cards+Shared.swift, Cards+DeckKit.swift): the glossy
 * payment card, the tall destination deck face, and a few helpers for SwiftUI's 3D modifiers.
 */
import { useState, type CSSProperties, type ReactNode } from "react";
import { useMotionValueEvent, type MotionValue } from "motion/react";
import { Leaf, Mountain, Nfc, Sparkle, Sparkles, Sun, TramFront, Waves, type LucideIcon } from "lucide-react";
import { black, fonts, hex, white, type DemoContext } from "../../kit";

/** A bilingual string: [en, zh]. */
export type LText = readonly [string, string];
export const tr = (ctx: DemoContext, l: LText) => ctx.t(l[0], l[1]);

// MARK: - CardsArt

export const cardThemes: string[][] = [
  ["#5B5BFF", "#9B5CFF", "#FF6FB5"], // Aurora
  ["#2B2F45", "#1B1D2B", "#0E0F18"], // Midnight
  ["#FFB35C", "#FF6B6B", "#D9468F"], // Sunset
  ["#2BD9FE", "#3A7BFF", "#5B3BFF"], // Ocean
  ["#21D4A8", "#1A9E9A", "#215F8F"], // Mint
  ["#E9C98A", "#B8894A", "#6E4B2A"], // Gold
];
const themeNames = ["Aurora", "Midnight", "Sunset", "Ocean", "Mint", "Gold"];
const wrap = (i: number, n: number) => ((i % n) + n) % n;
export const themeColors = (i: number) => cardThemes[wrap(i, cardThemes.length)];
export const themeName = (i: number) => themeNames[wrap(i, themeNames.length)];

/** `LinearGradient(colors:, startPoint: .topLeading, endPoint: .bottomTrailing)` on a box of any shape. */
export const diag = (colors: string[]) => `linear-gradient(to bottom right, ${colors.join(", ")})`;

/**
 * SwiftUI `rotation3DEffect(perspective:)`: the vanishing distance is the view's larger side divided
 * by `perspective`. Returns the CSS `perspective(…)` function for a view of `w × h`.
 */
export const persp = (w: number, h: number, p: number) => `perspective(${Math.max(w, h) / Math.max(p, 0.0001)}px)`;

/** `strokeBorder(gradient, lineWidth:)` drawn as a masked ring over a rounded box. */
export function StrokeBorder({ radius, width = 1, color, style }: { radius: number; width?: number; color: string; style?: CSSProperties }) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: radius,
        padding: width,
        background: color,
        WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
        WebkitMaskComposite: "xor",
        maskComposite: "exclude",
        pointerEvents: "none",
        ...style,
      }}
    />
  );
}

// MARK: - CardsCreditCard

/** A glossy payment-card illustration designed at 250×158, scaled to `width`. */
export function CreditCard({
  theme = 0,
  width = 250,
  last4 = "4821",
  shift = { x: 0, y: 0 },
  overlay,
}: {
  theme?: number;
  width?: number;
  last4?: string;
  /** Parallax shift of the inner light blobs (tilt effects). */
  shift?: { x: number; y: number };
  /** Extra layers drawn over the face, inside its clip (glare, dent…). */
  overlay?: ReactNode;
}) {
  const s = width / 250;
  return (
    <div style={{ position: "relative", width, height: (width * 158) / 250, flexShrink: 0 }}>
      <div style={{ position: "absolute", left: 0, top: 0, width: 250, height: 158, transform: s === 1 ? undefined : `scale(${s})`, transformOrigin: "0 0" }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: 18, overflow: "hidden", isolation: "isolate" }}>
          <CreditBackground colors={themeColors(theme)} shift={shift} />
          <CreditContent name={themeName(theme)} last4={last4} />
          {overlay}
        </div>
        <StrokeBorder radius={18} color={`linear-gradient(to bottom right, ${white(0.5)}, ${white(0.06)})`} />
      </div>
    </div>
  );
}

function CreditBackground({ colors, shift }: { colors: string[]; shift: { x: number; y: number } }) {
  return (
    <div style={{ position: "absolute", inset: 0, background: diag(colors), overflow: "hidden" }}>
      <div
        style={{
          position: "absolute",
          left: 125 - 110 + 110 + shift.x,
          top: 79 - 110 - 90 + shift.y,
          width: 220,
          height: 220,
          borderRadius: "50%",
          background: white(0.22),
          filter: "blur(30px)",
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 125 - 106 - 125 - shift.x * 0.5,
          top: 79 - 106 + 85 - shift.y * 0.5,
          width: 212,
          height: 212,
          borderRadius: "50%",
          border: `22px solid ${white(0.1)}`,
        }}
      />
    </div>
  );
}

function CreditContent({ name, last4 }: { name: string; last4: string }) {
  return (
    <div style={{ position: "absolute", inset: 0, padding: 18, display: "flex", flexDirection: "column", color: "#fff" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6, height: 18 }}>
        <Sparkle size={13} fill="currentColor" strokeWidth={1.5} />
        <span style={{ fontFamily: fonts.rounded, fontSize: 15, fontWeight: 700, lineHeight: "18px" }}>{name}</span>
        <span style={{ flex: 1 }} />
        <Nfc size={16} strokeWidth={2.2} style={{ opacity: 0.85 }} />
      </div>
      <span style={{ flex: 1 }} />
      <Chip />
      <div style={{ fontFamily: fonts.mono, fontSize: 15, fontWeight: 600, lineHeight: "18px", marginTop: 12, whiteSpace: "pre" }}>
        {`••••  ••••  ••••  ${last4}`}
      </div>
      <div style={{ display: "flex", fontSize: 9, fontWeight: 600, letterSpacing: 1.2, opacity: 0.8, marginTop: 6, lineHeight: "11px" }}>
        <span>ALEX MORGAN</span>
        <span style={{ flex: 1 }} />
        <span>09/29</span>
      </div>
    </div>
  );
}

function Chip() {
  return (
    <div
      style={{
        width: 34,
        height: 25,
        borderRadius: 5,
        background: diag(["#F7E3A1", "#C9A24B"]),
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        gap: 5,
        padding: "0 4px",
        flexShrink: 0,
      }}
    >
      {[0, 1, 2].map((i) => (
        <div key={i} style={{ height: 0.8, background: black(0.18) }} />
      ))}
    </div>
  );
}

// MARK: - CardsDeck

export interface DeckItem {
  title: LText;
  detail: LText;
  Icon: LucideIcon;
  /** Draw the symbol filled (SF `.fill` symbols with a closed outline). */
  filled: boolean;
  colors: string[];
}

export const deckItems: DeckItem[] = [
  { title: ["Kyoto", "京都"], detail: ["Temples · 4 days", "古寺 · 4 天"], Icon: Leaf, filled: true, colors: ["#FFB36B", "#FF5F8F"] },
  { title: ["Reykjavík", "雷克雅未克"], detail: ["Aurora · 3 nights", "极光 · 3 晚"], Icon: Sparkles, filled: true, colors: ["#4ED6A0", "#2A9DF4"] },
  { title: ["Lisbon", "里斯本"], detail: ["Trams · 5 days", "电车 · 5 天"], Icon: TramFront, filled: false, colors: ["#FFC247", "#FF7A45"] },
  { title: ["Patagonia", "巴塔哥尼亚"], detail: ["Peaks · 8 days", "山峰 · 8 天"], Icon: Mountain, filled: true, colors: ["#3AC4FF", "#4F7CFF"] },
  { title: ["Marrakesh", "马拉喀什"], detail: ["Souks · 4 days", "市集 · 4 天"], Icon: Sun, filled: true, colors: ["#A46BFF", "#6E7BFF"] },
  { title: ["Bali", "巴厘岛"], detail: ["Surf · 6 days", "冲浪 · 6 天"], Icon: Waves, filled: false, colors: ["#21D4A8", "#1A9E9A"] },
];
export const deckItem = (i: number) => deckItems[wrap(i, deckItems.length)];

/** A tall destination card (gradient, big glyph, caption), 190×240 by default. */
export function DeckFace({
  index,
  ctx,
  width = 190,
  height = 240,
  children,
}: {
  index: number;
  ctx: DemoContext;
  width?: number;
  height?: number;
  /** Extra overlays inside the clip. */
  children?: ReactNode;
}) {
  const item = deckItem(index);
  const glyph = width * 0.36;
  const blob = width * 0.9;
  const { Icon } = item;
  return (
    <div style={{ position: "relative", width, height, flexShrink: 0 }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: 24, overflow: "hidden", background: diag(item.colors) }}>
        <div
          style={{
            position: "absolute",
            left: width / 2 - blob / 2 + width * 0.35,
            top: height / 2 - blob / 2 - height * 0.35,
            width: blob,
            height: blob,
            borderRadius: "50%",
            background: white(0.2),
            filter: "blur(24px)",
          }}
        />
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "grid",
            placeItems: "center",
            transform: `translateY(${-height * 0.1}px)`,
            color: white(0.94),
            filter: `drop-shadow(0 5px 8px ${black(0.12)})`,
          }}
        >
          <Icon size={glyph} fill={item.filled ? "currentColor" : "none"} strokeWidth={item.filled ? 0.6 : 1.3} />
        </div>
        <div style={{ position: "absolute", inset: 0, background: `linear-gradient(transparent 50%, ${black(0.42)})` }} />
        <div style={{ position: "absolute", left: 0, bottom: 0, padding: 14, color: "#fff", display: "flex", flexDirection: "column", gap: 2 }}>
          <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 700 }}>{tr(ctx, item.title)}</span>
          <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, opacity: 0.85 }}>{tr(ctx, item.detail)}</span>
        </div>
        {children}
      </div>
      <StrokeBorder radius={24} color={white(0.18)} />
    </div>
  );
}

/** Centered full-stage column (`VStack { … }.frame(maxWidth: .infinity, maxHeight: .infinity)`). */
export function Stage({ children, gap = 0, style }: { children: ReactNode; gap?: number; style?: CSSProperties }) {
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap, ...style }}>
      {children}
    </div>
  );
}

export { hex };

/** Re-renders with a motion value's latest value (for props that are not plain styles). */
export function useMV(mv: MotionValue<number>): number {
  const [v, setV] = useState(() => mv.get());
  useMotionValueEvent(mv, "change", setV);
  return v;
}

/**
 * `DragGesture.Value.predictedEndTranslation`: where the drag would coast to with UIKit's normal
 * deceleration, approximated as translation + velocity × 0.25 s.
 */
export const predictEnd = (translation: number, velocity: number) => translation + velocity * 0.25;

/**
 * `LinearGradient(stops:, startPoint:, endPoint:)` with arbitrary unit points on a `w × h` box, as an
 * exact CSS `linear-gradient` (the gradient line and the stop positions are converted to px).
 * `stops` are `[color, location]`.
 */
export function linearPoints(w: number, h: number, from: [number, number], to: [number, number], stops: [string, number][]): string {
  const dx = (to[0] - from[0]) * w;
  const dy = (to[1] - from[1]) * h;
  const theta = Math.atan2(dx, -dy);
  const ux = Math.sin(theta);
  const uy = -Math.cos(theta);
  const length = Math.abs(w * ux) + Math.abs(h * uy);
  const sx = w / 2 - (ux * length) / 2;
  const sy = h / 2 - (uy * length) / 2;
  const s0 = (from[0] * w - sx) * ux + (from[1] * h - sy) * uy;
  const s1 = (to[0] * w - sx) * ux + (to[1] * h - sy) * uy;
  return `linear-gradient(${theta}rad, ${stops.map(([c, l]) => `${c} ${(s0 + l * (s1 - s0)).toFixed(2)}px`).join(", ")})`;
}

/** `AngularGradient(colors:, center:, angle:)`: SwiftUI starts at 3 o'clock, CSS at 12, both clockwise. */
export function angular(colors: string[], cx: number, cy: number, angleDeg: number): string {
  return `conic-gradient(from ${angleDeg + 90}deg at ${cx * 100}% ${cy * 100}%, ${colors.join(", ")})`;
}
