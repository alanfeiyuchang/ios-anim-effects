/** text.news-ticker · 新闻快讯轮播 (Text+NewsTicker.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, demoCard, useClock, useHaptics, type DemoContext, type DemoProps } from "../../kit";

const HEADLINES = [
  { category: ["Markets", "财经"], title: ["Chip makers lead a late-session rally", "芯片股尾盘领涨，大盘翻红"], time: ["2 min ago", "2 分钟前"] },
  { category: ["Weather", "天气"], title: ["First snow expected in the hills tonight", "今夜山区将迎来初雪"], time: ["6 min ago", "6 分钟前"] },
  { category: ["Sport", "体育"], title: ["Underdogs force a decisive game seven", "黑马逆袭，系列赛进入抢七"], time: ["11 min ago", "11 分钟前"] },
  { category: ["Science", "科学"], title: ["Probe sends back its closest photos yet", "探测器传回迄今最近距离照片"], time: ["18 min ago", "18 分钟前"] },
];
type Headline = (typeof HEADLINES)[number];
const WIDTH = 264;
const secs = () => performance.now() / 1000;

/** Ease-in-out cubic on 0…1. */
function eased(raw: number) {
  const x = Math.min(Math.max(raw, 0), 1);
  return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
}

export default function NewsTicker({ ctx }: DemoProps) {
  const haptics = useHaptics();
  useClock(true, ctx.isPreview ? 30 : undefined);
  const [start, setStart] = useState(() => secs());
  const [skipped, setSkipped] = useState(0);
  const interval = Math.max(ctx.n("interval"), 0.5);

  // A new interval keeps the current headline and the hairline's fraction.
  const lastInterval = useRef(interval);
  useEffect(() => {
    const now = secs();
    const beat = (now - start) / lastInterval.current;
    lastInterval.current = interval;
    setStart(now - beat * interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [interval]);

  const elapsed = secs() - start;
  const ticks = Math.floor(elapsed / interval);
  const inTick = elapsed - ticks * interval;
  const fraction = inTick / interval;
  const step = ticks + skipped;
  const wipe = step === 0 ? 1 : eased(inTick / Math.max(ctx.n("wipe"), 0.05));
  const index = step % HEADLINES.length;

  const skip = () => {
    haptics.selection();
    const now = secs();
    setSkipped((s) => s + Math.floor((now - start) / interval) + 1);
    setStart(now);
  };

  const item = HEADLINES[index];
  const old = HEADLINES[(index + HEADLINES.length - 1) % HEADLINES.length];
  return (
    <div onClick={skip} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16, cursor: "pointer" }}>
      <div style={{ ...demoCard(), width: 300, padding: 18, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ position: "relative" }}>
          <AnimatePresence initial={false} mode="popLayout">
            <motion.div key={index} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={anim.easeInOut(0.3)}>
              <Header item={item} ctx={ctx} />
            </motion.div>
          </AnimatePresence>
        </div>
        <Slot ctx={ctx} item={item} old={old} wipe={wipe} />
        <div style={{ position: "relative", width: WIDTH, height: 2, borderRadius: 1, background: Palette.labelAlpha(0.08) }}>
          <div style={{ position: "absolute", left: 0, top: 0, height: 2, width: WIDTH * fraction, borderRadius: 1, background: alpha(Palette.red, 0.8) }} />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to skip" zh="点击跳过" />
    </div>
  );
}

function Slot({ ctx, item, old, wipe }: { ctx: DemoContext; item: Headline; old: Headline; wipe: number }) {
  const push = ctx.n("push");
  const shown = WIDTH * wipe;
  const hidden = WIDTH - shown;
  const title = (h: Headline) => (
    <div
      style={{
        width: WIDTH,
        height: 58,
        fontSize: 21,
        lineHeight: "26px",
        fontWeight: 700,
        color: Palette.label,
        display: "-webkit-box",
        WebkitBoxOrient: "vertical",
        WebkitLineClamp: 2,
        overflow: "hidden",
      }}
    >
      {ctx.lang === "zh" ? h.title[1] : h.title[0]}
    </div>
  );
  return (
    <div style={{ position: "relative", width: WIDTH, height: 58, overflow: "hidden" }}>
      <div style={{ position: "absolute", inset: 0, clipPath: `inset(0 0 0 ${shown}px)` }}>
        <div style={{ transform: `translateX(${-push * wipe}px)` }}>{title(old)}</div>
      </div>
      <div style={{ position: "absolute", inset: 0, clipPath: `inset(0 ${hidden}px 0 0)` }}>
        <div style={{ transform: `translateX(${push * (1 - wipe)}px)` }}>{title(item)}</div>
      </div>
      <div
        style={{
          position: "absolute",
          left: shown - 1,
          top: 2,
          width: 2,
          height: 54,
          borderRadius: 1,
          background: Palette.red,
          boxShadow: `0 0 4px ${alpha(Palette.red, 0.5)}`,
          opacity: wipe > 0.001 && wipe < 0.999 ? 1 : 0,
        }}
      />
    </div>
  );
}

function Header({ item, ctx }: { item: Headline; ctx: DemoContext }) {
  const zh = ctx.lang === "zh";
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 4, height: 20, padding: "0 7px", borderRadius: 10, background: Palette.red, color: "#fff" }}>
        <motion.span
          animate={{ opacity: [1, 0.35, 1] }}
          transition={{ duration: 1.1, repeat: Infinity, ease: "easeInOut" }}
          style={{ width: 6, height: 6, borderRadius: "50%", background: "#fff" }}
        />
        <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 800 }}>LIVE</span>
      </div>
      <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 700, color: Palette.red }}>{zh ? item.category[1] : item.category[0]}</span>
      <span style={{ flex: 1 }} />
      <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{zh ? item.time[1] : item.time[0]}</span>
    </div>
  );
}
