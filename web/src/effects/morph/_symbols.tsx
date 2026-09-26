/**
 * Small SVG stand-ins for SF Symbols that lucide has no close match for.
 */
import { useId, type ComponentType, type CSSProperties } from "react";

/** Props shared by lucide icons and these stand-ins. */
export type SymbolProps = { size?: number; strokeWidth?: number; fill?: string; style?: CSSProperties; color?: string };
export type SymbolComponent = ComponentType<SymbolProps>;

/** `mountain.2.fill`: two filled peaks with a snow-line cut. */
export function Mountain2({ size = 24, style }: SymbolProps) {
  const id = useId().replace(/:/g, "");
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={style}>
      <defs>
        <mask id={`m2${id}`}>
          <rect x="0" y="0" width="24" height="24" fill="#fff" />
          <path d="M12.2 10.4 L13.6 11.7 L14.9 10.3 L16.3 11.7 L17.6 10.6" fill="none" stroke="#000" strokeWidth="1.1" strokeLinejoin="round" strokeLinecap="round" />
          <path d="M4.6 13.2 L5.8 14.1 L7 13.1 L8.1 13.9" fill="none" stroke="#000" strokeWidth="1.1" strokeLinejoin="round" strokeLinecap="round" />
          <path d="M9.4 18.8 L14.9 6.2" fill="none" stroke="#000" strokeWidth="1.3" />
        </mask>
      </defs>
      <g mask={`url(#m2${id})`} fill="currentColor" stroke="currentColor" strokeWidth="1.4" strokeLinejoin="round">
        <path d="M1.8 18.6 L6.4 9.6 Q6.9 8.8 7.4 9.6 L10.4 15 L9.2 18.6 Z" />
        <path d="M8.4 18.6 L14.1 6.3 Q14.9 5.2 15.7 6.3 L22.2 18.6 Z" />
      </g>
    </svg>
  );
}

/** `sun.horizon.fill`: a half sun with five rays resting on the horizon. */
export function SunHorizon({ size = 24, style }: SymbolProps) {
  const rays = [180, 225, 270, 315, 360].map((deg) => {
    const r = (deg * Math.PI) / 180;
    return [12 + Math.cos(r) * 7.6, 15.6 + Math.sin(r) * 7.6, 12 + Math.cos(r) * 9.8, 15.6 + Math.sin(r) * 9.8];
  });
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={style} fill="currentColor" stroke="currentColor" strokeLinecap="round">
      <path d="M6.9 15.6 A5.1 5.1 0 0 1 17.1 15.6 Z" strokeWidth="0.6" />
      {rays.map(([x1, y1, x2, y2], i) => (
        <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} strokeWidth="1.9" />
      ))}
      <line x1="2.4" y1="18.6" x2="21.6" y2="18.6" strokeWidth="1.9" />
    </svg>
  );
}

/** `xmark.circle.fill`: a filled disc with the cross knocked out. */
export function XCircleFill({ size = 24, style }: SymbolProps) {
  const id = useId().replace(/:/g, "");
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={style}>
      <mask id={`xc${id}`}>
        <rect width="24" height="24" fill="#fff" />
        <path d="M8.6 8.6 L15.4 15.4 M15.4 8.6 L8.6 15.4" stroke="#000" strokeWidth="2.2" strokeLinecap="round" />
      </mask>
      <circle cx="12" cy="12" r="10.5" fill="currentColor" mask={`url(#xc${id})`} />
    </svg>
  );
}

/** `checkmark.circle.fill`: a filled disc with the check knocked out. */
export function CheckCircleFill({ size = 24, style }: SymbolProps) {
  const id = useId().replace(/:/g, "");
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} style={style}>
      <mask id={`cc${id}`}>
        <rect width="24" height="24" fill="#fff" />
        <path d="M7.4 12.4 L10.6 15.5 L16.6 8.9" fill="none" stroke="#000" strokeWidth="2.3" strokeLinecap="round" strokeLinejoin="round" />
      </mask>
      <circle cx="12" cy="12" r="10.5" fill="currentColor" mask={`url(#cc${id})`} />
    </svg>
  );
}
