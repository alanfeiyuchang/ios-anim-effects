/** navigation.page-dots · 伸展页码指示器 (Navigation+PageDots.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { Flame, Heart, Leaf, MoonStar, Sparkles, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, clamp, rubberBand, useAutoplay, usePan, type DemoProps } from "../../kit";

const PAGES: [LucideIcon, [string, string]][] = [
  [Sparkles, [Palette.indigo, Palette.violet]],
  [Leaf, [Palette.mint, Palette.sky]],
  [Flame, [Palette.amber, Palette.coral]],
  [Heart, [Palette.pink, Palette.violet]],
  [MoonStar, [Palette.blue, "#241B5C"]],
];
const WIDTH = 340;
const COUNT = PAGES.length;

export default function PageDots({ ctx }: DemoProps) {
  /** The scroll view's contentOffset.x. */
  const offset = useMotionValue(0);
  const [progress, setProgress] = useState(0);
  useMotionValueEvent(offset, "change", (x) => setProgress(x / WIDTH));
  const page = useRef(0);
  const dragStart = useRef(0);

  const scrollTo = (target: number, velocity = 0) => {
    page.current = target;
    animate(offset, target * WIDTH, { ...anim.smoothD(0.6), velocity });
  };

  useAutoplay(ctx.isPreview, () => scrollTo((page.current + 1) % COUNT), { every: 1.4 });

  // A paging scroll view: follows the finger 1:1 and settles on the nearest page (or the next one on a flick).
  const pan = usePan({
    onStart: () => {
      offset.stop();
      dragStart.current = offset.get();
    },
    onChange: ({ translation }) => {
      const raw = dragStart.current - translation.x;
      const max = (COUNT - 1) * WIDTH;
      offset.set(raw < 0 ? rubberBand(raw, WIDTH) : raw > max ? max + rubberBand(raw - max, WIDTH) : raw);
    },
    onEnd: ({ velocity }) => {
      const current = offset.get() / WIDTH;
      let target = Math.round(current);
      if (Math.abs(velocity.x) > 250) target = velocity.x < 0 ? Math.floor(current) + 1 : Math.ceil(current) - 1;
      target = clamp(target, Math.max(page.current - 1, 0), Math.min(page.current + 1, COUNT - 1));
      scrollTo(target, -velocity.x);
    },
  });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: WIDTH, height: 234, overflow: "hidden", flexShrink: 0, cursor: "grab" }}>
        <div style={{ position: "absolute", left: 0, top: 0, height: 234, display: "flex", transform: `translateX(${-progress * WIDTH}px)` }}>
          {PAGES.map(([Icon, colors], index) => (
            <div key={index} style={{ width: WIDTH, height: 234, padding: "24px 32px", flexShrink: 0 }}>
              <div
                style={{
                  width: "100%",
                  height: "100%",
                  borderRadius: 28,
                  background: `linear-gradient(135deg, ${colors[0]}, ${colors[1]})`,
                  boxShadow: `0 8px 14px ${alpha(colors[0], 0.3)}`,
                  display: "grid",
                  placeItems: "center",
                  color: "rgb(255 255 255 / 0.92)",
                }}
              >
                <Icon size={62} fill="currentColor" strokeWidth={1.2} />
              </div>
            </div>
          ))}
        </div>
      </div>
      <PageIndicator progress={progress} style={ctx.i("style")} activeWidth={ctx.n("width")} />
      <DemoHint ctx={ctx} en="Swipe the cards" zh="左右滑动卡片" />
    </div>
  );
}

const DOT = 8;
const SPACING = 8;
const INACTIVE = Palette.labelAlpha(0.18);

function PageIndicator({ progress, style, activeWidth }: { progress: number; style: number; activeWidth: number }) {
  const weight = (index: number) => Math.max(0, 1 - Math.abs(progress - index));
  const indices = Array.from({ length: COUNT }, (_, i) => i);

  if (style === 1) {
    const clamped = clamp(progress, 0, COUNT - 1);
    const base = Math.floor(clamped);
    const fraction = clamped - base;
    const step = DOT + SPACING;
    const leading = (base + Math.max(0, fraction * 2 - 1)) * step;
    const trailing = (base + Math.min(1, fraction * 2)) * step + DOT;
    return (
      <div style={{ position: "relative", display: "flex", gap: SPACING }}>
        {indices.map((i) => (
          <div key={i} style={{ width: DOT, height: DOT, borderRadius: "50%", background: INACTIVE }} />
        ))}
        <div
          style={{
            position: "absolute",
            left: leading,
            top: 0,
            width: Math.max(trailing - leading, DOT),
            height: DOT,
            borderRadius: DOT / 2,
            background: Palette.indigo,
          }}
        />
      </div>
    );
  }

  if (style === 2) {
    return (
      <div style={{ display: "flex", gap: SPACING + 4 }}>
        {indices.map((i) => {
          const w = weight(i);
          return (
            <div key={i} style={{ position: "relative", width: DOT, height: DOT, borderRadius: "50%", background: INACTIVE, transform: `scale(${1 + 0.6 * w})` }}>
              <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.indigo, opacity: w }} />
            </div>
          );
        })}
      </div>
    );
  }

  return (
    <div style={{ display: "flex", gap: SPACING }}>
      {indices.map((i) => {
        const w = weight(i);
        return (
          <div key={i} style={{ position: "relative", width: DOT + (activeWidth - DOT) * w, height: DOT, borderRadius: DOT / 2, background: INACTIVE }}>
            <div style={{ position: "absolute", inset: 0, borderRadius: DOT / 2, background: Palette.indigo, opacity: w }} />
          </div>
        );
      })}
    </div>
  );
}
