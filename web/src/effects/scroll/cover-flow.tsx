/** scroll.cover-flow · 封面流 (Scroll+CoverFlow.swift) */
import { useRef, useState } from "react";
import { clamp, spring, useAutoplay, white, black, type DemoProps } from "../../kit";
import { FadeText, ScrollKit, ScrollKitArt, SnapMarkers, perspectivePx, strideSnap, useScroller } from "./_kit";

const COUNT = 10;
const SIDE = 150;
const INITIAL = 3;
const WIDTH = 340;
const ITEM_H = SIDE + 6 + 56;

export default function CoverFlow({ ctx }: DemoProps) {
  const spacing = ctx.n("spacing");
  const pitch = Math.max(SIDE + spacing, 1);
  const [current, setCurrent] = useState(INITIAL);
  const direction = useRef(1);
  const sc = useScroller({
    axis: "x",
    initial: INITIAL * pitch,
    snap: strideSnap(pitch),
    onScroll: (o) => setCurrent(clamp(Math.round(o / pitch), 0, COUNT - 1)),
  });

  const select = (i: number) => sc.scrollTo(i * pitch, spring(0.5, 0.86));
  useAutoplay(
    ctx.isPreview,
    () => {
      if (current + direction.current >= COUNT || current + direction.current < 0) direction.current = -direction.current;
      sc.scrollTo((current + direction.current) * pitch, spring(0.6, 0.86));
    },
    { every: 1.4 },
  );

  const angle = ctx.n("angle");
  const persp = ctx.n("perspective");
  const reflection = ctx.b("reflection");
  const pad = (WIDTH - SIDE) / 2;
  const contentWidth = pad * 2 + COUNT * SIDE + (COUNT - 1) * spacing;
  const offset = sc.offset;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10 }}>
      <div {...sc.props} style={{ ...sc.props.style, width: WIDTH, height: SIDE + 72, flexShrink: 0 }}>
        <div ref={sc.contentRef} style={{ position: "relative", width: contentWidth, height: "100%" }}>
          <SnapMarkers count={COUNT} pitch={pitch} />
          {Array.from({ length: COUNT }, (_, i) => {
            const t = clamp((i * pitch - offset) / (WIDTH / 2), -1, 1);
            return (
              <div
                key={i}
                onClick={() => select(i)}
                style={{
                  position: "absolute",
                  left: pad + i * pitch,
                  top: (SIDE + 72 - ITEM_H) / 2,
                  width: SIDE,
                  height: ITEM_H,
                  zIndex: 20 - Math.abs(i - current),
                  display: "flex",
                  flexDirection: "column",
                  gap: 6,
                  transform: `scale(${1 - Math.abs(t) * 0.15}) perspective(${perspectivePx(SIDE, ITEM_H, persp)}px) rotateY(${-t * angle}deg)`,
                  opacity: 1 - Math.abs(t) * 0.25,
                  cursor: "pointer",
                }}
              >
                <Cover index={i} lang={ctx.lang} />
                {reflection ? (
                  <div
                    style={{
                      position: "relative",
                      height: 56,
                      overflow: "hidden",
                      WebkitMaskImage: `linear-gradient(${black(0.6)}, ${black(0.22)} 55%, transparent)`,
                      maskImage: `linear-gradient(${black(0.6)}, ${black(0.22)} 55%, transparent)`,
                    }}
                  >
                    <div style={{ position: "absolute", left: 0, top: 0, width: SIDE, height: SIDE, transform: "scaleY(-1)" }}>
                      <Cover index={i} lang={ctx.lang} />
                    </div>
                  </div>
                ) : (
                  <div style={{ height: 56 }} />
                )}
              </div>
            );
          })}
        </div>
      </div>
      <FadeText text={ScrollKit.title(current, ctx.lang)} style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }} />
    </div>
  );
}

function Cover({ index, lang }: { index: number; lang: DemoProps["ctx"]["lang"] }) {
  return (
    <div style={{ position: "relative", width: SIDE, height: SIDE, flexShrink: 0, borderRadius: 14, overflow: "hidden" }}>
      <ScrollKitArt index={index} lang={lang} showsTitle={false} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 14, boxShadow: `inset 0 0 0 1px ${white(0.2)}` }} />
    </div>
  );
}
