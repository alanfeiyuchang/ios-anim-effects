/** loading.indeterminate-bar · 不确定进度条 (Loading+Progress.swift) */
import { Palette, alpha, demoCard, useClock, type DemoProps } from "../../kit";
import { easeInOutCubic, previewFps, primary, usePhase } from "./shared";

const WIDTH = 240;
const easeOut = (x: number) => 1 - Math.pow(1 - Math.min(Math.max(x, 0), 1), 3);
const easeIn = (x: number) => Math.pow(Math.min(Math.max(x, 0), 1), 3);

function first(u: number) {
  const v = u / 0.8;
  if (v > 1) return { tail: 1.2, head: 1.2 };
  return { tail: -0.1 + 1.3 * easeInOutCubic((v - 0.2) / 0.8), head: -0.1 + 1.3 * easeInOutCubic(v) };
}

function second(u: number) {
  const shifted = u - 0.5;
  const w = (shifted - Math.floor(shifted)) / 0.8;
  if (w > 1) return { tail: -0.2, head: -0.2 };
  return { tail: -0.1 + 1.3 * easeIn(w), head: -0.1 + 1.3 * easeOut(w) };
}

export default function IndeterminateBar({ ctx }: DemoProps) {
  const zh = ctx.lang === "zh";
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ ...demoCard(), padding: 22 }}>
        <div style={{ width: WIDTH, display: "flex", flexDirection: "column", gap: 18 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: 12,
                background: Palette.primary,
                boxShadow: `0 4px 8px ${alpha(Palette.indigo, 0.3)}`,
                display: "grid",
                placeItems: "center",
                flexShrink: 0,
              }}
            >
              <WifiVariable fps={previewFps(ctx.isPreview)} />
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "加入 “Studio 5G”" : "Joining “Studio 5G”"}</span>
              <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{zh ? "正在连接…" : "Connecting…"}</span>
            </div>
          </div>
          <Track period={ctx.n("period")} height={ctx.n("height")} preview={ctx.isPreview} />
        </div>
      </div>
    </div>
  );
}

/** `wifi` with `.symbolEffect(.variableColor.iterative)`: the arcs light up one after another. */
function WifiVariable({ fps }: { fps?: number }) {
  const t = useClock(true, fps);
  // Iterative variable colour: each of the three arcs takes a turn at full opacity, inner → outer.
  const cycle = (t % 1.2) / 1.2;
  const active = Math.floor(cycle * 4); // 0..2 = an arc, 3 = rest
  const op = (i: number) => (active === i ? 1 : 0.35);
  return (
    <svg width={22} height={17} viewBox="0 0 22 17" fill="none" stroke="#fff" strokeWidth={2.6} strokeLinecap="round">
      <circle cx={11} cy={14.6} r={1.9} fill="#fff" stroke="none" />
      <path d="M7.6 11.2 A4.8 4.8 0 0 1 14.4 11.2" opacity={op(0)} />
      <path d="M4.6 8.1 A9 9 0 0 1 17.4 8.1" opacity={op(1)} />
      <path d="M1.6 5 A13.2 13.2 0 0 1 20.4 5" opacity={op(2)} />
    </svg>
  );
}

function Track({ period, height, preview }: { period: number; height: number; preview: boolean }) {
  const phase = usePhase(1 / Math.max(period, 0.1), previewFps(preview));
  const u = phase % 1;
  const segment = (span: { tail: number; head: number }) => (
    <div
      style={{
        position: "absolute",
        left: span.tail * WIDTH,
        top: 0,
        width: Math.max(0, (span.head - span.tail) * WIDTH),
        height,
        borderRadius: height / 2,
        background: Palette.primary,
      }}
    />
  );
  return (
    <div style={{ filter: `drop-shadow(0 0 6px ${alpha(Palette.violet, 0.35)})` }}>
      <div style={{ position: "relative", width: WIDTH, height, borderRadius: height / 2, overflow: "hidden", background: primary(0.08) }}>
        {segment(first(u))}
        {segment(second(u))}
      </div>
    </div>
  );
}
