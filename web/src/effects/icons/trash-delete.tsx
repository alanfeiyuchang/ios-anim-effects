/** icons.trash-delete · 删除入篓 (Icons+TrashDelete.swift) */
import { useState } from "react";
import { DemoHint, NumericText, Palette, hex, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { C, Glyph, L, S, SPRINGS, sym, track, useSince, type GlyphDef } from "./_icons-kit";

const DOC_TEXT_FILL: GlyphDef = [
  {
    d: "M6 2h7.6L20 8.4V20a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2Z",
    cut: { d: "M13.6 1.6v5.3a1.5 1.5 0 0 0 1.5 1.5h5.3M8 12.6h8M8 16.6h8M8 8.6h2.6", sw: 1.6 },
  },
];

export default function TrashDelete({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [drops, setDrops] = useState(0);
  const [deleted, setDeleted] = useState(0);

  const lidAngle = ctx.n("lid");
  const bounce = ctx.n("bounce");
  const squashes = ctx.b("squash");
  const close: [number, number] = [0.4, 1 - bounce];

  const t = useSince(drops, 1.35);
  const v = (initial: number, frames: Parameters<typeof track>[2]) => (t < 0 ? initial : track(t, initial, frames));
  const lid = v(0, [S(-lidAngle, 0.2, SPRINGS.snappy), L(-lidAngle, 0.35), S(0, 0.4, close), L(0, 0.35)]);
  const lidLift = v(0, [C(-8, 0.2), L(-8, 0.35), S(0, 0.4, close), L(0, 0.35)]);
  const docY = v(0, [C(-16, 0.18), C(84, 0.3), L(84, 0.37), L(0, 0.01), L(0, 0.44)]);
  const docScale = v(1, [C(1.06, 0.18), C(0.6, 0.3), L(0.6, 0.37), L(0.4, 0.01), S(1, 0.44, SPRINGS.bouncy)]);
  const docOpacity = v(1, [L(1, 0.36), L(0, 0.12), L(0, 0.49), C(1, 0.33)]);
  const docTilt = v(0, [C(-6, 0.18), C(14, 0.3), L(14, 0.37), L(0, 0.01), L(0, 0.44)]);
  const squash = v(1, [L(1, 0.46), C(squashes ? 0.9 : 1, 0.08), S(1, 0.4, SPRINGS.bouncy), L(1, 0.36)]);

  /** `scripted`: the delayed lid-thud haptic stays silent for autoplay and the detail intro. */
  const remove = (scripted = false) => {
    setDrops((d) => d + 1);
    haptics.tap("medium");
    after(0.5, () => setDeleted((n) => n + 1));
    after(0.72, () => {
      if (!scripted) haptics.tap("rigid");
    });
  };
  useAutoplay(ctx.isPreview, () => remove(true), { every: 1.8 });

  const docSize = sym(42);
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div onClick={() => remove()} style={{ position: "relative", width: 200, height: 224, cursor: "pointer" }}>
        <div
          style={{
            position: "absolute",
            left: 100 - docSize / 2,
            top: 112 - docSize / 2,
            transform: `translateY(${-82 + docY}px) rotate(${docTilt}deg) scale(${docScale})`,
            opacity: docOpacity,
            filter: "drop-shadow(0 4px 8px rgb(79 124 255 / 0.3))",
          }}
        >
          <Glyph
            def={DOC_TEXT_FILL}
            size={docSize}
            paint="url(#trash-doc)"
            defs={
              <linearGradient id="trash-doc" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor={Palette.sky} />
                <stop offset="1" stopColor={Palette.blue} />
              </linearGradient>
            }
          />
        </div>
        {/* Can: lid stacked on the body (spacing −2), squashing from its base. */}
        <div
          style={{
            position: "absolute",
            left: 100 - 47,
            top: 112 - 52.5,
            width: 94,
            height: 105,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            transform: `scale(${2 - squash}, ${squash})`,
            transformOrigin: "50% 100%",
          }}
        >
          <div
            style={{
              position: "relative",
              zIndex: 1,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              transform: `translateY(${lidLift}px) rotate(${lid}deg)`,
              transformOrigin: "100% 50%",
            }}
          >
            <div style={{ width: 30, height: 8, borderRadius: "5px 5px 0 0", background: hex(0xff7a88) }} />
            <div style={{ width: 94, height: 11, borderRadius: 5.5, background: `linear-gradient(${hex(0xff8c98)}, ${hex(0xe83e52)})` }} />
          </div>
          <div
            style={{
              marginTop: -2,
              width: 78,
              height: 88,
              borderRadius: "4px 4px 16px 16px",
              background: `linear-gradient(${hex(0xff7a88)}, ${Palette.red})`,
              boxShadow: "0 8px 12px rgb(255 77 94 / 0.3)",
              display: "flex",
              justifyContent: "center",
              alignItems: "center",
              gap: 13,
            }}
          >
            {[0, 1, 2].map((i) => (
              <div key={i} style={{ width: 5, height: 52, borderRadius: 2.5, background: "rgb(255 255 255 / 0.35)" }} />
            ))}
          </div>
        </div>
      </div>
      <div style={{ position: "relative", display: "flex", gap: 6, ...textStyle.subheadline, fontWeight: 600, color: Palette.secondaryLabel }}>
        <NumericText value={deleted} />
        <span>{ctx.t("items deleted", "项已删除")}</span>
        <DemoHint ctx={ctx} en="Tap to delete" zh="点击删除" style={{ position: "absolute", left: "50%", bottom: -26, transform: "translateX(-50%)", whiteSpace: "nowrap" }} />
      </div>
    </div>
  );
}
