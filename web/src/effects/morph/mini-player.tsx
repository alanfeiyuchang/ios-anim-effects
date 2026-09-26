/** morph.mini-player · 迷你播放器展开 (Morph+MiniPlayer.swift) */
import { AnimatePresence, animate, motion, useMotionValue } from "motion/react";
import { AudioWaveform, FastForward, Headphones, Music, Pause, Piano, Play, Rewind } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, black, delayed, glass, hex, rubberBand, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { LayoutRoot, diag, predicted, useMV } from "./_shared";
import { SunHorizon } from "./_symbols";

export default function MiniPlayer({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [expanded, setExpanded] = useState(false);
  const [playing, setPlaying] = useState(true);
  const [appeared, setAppeared] = useState(false);
  const step = useRef(0);
  const dragMV = useMotionValue(0);
  const dragY = useMV(dragMV);
  const spr = spring(ctx.n("response"), ctx.n("damping"));
  const zh = ctx.lang === "zh";

  const expand = () => {
    haptics.tap("medium");
    animate(dragMV, 0, spr);
    setExpanded(true);
    requestAnimationFrame(() => setAppeared(true));
  };
  const collapse = () => {
    haptics.tap("soft");
    setExpanded(false);
    setAppeared(false);
    animate(dragMV, 0, spr);
  };
  const togglePlay = () => {
    haptics.tap();
    setPlaying((p) => !p);
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      const s = step.current % 4;
      if (s === 0) expand();
      else if (s === 3) collapse();
      else togglePlay();
      step.current += 1;
    },
    { every: 1.5 },
  );

  const pan = usePan(
    {
      onChange: ({ translation: t }) => dragMV.set(t.y > 0 ? t.y : rubberBand(t.y, 20)),
      onEnd: ({ translation, velocity }) => {
        if (translation.y > 90 || predicted(translation.y, velocity.y) > 220) collapse();
        else animate(dragMV, 0, spr);
      },
    },
    6,
  );

  const title = zh ? "黄金时刻" : "Golden Hour";
  const artist = zh ? "极光巷" : "Aurora Lane";
  const artScale = playing || !ctx.b("breathe") ? 1 : 0.84;
  const small = artScale < 1;
  const playSpring = spring(0.45, 0.62);
  const material = glass("regular");

  return (
    <LayoutRoot>
      <motion.div
        initial={false}
        animate={{ scale: expanded ? 0.94 : 1, filter: `blur(${expanded ? 4 : 0}px)`, opacity: expanded ? 0.55 : 1 }}
        transition={spr}
        style={{ position: "absolute", inset: 0, transformOrigin: "50% 0%", pointerEvents: expanded ? "none" : "auto" }}
      >
        <Library zh={zh} />
      </motion.div>
      {expanded ? (
        <div {...pan} style={{ ...pan.style, position: "absolute", left: 10, right: 10, bottom: 10, transform: `translateY(${dragY}px)` }}>
          <motion.div layoutId="bg" transition={spr} style={{ position: "absolute", inset: 0, borderRadius: 32, ...material, boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 12px 26px ${black(0.2)}` }} />
          <div style={{ position: "absolute", top: 7, left: "50%", marginLeft: -18, width: 36, height: 5, borderRadius: 3, background: Palette.labelAlpha(0.18) }} />
          <div style={{ position: "relative", padding: "18px 22px", display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
            <motion.div
              animate={{ scale: artScale, boxShadow: `0 ${small ? 5 : 14}px ${small ? 10 : 22}px ${hex(Palette.coral, small ? 0.2 : 0.45)}` }}
              initial={false}
              transition={playSpring}
              onClick={collapse}
              style={{ width: 132, height: 132, borderRadius: 18 }}
            >
              <motion.div layoutId="art" transition={spr} style={{ width: "100%", height: "100%", borderRadius: 18, overflow: "hidden" }}>
                <Artwork />
              </motion.div>
            </motion.div>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}>
              <motion.span layoutId="title" transition={spr} style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>
                {title}
              </motion.span>
              <Reveal visible={appeared} delay={0.04}>
                <span style={{ fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel }}>{artist}</span>
              </Reveal>
            </div>
            <Reveal visible={appeared} delay={0.1} style={{ alignSelf: "stretch" }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
                <div style={{ position: "relative", height: 4, borderRadius: 2, background: Palette.labelAlpha(0.12) }}>
                  <div style={{ position: "absolute", left: 0, top: 0, width: 96, height: 4, borderRadius: 2, background: Palette.labelAlpha(0.7) }} />
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 11, lineHeight: "13px", fontWeight: 500, fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>
                  <span>1:24</span>
                  <span>-2:05</span>
                </div>
              </div>
            </Reveal>
            <Reveal visible={appeared} delay={0.16}>
              <div style={{ display: "flex", alignItems: "center", gap: 34 }}>
                <Rewind size={22} fill="currentColor" strokeWidth={1} />
                <button type="button" onPointerDown={(e) => e.stopPropagation()} onClick={togglePlay} style={{ width: 44, height: 40, display: "grid", placeItems: "center" }}>
                  <PlayGlyph playing={playing} size={30} />
                </button>
                <FastForward size={22} fill="currentColor" strokeWidth={1} />
              </div>
            </Reveal>
          </div>
        </div>
      ) : (
        <div onClick={expand} style={{ position: "absolute", left: 12, right: 12, bottom: 12, height: 64, padding: "0 10px", display: "flex", alignItems: "center", gap: 12, cursor: "pointer" }}>
          <motion.div layoutId="bg" transition={spr} style={{ position: "absolute", inset: 0, borderRadius: 20, ...material, boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 16px ${black(0.14)}` }} />
          <motion.div layoutId="art" transition={spr} style={{ position: "relative", width: 44, height: 44, borderRadius: 10, overflow: "hidden", flexShrink: 0, boxShadow: `0 3px 6px ${hex(Palette.coral, 0.3)}` }}>
            <Artwork />
          </motion.div>
          <div style={{ position: "relative", display: "flex", flexDirection: "column", gap: 1, alignItems: "flex-start" }}>
            <motion.span layoutId="title" transition={spr} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>
              {title}
            </motion.span>
            <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{artist}</span>
          </div>
          <div style={{ flex: 1 }} />
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              togglePlay();
            }}
            style={{ position: "relative", width: 36, height: 36, display: "grid", placeItems: "center" }}
          >
            <PlayGlyph playing={playing} size={21} />
          </button>
          <span style={{ position: "relative", width: 30, height: 36, display: "grid", placeItems: "center", color: Palette.secondaryLabel }}>
            <FastForward size={17} fill="currentColor" strokeWidth={1} />
          </span>
        </div>
      )}
      <div style={{ position: "absolute", left: 0, right: 0, pointerEvents: "none", opacity: dragY > 4 ? 0 : 1, ...(expanded ? { top: 12 } : { bottom: 88 }) }}>
        <DemoHint ctx={ctx} en={expanded ? "Drag the player down to close" : "Tap the now-playing bar"} zh={expanded ? "向下拖动播放器即可收起" : "点击正在播放条"} />
      </div>
    </LayoutRoot>
  );
}

