/** cards.hinge-reveal · 铰链揭示 (Cards+HingeReveal.swift) */
import { animate, useMotionValue } from "motion/react";
import { Gift } from "lucide-react";
import { useId, useRef } from "react";
import { DemoHint, Palette, black, clamp, fonts, spring, useAutoplay, useHaptics, white, type DemoContext, type DemoProps } from "../../kit";
import { Stage, StrokeBorder, diag, persp, themeColors, useMV } from "./shared";

const W = 210;
const H = 140;

export default function HingeReveal({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const angleMV = useMotionValue(0);
  const open = useRef(false);

  const toggle = () => {
    haptics.tap(open.current ? "rigid" : "medium");
    if (open.current) {
      open.current = false;
      animate(angleMV, 0, spring(0.5, 0.86));
    } else {
      open.current = true;
      animate(angleMV, ctx.n("openAngle"), spring(ctx.n("response"), ctx.n("damping")));
    }
  };
  useAutoplay(ctx.isPreview, toggle, { every: 2.4 });

  const angle = useMV(angleMV);
  const openAngle = Math.max(ctx.n("openAngle"), 1);
  const fraction = clamp(angle / openAngle, 0, 1.2);
  const showsInside = angle > 90;
  const edgeOn = Math.abs(Math.sin((angle * Math.PI) / 180));

  return (
    <Stage gap={30}>
      <div onClick={toggle} style={{ position: "relative", width: W, height: H, cursor: "pointer", transform: `translateX(${30 * Math.min(fraction, 1)}px)` }}>
        <Inside fraction={fraction} ctx={ctx} />
        <div style={{ position: "absolute", inset: 0, transformOrigin: "0 50%", transform: `${persp(W, H, 0.6)} rotateY(${-angle}deg)` }}>
          {showsInside ? (
            <div style={{ position: "absolute", inset: 0, borderRadius: 18, background: "#F4F1EA" }}>
              <div style={{ position: "absolute", inset: 0, borderRadius: 18, background: black(0.25 * edgeOn) }} />
            </div>
          ) : (
            <div style={{ position: "absolute", inset: 0 }}>
              <CoverFront ctx={ctx} />
              <div style={{ position: "absolute", inset: 0, borderRadius: 18, background: black(0.35 * edgeOn) }} />
            </div>
          )}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to open the cover" zh="点击打开封面" />
    </Stage>
  );
}

function Inside({ fraction, ctx }: { fraction: number; ctx: DemoContext }) {
  const id = useId().replace(/:/g, "");
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: 18,
        background: Palette.elevated,
        boxShadow: `0 8px 14px ${black(0.14)}`,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
      }}
    >
      <svg width={0} height={0} style={{ position: "absolute" }}>
        <defs>
          <linearGradient id={`${id}s`} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={Palette.amber} />
            <stop offset="0.5" stopColor={Palette.coral} />
            <stop offset="1" stopColor={Palette.pink} />
          </linearGradient>
        </defs>
      </svg>
      <Gift size={34} fill={`url(#${id}s)`} stroke={Palette.elevated} strokeWidth={1.6} />
      <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 700 }}>{ctx.t("$50 for you", "送你 ¥300")}</span>
      <span style={{ fontFamily: fonts.mono, fontSize: 13, lineHeight: "16px", fontWeight: 600, letterSpacing: 1.5, padding: "5px 10px", borderRadius: 999, background: Palette.labelAlpha(0.07) }}>
        MOTION-2026
      </span>
      {/* Shadow cast by the cover, strongest while it still hangs over the card. */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 18,
          background: `linear-gradient(90deg, ${black(0.35)}, transparent 70%)`,
          opacity: Math.max(1 - fraction, 0),
          pointerEvents: "none",
        }}
      />
      <div style={{ position: "absolute", inset: 0, borderRadius: 18, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
    </div>
  );
}

function CoverFront({ ctx }: { ctx: DemoContext }) {
  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: 18, overflow: "hidden", background: diag(themeColors(2)) }}>
        <div style={{ position: "absolute", top: 0, bottom: 0, left: W / 2 - 7 + 50, width: 14, background: white(0.85) }} />
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", transform: "translateX(-24px)" }}>
          <span style={{ fontFamily: fonts.rounded, fontSize: 17, fontWeight: 700, color: "#fff" }}>{ctx.t("Open me", "打开我")}</span>
        </div>
      </div>
      <StrokeBorder radius={18} color={white(0.25)} />
    </div>
  );
}
