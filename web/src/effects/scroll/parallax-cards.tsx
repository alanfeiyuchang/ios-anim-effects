/** scroll.parallax-cards · 视差窗口卡片 (Scroll+ParallaxCards.swift) */
import { useRef } from "react";
import { anim, black, clamp, useAutoplay, white, type DemoProps } from "../../kit";
import { ScrollKit, Sym, edgePhase, useScroller } from "./_kit";

const WINDOW_H = 150;
const GAP = 14;
const TOP = 16;

export default function ParallaxCards({ ctx }: DemoProps) {
  const sc = useScroller({ axis: "y" });
  const down = useRef(false);

  useAutoplay(
    ctx.isPreview,
    () => {
      down.current = !down.current;
      sc.scrollTo(down.current ? 560 : 0, anim.smoothD(2.6));
    },
    { every: 3.0 },
  );

  const amount = ctx.n("amount");
  const zoom = ctx.b("zoom");
  const viewport = sc.size.height;
  const half = Math.max(viewport / 2, 1);

  return (
    <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
      <div ref={sc.contentRef} style={{ padding: `${TOP}px 20px 20px`, display: "flex", flexDirection: "column", gap: GAP }}>
        {Array.from({ length: 9 }, (_, i) => {
          const top = TOP + i * (WINDOW_H + GAP) - sc.offset;
          const t = clamp((top + WINDOW_H / 2 - half) / half, -1, 1);
          const phase = edgePhase(top, WINDOW_H, viewport);
          const scale = zoom ? 1 - Math.abs(phase) * 0.08 : 1;
          const index = i * 2 + 1;
          return (
            <div
              key={i}
              style={{
                position: "relative",
                height: WINDOW_H,
                flexShrink: 0,
                borderRadius: 22,
                boxShadow: `0 6px 12px ${black(0.12)}`,
                transform: `scale(${scale})`,
              }}
            >
              <div style={{ position: "absolute", inset: 0, borderRadius: 22, overflow: "hidden" }}>
                <div style={{ position: "absolute", left: 0, right: 0, top: -amount - t * amount, height: WINDOW_H + amount * 2 }}>
                  <Art index={index} />
                </div>
              </div>
              <div
                style={{
                  position: "absolute",
                  left: 0,
                  bottom: 0,
                  padding: 14,
                  display: "flex",
                  flexDirection: "column",
                  gap: 2,
                  color: "#fff",
                  textShadow: `0 2px 6px ${black(0.25)}`,
                }}
              >
                <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 700, whiteSpace: "nowrap" }}>{ScrollKit.title(index, ctx.lang)}</div>
                <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, opacity: 0.85, whiteSpace: "nowrap" }}>{ScrollKit.subtitle(index, ctx.lang)}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

/** Oversized window artwork: gradient, big glyph and soft, low-contrast light blobs. */
function Art({ index }: { index: number }) {
  const blob = (w: number, x: number, y: number, color: string) => (
    <div
      style={{
        position: "absolute",
        left: "50%",
        top: "50%",
        width: w,
        height: w,
        marginLeft: -w / 2 + x,
        marginTop: -w / 2 + y,
        borderRadius: "50%",
        background: color,
        filter: "blur(30px)",
      }}
    />
  );
  return (
    <div style={{ position: "absolute", inset: 0, background: ScrollKit.gradient(index), overflow: "hidden" }}>
      {blob(180, 90, -40, white(0.12))}
      {blob(160, -100, 60, black(0.1))}
      <div
        style={{
          position: "absolute",
          left: "50%",
          top: "50%",
          transform: "translate(-50%, -50%) translateX(70px)",
          color: white(0.9),
          filter: `drop-shadow(0 5px 10px ${black(0.18)})`,
        }}
      >
        <Sym name={ScrollKit.symbol(index)} size={64} weight={600} />
      </div>
      <div style={{ position: "absolute", inset: 0, background: `linear-gradient(transparent 50%, ${black(0.25)})` }} />
    </div>
  );
}
