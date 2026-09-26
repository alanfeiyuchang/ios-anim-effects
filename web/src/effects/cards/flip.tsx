/** cards.flip · 翻转卡片 (Cards+Flip.swift) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { DemoHint, Palette, black, fonts, spring, useAutoplay, useHaptics, white, type DemoContext, type DemoProps } from "../../kit";
import { CreditCard, Stage, StrokeBorder, diag, persp, themeColors, useMV } from "./shared";

export default function Flip({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const angleMV = useMotionValue(0);
  const target = useRef(0);
  const angle = useMV(angleMV);

  const flip = () => {
    haptics.tap("medium");
    target.current += 180;
    animate(angleMV, target.current, spring(ctx.n("response"), ctx.n("damping")));
  };
  useAutoplay(ctx.isPreview, flip, { every: 2.2 });

  const vertical = ctx.i("axis") === 1;
  const remainder = angle % 360;
  const normalized = remainder < 0 ? remainder + 360 : remainder;
  const showBack = normalized > 90 && normalized < 270;
  const rise = Math.abs(Math.sin((angle * Math.PI) / 180));
  const lifted = 1 + ctx.n("lift") * rise;
  const rot = vertical ? "rotateX" : "rotateY";

  return (
    <Stage gap={28}>
      <div onClick={flip} style={{ position: "relative", width: 250, height: 158, cursor: "pointer" }}>
        <div style={{ position: "absolute", inset: 0, filter: `drop-shadow(0 ${12 + 16 * rise}px ${16 + 14 * rise}px ${black(0.18 + 0.12 * rise)})` }}>
          <div style={{ position: "absolute", inset: 0, transform: `scale(${lifted})` }}>
            <div style={{ position: "absolute", inset: 0, transform: `${persp(250, 158, 0.45)} ${rot}(${angle}deg)` }}>
              <div style={{ position: "absolute", inset: 0, opacity: showBack ? 0 : 1 }}>
                <CreditCard theme={1} last4="7310" />
              </div>
              <div style={{ position: "absolute", inset: 0, opacity: showBack ? 1 : 0, transform: `${rot}(180deg)` }}>
                <FlipBack ctx={ctx} />
              </div>
            </div>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap the card to flip it" zh="点击卡片翻面" />
    </Stage>
  );
}

function FlipBack({ ctx }: { ctx: DemoContext }) {
  return (
    <div style={{ position: "relative", width: 250, height: 158 }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: 18, overflow: "hidden", background: diag(themeColors(1)), display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ height: 34, marginTop: 18, background: black(0.85), flexShrink: 0 }} />
        <div style={{ display: "flex", gap: 10, padding: "0 18px", alignItems: "center" }}>
          <div style={{ flex: 1, height: 30, borderRadius: 4, background: white(0.9), display: "flex", alignItems: "center", paddingLeft: 10 }}>
            <span style={{ fontFamily: fonts.serif, fontStyle: "italic", fontSize: 13, fontWeight: 500, color: black(0.7) }}>Alex Morgan</span>
          </div>
          <div style={{ width: 44, height: 30, borderRadius: 4, background: "#fff", display: "grid", placeItems: "center", fontFamily: fonts.mono, fontSize: 13, fontWeight: 700, color: black(0.8) }}>
            382
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "flex-end", padding: "0 18px" }}>
          <div style={{ display: "flex", flexDirection: "column", gap: 3, fontSize: 8, fontWeight: 600, lineHeight: "10px", color: white(0.6) }}>
            <span>{ctx.t("Authorized signature", "持卡人签名")}</span>
            <span>{ctx.t("Customer care 800-555-0199", "客服热线 400-820-0199")}</span>
          </div>
          <span style={{ flex: 1 }} />
          <div
            style={{
              width: 30,
              height: 30,
              borderRadius: "50%",
              opacity: 0.85,
              background: `conic-gradient(from 90deg, ${[...Palette.spectrum, Palette.indigo].join(", ")})`,
            }}
          />
        </div>
      </div>
      <StrokeBorder radius={18} color={white(0.2)} />
    </div>
  );
}
