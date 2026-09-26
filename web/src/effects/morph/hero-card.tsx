/** morph.hero-card · 卡片展开转场 (Morph+HeroCard.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { Sparkles, Wind, X } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, black, clamp, delayed, fonts, pressHandlers, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { diag, mixN, mixRect, useMV, useSize, type Rect } from "./_shared";

interface Story {
  id: number;
  Icon: typeof Wind;
  colors: string[];
  eyebrow: [string, string];
  title: [string, string];
  paragraphs: [string, string][];
}

const stories: Story[] = [
  {
    id: 0,
    Icon: Wind,
    colors: [Palette.amber, Palette.coral, Palette.pink],
    eyebrow: ["MOTION OF THE DAY", "今日动效"],
    title: ["Designing with springs", "用弹簧做设计"],
    paragraphs: [
      [
        "Springs don't have a duration — they have a feel. Response sets how quickly a view reaches its target; damping decides whether it overshoots.",
        "弹簧没有“时长”，只有“手感”。响应决定视图多快抵达目标，阻尼决定它是否冲过头。",
      ],
      [
        "Start near 0.5 s and 0.8, then tune by hand: a card that lands with a whisper of bounce feels caught, not placed.",
        "从 0.5 秒、0.8 起步再亲手微调：带一丝回弹落定的卡片，像被稳稳接住，而不是被摆放。",
      ],
    ],
  },
  {
    id: 1,
    Icon: Sparkles,
    colors: [Palette.sky, Palette.blue, Palette.violet],
    eyebrow: ["STUDIO NOTES", "设计札记"],
    title: ["The art of easing", "缓动的艺术"],
    paragraphs: [
      [
        "Easing is how motion breathes. Ease-out feels responsive because it starts fast and settles gently, like a ball caught in a glove.",
        "缓动是动效的呼吸。缓出曲线起步快、收尾柔，像被手套稳稳接住的球，所以显得灵敏。",
      ],
      ["Save ease-in for exits, and never use linear timing for anything that travels across the screen.", "缓入留给退场；任何横穿屏幕的运动，都别用线性曲线。"],
    ],
  },
];

const CARD_H = 132;
const GAP = 14;

export default function HeroCard({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const root = useRef<HTMLDivElement>(null);
  const size = useSize(root, { width: 340, height: ctx.isPreview ? 340 : 400 });
  const [selected, setSelected] = useState<number | null>(null);
  const [shown, setShown] = useState(0);
  const [showBody, setShowBody] = useState(false);
  const [autoIndex, setAutoIndex] = useState(0);
  const pMV = useMotionValue(0);
  const p = useMV(pMV);
  const spr = spring(ctx.n("response"), ctx.n("damping"));
  const lang = ctx.lang === "zh" ? 1 : 0;

  const feedTop = (size.height - (CARD_H * 2 + GAP)) / 2;
  const cardRect = (id: number): Rect => ({ x: 22, y: feedTop + id * (CARD_H + GAP), w: size.width - 44, h: CARD_H });
  const stageRect: Rect = { x: 0, y: 0, w: size.width, h: size.height };

  const open = (id: number) => {
    haptics.tap("medium");
    setShown(id);
    setSelected(id);
    animate(pMV, 1, spr);
    requestAnimationFrame(() => setShowBody(true));
  };
  const close = () => {
    haptics.tap();
    setShowBody(false);
    setSelected(null);
    animate(pMV, 0, spr);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (selected === null) {
        open(stories[autoIndex % stories.length].id);
        setAutoIndex((i) => i + 1);
      } else close();
    },
    { every: 2.2 },
  );

  const flying = selected !== null || p > 0.001;
  const rect = mixRect(cardRect(shown), stageRect, p);
  const story = stories[shown];
  const fade = clamp(p);

  return (
    <div ref={root} style={{ position: "absolute", inset: 0 }}>
      <motion.div
        initial={false}
        animate={{ scale: selected === null ? 1 : 0.92, opacity: selected === null ? 1 : 0.4 }}
        transition={spr}
        style={{ position: "absolute", inset: 0 }}
      >
        {stories.map((s) => (
          <FeedCard key={s.id} story={s} lang={lang} rect={cardRect(s.id)} hidden={flying && shown === s.id} press={ctx.n("press")} onTap={() => open(s.id)} />
        ))}
      </motion.div>
      {flying && (
        <div
          style={{
            position: "absolute",
            left: rect.x,
            top: rect.y,
            width: rect.w,
            height: rect.h,
            borderRadius: mixN(22, 30, fade),
            overflow: "hidden",
            zIndex: 1,
          }}
        >
          <div style={{ position: "absolute", inset: 0, opacity: 1 - fade, borderRadius: 22, overflow: "hidden" }}>
            <Artwork story={story} lang={lang} expanded={false} />
          </div>
          <div style={{ position: "absolute", inset: 0, opacity: fade, background: Palette.elevated, display: "flex", flexDirection: "column" }}>
            <div style={{ position: "relative", height: 160, flexShrink: 0 }}>
              <Artwork story={story} lang={lang} expanded />
            </div>
            <div style={{ padding: 20, display: "flex", flexDirection: "column", gap: 10, width: size.width }}>
              <BodyLine visible={showBody} index={0}>
                <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel }}>
                  {lang ? "阅读 3 分钟 · Motionary 编辑部" : "3 min read · Motionary Editors"}
                </div>
              </BodyLine>
              {story.paragraphs.map((para, i) => (
                <BodyLine key={i} visible={showBody} index={i + 1}>
                  <div
                    style={{
                      fontSize: 15,
                      lineHeight: "20px",
                      color: Palette.label,
                      display: "-webkit-box",
                      WebkitLineClamp: 4,
                      WebkitBoxOrient: "vertical",
                      overflow: "hidden",
                    }}
                  >
                    {para[lang]}
                  </div>
                </BodyLine>
              ))}
            </div>
            <motion.button
              type="button"
              onClick={close}
              initial={false}
              animate={{ opacity: showBody ? 1 : 0 }}
              transition={delayed(anim.easeOut(0.2), showBody ? 0.2 : 0)}
              style={{
                position: "absolute",
                left: 14,
                top: 14,
                width: 32,
                height: 32,
                borderRadius: 16,
                background: black(0.25),
                display: "grid",
                placeItems: "center",
                color: "#fff",
                pointerEvents: selected !== null ? "auto" : "none",
              }}
            >
              <X size={14} strokeWidth={3.2} />
            </motion.button>
          </div>
        </div>
      )}
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          bottom: 12,
          opacity: selected === null ? 1 : 0,
          transition: "opacity 0.3s",
          pointerEvents: "none",
        }}
      >
        <DemoHint ctx={ctx} en="Tap a story card" zh="点击一张故事卡片" />
      </div>
    </div>
  );
}

function FeedCard({ story, lang, rect, hidden, press, onTap }: { story: Story; lang: number; rect: Rect; hidden: boolean; press: number; onTap: () => void }) {
  const [pressed, setPressed] = useState(false);
  return (
    <motion.button
      type="button"
      onClick={onTap}
      {...pressHandlers(setPressed)}
      animate={{ scale: pressed ? press : 1 }}
      transition={spring(0.3, 0.7)}
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: rect.w,
        height: rect.h,
        borderRadius: 22,
        overflow: "hidden",
        boxShadow: `0 8px 14px ${black(0.14)}`,
        opacity: hidden ? 0 : 1,
        textAlign: "left",
      }}
    >
      <Artwork story={story} lang={lang} expanded={false} />
    </motion.button>
  );
}

function Artwork({ story, lang, expanded }: { story: Story; lang: number; expanded: boolean }) {
  const { Icon } = story;
  const size = expanded ? 96 : 64;
  return (
    <div style={{ position: "absolute", inset: 0, background: diag(...story.colors) }}>
      <div style={{ position: "absolute", top: expanded ? 26 : 16, right: expanded ? 26 : 16, color: white(0.35) }}>
        <Icon size={size} strokeWidth={2} fill={story.id === 1 ? "currentColor" : "none"} />
      </div>
      <div style={{ position: "absolute", left: 18, bottom: 18, display: "flex", flexDirection: "column", gap: 4 }}>
        <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 700, color: white(0.8), fontFamily: fonts.text }}>{story.eyebrow[lang]}</span>
        <span style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700, color: "#fff", whiteSpace: "nowrap" }}>{story.title[lang]}</span>
      </div>
    </div>
  );
}

function BodyLine({ visible, index, children }: { visible: boolean; index: number; children: React.ReactNode }) {
  return (
    <motion.div
      initial={false}
      animate={{ opacity: visible ? 1 : 0, y: visible ? 0 : 12 }}
      transition={visible ? delayed(spring(0.5, 0.9), 0.15 + index * 0.05) : anim.easeOut(0.1)}
    >
      {children}
    </motion.div>
  );
}
