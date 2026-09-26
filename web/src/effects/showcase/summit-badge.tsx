/** showcase.summit-badge · 登顶徽章 (Sport+SummitBadge.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { Sparkle } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, anim, delayed, fonts, spring, useAutoplay, useClock, useHaptics, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";
import { SportPress } from "./_a-sport";

const B = 118;
const HEX = Array.from({ length: 6 }, (_, i) => {
  const a = ((i * 60 - 90) * Math.PI) / 180;
  return [B / 2 + Math.cos(a) * (B / 2), B / 2 + Math.sin(a) * (B / 2)];
});
const HEX_POINTS = HEX.map(([x, y]) => `${x},${y}`).join(" ");
const HEX_CLIP = `polygon(${HEX.map(([x, y]) => `${x}px ${y}px`).join(", ")})`;

export default function SummitBadge({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const dropMV = useMotionValue(0);
  const spinMV = useMotionValue(0);
  const [drop, setDrop] = useState(0);
  const [spin, setSpin] = useState(0);
  useMotionValueEvent(dropMV, "change", setDrop);
  useMotionValueEvent(spinMV, "change", setSpin);
  const [revealed, setRevealed] = useState(true);
  const [run, setRun] = useState({ id: 0, silent: false });
  const spinTarget = useRef(0);

  useEffect(() => {
    if (run.id === 0) return;
    const height = ctx.n("drop");
    const spins = Math.max(ctx.i("spins"), 0);
    const muted = run.silent;
    let cancelled = false;
    const timers: number[] = [];
    const at = (s: number, fn: () => void) => timers.push(window.setTimeout(() => !cancelled && fn(), s * 1000));
    dropMV.stop();
    dropMV.set(height);
    setRevealed(false);
    at(0.04, () => {
      animate(dropMV, 0, spring(0.55, 0.6));
      spinTarget.current = spinMV.get() + 360 * spins;
      animate(spinMV, spinTarget.current, anim.curve(0.15, 0.85, 0.3, 1, 1.2));
    });
    at(0.46, () => {
      if (!muted) haptics.tap("medium");
      setRevealed(true);
    });
    at(0.76, () => !muted && haptics.success());
    return () => {
      cancelled = true;
      timers.forEach(clearTimeout);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [run]);

  useAutoplay(ctx.isPreview, () => setRun((r) => ({ id: r.id + 1, silent: true })), { every: 4.0, delay: 0.5 });

  const zh = ctx.lang === "zh";
  const textT = (d: number) => delayed(spring(0.45, 0.8), revealed ? d : 0);

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <SportPress scale={0.98} dim={0.04} radius={26} onClick={() => setRun((r) => ({ id: r.id + 1, silent: false }))}>
          <div style={{ ...signatureCard(), padding: "20px 0", width: 280, display: "flex", flexDirection: "column", alignItems: "center", gap: 14, color: "#fff" }}>
            <div style={{ position: "relative", width: 220, height: 170, display: "grid", placeItems: "center" }}>
              {ctx.b("rays") && <Rays visible={revealed} preview={ctx.isPreview} />}
              <Sparkles visible={revealed} preview={ctx.isPreview} />
              <div style={{ position: "absolute", transform: `translateY(${-drop}px)` }}>
                <Spinner angle={spin} />
              </div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
              <motion.span
                initial={false}
                animate={{ y: revealed ? 0 : 12, opacity: revealed ? 1 : 0 }}
                transition={revealed ? textT(0.1) : { duration: 0 }}
                style={{ fontFamily: fonts.rounded, fontSize: 20, fontWeight: 700, color: "#fff", lineHeight: "24px" }}
              >
                {zh ? "登顶成功" : "Summit reached"}
              </motion.span>
              <motion.span
                initial={false}
                animate={{ y: revealed ? 0 : 12, opacity: revealed ? 1 : 0 }}
                transition={revealed ? textT(0.25) : { duration: 0 }}
                style={signatureEyebrow()}
              >
                {zh ? "Zugspitze · 本季第 3 座高峰" : "Zugspitze · 3rd peak this season"}
              </motion.span>
            </div>
            <SignatureRim />
          </div>
        </SportPress>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap to replay the unlock" zh="点击重播解锁" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

/** Un-mirrors the face while its back turns toward the viewer and flashes a glint near front-on. */
function Spinner({ angle }: { angle: number }) {
  const facing = Math.cos((angle * Math.PI) / 180);
  const c = Math.abs(facing);
  const glint = Math.pow(c, 6) * (1 - Math.pow(c, 40));
  const sweep = Math.sin((angle * Math.PI) / 180) * 70;
  const mirror = facing < 0 ? -1 : 1;
  // perspective 0.5 on a 118-wide layer ≈ CSS perspective 236 px.
  return (
    <div style={{ transform: `perspective(236px) rotateY(${angle}deg) scaleX(${mirror})` }}>
      <div style={{ position: "relative", width: B, height: B, filter: "drop-shadow(0 8px 16px rgb(255 138 31 / 0.5))" }}>
        <svg width={B} height={B} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <defs>
            <linearGradient id="summit-fill" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Signature.accentSoft} />
              <stop offset="0.5" stopColor={Signature.accent} />
              <stop offset="1" stopColor={Signature.accentHot} />
            </linearGradient>
            <linearGradient id="summit-gloss" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2={B / 2} y2={B / 2}>
              <stop offset="0" stopColor="#fff" stopOpacity={0.45} />
              <stop offset="1" stopColor="#fff" stopOpacity={0} />
            </linearGradient>
          </defs>
          <polygon points={HEX_POINTS} fill="url(#summit-fill)" />
          <polygon points={HEX_POINTS} fill="none" stroke={Signature.accentSoft} strokeWidth={3} strokeLinejoin="miter" />
          <polygon points={HEX_POINTS} fill="url(#summit-gloss)" />
        </svg>
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2, color: "#fff" }}>
          <svg width={44} height={30} viewBox="0 0 38 24" fill="currentColor">
            <path d="M27 8.5 Q28 7.3 29 8.5 L37.4 20 Q38.5 22 36.4 22 H26.8 L19.2 13.6 Z" />
            <path d="M12 2.5 Q13 1.3 14 2.5 L25 20 Q26 22 23.8 22 H1.2 Q-0.8 22 0.4 20 Z" />
            <path d="M6.8 11 L9.5 12.8 L12.5 10.6 L15.5 12.8 L19 11 M24.6 12.2 L26.4 13.8 L28.4 12.4 L30.4 13.8 L31.8 12.8" fill="none" stroke={Signature.accent} strokeWidth={1.5} strokeLinejoin="round" strokeLinecap="round" />
          </svg>
          <span style={{ ...signatureNumber(14), lineHeight: "17px" }}>3,798 m</span>
        </div>
        <div style={{ position: "absolute", inset: 0, clipPath: HEX_CLIP, mixBlendMode: "plus-lighter", opacity: glint, pointerEvents: "none" }}>
          <div
            style={{
              position: "absolute",
              left: B / 2 - 23,
              top: B / 2 - 85,
              width: 46,
              height: 170,
              transform: `translateX(${sweep}px) rotate(18deg)`,
              background: `linear-gradient(90deg, transparent, ${white(0.9)}, transparent)`,
            }}
          />
        </div>
      </div>
    </div>
  );
}

