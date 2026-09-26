/** morph.cube-transition · 3D 立方体转场 (Morph+CubeTransition.swift) */
import { animate, useMotionValue } from "motion/react";
import { Leaf, MoonStar, Sparkles, Sun } from "lucide-react";
import { useRef } from "react";
import { DemoHint, Palette, clamp, rubberBand, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { diag, predicted, useMV } from "./_shared";

const pages: { Icon: typeof Sun; colors: string[]; title: [string, string]; subtitle: [string, string] }[] = [
  { Icon: Sun, colors: [Palette.amber, Palette.coral], title: ["Morning", "清晨"], subtitle: ["6:40 · Sunrise run", "6:40 · 日出晨跑"] },
  { Icon: Leaf, colors: [Palette.mint, Palette.sky], title: ["Garden", "花园"], subtitle: ["Water the ferns", "给蕨类浇水"] },
  { Icon: Sparkles, colors: [Palette.violet, Palette.pink], title: ["Studio", "工作室"], subtitle: ["Review motion specs", "评审动效规范"] },
  { Icon: MoonStar, colors: [Palette.indigo, "#241B5C"], title: ["Night", "夜晚"], subtitle: ["22:30 · Wind down", "22:30 · 放松入睡"] },
];
const FACE_W = 230;
const FACE_H = 250;
const LAST = pages.length - 1;

export default function CubeTransition({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const mv = useMotionValue(0);
  const progress = useMV(mv);
  const dragStart = useRef<number | null>(null);
  const direction = useRef(1);
  const lang = ctx.lang === "zh" ? 1 : 0;

  const snap = (target: number) => {
    if (target !== Math.round(mv.get())) haptics.tap("soft");
    animate(mv, target, spring(ctx.n("response"), 0.85));
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      const current = Math.round(mv.get());
      if (current + direction.current > LAST || current + direction.current < 0) direction.current = -direction.current;
      snap(current + direction.current);
    },
    { every: 1.6 },
  );

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (dragStart.current === null) {
          if (Math.abs(translation.y) > Math.abs(translation.x)) return;
          mv.stop();
          dragStart.current = mv.get();
        }
        const raw = dragStart.current - translation.x / FACE_W;
        if (raw < 0) mv.set(rubberBand(raw * FACE_W, 60) / FACE_W);
        else if (raw > LAST) mv.set(LAST + rubberBand((raw - LAST) * FACE_W, 60) / FACE_W);
        else mv.set(raw);
      },
      onEnd: ({ translation, velocity }) => {
        const start = dragStart.current;
        if (start === null) return;
        dragStart.current = null;
        const projected = start - predicted(translation.x, velocity.x) / FACE_W;
        const target = Math.min(Math.max(Math.round(projected), Math.round(start) - 1), Math.round(start) + 1);
        snap(clamp(target, 0, LAST));
      },
    },
    8,
  );

  const perspective = Math.max(FACE_W, FACE_H) / Math.max(ctx.n("perspective"), 0.01);
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: FACE_W, height: FACE_H, flexShrink: 0, cursor: "grab" }}>
        {pages.map((page, index) => {
          const position = index - progress;
          const p = clamp(position, -1, 1);
          if (Math.abs(position) >= 0.999) return null;
          return (
            <div
              key={index}
              style={{
                position: "absolute",
                inset: 0,
                transform: `translateX(${p * FACE_W}px) perspective(${perspective}px) rotateY(${p * 90}deg)`,
                transformOrigin: p < 0 ? "100% 50%" : "0% 50%",
                filter: ctx.b("shade") ? `brightness(${1 - 0.3 * Math.abs(p)})` : undefined,
              }}
            >
              <Face page={page} lang={lang} />
            </div>
          );
        })}
      </div>
      <div style={{ display: "flex", gap: 7 }}>
        {pages.map((_, index) => {
          const active = Math.max(0, 1 - Math.abs(progress - index));
          return <span key={index} style={{ width: 7 + 12 * active, height: 7, borderRadius: 3.5, background: Palette.labelAlpha(0.2 + 0.6 * active) }} />;
        })}
      </div>
      <DemoHint ctx={ctx} en="Swipe left or right to turn the cube" zh="左右滑动旋转立方体" />
    </div>
  );
}

function Face({ page, lang }: { page: (typeof pages)[number]; lang: number }) {
  return (
    <div style={{ position: "absolute", inset: 0, borderRadius: 6, overflow: "hidden", background: diag(...page.colors), padding: 22, display: "flex", flexDirection: "column", gap: 10 }}>
      <div style={{ flex: 1, display: "grid", placeItems: "center", color: "#fff" }}>
        <page.Icon size={58} strokeWidth={1.4} fill="currentColor" />
      </div>
      <span style={{ fontSize: 22, lineHeight: "28px", fontWeight: 700, color: "#fff" }}>{page.title[lang]}</span>
      <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, color: white(0.8), whiteSpace: "nowrap" }}>{page.subtitle[lang]}</span>
    </div>
  );
}
