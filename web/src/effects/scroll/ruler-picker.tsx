/** scroll.ruler-picker · 刻度尺选择器 (Scroll+RulerPicker.swift) */
import { useRef, useState } from "react";
import { NumericText, Palette, alpha, black, clamp, fonts, spring, useAutoplay, type DemoProps } from "../../kit";
import { SnapMarkers, strideSnap, useScroller, useSelectionTick } from "./_kit";

const MIN = 40;
const MAX = 120;
const PITCH = 12;
const WIDTH = 340;
const INITIAL = 28;
const TARGETS = [34, 22, 45, 30, 12, 28];

export default function RulerPicker({ ctx }: DemoProps) {
  const count = MAX - MIN + 1;
  const [index, setIndex] = useState(INITIAL);
  const step = useRef(0);
  const scripted = useRef(false);
  const sc = useScroller({
    axis: "x",
    initial: INITIAL * PITCH,
    snap: strideSnap(PITCH),
    onScroll: (o) => setIndex(clamp(Math.round(o / PITCH), 0, count - 1)),
    onPhase: (p) => {
      if (p === "interacting") scripted.current = false;
    },
  });
  useSelectionTick(index, ctx.isPreview, scripted);

  useAutoplay(
    ctx.isPreview,
    () => {
      const target = TARGETS[step.current % TARGETS.length];
      step.current += 1;
      scripted.current = true;
      sc.scrollTo(target * PITCH, spring(0.8, 0.9));
    },
    { every: 1.4 },
  );

  const swell = ctx.n("swell");
  const lens = Math.max(ctx.n("lens"), 1);
  const pad = (WIDTH - PITCH) / 2;
  const mask = `linear-gradient(90deg, transparent, ${black(1)} 20%, ${black(1)} 80%, transparent)`;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 4, flexShrink: 0 }}>
        <NumericText
          value={index}
          text={String(MIN + index)}
          style={{ fontFamily: fonts.rounded, fontSize: 56, lineHeight: "66px", fontWeight: 700 }}
        />
        <span style={{ fontSize: 20, lineHeight: "25px", fontWeight: 600, color: Palette.secondaryLabel }}>kg</span>
      </div>
      <div style={{ position: "relative", width: WIDTH, height: 100, flexShrink: 0, WebkitMaskImage: mask, maskImage: mask }}>
        <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
          <div ref={sc.contentRef} style={{ position: "relative", width: pad * 2 + count * PITCH, height: 100 }}>
            <SnapMarkers count={count} pitch={PITCH} />
            {Array.from({ length: count }, (_, i) => {
              const value = MIN + i;
              const major = value % 5 === 0;
              const t = Math.min(Math.abs(i * PITCH - sc.offset) / lens, 1);
              const grow = 1 + (swell - 1) * (1 - t);
              const fade = 0.35 + 0.65 * (1 - t);
              return (
                <div key={i} style={{ position: "absolute", left: pad + i * PITCH, top: 2, width: PITCH, height: 96 }}>
                  <div
                    style={{
                      position: "absolute",
                      bottom: 18,
                      left: (PITCH - (major ? 2 : 1.5)) / 2,
                      width: major ? 2 : 1.5,
                      height: major ? 34 : 20,
                      borderRadius: 1,
                      background: Palette.labelAlpha(major ? 0.7 : 0.35),
                      transformOrigin: "50% 100%",
                      transform: `scaleY(${grow})`,
                      opacity: fade,
                    }}
                  />
                  {major && (
                    <div
                      style={{
                        position: "absolute",
                        bottom: 0,
                        left: PITCH / 2 - 20,
                        width: 40,
                        height: 12,
                        textAlign: "center",
                        fontSize: 10,
                        lineHeight: "12px",
                        fontWeight: 600,
                        fontVariantNumeric: "tabular-nums",
                        color: Palette.secondaryLabel,
                        opacity: fade,
                      }}
                    >
                      {value}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
        <div
          style={{
            position: "absolute",
            left: (WIDTH - 3) / 2,
            bottom: 22,
            width: 3,
            height: 66,
            borderRadius: 2,
            background: Palette.primary,
            boxShadow: `0 0 6px ${alpha(Palette.indigo, 0.5)}`,
            pointerEvents: "none",
          }}
        />
      </div>
    </div>
  );
}