function PlayGlyph({ playing, size }: { playing: boolean; size: number }) {
  return (
    <AnimatePresence mode="popLayout" initial={false}>
      <motion.span
        key={playing ? "pause" : "play"}
        initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
        animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
        exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
        transition={anim.snappyD(0.3)}
        style={{ display: "grid" }}
      >
        {playing ? <Pause size={size} fill="currentColor" strokeWidth={0} /> : <Play size={size} fill="currentColor" strokeWidth={0} />}
      </motion.span>
    </AnimatePresence>
  );
}

function Artwork() {
  return (
    <div style={{ width: "100%", height: "100%", background: diag(Palette.amber, Palette.coral, Palette.pink), display: "grid", placeItems: "center", color: white(0.9) }}>
      <SunHorizon style={{ width: "50%", height: "50%" }} />
    </div>
  );
}

function Reveal({ visible, delay, children, style }: { visible: boolean; delay: number; children: React.ReactNode; style?: React.CSSProperties }) {
  return (
    <motion.div
      initial={false}
      animate={{ opacity: visible ? 1 : 0, y: visible ? 0 : 10, filter: `blur(${visible ? 0 : 5}px)` }}
      transition={visible ? delayed(spring(0.45, 0.86), delay) : anim.easeOut(0.1)}
      style={style}
    >
      {children}
    </motion.div>
  );
}

function Library({ zh }: { zh: boolean }) {
  const albums: [typeof Music, string[]][] = [
    [Music, [Palette.violet, Palette.indigo]],
    [AudioWaveform, [Palette.mint, Palette.sky]],
    [Piano, [Palette.pink, Palette.coral]],
    [Headphones, [Palette.sky, Palette.blue]],
  ];
  return (
    <div style={{ position: "absolute", inset: 0, padding: "20px 20px 0", display: "flex", flexDirection: "column", gap: 12 }}>
      <span style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{zh ? "最近播放" : "Recently Played"}</span>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
        {albums.map(([Icon, colors], i) => (
          <div key={i} style={{ height: 84, borderRadius: 16, background: diag(...colors), display: "grid", placeItems: "center", color: white(0.9) }}>
            <Icon size={28} strokeWidth={2.4} />
          </div>
        ))}
      </div>
    </div>
  );
}
