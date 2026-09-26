/** navigation.elastic-underline · 弹性标签下划线 (Navigation+ElasticUnderline.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { Flame, Radio, Sparkles, Users } from "lucide-react";
import { useLayoutEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, demoCard, fonts, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BlurReplace } from "./groupA-kit";

const TABS: [string, string][] = [
  ["For You", "推荐"],
  ["Following", "关注"],
  ["Trending", "热门"],
  ["Live", "直播"],
];
const CARDS: [[string, string], [string, string]][] = [
  [["Picked for you", "为你精选"], ["12 new posts from creators you watch most.", "你常看的创作者发布了 12 条新内容。"]],
  [["From people you follow", "来自你的关注"], ["Mia and Kai shared new work this morning.", "米娅和凯今天上午分享了新作品。"]],
  [["Trending now", "正在热议"], ["#SpringPhysics is up 240% in the last hour.", "#弹簧物理 近一小时热度上涨 240%。"]],
  [["Live · 2.4k watching", "直播中 · 2.4k 人在看"], ["Motion design Q&A with the Studio team.", "与工作室团队的动效设计问答。"]],
];

const GRAD_ID = "elastic-underline-primary";

function CardSymbol({ index }: { index: number }) {
  const paint = `url(#${GRAD_ID})`;
  const size = 34;
  if (index === 0) return <Sparkles size={size} color={paint} fill={paint} strokeWidth={1.4} />;
  if (index === 1) return <Users size={size} color={paint} fill={paint} strokeWidth={1.6} />;
  if (index === 2) return <Flame size={size} color={paint} fill={paint} strokeWidth={1.4} />;
  return <Radio size={size} color={paint} strokeWidth={2.4} />;
}

export default function ElasticUnderline({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(0);
  const labels = useRef<(HTMLDivElement | null)[]>([]);
  const frames = useRef<{ minX: number; maxX: number }[]>([]);
  const selectedRef = useRef(0);
  selectedRef.current = selected;
  const leftEdge = useMotionValue(0);
  const rightEdge = useMotionValue(0);
  const width = useTransform(() => Math.max(rightEdge.get() - leftEdge.get(), 0));
  const opacity = useTransform(rightEdge, (r) => (r > 0 ? 1 : 0));

  // onGeometryChange: re-sync on any layout change (first layout, language switch).
  useLayoutEffect(() => {
    const measure = () => {
      frames.current = labels.current.map((el) => ({ minX: el?.offsetLeft ?? 0, maxX: (el?.offsetLeft ?? 0) + (el?.offsetWidth ?? 0) }));
      const f = frames.current[selectedRef.current];
      if (f) {
        leftEdge.jump(f.minX);
        rightEdge.jump(f.maxX);
      }
    };
    measure();
    let alive = true;
    document.fonts?.ready.then(() => alive && measure());
    return () => {
      alive = false;
    };
  }, [ctx.lang, leftEdge, rightEdge]);

  const select = (index: number) => {
    const target = frames.current[index];
    if (index === selected || !target) return;
    haptics.selection();
    const movingRight = index > selected;
    const lead = spring(ctx.n("response"), 0.78);
    const follow = delayed(spring(ctx.n("response") * 1.25, 0.86), ctx.n("lag"));
    setSelected(index);
    animate(rightEdge, target.maxX, movingRight ? lead : follow);
    animate(leftEdge, target.minX, movingRight ? follow : lead);
  };

  useAutoplay(ctx.isPreview, () => select(selected === TABS.length - 1 ? 0 : selected + 1), { every: 1.3 });

  const thickness = ctx.n("thickness");
  const [title, body] = CARDS[selected];

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 26 }}>
      <svg width={0} height={0} style={{ position: "absolute" }} aria-hidden>
        <defs>
          <linearGradient id={GRAD_ID} gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="24" y2="24">
            <stop offset="0" stopColor={Palette.indigo} />
            <stop offset="1" stopColor={Palette.violet} />
          </linearGradient>
        </defs>
      </svg>
      {/* tab row */}
      <motion.div layout="position" transition={anim.snappy} style={{ position: "relative", display: "flex", gap: 22, flexShrink: 0 }}>
        {TABS.map(([en, zh], index) => (
          <div
            key={index}
            ref={(el) => void (labels.current[index] = el)}
            onClick={() => select(index)}
            style={{
              padding: "10px 0",
              fontFamily: fonts.text,
              fontSize: 15,
              lineHeight: "20px",
              fontWeight: 600,
              whiteSpace: "nowrap",
              cursor: "pointer",
              color: index === selected ? Palette.label : Palette.secondaryLabel,
              transition: "color 0.35s",
            }}
          >
            {ctx.t(en, zh)}
          </div>
        ))}
        <motion.div
          style={{
            position: "absolute",
            left: 0,
            bottom: 0,
            x: leftEdge,
            width,
            height: thickness,
            borderRadius: thickness / 2,
            background: Palette.primary,
            boxShadow: `0 2px 6px rgb(110 123 255 / 0.5)`,
            opacity,
            pointerEvents: "none",
          }}
        />
      </motion.div>
      {/* content card */}
      <motion.div layout="position" transition={anim.snappy}>
      <BlurReplace id={selected} transition={anim.snappy}>
        <div style={{ ...demoCard(24), width: 280, padding: 22, display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
          <CardSymbol index={selected} />
          <div style={{ fontFamily: fonts.text, fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label, textAlign: "center" }}>{ctx.t(...title)}</div>
          <div style={{ fontFamily: fonts.text, fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel, textAlign: "center" }}>{ctx.t(...body)}</div>
        </div>
      </BlurReplace>
      </motion.div>
      <motion.div layout="position" transition={anim.snappy}>
        <DemoHint ctx={ctx} en="Tap a tab" zh="点击任一标签" />
      </motion.div>
    </div>
  );
}
