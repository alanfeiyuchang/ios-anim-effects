/** scroll.minimap · 缩略图导航 (Scroll+Minimap.swift) */
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, clamp, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { ScrollKit, useScroller } from "./_kit";

type Kind = "heading" | "text" | "image" | "code";
const BLOCKS: [Kind, number, number][] = [
  ["heading", 22, 0.7], ["text", 60, 1], ["text", 44, 0.9], ["image", 110, 1], ["text", 58, 1],
  ["code", 84, 0.95], ["heading", 20, 0.55], ["text", 70, 1], ["image", 90, 1], ["text", 40, 0.8],
  ["code", 64, 0.9], ["text", 56, 1], ["heading", 22, 0.65], ["text", 48, 1], ["image", 120, 1], ["text", 62, 0.85],
];
const SPACING = 14;
const PADDING = 16;

export default function Minimap({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [active, setActive] = useState(false);
  const idleTimer = useRef(0);
  const lastJump = useRef(-1);
  const held = useRef(false);
  const down = useRef(false);
  const scheduleIdle = () => {
    window.clearTimeout(idleTimer.current);
    idleTimer.current = window.setTimeout(() => setActive(false), 600);
  };
  useEffect(() => () => window.clearTimeout(idleTimer.current), []);
  const sc = useScroller({
    axis: "y",
    onPhase: (p) => {
      if (p !== "idle") {
        window.clearTimeout(idleTimer.current);
        setActive(true);
      } else scheduleIdle();
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      down.current = !down.current;
      sc.scrollTo(down.current ? "end" : 0, anim.smoothD(2.2));
    },
    { every: 2.8 },
  );

  const scale = ctx.n("scale");
  const viewport = Math.max(sc.size.height, 1);
  const content = viewport + sc.max();
  const lit = active && ctx.b("glow");

  const scrub = (e: React.PointerEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const s = rect.width / e.currentTarget.offsetWidth || 1;
    const y = (e.clientY - rect.top) / s;
    const target = clamp(y / Math.max(scale, 0.01) - viewport / 2, 0, Math.max(content - viewport, 0));
    const bucket = Math.floor(target / 80);
    if (bucket !== lastJump.current) {
      lastJump.current = bucket;
      haptics.selection();
    }
    sc.scrollTo(target, null);
    window.clearTimeout(idleTimer.current);
    setActive(true);
  };
  const endHold = () => {
    if (!held.current) return;
    held.current = false;
    lastJump.current = -1;
    scheduleIdle();
  };

  return (
    <div style={{ position: "absolute", inset: 0, padding: "12px 14px", display: "flex", flexDirection: "column", gap: 8 }}>
      <div style={{ flex: 1, minHeight: 0, display: "flex", gap: 10 }}>
        <div {...sc.props} style={{ ...sc.props.style, flex: 1, minWidth: 0, borderRadius: 18, background: Palette.elevated }}>
          <div ref={sc.contentRef} style={{ padding: PADDING }}>
            <Document scale={1} />
          </div>
        </div>
        <div
          onPointerDown={(e) => {
            e.currentTarget.setPointerCapture(e.pointerId);
            held.current = true;
            scrub(e);
          }}
          onPointerMove={(e) => held.current && scrub(e)}
          onPointerUp={endHold}
          onPointerCancel={endHold}
          style={{ position: "relative", width: 44, flexShrink: 0, overflow: "hidden", touchAction: "none", cursor: "pointer" }}
        >
          <div style={{ padding: PADDING * scale }}>
            <Document scale={scale} />
          </div>
          <div
            style={{
              position: "absolute",
              left: -3,
              right: -3,
              top: sc.offset * scale,
              height: viewport * scale,
              borderRadius: 5,
              background: alpha(Palette.indigo, lit ? 0.22 : 0.12),
              boxShadow: `inset 0 0 0 ${lit ? 1.5 : 1}px ${alpha(Palette.indigo, 0.8)}`,
              transition: active ? "background 0.15s ease-out, box-shadow 0.15s ease-out" : "background 0.4s ease-in-out, box-shadow 0.4s ease-in-out",
            }}
          />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Scroll the page, or drag on the minimap" zh="滚动页面，或在缩略图上拖动" />
    </div>
  );
}

/** The document, drawn at any scale so the minimap is an exact miniature of the page. */
function Document({ scale }: { scale: number }) {
  const radius = Math.max(6 * scale, 1);
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: SPACING * scale }}>
      {BLOCKS.map(([kind, height, width], i) => {
        const h = height * scale;
        const base = { height: h, flexShrink: 0, borderRadius: radius } as const;
        if (kind === "heading") return <div key={i} style={{ ...base, width: `${width * 100}%`, background: Palette.labelAlpha(0.75) }} />;
        if (kind === "text") return <div key={i} style={{ ...base, width: `${width * 100}%`, background: Palette.labelAlpha(0.14) }} />;
        if (kind === "image") return <div key={i} style={{ ...base, borderRadius: radius * 2, background: ScrollKit.gradient(i) }} />;
        return <div key={i} style={{ ...base, background: alpha(Palette.indigo, 0.16) }} />;
      })}
    </div>
  );
}
