/**
 * Shared styling of the "Signature Interactions" category (SignatureKit.swift): dark, glossy,
 * widget-style cards with a warm orange accent.
 */
import type { CSSProperties, ReactNode } from "react";
import { black, fonts, white } from "../../kit";

export const Signature = {
  accent: "#FF8A1F",
  accentHot: "#FF5A1F",
  accentSoft: "#FFB45C",
  lime: "#C8F560",
  ink: "#0B0B0D",
  card: "#17171A",
  cardHigh: "#222226",
  paper: "#F3F1EC",
  textPrimary: "#FFFFFF",
  textSecondary: white(0.55),
  hairline: white(0.09),
  /** accentSoft → accent → accentHot, top-leading → bottom-trailing. */
  accentGradient: "linear-gradient(135deg, #FFB45C, #FF8A1F, #FF5A1F)",
};

/** `Signature.number(size)`: rounded, semibold, monospaced digits. */
export function signatureNumber(size: number): CSSProperties {
  return { fontFamily: fonts.rounded, fontSize: size, fontWeight: 600, fontVariantNumeric: "tabular-nums", lineHeight: 1.1 };
}

/** `.signatureEyebrow(light:)`: 10 pt bold rounded, uppercase, tracking 1.2. */
export function signatureEyebrow(light = false): CSSProperties {
  return {
    fontFamily: fonts.rounded,
    fontSize: 10,
    fontWeight: 700,
    letterSpacing: 1.2,
    textTransform: "uppercase",
    color: light ? black(0.45) : Signature.textSecondary,
    lineHeight: "12px",
  };
}

/**
 * `.signatureCard(cornerRadius:light:)`: near-black gradient, hairline gradient border, deep shadow.
 * Spread into the card's style; the border is drawn by a `::after`-free inset shadow trick, so the
 * element may also clip its content (`overflow: hidden`).
 */
export function signatureCard(radius = 26, light = false): CSSProperties {
  return {
    borderRadius: radius,
    background: light
      ? `linear-gradient(${Signature.paper}, #E4E1DA)`
      : `linear-gradient(${Signature.cardHigh}, ${Signature.card})`,
    boxShadow: `0 14px 22px ${black(0.45)}`,
    position: "relative",
  };
}

/** The hairline border of a signature card; place it as the card's last child. */
export function SignatureRim({ radius = 26, light = false }: { radius?: number; light?: boolean }) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: radius,
        padding: 1,
        background: `linear-gradient(${white(light ? 0.9 : 0.16)}, ${white(light ? 0.3 : 0.03)})`,
        WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
        WebkitMaskComposite: "xor",
        maskComposite: "exclude",
        pointerEvents: "none",
      }}
    />
  );
}

/** Dark stage backdrop behind showcase demos (always dark, like `.environment(\.colorScheme, .dark)`). */
export function SignatureStage({ children, style }: { children: ReactNode; style?: CSSProperties }) {
  return (
    <div
      className="ml-dark"
      style={{
        position: "absolute",
        inset: 0,
        background: `radial-gradient(260px circle at 100% 0%, rgb(255 138 31 / 0.12), transparent 100%), linear-gradient(#1C1C20, ${Signature.ink})`,
        ...style,
      }}
    >
      {children}
    </div>
  );
}

const LANDSCAPES: { sky: string[]; sun: string; ridges: string[] }[] = [
  // snowy peaks, golden hour
  { sky: ["#3D5A80", "#F2A65A", "#FFD8A8"], sun: "#FFF3D6", ridges: ["#E9EEF5", "#7C8BA1", "#2E3A4D"] },
  // dusk coast
  { sky: ["#2B2E5A", "#E0785A", "#F5C27A"], sun: "#FFE2A8", ridges: ["#6A4B6E", "#3B2C4A", "#1C1726"] },
  // alpine lake
  { sky: ["#8FC9F0", "#D8EEF8"], sun: "#FFFFFF", ridges: ["#A9B8C8", "#4F7A8A", "#1F4A55"] },
  // desert
  { sky: ["#F7B267", "#F4845F"], sun: "#FFF1C1", ridges: ["#D2693C", "#A2482A", "#5E2A1C"] },
  // night
  { sky: ["#0B1026", "#27305E"], sun: "#E8ECFF", ridges: ["#323A66", "#1D2347", "#0D1129"] },
];

/** A jagged ridge polygon in a 0…1 unit box (Swift `RidgeShape`). */
function ridgePoints(seed: number, baseline: number, amplitude: number): string {
  const steps = 9;
  const points = ["0,1"];
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    const n = Math.sin(seed * 12.9898 + i * 78.233) * 43758.5453;
    const jitter = n - Math.floor(n);
    const y = baseline - amplitude * (i % 2 === 0 ? jitter * 0.5 : 0.6 + jitter * 0.4);
    points.push(`${t},${y}`);
  }
  points.push("1,1");
  return points.join(" ");
}

/**
 * A procedurally drawn "landscape photo" (sky gradient, sun, three mountain ridges), `seed` picks
 * the mood. Fills its parent (position it absolutely or give it a size).
 */
export function LandscapeArt({ seed = 0, style }: { seed?: number; style?: CSSProperties }) {
  const p = LANDSCAPES[((seed % 5) + 5) % 5];
  const sunX = 0.25 + (seed % 3) * 0.22;
  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden", containerType: "size", background: `linear-gradient(${p.sky.join(", ")})`, ...style }}>
      <div
        style={{
          position: "absolute",
          width: "22cqw",
          height: "22cqw",
          left: `calc(${sunX * 100}cqw - 11cqw)`,
          top: "calc(34cqh - 11cqw)",
          borderRadius: "50%",
          background: p.sun,
          filter: "blur(1px)",
          boxShadow: `0 0 40px ${p.sun}cc`,
        }}
      />
      <svg viewBox="0 0 1 1" preserveAspectRatio="none" style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}>
        {[0, 1, 2].map((layer) => (
          <polygon key={layer} points={ridgePoints(seed * 7 + layer * 3, 0.5 + layer * 0.14, 0.2 - layer * 0.04)} fill={p.ridges[layer]} />
        ))}
      </svg>
    </div>
  );
}
