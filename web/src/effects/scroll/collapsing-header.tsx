/** scroll.collapsing-header · 折叠标题栏 (Scroll+CollapsingHeader.swift) */
import { useRef } from "react";
import { Palette, anim, clamp, glass, mix, useAutoplay, type DemoProps } from "../../kit";
import { ScrollKitRow, Sym, useScroller } from "./_kit";

export default function CollapsingHeader({ ctx }: DemoProps) {
  const range = Math.max(ctx.n("range"), 1);
  const down = useRef(false);
  const sc = useScroller({
    axis: "y",
    onPhase: (phase) => {
      if (phase !== "idle") return;
      // Avoid resting half-collapsed: settle to fully expanded or collapsed.
      const offset = sc.get();
      if (!ctx.b("snap") || offset <= 0 || offset >= range) return;
      sc.scrollTo(offset < range / 2 ? 0 : range, anim.smoothD(0.35));
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      down.current = !down.current;
      sc.scrollTo(down.current ? 220 : 0, anim.smoothD(1.4));
    },
    { every: 2.2 },
  );

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
        <div ref={sc.contentRef} style={{ padding: "0 16px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ height: 150, flexShrink: 0 }} />
          {Array.from({ length: 14 }, (_, i) => (
            <ScrollKitRow key={i} index={i + 4} lang={ctx.lang} style={{ flexShrink: 0 }} />
          ))}
        </div>
      </div>
      <Bar progress={clamp(sc.offset / range)} divider={ctx.b("divider")} zh={ctx.lang === "zh"} />
    </div>
  );
}

function Bar({ progress: p, divider, zh }: { progress: number; divider: boolean; zh: boolean }) {
  const avatar = mix(64, 30, p);
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: mix(150, 60, p), pointerEvents: "none" }}>
      <div style={{ position: "absolute", inset: 0, ...glass("regular"), opacity: p }} />
      <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
        <div
          style={{
            position: "absolute",
            left: 16,
            top: mix(16, 15, p),
            width: avatar,
            height: avatar,
            borderRadius: "50%",
            background: `linear-gradient(135deg, ${Palette.coral}, ${Palette.pink}, ${Palette.violet})`,
            display: "grid",
            placeItems: "center",
            color: "#fff",
          }}
        >
          <Sym name="music.note" size={avatar * 0.42} weight={700} />
        </div>
        <div
          style={{
            position: "absolute",
            left: mix(16, 56, p),
            top: mix(88, 20, p),
            fontSize: 30,
            lineHeight: "36px",
            fontWeight: 700,
            whiteSpace: "nowrap",
            transformOrigin: "0 0",
            transform: `scale(${mix(1, 0.57, p)})`,
          }}
        >
          {zh ? "资料库" : "Library"}
        </div>
        <div
          style={{
            position: "absolute",
            left: 16,
            top: mix(126, 90, p),
            fontSize: 15,
            lineHeight: "20px",
            color: Palette.secondaryLabel,
            whiteSpace: "nowrap",
            opacity: Math.max(1 - p * 2, 0),
          }}
        >
          {zh ? "128 项 · 刚刚同步" : "128 items · Synced just now"}
        </div>
        <div
          style={{
            position: "absolute",
            right: 16,
            top: 15,
            width: 30,
            height: 30,
            borderRadius: "50%",
            background: Palette.primary,
            display: "grid",
            placeItems: "center",
            color: "#fff",
          }}
        >
          <Sym name="plus" size={15} weight={700} />
        </div>
      </div>
      {divider && <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 0.5, background: Palette.labelAlpha(0.12 * p) }} />}
    </div>
  );
}