function Rays({ visible, preview }: { visible: boolean; preview: boolean }) {
  useClock(true, preview ? 30 : undefined);
  const turn = ((Date.now() / 1000) % 30) * 12;
  return (
    <motion.div
      initial={false}
      animate={{ scale: visible ? 1 : 0.6, opacity: visible ? 1 : 0 }}
      transition={visible ? anim.easeOut(0.6) : { duration: 0 }}
      style={{ position: "absolute", left: "50%", top: "50%", width: 0, height: 0, filter: "blur(2px)", pointerEvents: "none" }}
    >
      <div style={{ position: "absolute", transform: `rotate(${turn}deg)` }}>
        {Array.from({ length: 12 }, (_, i) => (
          <div
            key={i}
            style={{
              position: "absolute",
              left: -5,
              top: -82,
              width: 10,
              height: 82,
              borderRadius: 5,
              transformOrigin: "50% 100%",
              transform: `rotate(${i * 30}deg)`,
              background: "linear-gradient(to top, rgb(255 138 31 / 0.55), rgb(255 138 31 / 0))",
            }}
          />
        ))}
      </div>
    </motion.div>
  );
}

const SPOTS = [
  [-84, -50],
  [88, -34],
  [-70, 56],
  [76, 60],
];

function Sparkles({ visible, preview }: { visible: boolean; preview: boolean }) {
  useClock(true, preview ? 30 : undefined);
  const t = Date.now() / 1000;
  return (
    <motion.div
      initial={false}
      animate={{ opacity: visible ? 1 : 0 }}
      transition={visible ? anim.easeOut(0.5) : { duration: 0 }}
      style={{ position: "absolute", left: "50%", top: "50%", width: 0, height: 0, pointerEvents: "none" }}
    >
      {SPOTS.map(([x, y], i) => {
        const glow = 0.5 + 0.5 * Math.sin(t * 3 + i * 1.7);
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x - 7,
              top: y - 7,
              width: 14,
              height: 14,
              color: Signature.accentSoft,
              opacity: 0.3 + 0.7 * glow,
              transform: `scale(${0.5 + 0.6 * glow})`,
            }}
          >
            <Sparkle size={14} fill="currentColor" strokeWidth={1.5} />
          </div>
        );
      })}
    </motion.div>
  );
}
