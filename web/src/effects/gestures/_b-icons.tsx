/** Small SVG stand-ins for SF Symbols whose shape matters (gestures-b demos). */
import { useId, type CSSProperties } from "react";

/** `person.fill` */
export function PersonFill({ size = 24, style }: { size?: number; style?: CSSProperties }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={style} fill="currentColor">
      <circle cx="12" cy="7.2" r="4.9" />
      <path d="M12 13.6c-5.2 0-8.6 2.7-8.6 5.6 0 1.1.7 1.8 2 1.8h13.2c1.3 0 2-.7 2-1.8 0-2.9-3.4-5.6-8.6-5.6Z" />
    </svg>
  );
}

/** A filled circle with a glyph knocked out of it (`xxx.circle.fill`). `glyph` is drawn in a 24-unit box. */
export function CircleFillCutout({ size = 24, glyph, strokeWidth = 2.4, style }: { size?: number; glyph: string; strokeWidth?: number; style?: CSSProperties }) {
  const id = `b-cut-${useId().replace(/:/g, "")}`;
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={style}>
      <defs>
        <mask id={id}>
          <circle cx="12" cy="12" r="11" fill="#fff" />
          <path d={glyph} fill="none" stroke="#000" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
        </mask>
      </defs>
      <circle cx="12" cy="12" r="11" fill="currentColor" mask={`url(#${id})`} />
    </svg>
  );
}

/** Glyph paths for `CircleFillCutout` / outline circles. */
export const glyphs = {
  check: "M7.4 12.4l3.1 3.1 6-6.6",
  uturnBack: "M9.6 7.6 6.6 10.6l3 3M6.8 10.6h6.6a3.6 3.6 0 0 1 0 7.2h-2",
  plus: "M12 7.2v9.6M7.2 12h9.6",
};

/** `checkmark.circle` (outline). */
export function CircleOutlineGlyph({ size = 24, glyph, strokeWidth = 2, style }: { size?: number; glyph: string; strokeWidth?: number; style?: CSSProperties }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={style} fill="none" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10.2" />
      <path d={glyph} />
    </svg>
  );
}

/** `archivebox.fill` */
export function ArchiveBoxFill({ size = 24, style }: { size?: number; style?: CSSProperties }) {
  const id = `b-arch-${useId().replace(/:/g, "")}`;
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={style}>
      <defs>
        <mask id={id}>
          <rect x="0" y="0" width="24" height="24" fill="#fff" />
          <rect x="9" y="11.2" width="6" height="2.2" rx="1.1" fill="#000" />
        </mask>
      </defs>
      <g fill="currentColor" mask={`url(#${id})`}>
        <rect x="2" y="3.2" width="20" height="5" rx="1.6" />
        <path d="M3.4 9.6h17.2v8.6a2.6 2.6 0 0 1-2.6 2.6H6a2.6 2.6 0 0 1-2.6-2.6Z" />
      </g>
    </svg>
  );
}

/** `trash.fill` */
export function TrashFill({ size = 24, style }: { size?: number; style?: CSSProperties }) {
  const id = `b-trash-${useId().replace(/:/g, "")}`;
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={style}>
      <defs>
        <mask id={id}>
          <rect x="0" y="0" width="24" height="24" fill="#fff" />
          <path d="M9.6 10.4v7M14.4 10.4v7" stroke="#000" strokeWidth="1.5" strokeLinecap="round" />
        </mask>
      </defs>
      <g fill="currentColor" mask={`url(#${id})`}>
        <path d="M9.2 2.6h5.6a1.2 1.2 0 0 1 1.2 1.2v1H8v-1a1.2 1.2 0 0 1 1.2-1.2Z" />
        <rect x="3" y="4.6" width="18" height="2.2" rx="1.1" />
        <path d="M4.9 7.6h14.2l-.9 12.2a2 2 0 0 1-2 1.8H7.8a2 2 0 0 1-2-1.8Z" />
      </g>
    </svg>
  );
}

/** `clock.fill` */
export function ClockFill({ size = 24, style }: { size?: number; style?: CSSProperties }) {
  return <CircleFillCutout size={size} glyph="M12 6.4V12l3.6 2.2" strokeWidth={2} style={style} />;
}
