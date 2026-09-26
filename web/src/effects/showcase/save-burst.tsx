/** showcase.save-burst · 收藏迸发 (TravelSaveBurst.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Bookmark } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import {
  DemoHint,
  NumericText,
  SymbolBounce,
  anim,
  ease,
  fonts,
  glass,
  mix,
  progress,
  spring,
  springAt,
  useAutoplay,
  useDoubleTap,
  useElapsed,
  useHaptics,
  useTimeouts,
  type DemoProps,
  type Point,
} from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow } from "./signature";

export default function SaveBurst({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [saved, setSaved] = useState(false);
  const [burstID, setBurstID] = useState(0);
  const [pop, setPop] = useState<{ id: number; at: Point } | null>(null);
  const [toast, setToast] = useState(false);
  const saveCount = 2318 + (saved ? 1 : 0);

  const toggleSave = useCallback(() => {
    const now = !saved;
    setSaved(now);
    if (now) {
      setBurstID((b) => b + 1);
      haptics.success();
      if (ctx.b("toast")) setToast(true);
      clearAll();
      after(1.6, () => setToast(false));
    } else {
      haptics.tap();
    }
  }, [saved, ctx, haptics, after, clearAll]);

  const doubleTap = useCallback(
    (at: Point) => {
      setPop((p) => ({ id: (p?.id ?? 0) + 1, at }));
      if (!saved) toggleSave();
    },
    [saved, toggleSave],
  );
  const onDoubleTap = useDoubleTap(doubleTap);

  useAutoplay(ctx.isPreview, () => (saved ? toggleSave() : doubleTap({ x: 140, y: 130 })), { every: 1.5, delay: 0.4 });

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div
          onPointerUp={onDoubleTap}
          style={{ ...signatureCard(26), width: 280, height: 300, flexShrink: 0, cursor: "pointer" }}
        >
          <div style={{ position: "absolute", inset: 0, borderRadius: 26, overflow: "hidden" }}>
            <LandscapeArt seed={2} />
            <div style={{ position: "absolute", inset: 0, background: `linear-gradient(rgb(0 0 0 / 0.3), transparent, rgb(0 0 0 / 0.75))` }} />
            {pop && <BigBookmark key={pop.id} at={pop.at} />}
            <Info ctx={ctx} saved={saved} count={saveCount} burstID={burstID} onSave={toggleSave} />
            <AnimatePresence>{toast && <Toast zh={ctx.lang === "zh"} />}</AnimatePresence>
          </div>
          <SignatureRim radius={26} />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Double-tap the photo to save it" zh="双击照片即可收藏" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Info({ ctx, saved, count, burstID, onSave }: { ctx: DemoProps["ctx"]; saved: boolean; count: number; burstID: number; onSave: () => void }) {
  const zh = ctx.lang === "zh";
  return (
    <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, padding: 16, display: "flex", alignItems: "flex-end" }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
        <div style={signatureEyebrow()}>{zh ? "意大利 · 多洛米蒂" : "Italy · Dolomites"}</div>
        <div style={{ fontFamily: fonts.rounded, fontSize: 22, fontWeight: 700, color: "#fff", lineHeight: "26px" }}>Lago di Braies</div>
        <div style={{ display: "flex", alignItems: "center", gap: 4, fontFamily: fonts.rounded, fontSize: 11, fontWeight: 600, color: Signature.textSecondary }}>
          <Bookmark size={9} fill="currentColor" strokeWidth={0} />
          <NumericText value={count} text={count.toLocaleString("en-US")} />
          <span>{zh ? "人收藏" : "saves"}</span>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <button
        type="button"
        onPointerUp={(e) => e.stopPropagation()}
        onClick={(e) => {
          e.stopPropagation();
          onSave();
        }}
        style={{ position: "relative", width: 44, height: 44, display: "grid", placeItems: "center" }}
      >
        {burstID > 0 && <SparkRing key={burstID} count={Math.max(ctx.i("particles"), 1)} radius={ctx.n("radius")} />}
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", ...glass("ultraThin", "dark") }} />
        <SymbolBounce trigger={saved}>
          <AnimatePresence mode="popLayout" initial={false}>
            <motion.span
              key={saved ? "on" : "off"}
              initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
              exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              transition={anim.snappyD(0.3)}
              style={{ display: "grid", color: saved ? Signature.accent : "#fff" }}
            >
              <Bookmark size={19} strokeWidth={2.4} fill={saved ? "currentColor" : "none"} />
            </motion.span>
          </AnimatePresence>
        </SymbolBounce>
      </button>
    </div>
  );
}

/** One fixed timeline: pop (0–300 ms), hold 150 ms, float away (450–800 ms). */
function BigBookmark({ at }: { at: Point }) {
  const t = useElapsed(0, 0.8);
  const popped = springAt(t, 0.3, 0.5);
  const away = ease.inOut(progress(t, 0.45, 0.35));
  const scale = t < 0.45 ? mix(0.2, 1, popped) : mix(1, 0.8, away);
  const rotation = mix(-18, 0, popped);
  const lift = -50 * away;
  const opacity = 1 - away;
  return (
    <div
      style={{
        position: "absolute",
        left: at.x - 32,
        top: at.y - 32,
        width: 64,
        height: 64,
        pointerEvents: "none",
        transform: `translateY(${lift}px) rotate(${rotation}deg) scale(${scale})`,
        opacity,
        filter: `drop-shadow(0 0 12px rgb(255 138 31 / 0.6))`,
      }}
    >
      <svg viewBox="0 0 24 24" width={64} height={64}>
        <defs>
          <linearGradient id="save-burst-grad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={Signature.accentSoft} />
            <stop offset="0.5" stopColor={Signature.accent} />
            <stop offset="1" stopColor={Signature.accentHot} />
          </linearGradient>
        </defs>
        <path d="M6.5 2h11A1.5 1.5 0 0 1 19 3.5V22l-7-4.6L5 22V3.5A1.5 1.5 0 0 1 6.5 2Z" fill="url(#save-burst-grad)" />
      </svg>
    </div>
  );
}

