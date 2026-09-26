/** Shared bits for the inputs-a ports (only used by files this agent created). */
import { AnimatePresence, motion } from "motion/react";
import { useCallback, useId, useRef, type CSSProperties, type ReactNode } from "react";
import { anim } from "../../kit";

/** `.contentTransition(.symbolEffect(.replace))`: keyed glyphs swap with scale + blur. */
export function SymbolSwap({ k, children, style }: { k: string | number; children: ReactNode; style?: CSSProperties }) {
  return (
    <span style={{ display: "inline-grid", placeItems: "center", ...style }}>
      <AnimatePresence mode="popLayout" initial={false}>
        <motion.span
          key={k}
          initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
          animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
          exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
          transition={anim.snappyD(0.3)}
          style={{ display: "grid", placeItems: "center", gridArea: "1 / 1" }}
        >
          {children}
        </motion.span>
      </AnimatePresence>
    </span>
  );
}

/** `.contentTransition(.opacity)` on a Text: old and new strings cross-fade in place. */
export function FadeText({ text, style, duration = 0.25 }: { text: string; style?: CSSProperties; duration?: number }) {
  return (
    <span style={{ display: "inline-grid", ...style }}>
      <AnimatePresence initial={false}>
        <motion.span
          key={text}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={anim.easeInOut(duration)}
          style={{ gridArea: "1 / 1", whiteSpace: "nowrap" }}
        >
          {text}
        </motion.span>
      </AnimatePresence>
    </span>
  );
}

/** Style for real text fields inside the canvas (which disables selection and browser gestures). */
export const fieldInputStyle: CSSProperties = {
  touchAction: "auto",
  userSelect: "text",
  WebkitUserSelect: "text",
  background: "transparent",
  border: 0,
  outline: "none",
  padding: 0,
  margin: 0,
  minWidth: 0,
};

/** SwiftUI's `Color.gray` (systemGray). */
export const systemGray = "#8E8E93";

/** `checkmark.circle.fill`: a filled disc with the check knocked out (transparent). */
export function CheckCircleFill({ size, color = "currentColor", weight = 2.4 }: { size: number; color?: string; weight?: number }) {
  const id = `a-ccf-${useId().replace(/:/g, "")}`;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: "block" }}>
      <defs>
        <mask id={id}>
          <rect width="24" height="24" fill="#fff" />
          <path d="M7.4 12.4l3.1 3.1 6.1-6.6" fill="none" stroke="#000" strokeWidth={weight} strokeLinecap="round" strokeLinejoin="round" />
        </mask>
      </defs>
      <circle cx="12" cy="12" r="11" fill={color} mask={`url(#${id})`} />
    </svg>
  );
}

/**
 * Swift captures `let muted = Haptics.isMuted` inside autoplay actions so haptics fired later by a
 * `Task` stay silent too. `wrap(action)` marks the synchronous part; `muted()` reads the mark.
 */
export function useAutoMute() {
  const flag = useRef(false);
  const wrap = useCallback((action: () => void) => () => {
    flag.current = true;
    try {
      action();
    } finally {
      flag.current = false;
    }
  }, []);
  const muted = useCallback(() => flag.current, []);
  return { wrap, muted };
}

/** SwiftUI `Divider()`: a hairline in the separator colour. */
export function Divider({ style }: { style?: CSSProperties }) {
  return <div style={{ height: 0.5, flexShrink: 0, alignSelf: "stretch", background: "rgb(var(--ml-label-rgb) / 0.2)", ...style }} />;
}

/** A `ButtonStyle` that scales its label while pressed: `<PressScale scale={0.88}>`. */
export function PressScale({
  scale,
  children,
  onClick,
  style,
  transition,
  disabled,
}: {
  scale: number;
  children: ReactNode;
  onClick?: () => void;
  style?: CSSProperties;
  transition?: import("motion/react").Transition;
  disabled?: boolean;
}) {
  return (
    <motion.button
      type="button"
      onClick={onClick}
      disabled={disabled}
      whileTap={{ scale }}
      transition={transition ?? { type: "spring", stiffness: (2 * Math.PI / 0.25) ** 2, damping: (4 * Math.PI * 0.55) / 0.25 }}
      style={{ display: "grid", placeItems: "center", ...style }}
    >
      {children}
    </motion.button>
  );
}

/** SF `cup.and.saucer.fill`. */
export function CupSaucer({ size = 22, color = "currentColor" }: { size?: number; color?: string }) {
  return (
    <svg width={size} height={(size * 18) / 22} viewBox="0 0 22 18" fill={color} style={{ display: "block" }}>
      <path d="M3 3.2h12.6v4.6a6.3 6.3 0 0 1-12.6 0Z" />
      <path d="M15.2 4.4h1.6a2.9 2.9 0 0 1 0 5.8h-1.9l.5-1.8h1.4a1.1 1.1 0 0 0 0-2.2h-1.6Z" />
      <rect x="0.5" y="14.6" width="17.6" height="2.4" rx="1.2" />
    </svg>
  );
}

/**
 * `Text(…).id(key).transition(.push(from: .bottom))` inside a clipped container animated with
 * `.snappy`: the new text pushes in from below while the old one leaves through the top.
 */
export function PushText({ k, children, style, height }: { k: string | number; children: ReactNode; style?: CSSProperties; height?: number }) {
  return (
    <div style={{ position: "relative", overflow: "hidden", display: "grid", placeItems: "center", height, ...style }}>
      <AnimatePresence initial={false}>
        <motion.div
          key={k}
          initial={{ y: "100%", opacity: 0 }}
          animate={{ y: "0%", opacity: 1 }}
          exit={{ y: "-100%", opacity: 0 }}
          transition={anim.snappy}
          style={{ gridArea: "1 / 1", whiteSpace: "nowrap" }}
        >
          {children}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}

/** SF `star.fill` (slightly rounded five-point star) in a 24-unit box. */
export const STAR_PATH =
  "M12 1.6c.4 0 .8.2 1 .6l2.8 5.7 6.3.9c.9.1 1.3 1.2.6 1.9l-4.6 4.4 1.1 6.3c.2.9-.8 1.6-1.6 1.2L12 19.6l-5.6 3c-.8.4-1.8-.3-1.6-1.2l1.1-6.3-4.6-4.4c-.7-.7-.3-1.8.6-1.9l6.3-.9 2.8-5.7c.2-.4.6-.6 1-.6Z";
