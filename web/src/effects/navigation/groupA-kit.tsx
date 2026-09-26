/**
 * Helpers for the tab-bar family of Navigation demos (group A): SF-Symbol-like filled glyphs that
 * lucide has no filled twin for, SwiftUI's `Color.gradient`, and `.transition(.blurReplace)`.
 */
import { AnimatePresence, motion, useAnimationControls, type Transition } from "motion/react";
import { useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";

/** `Color.gradient`: a soft top-to-bottom sheen of the colour. */
export function colorGradient(color: string): string {
  return `linear-gradient(180deg, color-mix(in srgb, ${color}, white 18%), color-mix(in srgb, ${color}, black 4%))`;
}

/** Palette.primary on non-square shapes: topLeading → bottomTrailing corner to corner. */
export const primaryCorner = "linear-gradient(to bottom right, #6E7BFF, #A46BFF)";

/**
 * `.id(key).transition(.blurReplace)`: the old view blurs, shrinks a little and fades while the new one
 * does the reverse, both in the same place (a one-cell grid keeps them stacked).
 */
export function BlurReplace({
  id,
  transition,
  children,
  style,
}: {
  id: string | number;
  transition: Transition;
  children: ReactNode;
  style?: CSSProperties;
}) {
  return (
    <div style={{ display: "grid", placeItems: "center", ...style }}>
      <AnimatePresence initial={false}>
        <motion.div
          key={id}
          initial={{ opacity: 0, scale: 0.8, filter: "blur(10px)" }}
          animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
          exit={{ opacity: 0, scale: 0.8, filter: "blur(10px)" }}
          transition={transition}
          style={{ gridArea: "1 / 1", display: "flex", flexDirection: "column", alignItems: "center" }}
        >
          {children}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}

type IconProps = { size: number; color?: string; style?: CSSProperties };

function Glyph({ size, color = "currentColor", style, children }: IconProps & { children: ReactNode }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} fill={color} fillRule="evenodd" clipRule="evenodd" style={{ display: "block", flexShrink: 0, ...style }} aria-hidden>
      {children}
    </svg>
  );
}

/** `house.fill` */
export const HouseFill = (p: IconProps) => (
  <Glyph {...p}>
    <path d="M12.9 2.9a1.4 1.4 0 0 0-1.8 0L1.9 10.8c-.6.5-.2 1.4.5 1.4H4v7.9A1.9 1.9 0 0 0 5.9 22h12.2a1.9 1.9 0 0 0 1.9-1.9v-7.9h1.6c.7 0 1.1-.9.5-1.4ZM10 22v-5.2a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1V22Z" />
  </Glyph>
);

/** `safari.fill` */
export const SafariFill = (p: IconProps) => (
  <Glyph {...p}>
    <path d="M12 2a10 10 0 1 1 0 20 10 10 0 0 1 0-20Zm4.6 5.4-6 3.2-3.2 6 6-3.2Zm-4.6 3.4a1.2 1.2 0 1 0 0 2.4 1.2 1.2 0 0 0 0-2.4Z" />
  </Glyph>
);

/** `heart.fill` */
export const HeartFill = (p: IconProps) => (
  <Glyph {...p}>
    <path d="M12 21.2c-.3 0-.6-.1-.8-.3C5.6 16.6 2 13.2 2 8.8 2 5.7 4.4 3.3 7.4 3.3c1.9 0 3.5 1 4.6 2.5 1.1-1.5 2.7-2.5 4.6-2.5 3 0 5.4 2.4 5.4 5.5 0 4.4-3.6 7.8-9.2 12.1-.2.2-.5.3-.8.3Z" />
  </Glyph>
);

/** `person.fill` */
export const PersonFill = (p: IconProps) => (
  <Glyph {...p}>
    <circle cx="12" cy="7.4" r="4.4" />
    <path d="M3.4 20.2c0-4 3.8-6.9 8.6-6.9s8.6 2.9 8.6 6.9c0 1-.7 1.5-1.7 1.5H5.1c-1 0-1.7-.5-1.7-1.5Z" />
  </Glyph>
);

/** `bell.fill` */
export const BellFill = (p: IconProps) => (
  <Glyph {...p}>
    <path d="M12 1.8c-.8 0-1.4.6-1.4 1.4v.6C7.6 4.4 5.6 7.1 5.6 10.3v4.5L3.7 17c-.5.6-.1 1.4.6 1.4h15.4c.7 0 1.1-.8.6-1.4l-1.9-2.2v-4.5c0-3.2-2-5.9-5-6.5v-.6c0-.8-.6-1.4-1.4-1.4ZM9.2 19.6a2.9 2.9 0 0 0 5.6 0Z" />
  </Glyph>
);

