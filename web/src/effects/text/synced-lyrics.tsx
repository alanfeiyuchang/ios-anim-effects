/** text.synced-lyrics · 同步歌词 (Text+Lyrics.swift) */
import { Music } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, fonts, springAt, useClock, useHaptics, white, type DemoProps } from "../../kit";
import { fittedSize } from "./_text-kit";

const LINES = {
  zh: ["夜色把城市轻轻点亮", "我们沿着海岸线奔跑", "风把心事吹成浪花", "每一秒都值得收藏", "直到天边泛起微光"],
  en: ["City lights begin to glow", "We ran along the coastline", "Wind turns secrets into waves", "Every second worth keeping", "Until the dawn breaks through"],
};
const LINE_HEIGHT = 64;
const secs = () => performance.now() / 1000;

function easeOutBack(x: number) {
  const c1 = 1.2;
  const c3 = c1 + 1;
  const t = x - 1;
  return 1 + c3 * t * t * t + c1 * t * t;
}

/** Column position in lines (the focus slot shows line `scroll + 1`), gliding into each new line. */
function columnScroll(elapsed: number, lineDuration: number) {
  const beat = Math.max(elapsed, 0) / lineDuration;
  const active = Math.floor(beat);
  const glide = Math.min(((beat - active) * lineDuration) / 0.45, 1);
  return active - 1 + easeOutBack(glide);
}

export default function SyncedLyrics({ ctx }: DemoProps) {
  const haptics = useHaptics();
  useClock(true, ctx.isPreview ? 30 : undefined);
  const lineDuration = Math.max(ctx.n("duration"), 0.5);
  const [start, setStart] = useState(() => secs());
  const seek = useRef({ gap: 0, at: -Infinity });

  // A new line duration keeps the song where it is.
  const lastDuration = useRef(lineDuration);
  useEffect(() => {
    const now = secs();
    const beat = (now - start) / lastDuration.current;
    lastDuration.current = lineDuration;
    setStart(now - beat * lineDuration);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lineDuration]);

  const gap = (at: number) => {
    const t = at - seek.current.at;
    if (seek.current.gap === 0 || t >= 2) return 0;
    return seek.current.gap * (1 - springAt(Math.max(t, 0), 0.7, 0.88));
  };

  const seekTo = (line: number) => {
    if (ctx.isPreview) return;
    haptics.selection();
    const now = secs();
    const shown = columnScroll(now - start, lineDuration) + gap(now);
    const newStart = now - line * lineDuration;
    seek.current = { gap: shown - columnScroll(now - newStart, lineDuration), at: now };
    setStart(newStart);
  };

  const now = secs();
  const elapsed = now - start;
  const beat = Math.max(elapsed, 0) / lineDuration;
  const active = Math.floor(beat);
  const local = beat - active;
  const scroll = columnScroll(elapsed, lineDuration) + gap(now);
  const fill = Math.min(Math.max((local * lineDuration - 0.35) / Math.max(lineDuration - 0.7, 0.1), 0), 1);
  const first = Math.max(Math.min(active, Math.floor(scroll)) - 2, 0);
  const last = Math.max(active, Math.ceil(scroll)) + 3;
  const lines = LINES[ctx.lang];
  const blur = ctx.n("blur");
  const glow = ctx.b("glow");

  const fade = "linear-gradient(transparent 0%, #000 20%, #000 80%, transparent 100%)";
  const rows = [];
  for (let i = first; i <= last; i++) {
    const distance = i - scroll;
    const far = Math.min(Math.abs(distance), 3);
    const isActive = i === active;
    rows.push(
      <div
        key={i}
        onClick={() => seekTo(i)}
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 0,
          transform: `translateY(${distance * LINE_HEIGHT + LINE_HEIGHT * 0.9}px)`,
          cursor: "pointer",
        }}
      >
        <div
          style={{
            transform: `scale(${1 - 0.08 * Math.min(far, 1)})`,
            transformOrigin: "left center",
            opacity: isActive ? 1 : Math.max(0.75 - far * 0.2, 0.1),
            filter: isActive || far * blur === 0 ? undefined : `blur(${far * blur}px)`,
          }}
        >
          <LyricLine text={lines[((i % lines.length) + lines.length) % lines.length]} fill={isActive ? fill : i < active ? 1 : 0} glow={glow && isActive} />
        </div>
      </div>,
    );
  }

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div
        style={{
          width: 310,
          padding: 20,
          borderRadius: 28,
          background: "linear-gradient(to bottom right, #3B2A8C, #6B2F8F, #1E1B4B)",
          boxShadow: `0 12px 20px rgb(59 42 140 / 0.35)`,
          display: "flex",
          flexDirection: "column",
          gap: 14,
        }}
      >
        <Header zh={ctx.lang === "zh"} fps={ctx.isPreview ? 30 : undefined} />
        <div style={{ position: "relative", height: 196, overflow: "hidden", WebkitMaskImage: fade, maskImage: fade }}>{rows}</div>
      </div>
      <DemoHint ctx={ctx} en="Tap a line to jump to it" zh="点击歌词跳转到该行" />
    </div>
  );
}

