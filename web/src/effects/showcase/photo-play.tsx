/** showcase.photo-play · 照片卡片播放 (Sport+PhotoPlay.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Pause, Play } from "lucide-react";
import { useState } from "react";
import { DemoHint, anim, fonts, glass, spring, useAutoplay, useClock, useHaptics, white, type DemoProps } from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard } from "./signature";
import { SportPress } from "./_a-sport";

export default function PhotoPlay({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [playing, setPlaying] = useState(false);
  // The TimelineView is paused while not playing: the clock accumulates playing time only.
  const seconds = useClock(playing, ctx.isPreview ? 30 : undefined);

  const toggle = () => {
    setPlaying((p) => !p);
    haptics.tap("medium");
  };
  useAutoplay(ctx.isPreview, toggle, { every: 3.2, delay: 0.8 });

  const clip = Math.max(ctx.n("clip"), 1);
  const progress = (seconds % clip) / clip;
  const kenBurns = (1 - Math.cos((seconds / clip) * Math.PI)) / 2;
  const zoom = ctx.n("zoom");
  const t = spring(0.4, 0.7);
  const secs = Math.floor(seconds % clip);

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <SportPress scale={ctx.n("press")} dim={0.12} radius={30} onClick={toggle}>
          <div style={{ ...signatureCard(30), padding: 10, width: 272, display: "flex", flexDirection: "column", gap: 12, color: "#fff" }}>
            <div style={{ position: "relative", height: 180, borderRadius: 22, overflow: "hidden" }}>
              <motion.div
                animate={{ filter: `saturate(${playing ? 1.05 : 0.85})` }}
                transition={t}
                style={{
                  position: "absolute",
                  inset: 0,
                  transformOrigin: "35% 45%",
                  transform: `translateX(${-10 * kenBurns}px) scale(${1 + (zoom - 1) * kenBurns})`,
                }}
              >
                <LandscapeArt seed={0} />
              </motion.div>
              <div
                style={{
                  position: "absolute",
                  left: 10,
                  top: 10,
                  display: "flex",
                  alignItems: "center",
                  gap: 5,
                  padding: "5px 8px",
                  borderRadius: 999,
                  ...glass("ultraThin", "dark"),
                }}
              >
                <motion.span animate={{ background: playing ? Signature.accent : white(0.6) }} transition={t} style={{ width: 6, height: 6, borderRadius: "50%" }} />
                <span style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 700, fontVariantNumeric: "tabular-nums", color: "#fff", lineHeight: "12px" }}>
                  0:{String(secs).padStart(2, "0")} / 0:{String(Math.trunc(clip)).padStart(2, "0")}
                </span>
              </div>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "0 8px 6px" }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 3, flex: 1 }}>
                <span style={{ fontFamily: fonts.rounded, fontSize: 17, fontWeight: 600, color: "#fff", lineHeight: "20px" }}>Nordkette Ridge</span>
                <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 500, color: Signature.textSecondary, lineHeight: "13px" }}>Innsbruck · 2,256 m</span>
              </div>
              <PlayButton progress={progress} playing={playing} />
            </div>
            <SignatureRim radius={30} />
          </div>
        </SportPress>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap the card to play / pause" zh="点击卡片播放或暂停" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function PlayButton({ progress, playing }: { progress: number; playing: boolean }) {
  const t = spring(0.4, 0.7);
  const r = 23;
  const c = 2 * Math.PI * r;
  return (
    <motion.div animate={{ scale: playing ? 1.08 : 1 }} transition={t} style={{ position: "relative", width: 46, height: 46, flexShrink: 0 }}>
      <motion.div animate={{ background: playing ? white(0.1) : white(1) }} transition={t} style={{ position: "absolute", inset: 0, borderRadius: "50%" }} />
      <motion.svg width={46} height={46} animate={{ opacity: playing ? 1 : 0 }} transition={t} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        <circle cx={23} cy={23} r={r} fill="none" stroke={white(0.14)} strokeWidth={3} />
      </motion.svg>
      <motion.svg
        width={46}
        height={46}
        animate={{ opacity: playing ? 1 : 0 }}
        transition={t}
        style={{ position: "absolute", inset: 0, overflow: "visible", transform: "rotate(-90deg)", filter: "drop-shadow(0 0 4px rgb(255 138 31 / 0.7))" }}
      >
        {progress > 0 && (
          <circle cx={23} cy={23} r={r} fill="none" stroke={Signature.accent} strokeWidth={3} strokeLinecap="round" strokeDasharray={`${progress * c} ${c}`} />
        )}
      </motion.svg>
      <motion.div animate={{ x: playing ? 0 : 1.5 }} transition={t} style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.span
            key={playing ? "pause" : "play"}
            initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
            animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
            exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
            transition={anim.snappyD(0.3)}
            style={{ display: "grid", color: playing ? "#fff" : "#000" }}
          >
            {playing ? <Pause size={17} fill="currentColor" strokeWidth={0} /> : <Play size={16} fill="currentColor" strokeWidth={0} />}
          </motion.span>
        </AnimatePresence>
      </motion.div>
    </motion.div>
  );
}
