/**
 * Shared pieces of the Navigation demos (NavigationGestures.swift).
 */
import { Palette, PlaceholderLines } from "../../kit";

const labelAlphaSafe = (a: number) => Palette.labelAlpha(a);

/**
 * `NavigationScreenPlaceholder`: faint screen content behind tab-bar demos in grid previews, so a
 * thumbnail reads as an app screen. Show it only when `ctx.isPreview`. Never takes touches.
 */
export function NavigationScreenPlaceholder({ rows = 3, showsTitle = true }: { rows?: number; showsTitle?: boolean }) {
  return (
    <div style={{ width: 290, display: "flex", flexDirection: "column", gap: 8, alignItems: "flex-start", pointerEvents: "none" }} aria-hidden>
      {showsTitle && <div style={{ width: 120, height: 12, borderRadius: 6, background: labelAlphaSafe(0.14), marginLeft: 4 }} />}
      {Array.from({ length: rows }, (_, i) => (
        <div
          key={i}
          style={{
            alignSelf: "stretch",
            height: 44,
            padding: "0 10px",
            display: "flex",
            alignItems: "center",
            gap: 12,
            borderRadius: 14,
            background: labelAlphaSafe(0.035),
          }}
        >
          <div style={{ width: 28, height: 28, borderRadius: 9, background: labelAlphaSafe(0.08), flexShrink: 0 }} />
          <div style={{ flex: 1 }}>
            <PlaceholderLines count={2} color={labelAlphaSafe(0.08)} />
          </div>
        </div>
      ))}
    </div>
  );
}