const lyricFont = (size: number) => `800 ${size}px ${fonts.rounded}`;

function LyricLine({ text, fill, glow }: { text: string; fill: number; glow: boolean }) {
  const soft = 0.12;
  const edge = fill * (1 + soft) - soft;
  const size = fittedSize(text, 24, 270, lyricFont);
  const mask = `linear-gradient(to right, #000 ${Math.max(edge, 0) * 100}%, transparent ${Math.min(Math.max(edge + soft, 0.0001), 1) * 100}%)`;
  const font = { fontFamily: fonts.rounded, fontSize: size, fontWeight: 800, lineHeight: `${Math.round(size * 1.2)}px`, whiteSpace: "pre" } as const;
  return (
    <div style={{ position: "relative", display: "inline-block" }}>
      <span style={{ ...font, color: white(0.35) }}>{text}</span>
      <span
        style={{
          ...font,
          position: "absolute",
          left: 0,
          top: 0,
          color: "#fff",
          textShadow: glow ? `0 0 8px ${white(0.55)}` : undefined,
          WebkitMaskImage: mask,
          maskImage: mask,
        }}
      >
        {text}
      </span>
    </div>
  );
}

function Header({ zh, fps }: { zh: boolean; fps?: number }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
      <div style={{ width: 36, height: 36, borderRadius: 8, background: Palette.sunset, display: "grid", placeItems: "center", color: "#fff" }}>
        <Music size={15} strokeWidth={3} />
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 1, color: "#fff" }}>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 700 }}>{zh ? "海岸线" : "Coastline"}</span>
        <span style={{ fontSize: 12, lineHeight: "16px", opacity: 0.6 }}>{zh ? "霓虹海港" : "Neon Harbor"}</span>
      </div>
      <span style={{ flex: 1 }} />
      <Waveform fps={fps} />
    </div>
  );
}

/** SF Symbol `waveform` with `.variableColor.iterative` repeating: bars light up one after another. */
function Waveform({ fps }: { fps?: number }) {
  const t = useClock(true, fps);
  const bars = [5, 10, 16, 11, 7, 13, 6];
  const cycle = 1.2;
  const lit = Math.floor(((t % cycle) / cycle) * (bars.length + 2));
  return (
    <svg width={20} height={18} viewBox="0 0 20 18">
      {bars.map((h, i) => (
        <rect
          key={i}
          x={1 + i * 2.7}
          y={9 - h / 2}
          width={1.8}
          height={h}
          rx={0.9}
          fill="#fff"
          opacity={i === lit || i === lit - 1 ? 0.7 : 0.7 * 0.35}
        />
      ))}
    </svg>
  );
}
