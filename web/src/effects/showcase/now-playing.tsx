/** showcase.now-playing · 旅途音乐播放器 (TravelNowPlaying.swift) */
import { AnimatePresence, motion } from "motion/react";
import { FastForward, Pause, Play, Rewind } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, anim, clamp, fonts, spring, useAutoplay, useClock, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow } from "./signature";
import { SportPress, sportHash } from "./_a-sport";

const TRACKS = [
  { en: "Coastal Drive", zh: "海岸公路", artist: "Lumen & The Tides", seed: 1, length: 214 },
  { en: "Alpine Morning", zh: "高山清晨", artist: "North Pass", seed: 0, length: 188 },
  { en: "Desert Radio", zh: "沙漠电台", artist: "Wadi Sound", seed: 3, length: 241 },
];
const WAVE_W = 252;
const WAVE_H = 46;
const fmt = (s: number) => {
  const t = Math.max(0, Math.floor(s));
  return `${Math.floor(t / 60)}:${String(t % 60).padStart(2, "0")}`;
};

export default function NowPlaying({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  const [playing, setPlaying] = useState(false);
  const [scrubbing, setScrubbing] = useState(false);
  const [trackIndex, setTrackIndex] = useState(0);
  const [dir, setDir] = useState(1);
  const elapsed = useRef(38);
  const playStart = useRef(performance.now());
  const st = useRef({ playing: false, scrubbing: false, track: 0 });
  st.current = { playing, scrubbing, track: trackIndex };
  const [, rerender] = useState(0);
  useClock(playing, ctx.isPreview ? 30 : undefined);

  const track = TRACKS[trackIndex];
  const length = track.length;
  const position = () => {
    const s = st.current;
    const raw = s.playing && !s.scrubbing ? elapsed.current + Math.max(0, (performance.now() - playStart.current) / 1000) : elapsed.current;
    return raw % TRACKS[s.track].length;
  };

  const toggle = () => {
    if (st.current.playing) elapsed.current = position();
    else playStart.current = performance.now();
    setPlaying((p) => !p);
    haptics.tap("medium");
  };
  useAutoplay(ctx.isPreview, toggle, { every: 3.4, delay: 0.6 });

  const scrub = (fraction: number) => {
    if (!st.current.scrubbing) {
      haptics.tap("light");
      st.current.scrubbing = true;
      setScrubbing(true);
    }
    elapsed.current = clamp(fraction, 0, 0.999) * TRACKS[st.current.track].length;
    rerender((n) => n + 1);
  };
  const endScrub = () => {
    if (!st.current.scrubbing) return;
    playStart.current = performance.now();
    st.current.scrubbing = false;
    setScrubbing(false);
  };
  const pan = usePan({ onChange: ({ location }) => scrub(location.x / WAVE_W), onEnd: endScrub });

  /** Back rewinds first if the song is more than 3 s in; otherwise both buttons change track. */
  const skip = (delta: number) => {
    haptics.tap("light");
    if (delta < 0 && position() > 3) {
      elapsed.current = 0;
      playStart.current = performance.now();
      rerender((n) => n + 1);
      return;
    }
    setDir(delta < 0 ? -1 : 1);
    const next = (st.current.track + delta + TRACKS.length) % TRACKS.length;
    st.current.track = next;
    setTrackIndex(next);
    elapsed.current = 0;
    playStart.current = performance.now();
  };

  const seconds = position();
  const progress = seconds / length;
  const time = performance.now() / 1000;
  const bars = Math.max(ctx.i("bars"), 8);
  const gap = 3;
  const barW = (WAVE_W - gap * (bars - 1)) / bars;
  const t45 = spring(0.45, 0.72);
  const glowOpacity = ctx.b("glow") && playing ? 0.32 + 0.1 * Math.sin(time * 2.2) : 0;

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ position: "relative", flexShrink: 0 }}>
          <div
            style={{
              position: "absolute",
              inset: 0,
              borderRadius: 26,
              background: `linear-gradient(135deg, #E0785A, ${Signature.accent})`,
              filter: "blur(34px)",
              transform: "scale(0.9)",
              opacity: glowOpacity,
              transition: playing ? "none" : "opacity 0.45s",
            }}
          />
          <div style={{ ...signatureCard(), width: 288, padding: 18, display: "flex", flexDirection: "column", gap: 14 }}>
            {/* header */}
            <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
              <motion.div
                initial={false}
                animate={{
                  scale: playing ? 1 : ctx.n("artScale"),
                  boxShadow: playing ? "0 8px 14px rgb(224 120 90 / 0.5)" : "0 3px 5px rgb(224 120 90 / 0.1)",
                }}
                transition={t45}
                style={{ position: "relative", width: 78, height: 78, borderRadius: 16, flexShrink: 0 }}
              >
                <div style={{ position: "absolute", inset: 0, borderRadius: 16, overflow: "hidden" }}>
                  <AnimatePresence initial={false}>
                    <motion.div key={track.seed} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={spring(0.4, 0.8)} style={{ position: "absolute", inset: 0 }}>
                      <LandscapeArt seed={track.seed} />
                    </motion.div>
                  </AnimatePresence>
                </div>
                <div style={{ position: "absolute", inset: 0, borderRadius: 16, boxShadow: `inset 0 0 0 1px ${white(0.12)}` }} />
              </motion.div>
              <div style={{ display: "flex", flexDirection: "column", gap: 3, flex: 1, minWidth: 0 }}>
                <span style={signatureEyebrow()}>{zh ? "自驾 · 蔚蓝海岸" : "Road trip · Riviera"}</span>
                <div style={{ position: "relative", height: 40, overflow: "hidden" }}>
                  <AnimatePresence initial={false} custom={dir}>
                    <motion.div
                      key={track.seed}
                      custom={dir}
                      variants={{
                        enter: (d: number) => ({ x: `${100 * d}%`, opacity: 0 }),
                        center: { x: "0%", opacity: 1 },
                        exit: (d: number) => ({ x: `${-100 * d}%`, opacity: 0 }),
                      }}
                      initial="enter"
                      animate="center"
                      exit="exit"
                      transition={spring(0.4, 0.8)}
                      style={{ position: "absolute", left: 0, top: 0, right: 0, display: "flex", flexDirection: "column", gap: 3 }}
                    >
                      <span style={{ fontFamily: fonts.rounded, fontSize: 18, fontWeight: 700, color: "#fff", lineHeight: "22px", whiteSpace: "nowrap" }}>{zh ? track.zh : track.en}</span>
                      <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 500, color: Signature.textSecondary, lineHeight: "15px", whiteSpace: "nowrap" }}>{track.artist}</span>
                    </motion.div>
                  </AnimatePresence>
                </div>
              </div>
            </div>
            {/* waveform */}
            <div {...pan} style={{ position: "relative", width: WAVE_W, height: WAVE_H, display: "flex", alignItems: "center", gap, touchAction: "none", cursor: "ew-resize" }}>
              {Array.from({ length: bars }, (_, index) => {
                const played = index / bars < progress;
                const envelope = 0.35 + 0.65 * sportHash(index * 3.3 + 1);
                const live = playing ? 0.5 + 0.3 * Math.abs(Math.sin(time * 5.2 + index * 0.9)) + 0.2 * Math.abs(Math.sin(time * 2.3 + index * 0.37)) : 0.38;
                let lens = 1;
                if (scrubbing) {
                  const d = Math.abs((index + 0.5) / bars - progress) * bars;
                  if (d < 4) lens = 1 + 0.35 * (0.5 + 0.5 * Math.cos((d / 4) * Math.PI));
                }
                const h = Math.max(4, WAVE_H * envelope * live) * lens;
                return (
                  <div
                    key={index}
                    style={{ width: barW, height: h, borderRadius: barW / 2, flexShrink: 0, background: played ? Signature.accentGradient : white(0.18), transition: playing ? undefined : "height 0.45s" }}
                  />
                );
              })}
              <div style={{ position: "absolute", left: WAVE_W * progress - 1, top: -4, width: 2, height: WAVE_H + 8, borderRadius: 1, background: "#fff", boxShadow: "0 0 3px rgb(255 255 255 / 0.6)", pointerEvents: "none" }} />
            </div>
            <div style={{ display: "flex", marginTop: -6, fontFamily: fonts.rounded, fontSize: 11, fontWeight: 600, fontVariantNumeric: "tabular-nums", color: Signature.textSecondary, lineHeight: "13px" }}>
              <span>{fmt(seconds)}</span>
              <span style={{ flex: 1 }} />
              <span>-{fmt(length - seconds)}</span>
            </div>
            {/* controls */}
            <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 24, color: white(0.85) }}>
              <SportPress scale={0.85} dim={0.1} onClick={() => skip(-1)}>
                <span style={{ width: 40, height: 40, display: "grid", placeItems: "center" }}>
                  <Rewind size={21} fill="currentColor" strokeWidth={0} />
                </span>
              </SportPress>
              <SportPress scale={0.9} dim={0.05} onClick={toggle}>
                <motion.span
                  initial={false}
                  animate={{ borderRadius: playing ? 18 : 29, boxShadow: `0 4px ${playing ? 14 : 8}px rgb(255 138 31 / 0.55)` }}
                  transition={t45}
                  style={{ width: 58, height: 58, display: "grid", placeItems: "center", background: Signature.accentGradient, color: Signature.ink }}
                >
                  <motion.span initial={false} animate={{ x: playing ? 0 : 2 }} transition={t45} style={{ display: "grid" }}>
                    <AnimatePresence mode="popLayout" initial={false}>
                      <motion.span
                        key={playing ? "pause" : "play"}
                        initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                        animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                        exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                        transition={anim.snappyD(0.3)}
                        style={{ display: "grid" }}
                      >
                        {playing ? <Pause size={23} fill="currentColor" strokeWidth={0} /> : <Play size={23} fill="currentColor" strokeWidth={0} />}
                      </motion.span>
                    </AnimatePresence>
                  </motion.span>
                </motion.span>
              </SportPress>
              <SportPress scale={0.85} dim={0.1} onClick={() => skip(1)}>
                <span style={{ width: 40, height: 40, display: "grid", placeItems: "center" }}>
                  <FastForward size={21} fill="currentColor" strokeWidth={0} />
                </span>
              </SportPress>
            </div>
            <SignatureRim />
          </div>
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Play, skip, or drag the waveform" zh="播放、切歌，或拖动波形" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}