/** `play.square.stack.fill` */
export const PlaySquareStackFill = (p: IconProps) => (
  <Glyph {...p}>
    <rect x="6.8" y="1.6" width="10.4" height="1.7" rx=".85" />
    <rect x="4.6" y="4.3" width="14.8" height="1.8" rx=".9" />
    <path d="M5.4 7.2h13.2a2.9 2.9 0 0 1 2.9 2.9v9A2.9 2.9 0 0 1 18.6 22H5.4a2.9 2.9 0 0 1-2.9-2.9v-9a2.9 2.9 0 0 1 2.9-2.9Zm4.6 4.1v6.6l5.6-3.3Z" />
  </Glyph>
);

/** `square.grid.2x2.fill` */
export const SquareGrid2x2Fill = (p: IconProps) => (
  <Glyph {...p}>
    <rect x="2.6" y="2.6" width="8.4" height="8.4" rx="2.2" />
    <rect x="13" y="2.6" width="8.4" height="8.4" rx="2.2" />
    <rect x="2.6" y="13" width="8.4" height="8.4" rx="2.2" />
    <rect x="13" y="13" width="8.4" height="8.4" rx="2.2" />
  </Glyph>
);

/** `plus.circle.fill` */
export const PlusCircleFill = (p: IconProps) => (
  <Glyph {...p}>
    <path d="M12 2a10 10 0 1 1 0 20 10 10 0 0 1 0-20Zm-.95 5.6v3.45H7.6v1.9h3.45v3.45h1.9v-3.45h3.45v-1.9h-3.45V7.6Z" />
  </Glyph>
);

/** `bookmark.fill` */
export const BookmarkFill = (p: IconProps) => (
  <Glyph {...p}>
    <path d="M7 2h10a2 2 0 0 1 2 2v17.1c0 .8-.9 1.2-1.5.7L12 17.4l-5.5 4.4c-.6.5-1.5.1-1.5-.7V4a2 2 0 0 1 2-2Z" />
  </Glyph>
);

/**
 * Natural widths (layout px) of a few text labels in one style, measured off-screen, so a demo can
 * lay out and animate frames the way SwiftUI does (it knows every label's size up front). Render the
 * returned probe element once anywhere inside the demo.
 */
export function useTextWidths(texts: string[], style: CSSProperties): [number[], ReactNode] {
  const refs = useRef<(HTMLSpanElement | null)[]>([]);
  const [widths, setWidths] = useState<number[]>(() => texts.map(() => 0));
  const key = texts.join("\u0001");
  useLayoutEffect(() => {
    const measure = () => setWidths(refs.current.slice(0, texts.length).map((el) => el?.offsetWidth ?? 0));
    measure();
    let alive = true;
    document.fonts?.ready.then(() => alive && measure());
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);
  const probe = (
    <div aria-hidden style={{ position: "absolute", left: 0, top: 0, visibility: "hidden", pointerEvents: "none", display: "flex" }}>
      {texts.map((t, i) => (
        <span key={i} ref={(el) => void (refs.current[i] = el)} style={{ ...style, whiteSpace: "nowrap" }}>
          {t}
        </span>
      ))}
    </div>
  );
  return [widths, probe];
}

/**
 * Seconds since `trigger` last changed (−1 before its first change), re-rendering every frame for
 * `duration` seconds: `keyframeAnimator(trigger:)`. Unlike the kit's `useElapsed(…, true)` it does not
 * start on mount under React StrictMode's double effect run.
 */
export function useSince(trigger: number, duration: number): number {
  const [elapsed, setElapsed] = useState(-1);
  const initial = useRef(trigger);
  const start = useRef<{ trigger: number; at: number } | null>(null);
  useEffect(() => {
    if (trigger === initial.current && start.current === null) return;
    if (!start.current || start.current.trigger !== trigger) start.current = { trigger, at: performance.now() };
    const began = start.current.at;
    let raf = 0;
    const step = (now: number) => {
      const e = (now - began) / 1000;
      setElapsed(Math.min(e, duration));
      if (e < duration) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [trigger, duration]);
  return elapsed;
}

/** `symbolEffect(.bounce, value:)` that only plays when `trigger` really changes (StrictMode-safe). */
export function Bounce({ trigger, children, style }: { trigger: number; children: ReactNode; style?: CSSProperties }) {
  const controls = useAnimationControls();
  const last = useRef(trigger);
  useEffect(() => {
    if (last.current === trigger) return;
    last.current = trigger;
    void controls.start({ scale: [1, 1.22, 0.94, 1], transition: { duration: 0.45, times: [0, 0.35, 0.7, 1] } });
  }, [trigger, controls]);
  return (
    <motion.span animate={controls} style={{ display: "inline-flex", ...style }}>
      {children}
    </motion.span>
  );
}
