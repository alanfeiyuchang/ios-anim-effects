/** scroll.progress-indicator · 阅读进度 (Scroll+Progress.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Fragment, useRef } from "react";
import { Palette, alpha, anim, black, clamp, glass, spring, useAutoplay, type DemoProps } from "../../kit";
import { ScrollKitArt, ScrollKitIcon, Sym, useScroller } from "./_kit";

const HEADER = 44;

const PARAGRAPHS: [string, string][] = [
  [
    "Motion is the grammar of an interface. Before a person reads a single word, they have already felt whether a screen is calm or restless, heavy or light.",
    "动效是界面的语法。在读到第一个字之前，人们就已经感受到这个页面是沉静还是焦躁、厚重还是轻盈。",
  ],
  [
    "Good transitions answer three questions at once: where did this come from, where is it going, and what can I do with it now?",
    "好的转场会同时回答三个问题：它从哪里来，要到哪里去，现在我能拿它做什么？",
  ],
  [
    "Springs feel natural because they carry momentum. A card that overshoots by a few points and settles tells the eye it has weight.",
    "弹簧之所以自然，是因为它带着惯性。一张卡片多冲出几个点再回落，眼睛就知道它有分量。",
  ],
  [
    "Timing is a budget. Most feedback should land within 100 ms; larger choreography can take 300 to 500 ms before it starts to feel slow.",
    "时长是一种预算。大多数反馈应在 100 毫秒内到达；更大的编排可以用 300 到 500 毫秒，再长就会显得拖沓。",
  ],
  [
    "Let the finger lead. When motion is scrubbed by a gesture instead of a timer, the interface stops performing and starts responding.",
    "让手指来主导。当动效由手势驱动而不是由计时器播放，界面就从“表演”变成了“回应”。",
  ],
  [
    "Finally, restraint. The best motion is often the one nobody notices — it simply makes the product feel inevitable.",
    "最后是克制。最好的动效往往无人察觉——它只是让产品显得理所当然。",
  ],
];

const GRADIENT = [Palette.mint, Palette.sky, Palette.violet];

export default function ProgressIndicator({ ctx }: DemoProps) {
  const sc = useScroller({ axis: "y" });
  const down = useRef(false);
  useAutoplay(
    ctx.isPreview,
    () => {
      down.current = !down.current;
      sc.scrollTo(down.current ? "end" : 0, anim.smoothD(2.4));
    },
    { every: 3.0 },
  );

  const range = sc.max();
  const progress = range > 0 ? clamp(sc.offset / range) : 0;
  const zh = ctx.lang === "zh";
  const t = (i: number) => PARAGRAPHS[i][zh ? 1 : 0];

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
        <div ref={sc.contentRef} style={{ padding: `${HEADER + 16}px 22px 28px`, display: "flex", flexDirection: "column", gap: 18 }}>
          <div style={{ fontSize: 22, lineHeight: "28px", fontWeight: 700 }}>{zh ? "动效的艺术" : "The Art of Motion"}</div>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <ScrollKitIcon index={1} size={30} circle />
            <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, color: Palette.secondaryLabel }}>{zh ? "朴莉娜 · 6 分钟阅读" : "Lena Park · 6 min read"}</span>
          </div>
          {PARAGRAPHS.map((_, i) => (
            <Fragment key={i}>
              <div style={{ fontSize: 15, lineHeight: "24px", color: Palette.labelAlpha(0.82) }}>{t(i)}</div>
              {i === 1 && (
                <div style={{ position: "relative", height: 140, borderRadius: 18, overflow: "hidden", flexShrink: 0 }}>
                  <ScrollKitArt index={5} lang={ctx.lang} showsTitle={false} />
                </div>
              )}
              {i === 3 && (
                <div style={{ display: "flex", gap: 12 }}>
                  <div style={{ width: 3, borderRadius: 2, background: Palette.primary, flexShrink: 0 }} />
                  <div style={{ fontSize: 16, lineHeight: "21px", fontStyle: "italic", color: Palette.secondaryLabel }}>
                    {zh ? "好的动效，先被感受，后被看见。" : "Good motion is felt before it is seen."}
                  </div>
                </div>
              )}
            </Fragment>
          ))}
        </div>
      </div>
      <Header progress={progress} barHeight={ctx.n("barHeight")} zh={zh} />
      {ctx.b("ring") && <Ring progress={progress} onTap={() => sc.scrollTo(0, anim.smoothD(0.8))} />}
    </div>
  );
}

function Header({ progress, barHeight, zh }: { progress: number; barHeight: number; zh: boolean }) {
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: 0, ...glass("ultraThin"), pointerEvents: "none" }}>
      <div style={{ height: HEADER - 4, padding: "0 18px", display: "flex", alignItems: "center", fontSize: 13, fontWeight: 600 }}>
        <span>{zh ? "动效的艺术" : "The Art of Motion"}</span>
        <span style={{ flex: 1 }} />
        <span style={{ color: Palette.secondaryLabel, fontVariantNumeric: "tabular-nums" }}>{Math.round(progress * 100)}%</span>
      </div>
      <div
        style={{
          height: barHeight,
          borderRadius: barHeight / 2,
          background: `linear-gradient(90deg, ${GRADIENT.join(", ")})`,
          transformOrigin: "0 50%",
          transform: `scaleX(${Math.max(progress, 0.001)})`,
          boxShadow: `0 0 6px ${alpha(Palette.sky, 0.6)}`,
        }}
      />
    </div>
  );
}

function Ring({ progress, onTap }: { progress: number; onTap: () => void }) {
  const done = progress > 0.985;
  const p = progress * 100;
  const end = progress * 2 * Math.PI;
  const ringMask = `radial-gradient(circle closest-side, transparent calc(100% - 4px), #000 calc(100% - 4px))`;
  const endColor = progress < 0.5 ? mixHex(Palette.mint, Palette.sky, progress * 2) : mixHex(Palette.sky, Palette.violet, progress * 2 - 1);
  return (
    <motion.button
      type="button"
      onClick={onTap}
      animate={{ scale: done ? 1.12 : 1 }}
      transition={spring(0.35, 0.55)}
      style={{
        position: "absolute",
        right: 16,
        bottom: 16,
        width: 52,
        height: 52,
        borderRadius: "50%",
        ...glass("regular"),
        boxShadow: `0 4px 10px ${black(0.12)}`,
      }}
    >
      <div style={{ position: "absolute", left: 2, top: 2, width: 48, height: 48 }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.labelAlpha(0.1), WebkitMaskImage: ringMask, maskImage: ringMask }} />
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: "50%",
            background: `conic-gradient(${GRADIENT.join(", ")})`,
            WebkitMaskImage: `${ringMask}, conic-gradient(#000 ${p}%, transparent ${p}%)`,
            maskImage: `${ringMask}, conic-gradient(#000 ${p}%, transparent ${p}%)`,
            WebkitMaskComposite: "source-in",
            maskComposite: "intersect",
          }}
        />
        {progress > 0.002 && (
          <>
            <div style={{ position: "absolute", left: 22, top: 0, width: 4, height: 4, borderRadius: "50%", background: Palette.mint }} />
            <div
              style={{
                position: "absolute",
                left: 22 + 22 * Math.sin(end),
                top: 22 - 22 * Math.cos(end),
                width: 4,
                height: 4,
                borderRadius: "50%",
                background: endColor,
              }}
            />
          </>
        )}
      </div>
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
        <AnimatePresence initial={false} mode="popLayout">
          <motion.span
            key={done ? "up" : "book"}
            initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
            animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
            exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
            transition={anim.snappyD(0.3)}
            style={{ display: "grid", color: done ? Palette.violet : Palette.secondaryLabel }}
          >
            <Sym name={done ? "arrow.up" : "book.fill"} size={14} weight={700} />
          </motion.span>
        </AnimatePresence>
      </div>
    </motion.button>
  );
}

function mixHex(a: string, b: string, t: number) {
  const pa = [1, 3, 5].map((k) => parseInt(a.slice(k, k + 2), 16));
  const pb = [1, 3, 5].map((k) => parseInt(b.slice(k, k + 2), 16));
  return `rgb(${pa.map((v, k) => Math.round(v + (pb[k] - v) * clamp(t))).join(" ")})`;
}
