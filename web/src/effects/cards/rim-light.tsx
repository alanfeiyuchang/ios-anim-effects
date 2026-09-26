/** cards.rim-light · 边缘光 (Cards+RimLight.swift) */
import { animate, useMotionValue } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, black, clamp, spring, useClock, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";
import { CreditCard, Stage, StrokeBorder, persp, useMV } from "./shared";

const CARD = { w: 250, h: 158 };
const AREA = { w: 310, h: 218 };
const HALF = { w: 125, h: 79 };

export default function RimLight({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const lxMV = useMotionValue(0.6);
  const lyMV = useMotionValue(-0.5);
  const [touched, setTouched] = useState(false);
  const touchedRef = useRef(false);
  const held = useRef(false);

  useClock(!touched, ctx.isPreview ? 30 : undefined);
  const idle = (t: number) => ({ x: Math.cos(t * 0.9), y: Math.sin(t * 0.9) * 0.9 });
  const lx = useMV(lxMV);
  const ly = useMV(lyMV);
  const light = touched ? { x: lx, y: ly } : idle(Date.now() / 1000);

  /** `location` in the touch area's coordinates. */
  const moveLight = (location: Point) => {
    if (!touchedRef.current) {
      const s = idle(Date.now() / 1000);
      lxMV.jump(s.x);
      lyMV.jump(s.y);
      touchedRef.current = true;
      setTouched(true);
    }
    if (!held.current) {
      held.current = true;
      haptics.tap("soft");
    }
    const t = spring(ctx.n("lag"), 0.72);
    animate(lxMV, clamp((location.x - AREA.w / 2) / HALF.w, -1.3, 1.3), t);
    animate(lyMV, clamp((location.y - AREA.h / 2) / HALF.h, -1.3, 1.3), t);
  };
  const release = () => {
    if (!held.current) return;
    held.current = false;
    const t = spring(0.9, 0.8);
    animate(lxMV, lxMV.get() / 3, t);
    animate(lyMV, lyMV.get() / 3, t);
  };

  // Beside the card a drag starts after 8 pt; the card itself claims the touch at once.
  const areaPan = usePan({ onChange: ({ location }) => moveLight(location), onEnd: release }, 8);
  const cardPan = usePan({
    onChange: ({ location }) => moveLight({ x: location.x + (AREA.w - CARD.w) / 2, y: location.y + (AREA.h - CARD.h) / 2 }),
    onEnd: release,
  });

  const rim = ctx.n("rim");
  const maxAngle = ctx.n("angle");
  const peak = Math.atan2(light.y, light.x);
  const strength = Math.min(Math.hypot(light.x, light.y), 1);
  const tiltX = clamp(light.x, -1, 1);
  const tiltY = clamp(light.y, -1, 1);
  const p = persp(CARD.w, CARD.h, 0.55);
  const peakColor = white(rim * (0.35 + 0.65 * strength));
  const rimGradient = `conic-gradient(from ${((peak - Math.PI) * 180) / Math.PI + 90}deg, transparent 0turn, transparent ${1 / 3}turn, ${peakColor} 0.5turn, transparent ${2 / 3}turn, transparent 1turn)`;

  return (
    <Stage gap={30}>
      <div {...areaPan} style={{ ...areaPan.style, position: "relative", width: AREA.w, height: AREA.h, display: "grid", placeItems: "center" }}>
        <div
          {...cardPan}
          onPointerDown={(e) => {
            e.stopPropagation();
            cardPan.onPointerDown(e);
          }}
          style={{ ...cardPan.style, position: "relative", width: CARD.w, height: CARD.h, cursor: "grab" }}
        >
          <div style={{ position: "absolute", inset: 0, filter: `drop-shadow(${-light.x * 18}px ${16 - light.y * 10}px 20px ${black(0.3)})` }}>
            <div style={{ position: "absolute", inset: 0, transform: `${p} rotateY(${tiltX * maxAngle}deg)` }}>
              <div style={{ position: "absolute", inset: 0, transform: `${p} rotateX(${-tiltY * maxAngle}deg)` }}>
                <CreditCard
                  theme={1}
                  last4="5530"
                  overlay={
                    <div
                      style={{
                        position: "absolute",
                        left: CARD.w / 2 - 45,
                        top: CARD.h / 2 - 160,
                        width: 90,
                        height: 320,
                        background: `linear-gradient(90deg, transparent, ${white(0.22 * rim)}, transparent)`,
                        transform: `translate(${-light.x * 120}px, ${-light.y * 40}px) rotate(24deg)`,
                        mixBlendMode: "plus-lighter",
                        pointerEvents: "none",
                      }}
                    />
                  }
                />
                <div style={{ position: "absolute", inset: 0, filter: "blur(6px)" }}>
                  <StrokeBorder radius={18} width={6} color={rimGradient} />
                </div>
                <StrokeBorder radius={18} width={2.5} color={rimGradient} />
              </div>
            </div>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag around the card to move the light" zh="在卡片周围拖动以移动光源" />
    </Stage>
  );
}
