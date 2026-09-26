/** Layout helpers shared by the shader demos. */
import type { CSSProperties, ReactNode } from "react";
import { DemoHint, type DemoContext } from "../../kit";

/** `VStack(spacing:) { content; DemoHint }.frame(maxWidth: .infinity, maxHeight: .infinity)`. */
export function CenterStack({ ctx, en, zh, gap = 14, children, style }: { ctx: DemoContext; en: string; zh: string; gap?: number; children: ReactNode; style?: CSSProperties }) {
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap, ...style }}>
      {children}
      {!ctx.isPreview && <DemoHint ctx={ctx} en={en} zh={zh} />}
    </div>
  );
}

/** `.overlay(alignment: .bottom) { DemoHint(...).padding(.bottom, n) }`, optionally in the dark scheme's colours. */
export function BottomHint({ ctx, en, zh, bottom, dark }: { ctx: DemoContext; en: string; zh: string; bottom: number; dark?: boolean }) {
  if (ctx.isPreview) return null;
  return (
    <div style={{ position: "absolute", left: 0, right: 0, bottom, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
      <DemoHint ctx={ctx} en={en} zh={zh} style={dark ? { color: "rgb(235 235 245 / 0.6)" } : undefined} />
    </div>
  );
}