function SparkRing({ count, radius }: { count: number; radius: number }) {
  const [fired, setFired] = useState(false);
  useEffect(() => {
    const id = requestAnimationFrame(() => setFired(true));
    return () => cancelAnimationFrame(id);
  }, []);
  const t = anim.easeOut(0.6);
  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      <motion.div
        initial={{ scale: 0.8, opacity: 1 }}
        animate={fired ? { scale: 1.9, opacity: 0 } : undefined}
        transition={t}
        style={{ position: "absolute", inset: 0, borderRadius: "50%", border: `1.5px solid rgb(255 138 31 / 0.7)` }}
      />
      {Array.from({ length: count }, (_, index) => {
        const angle = (index / count) * 2 * Math.PI;
        const even = index % 2 === 0;
        const size = even ? 6 : 4;
        return (
          <motion.div
            key={index}
            initial={{ x: 0, y: 0, scale: 1, opacity: 1 }}
            animate={fired ? { x: Math.cos(angle) * radius, y: Math.sin(angle) * radius, scale: 0.2, opacity: 0 } : undefined}
            transition={t}
            style={{
              position: "absolute",
              left: 22 - size / 2,
              top: 22 - size / 2,
              width: size,
              height: size,
              borderRadius: "50%",
              background: even ? Signature.accent : Signature.lime,
            }}
          />
        );
      })}
    </div>
  );
}

function Toast({ zh }: { zh: boolean }) {
  return (
    <motion.div
      initial={{ y: -70, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      exit={{ y: -70, opacity: 0, transition: anim.easeInOut(0.3) }}
      transition={spring(0.45, 0.8)}
      style={{ position: "absolute", left: 12, right: 12, top: 12 }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 10,
          padding: 8,
          paddingRight: 14,
          borderRadius: 16,
          background: "rgb(34 34 38 / 0.95)",
          boxShadow: `inset 0 0 0 1px ${Signature.hairline}`,
        }}
      >
        <div style={{ position: "relative", width: 28, height: 28, borderRadius: 8, overflow: "hidden", flexShrink: 0 }}>
          <LandscapeArt seed={2} />
        </div>
        <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, color: "#fff" }}>{zh ? "已收藏到「2026 夏日」" : "Saved to Summer ’26"}</span>
        <span style={{ flex: 1 }} />
        <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 700, color: Signature.accent }}>{zh ? "查看" : "View"}</span>
      </div>
    </motion.div>
  );
}
