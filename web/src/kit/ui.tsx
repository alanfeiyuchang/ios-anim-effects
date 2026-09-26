/**
 * Small reusable pieces (DemoKit.swift's `DemoHint`, `demoGlass`, `demoCard`, `PlaceholderLines`)
 * plus web stand-ins for SwiftUI modifiers that have no CSS equivalent.
 */
import { AnimatePresence, motion, useAnimationControls } from "motion/react";
import { useEffect, useRef, type CSSProperties, type ReactNode } from "react";
import type { DemoContext } from "./types";
import { Palette, black } from "./palette";

/** Caption hint at the bottom of a demo stage, hidden in previews. `.font(.footnote.weight(.medium))`. */
export function DemoHint({ ctx, en, zh, style }: { ctx: DemoContext; en: string; zh: string; style?: CSSProperties }) {
  if (ctx.isPreview) return null;
  return (
    <div style={{ fontSize: 13, lineHeight: "18px", fontWeight: 500, color: Palette.secondaryLabel, textAlign: "center", ...style }}>
      {ctx.t(en, zh)}
    </div>
  );
}

/** Frosted material (`.ultraThinMaterial` etc.) as CSS: use as a style spread. */
export function glass(
  material: "ultraThin" | "thin" | "regular" | "thick" | "bar" = "ultraThin",
  scheme: "dark" | "light" | "auto" = "auto",
): CSSProperties {
  const blur = { ultraThin: 16, thin: 20, regular: 24, thick: 28, bar: 24 }[material];
  const alphaDark = { ultraThin: 0.35, thin: 0.45, regular: 0.55, thick: 0.7, bar: 0.6 }[material];
  const alphaLight = { ultraThin: 0.45, thin: 0.55, regular: 0.65, thick: 0.78, bar: 0.7 }[material];
  const background =
    scheme === "dark"
      ? `rgb(40 40 44 / ${alphaDark})`
      : scheme === "light"
        ? `rgb(250 250 252 / ${alphaLight})`
        : `color-mix(in srgb, var(--ml-elevated) ${Math.round(alphaLight * 100)}%, transparent)`;
  return {
    background,
    backdropFilter: `blur(${blur}px) saturate(1.8)`,
    WebkitBackdropFilter: `blur(${blur}px) saturate(1.8)`,
  };
}

/** `.demoCard(cornerRadius:)`: elevated fill, hairline, soft shadow. */
export function demoCard(radius = 22): CSSProperties {
  return {
    background: Palette.elevated,
    borderRadius: radius,
    boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 10px 18px ${black(0.12)}`,
  };
}

/** Placeholder "content lines" used in skeletons, cards and lists. */
export function PlaceholderLines({ count = 3, color = Palette.labelAlpha(0.12) }: { count?: number; color?: string }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 8, alignItems: "stretch" }}>
      {Array.from({ length: count }, (_, i) => (
        <div key={i} style={{ height: 10, borderRadius: 5, background: color, maxWidth: i === count - 1 ? 120 : undefined }} />
      ))}
    </div>
  );
}

/**
 * `symbolEffect(.bounce, value:)`: a quick scale bounce each time `trigger` changes.
 * `.pulse`, `.wiggle` and `.breathe` variants via `kind`.
 */
export function SymbolBounce({
  trigger,
  kind = "bounce",
  children,
  style,
}: {
  trigger: unknown;
  kind?: "bounce" | "bounceDown" | "pulse" | "wiggle";
  children: ReactNode;
  style?: CSSProperties;
}) {
  const controls = useAnimationControls();
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    if (kind === "bounce") void controls.start({ scale: [1, 1.22, 0.94, 1], transition: { duration: 0.45, times: [0, 0.35, 0.7, 1] } });
    if (kind === "bounceDown") void controls.start({ scale: [1, 0.8, 1.08, 1], transition: { duration: 0.45, times: [0, 0.35, 0.7, 1] } });
    if (kind === "pulse") void controls.start({ opacity: [1, 0.4, 1], transition: { duration: 0.6 } });
    if (kind === "wiggle") void controls.start({ rotate: [0, -12, 10, -6, 0], transition: { duration: 0.5 } });
  }, [trigger, kind, controls]);
  return (
    <motion.span animate={controls} style={{ display: "inline-flex", ...style }}>
      {children}
    </motion.span>
  );
}

/** Absolute-fill layer (`ZStack` child that fills the stack). */
export function Fill({ children, style, center }: { children?: ReactNode; style?: CSSProperties; center?: boolean }) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        ...(center ? { display: "flex", alignItems: "center", justifyContent: "center" } : null),
        ...style,
      }}
    >
      {children}
    </div>
  );
}

/** Vertical stack: `<VStack gap={12} align="center">`. */
export function VStack({
  gap = 8,
  align = "center",
  justify,
  children,
  style,
}: {
  gap?: number;
  align?: CSSProperties["alignItems"];
  justify?: CSSProperties["justifyContent"];
  children?: ReactNode;
  style?: CSSProperties;
}) {
  return <div style={{ display: "flex", flexDirection: "column", gap, alignItems: align, justifyContent: justify, ...style }}>{children}</div>;
}

/** Horizontal stack: `<HStack gap={12} align="center">`. */
export function HStack({
  gap = 8,
  align = "center",
  justify,
  children,
  style,
}: {
  gap?: number;
  align?: CSSProperties["alignItems"];
  justify?: CSSProperties["justifyContent"];
  children?: ReactNode;
  style?: CSSProperties;
}) {
  return <div style={{ display: "flex", flexDirection: "row", gap, alignItems: align, justifyContent: justify, ...style }}>{children}</div>;
}

/** `Spacer(minLength: 0)` inside a stack. */
export const Spacer = () => <div style={{ flex: 1, minWidth: 0, minHeight: 0 }} />;

/**
 * `.contentTransition(.numericText(value:))`: digits that changed roll in (up when the value
 * grows, down when it shrinks) with a short blur, unchanged ones stay put.
 */
export function NumericText({ value, text, style }: { value: number; text?: string; style?: CSSProperties }) {
  const shown = text ?? String(value);
  const previous = useRef(value);
  const direction = value >= previous.current ? 1 : -1;
  useEffect(() => {
    previous.current = value;
  }, [value]);
  const chars = shown.split("");
  return (
    <span style={{ display: "inline-flex", fontVariantNumeric: "tabular-nums", ...style }}>
      {chars.map((c, i) => (
        <span key={chars.length - i} style={{ position: "relative", display: "inline-block", overflow: "hidden" }}>
          <AnimatePresence initial={false} mode="popLayout" custom={direction}>
            <motion.span
              key={c}
              custom={direction}
              variants={{
                enter: (d: number) => ({ y: `${70 * d}%`, opacity: 0, filter: "blur(2px)" }),
                center: { y: "0%", opacity: 1, filter: "blur(0px)" },
                exit: (d: number) => ({ y: `${-70 * d}%`, opacity: 0, filter: "blur(2px)" }),
              }}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ type: "spring", stiffness: 300, damping: 30 }}
              style={{ display: "inline-block", whiteSpace: "pre" }}
            >
              {c}
            </motion.span>
          </AnimatePresence>
        </span>
      ))}
    </span>
  );
}
