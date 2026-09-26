/** cards.scrub-flip · 拖拽翻转 (Cards+ScrubFlip.swift) */
import { animate, useMotionValue } from "motion/react";
import { QrCode } from "lucide-react";
import { useEffect, useRef } from "react";
import { DemoHint, black, clamp, spring, useAutoplay, useHaptics, usePan, white, type DemoContext, type DemoProps } from "../../kit";
import { CreditCard, Stage, StrokeBorder, diag, persp, predictEnd, themeColors, useMV } from "./shared";

export default function ScrubFlip({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const angleMV = useMotionValue(0);
  const pitchMV = useMotionValue(0);
  const base = useRef<number | null>(null);
  const direction = useRef(1);
  const script = useRef(0);
  useEffect(() => () => window.clearTimeout(script.current), []);

  /** Rounds to the nearest face, at most three half-turns away from where the drag began. */
  const land = (projected: number, start: number) => {
    const startFace = Math.round(start / 180);
    const face = clamp(Math.round(projected / 180), startFace - 3, startFace + 3);
    haptics.tap("light");
    const t = spring(0.6, ctx.n("damping"));
    animate(angleMV, face * 180, t);
    animate(pitchMV, 0, t);
  };

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (base.current === null) {
          base.current = angleMV.get();
          window.clearTimeout(script.current);
        }
        angleMV.jump(base.current + translation.x * ctx.n("sensitivity"));
        pitchMV.jump(clamp(-translation.y * 0.12, -14, 14));
      },
      onEnd: ({ translation, velocity }) => {
        const start = base.current;
        if (start === null) return;
        base.current = null;
        const extra = (predictEnd(translation.x, velocity.x) - translation.x) * ctx.n("momentum");
        land(angleMV.get() + extra * ctx.n("sensitivity"), start);
      },
    },
    2,
  );

  useAutoplay(
    ctx.isPreview,
    () => {
      if (base.current !== null) return;
      direction.current = -direction.current;
      const dir = direction.current;
      const start = angleMV.get();
      const t = spring(0.35, 0.9);
      animate(angleMV, start + 55 * dir, t);
      animate(pitchMV, 8, t);
      window.clearTimeout(script.current);
      script.current = window.setTimeout(() => land(start + 470 * dir, start), 450);
    },
    { every: 2.2 },
  );

  const angle = useMV(angleMV);
  const pitch = useMV(pitchMV);
  const remainder = angle % 360;
  const normalized = remainder < 0 ? remainder + 360 : remainder;
  const showBack = normalized > 90 && normalized < 270;
  const edge = Math.abs(Math.sin((angle * Math.PI) / 180));
  const p = persp(250, 158, 0.5);

  return (
    <Stage gap={30}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: 250, height: 158, cursor: "grab" }}>
        <div style={{ position: "absolute", inset: 0, filter: `drop-shadow(0 ${12 + 12 * edge}px ${16 + 12 * edge}px ${black(0.18 + 0.12 * edge)})` }}>
          <div style={{ position: "absolute", inset: 0, transform: `scale(${1 + 0.06 * edge})` }}>
            <div style={{ position: "absolute", inset: 0, transform: `${p} rotateY(${angle}deg)` }}>
              <div style={{ position: "absolute", inset: 0, transform: `${p} rotateX(${pitch}deg)` }}>
                <div style={{ position: "absolute", inset: 0, opacity: showBack ? 0 : 1 }}>
                  <CreditCard theme={4} last4="8812" />
                </div>
                <div style={{ position: "absolute", inset: 0, opacity: showBack ? 1 : 0, transform: "rotateY(180deg)" }}>
                  <SpinBack ctx={ctx} />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag sideways, or flick to spin" zh="左右拖动，或快速甩动让它旋转" />
    </Stage>
  );
}

function SpinBack({ ctx }: { ctx: DemoContext }) {
  return (
    <div style={{ position: "relative", width: 250, height: 158 }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 18,
          background: diag(themeColors(3)),
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 10,
        }}
      >
        <QrCode size={58} strokeWidth={1.6} color={white(0.92)} />
        <span style={{ fontSize: 13, lineHeight: "16px", fontWeight: 600, color: white(0.8) }}>{ctx.t("Scan to pay", "扫码支付")}</span>
      </div>
      <StrokeBorder radius={18} color={white(0.2)} />
    </div>
  );
}
