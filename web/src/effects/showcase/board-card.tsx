/** showcase.board-card · 我的雪板翻转 (Sport+BoardCard.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { ArrowUpRight } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, clamp, fonts, spring, useAutoplay, useHaptics, usePan, white, black, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";

export default function BoardCard({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const angleMV = useMotionValue(0);
  const tiltW = useMotionValue(0);
  const tiltH = useMotionValue(0);
  const [pose, setPose] = useState({ angle: 0, w: 0, h: 0 });
  const update = () => setPose({ angle: angleMV.get(), w: tiltW.get(), h: tiltH.get() });
  useMotionValueEvent(angleMV, "change", update);
  useMotionValueEvent(tiltW, "change", update);
  useMotionValueEvent(tiltH, "change", update);
  const target = useRef(0);
  const dragged = useRef(false);

  const flip = () => {
    target.current += ctx.i("mode") === 1 ? 360 : 180;
    animate(angleMV, target.current, spring(ctx.n("response"), 0.72));
    haptics.tap("medium");
  };

  const level = () => {
    if (tiltW.get() === 0 && tiltH.get() === 0) return;
    animate(tiltW, 0, spring(0.5, 0.45));
    animate(tiltH, 0, spring(0.5, 0.45));
  };

  const pan = usePan(
    {
      onStart: () => {
        dragged.current = true;
        tiltW.stop();
        tiltH.stop();
      },
      onChange: ({ translation }) => {
        tiltW.set(clamp(translation.x, -100, 100));
        tiltH.set(clamp(translation.y, -100, 100));
      },
      onEnd: level,
    },
    10,
  );

  useAutoplay(ctx.isPreview, flip, { every: 2.4, delay: 0.8 });

  const k = 0.25 * ctx.n("tilt");
  const tiltX = pose.w * k;
  const tiltY = -pose.h * k;
  const zh = ctx.lang === "zh";

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(), padding: 20, width: 292, display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ display: "flex", alignItems: "flex-start" }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 3, flex: 1 }}>
              <span style={{ fontFamily: fonts.rounded, fontSize: 20, fontWeight: 600, color: "#fff", lineHeight: "24px" }}>{ctx.t("My Board", "我的雪板")}</span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 500, color: Signature.textSecondary, lineHeight: "15px" }}>Carve Custom · 156</span>
            </div>
            <div style={{ width: 30, height: 30, borderRadius: "50%", background: white(0.08), display: "grid", placeItems: "center", color: "#fff" }}>
              <ArrowUpRight size={13} strokeWidth={3} />
            </div>
          </div>
          <div
            {...pan}
            onClick={() => {
              if (dragged.current) {
                dragged.current = false;
                return;
              }
              flip();
            }}
            onPointerDown={(e) => {
              dragged.current = false;
              pan.onPointerDown(e);
            }}
            style={{ height: 124, margin: "4px 0", display: "grid", placeItems: "center", touchAction: "none", cursor: "pointer" }}
          >
            <Flipper angle={pose.angle} tiltX={tiltX} tiltY={tiltY} />
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            <Stat value="156" unit="cm" label={ctx.t("Length", "板长")} />
            <Stat value="6" unit="/10" label={ctx.t("Flex", "软硬")} />
            <Stat value="2" unit={zh ? "天" : "d"} label={ctx.t("Waxed", "打蜡")} />
          </div>
          <SignatureRim />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap to flip, drag to tilt" zh="点击翻转，拖动倾斜" style={{ paddingBottom: 16 }} />
      </div>
    </SignatureStage>
  );
}

function Flipper({ angle, tiltX, tiltY }: { angle: number; tiltX: number; tiltY: number }) {
  const wrapped = angle % 360;
  const a = wrapped < 0 ? wrapped + 360 : wrapped;
  const showsBase = a > 90 && a < 270;
  const shift = tiltX * 3 + Math.sin((angle * Math.PI) / 180) * 90;
  // perspective 0.28 on a 228-wide layer ≈ a CSS perspective of 228 / 0.28.
  return (
    <div style={{ filter: `drop-shadow(0 12px 14px ${black(0.55)})` }}>
      <div
        style={{
          width: 228,
          height: 60,
          borderRadius: 30,
          overflow: "hidden",
          position: "relative",
          isolation: "isolate",
          transform: `rotate(-10deg) perspective(814px) rotateY(${tiltX}deg) rotateX(${angle + tiltY}deg)`,
        }}
      >
        {showsBase ? (
          <div style={{ position: "absolute", inset: 0, transform: "scaleY(-1)" }}>
            <BoardBase />
          </div>
        ) : (
          <BoardTop />
        )}
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", mixBlendMode: "plus-lighter", pointerEvents: "none" }}>
          <div
            style={{
              width: 180,
              height: 180,
              flexShrink: 0,
              transform: `translateX(${shift}px) rotate(20deg)`,
              background: `linear-gradient(90deg, transparent 0%, ${white(0.07)} 30%, ${white(0.3)} 50%, ${white(0.07)} 70%, transparent 100%)`,
            }}
          />
        </div>
      </div>
    </div>
  );
}

const center = { position: "absolute", left: "50%", top: "50%" } as const;

function BoardTop() {
  return (
    <div style={{ position: "absolute", inset: 0, borderRadius: 30, overflow: "hidden", background: "linear-gradient(#2C2C33, #0E0E11)" }}>
      <div style={{ ...center, width: 44, height: 140, marginLeft: -22, marginTop: -70, transform: "translateX(46px) rotate(24deg)", background: Signature.accentGradient }} />
      <div style={{ ...center, width: 6, height: 140, marginLeft: -3, marginTop: -70, transform: "translateX(80px) rotate(24deg)", background: "rgb(200 245 96 / 0.9)" }} />
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 14 }}>
        <Binding />
        <span style={{ fontFamily: fonts.rounded, fontSize: 8, fontWeight: 800, letterSpacing: 2.5, color: white(0.55), marginRight: -2.5 }}>NORDKETTE</span>
        <Binding />
      </div>
      <div style={{ position: "absolute", inset: 0, borderRadius: 30, boxShadow: `inset 0 0 0 1px ${white(0.18)}` }} />
    </div>
  );
}

function BoardBase() {
  return (
    <div style={{ position: "absolute", inset: 0, borderRadius: 30, overflow: "hidden", background: Signature.accentGradient }}>
      {[0, 1, 2, 3].map((ring) => {
        const w = 50 + ring * 34;
        const h = 16 + ring * 11;
        return (
          <div
            key={ring}
            style={{ ...center, width: w, height: h, marginLeft: -w / 2 + 34, marginTop: -h / 2, borderRadius: "50%", boxShadow: `inset 0 0 0 1px ${black(0.16)}` }}
          />
        );
      })}
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", transform: "translateX(-30px)" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 6, color: black(0.72), fontFamily: fonts.rounded }}>
          <span style={{ fontSize: 9, fontWeight: 800, letterSpacing: 2 }}>CARVE</span>
          <span style={{ fontSize: 28, fontWeight: 900, lineHeight: "34px" }}>156</span>
        </div>
      </div>
      <div style={{ position: "absolute", inset: 0, borderRadius: 30, boxShadow: `inset 0 0 0 1px ${white(0.35)}` }} />
    </div>
  );
}

function Binding() {
  return (
    <div
      style={{
        width: 18,
        height: 42,
        borderRadius: 5,
        background: "linear-gradient(#4A4A52, #26262B)",
        boxShadow: `inset 0 0 0 1px ${white(0.2)}`,
      }}
    />
  );
}

function Stat({ value, unit, label }: { value: string; unit: string; label: string }) {
  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 2, padding: "8px 10px", borderRadius: 12, background: white(0.05) }}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 2 }}>
        <span style={{ ...signatureNumber(17), color: "#fff", lineHeight: "20px" }}>{value}</span>
        <span style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 600, color: Signature.textSecondary }}>{unit}</span>
      </div>
      <span style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 500, color: Signature.textSecondary, lineHeight: "12px" }}>{label}</span>
    </div>
  );
}
