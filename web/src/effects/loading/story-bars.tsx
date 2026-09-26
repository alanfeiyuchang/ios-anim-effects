/** loading.story-bars · 快拍进度条 (Loading+Stories.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Ellipsis, Flame, Haze, Heart, Leaf, MoonStar, Waves, type LucideIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, glass, localPoint, useClock, useHaptics, type DemoProps } from "../../kit";
import { Mountains2, previewFps } from "./shared";

interface Page {
  icon: LucideIcon | "mountains";
  colors: string[];
  en: string;
  zh: string;
}

const PAGES: Page[] = [
  { icon: Haze, colors: [Palette.amber, Palette.coral, Palette.pink], en: "Golden hour", zh: "黄金时刻" },
  { icon: "mountains", colors: [Palette.sky, Palette.blue, Palette.indigo], en: "Above the clouds", zh: "云端之上" },
  { icon: Leaf, colors: [Palette.mint, Palette.green, Palette.sky], en: "Forest trail", zh: "林间小径" },
  { icon: MoonStar, colors: [Palette.violet, Palette.indigo, "#241B5C"], en: "Night sky", zh: "星夜" },
  { icon: Waves, colors: [Palette.sky, Palette.mint, Palette.blue], en: "Tide pools", zh: "潮汐" },
  { icon: Flame, colors: [Palette.coral, Palette.red, Palette.amber], en: "Campfire", zh: "篝火" },
];

const W = 214;
const H = 300;
const smooth = anim.smoothD(0.45);

export default function StoryBars({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [step, setStep] = useState(0);
  const [restarts, setRestarts] = useState(0);
  const pageStart = useRef(performance.now());
  const count = Math.min(Math.max(ctx.i("count"), 1), PAGES.length);
  const duration = Math.max(ctx.n("duration"), 0.5);
  const index = step % count;
  const page = PAGES[index];
  const now = useClock(true, previewFps(ctx.isPreview));
  void now;
  const progress = Math.min(Math.max((performance.now() - pageStart.current) / 1000 / duration, 0), 1);

  const advance = (manual: boolean) => {
    if (manual) haptics.selection();
    pageStart.current = performance.now();
    setRestarts((r) => r + 1);
    setStep((s) => s + 1);
  };
  const back = () => {
    haptics.selection();
    pageStart.current = performance.now();
    setRestarts((r) => r + 1);
    setStep((s) => Math.max(s - 1, 0));
  };

  useEffect(() => {
    const remaining = duration - (performance.now() - pageStart.current) / 1000;
    const id = window.setTimeout(() => advance(false), Math.max(remaining, 0.05) * 1000);
    return () => clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [step, restarts, duration, count]);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div
        onClick={(e) => (localPoint(e, e.currentTarget).x < W / 3 ? back() : advance(true))}
        style={{
          position: "relative",
          width: W,
          height: H,
          borderRadius: 26,
          overflow: "hidden",
          cursor: "pointer",
          boxShadow: `0 12px 22px ${alpha(page.colors[0], 0.35)}`,
          transition: "box-shadow 0.45s",
        }}
      >
        <AnimatePresence initial={false}>
          <motion.div
            key={step}
            initial={{ opacity: 0, scale: 1.04 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={smooth}
            style={{ position: "absolute", inset: 0 }}
          >
            <Artwork page={page} scale={ctx.b("kenBurns") ? 1 + 0.08 * progress : 1} />
          </motion.div>
        </AnimatePresence>
        <Chrome page={page} index={index} count={count} progress={progress} zh={ctx.lang === "zh"} />
      </div>
      <DemoHint ctx={ctx} en="Tap right to skip, left to go back" zh="点右侧跳过，点左侧返回" />
    </div>
  );
}

function Artwork({ page, scale }: { page: Page; scale: number }) {
  const Icon = page.icon;
  return (
    <div style={{ position: "absolute", inset: 0, transform: `scale(${scale})` }}>
      <div style={{ position: "absolute", inset: 0, background: `linear-gradient(135deg, ${page.colors.join(", ")})` }} />
      <div style={{ position: "absolute", inset: 0, background: `radial-gradient(180px circle at 25% 20%, rgb(255 255 255 / 0.35), transparent)` }} />
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: "rgb(255 255 255 / 0.9)", transform: "translateY(-6px)", filter: "drop-shadow(0 6px 10px rgb(0 0 0 / 0.15))" }}>
        {Icon === "mountains" ? <Mountains2 size={100} /> : <Icon size={100} fill={Icon === Waves || Icon === Haze ? "none" : "currentColor"} strokeWidth={2.2} />}
      </div>
    </div>
  );
}

function Chrome({ page, index, count, progress, zh }: { page: Page; index: number; count: number; progress: number; zh: boolean }) {
  return (
    <div className="ml-dark" style={{ position: "absolute", inset: 0, padding: 12, display: "flex", flexDirection: "column", gap: 10, pointerEvents: "none", color: "#fff" }}>
      <div style={{ display: "flex", gap: 4, height: 3 }}>
        {Array.from({ length: count }, (_, segment) => {
          const fill = segment < index ? 1 : segment > index ? 0 : progress;
          return (
            <div key={segment} style={{ position: "relative", flex: 1, height: 3, borderRadius: 1.5, background: "rgb(255 255 255 / 0.35)" }}>
              <div style={{ position: "absolute", inset: 0, borderRadius: 1.5, background: "#fff", transform: `scaleX(${fill})`, transformOrigin: "0 50%" }} />
            </div>
          );
        })}
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: "50%", background: "rgb(255 255 255 / 0.25)", boxShadow: "inset 0 0 0 1.5px rgb(255 255 255 / 0.8)", display: "grid", placeItems: "center", fontSize: 11, fontWeight: 700 }}>
          AL
        </div>
        <span style={{ fontSize: 13, fontWeight: 600 }}>{zh ? "阿兰" : "alan"}</span>
        <span style={{ fontSize: 13, opacity: 0.7 }}>{zh ? "2 小时" : "2h"}</span>
        <div style={{ flex: 1 }} />
        <Ellipsis size={16} strokeWidth={3} />
      </div>
      <div style={{ flex: 1 }} />
      <div style={{ display: "grid" }}>
        <AnimatePresence initial={false}>
          <motion.span
            key={index}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={smooth}
            style={{ gridArea: "1 / 1", fontSize: 20, lineHeight: "25px", fontWeight: 700, textShadow: "0 2px 6px rgb(0 0 0 / 0.2)" }}
          >
            {zh ? page.zh : page.en}
          </motion.span>
        </AnimatePresence>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <div
          style={{
            flex: 1,
            height: 34,
            borderRadius: 17,
            padding: "0 14px",
            display: "flex",
            alignItems: "center",
            fontSize: 13,
            color: "rgb(255 255 255 / 0.85)",
            ...glass("ultraThin", "dark"),
            boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.35)",
          }}
        >
          {zh ? "发送消息" : "Send message"}
        </div>
        <Heart size={19} strokeWidth={2.2} />
      </div>
    </div>
  );
}
