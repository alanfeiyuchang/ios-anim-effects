/**
 * The app's shared palette (`Palette` in DemoKit.swift). Fixed colours are hex strings; colours
 * that adapt to light/dark (UIKit system colours) are CSS variables set on the stage canvas by
 * `kit.css`, so a demo written once follows the stage's scheme, like SwiftUI's `.primary`.
 */
export const Palette = {
  indigo: "#6E7BFF",
  violet: "#A46BFF",
  pink: "#FF5FA2",
  coral: "#FF7A5C",
  amber: "#FFC247",
  mint: "#21D4A8",
  sky: "#3AC4FF",
  blue: "#4F7CFF",
  green: "#34C77B",
  red: "#FF4D5E",
  ember: "#FF7A1A",
  emberHot: "#FF5E3A",
  onAccent: "#1A0A00",
  successStrong: "#17803F",

  /** Primary brand gradient (indigo → violet), top-leading → bottom-trailing. */
  primary: "linear-gradient(135deg, #6E7BFF, #A46BFF)",
  sunset: "linear-gradient(135deg, #FFC247, #FF7A5C, #FF5FA2)",
  ocean: "linear-gradient(135deg, #3AC4FF, #4F7CFF)",
  aurora: "linear-gradient(135deg, #21D4A8, #3AC4FF, #A46BFF)",
  accentFill: "linear-gradient(135deg, #FF7A1A, #FF5E3A)",
  spectrum: ["#6E7BFF", "#A46BFF", "#FF5FA2", "#FF7A5C", "#FFC247", "#21D4A8", "#3AC4FF"],

  // Adaptive (CSS variables, see kit.css)
  /** `Color.primary` (label) */
  label: "var(--ml-label)",
  /** `.secondary` (secondaryLabel) */
  secondaryLabel: "var(--ml-label2)",
  /** `.tertiary` (tertiaryLabel) */
  tertiaryLabel: "var(--ml-label3)",
  /** `Palette.surface` = secondarySystemBackground */
  surface: "var(--ml-surface)",
  /** `Palette.elevated` = tertiarySystemBackground */
  elevated: "var(--ml-elevated)",
  /** `Palette.stroke` = primary @ 8 % */
  stroke: "var(--ml-stroke)",
  /** systemBackground */
  background: "var(--ml-background)",
  /** systemGroupedBackground / page */
  page: "var(--ml-page)",
  /** The app tint (AccentColor asset): burnt orange in light, signature orange in dark. */
  accent: "var(--ml-accent)",
  /** `Color.primary.opacity(x)` */
  labelAlpha: (a: number) => `rgb(var(--ml-label-rgb) / ${a})`,
} as const;

/** `Color(hex: 0xRRGGBB, opacity:)` → CSS rgba string. */
export function hex(value: number | string, opacity = 1): string {
  const n = typeof value === "string" ? parseInt(value.replace("#", ""), 16) : value;
  const r = (n >> 16) & 0xff;
  const g = (n >> 8) & 0xff;
  const b = n & 0xff;
  return opacity >= 1 ? `rgb(${r} ${g} ${b})` : `rgb(${r} ${g} ${b} / ${opacity})`;
}

/** A hex colour at an opacity: `alpha(Palette.indigo, 0.3)`. Only for `#RRGGBB` strings. */
export function alpha(color: string, opacity: number): string {
  return hex(color, opacity);
}

/** SwiftUI's `Color.white.opacity(x)` / `Color.black.opacity(x)`. */
export const white = (a = 1) => `rgb(255 255 255 / ${a})`;
export const black = (a = 1) => `rgb(0 0 0 / ${a})`;

/** Font stacks: SF on Apple devices, sensible fallbacks elsewhere. */
export const fonts = {
  text: `system-ui, -apple-system, "SF Pro Text", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Helvetica Neue", Arial, sans-serif`,
  rounded: `ui-rounded, "SF Pro Rounded", system-ui, -apple-system, "PingFang SC", "Microsoft YaHei", "Helvetica Neue", Arial, sans-serif`,
  mono: `ui-monospace, "SF Mono", Menlo, Consolas, monospace`,
  serif: `ui-serif, "New York", Georgia, "Songti SC", serif`,
};

/** SwiftUI text styles (default Dynamic Type sizes, points = CSS px on the 340 canvas). */
export const textStyle = {
  largeTitle: { fontSize: 34, lineHeight: "41px" },
  title: { fontSize: 28, lineHeight: "34px" },
  title2: { fontSize: 22, lineHeight: "28px" },
  title3: { fontSize: 20, lineHeight: "25px" },
  headline: { fontSize: 17, lineHeight: "22px", fontWeight: 600 },
  body: { fontSize: 17, lineHeight: "22px" },
  callout: { fontSize: 16, lineHeight: "21px" },
  subheadline: { fontSize: 15, lineHeight: "20px" },
  footnote: { fontSize: 13, lineHeight: "18px" },
  caption: { fontSize: 12, lineHeight: "16px" },
  caption2: { fontSize: 11, lineHeight: "13px" },
} as const;
