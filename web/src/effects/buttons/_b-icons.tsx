/**
 * Filled SF Symbol stand-ins whose cut-outs matter (lucide's outline icons lose them when filled).
 * All drawn on a 24-unit grid in `currentColor`.
 */
import type { CSSProperties } from "react";

type P = { size?: number; style?: CSSProperties };

const svg = (size: number, style: CSSProperties | undefined, d: string) => (
  <svg width={size} height={size} viewBox="0 0 24 24" style={style}>
    <path d={d} fill="currentColor" fillRule="evenodd" />
  </svg>
);

/** `house.fill` */
export const HouseFill = ({ size = 24, style }: P) =>
  svg(size, style, "M12 2.6 1.9 11a1 1 0 0 0 1.3 1.5l.8-.7V20a2 2 0 0 0 2 2h3.5v-6.2a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1V22H18a2 2 0 0 0 2-2v-8.2l.8.7a1 1 0 0 0 1.3-1.5Z");

/** `camera.fill` */
export const CameraFill = ({ size = 24, style }: P) =>
  svg(size, style, "M9.2 3.5h5.6a1.6 1.6 0 0 1 1.4.8L17.3 6H20a2.5 2.5 0 0 1 2.5 2.5v9A2.5 2.5 0 0 1 20 20H4a2.5 2.5 0 0 1-2.5-2.5v-9A2.5 2.5 0 0 1 4 6h2.7l1.1-1.7a1.6 1.6 0 0 1 1.4-.8ZM12 8.6a4.2 4.2 0 1 0 0 8.4 4.2 4.2 0 0 0 0-8.4Zm0 1.9a2.3 2.3 0 1 1 0 4.6 2.3 2.3 0 0 1 0-4.6Z");

/** `person.crop.circle.fill` */
export const PersonCircleFill = ({ size = 24, style }: P) =>
  svg(size, style, "M12 1.5a10.5 10.5 0 1 1 0 21 10.5 10.5 0 0 1 0-21Zm0 4.2a3.7 3.7 0 1 0 0 7.4 3.7 3.7 0 0 0 0-7.4Zm0 9c-2.9 0-5.3 1.3-6.4 3.1a8.4 8.4 0 0 0 12.8 0c-1.1-1.8-3.5-3.1-6.4-3.1Z");

/** `play.tv.fill` */
export const PlayTvFill = ({ size = 24, style }: P) =>
  svg(size, style, "M4 4h16a2.5 2.5 0 0 1 2.5 2.5v10A2.5 2.5 0 0 1 20 19H4a2.5 2.5 0 0 1-2.5-2.5v-10A2.5 2.5 0 0 1 4 4Zm6 4.3v6.4a.6.6 0 0 0 .9.5l5.2-3.2a.6.6 0 0 0 0-1l-5.2-3.2a.6.6 0 0 0-.9.5ZM7 20.5h10a.75.75 0 0 1 0 1.5H7a.75.75 0 0 1 0-1.5Z");

/** `doc.on.doc` style copy glyph, outlined. */
export const CopyGlyph = ({ size = 24, style }: P) => (
  <svg width={size} height={size} viewBox="0 0 24 24" style={style} fill="none" stroke="currentColor" strokeWidth={2} strokeLinejoin="round">
    <rect x="8" y="8" width="12.5" height="13.5" rx="2.5" />
    <path d="M16 8V5.5A2.5 2.5 0 0 0 13.5 3H6a2.5 2.5 0 0 0-2.5 2.5V14A2.5 2.5 0 0 0 6 16.5h2" />
  </svg>
);
