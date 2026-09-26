/** navigation.gooey-tab · 黏液标签指示器 (Navigation+GooeyTab.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { Search } from "lucide-react";
import { useId, useState } from "react";
import { DemoHint, Palette, anim, black, delayed, fonts, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { NavigationScreenPlaceholder } from "./shared";
import { Bounce, BellFill, BlurReplace, HouseFill, PersonFill } from "./groupA-kit";

const TITLES: [string, string][] = [
  ["Home", "首页"],
  ["Search", "搜索"],
  ["Alerts", "通知"],
  ["Profile", "我的"],
];
const COUNT = TITLES.length;
const BAR_W = 300;
const BAR_H = 64;
const SLOT = BAR_W / COUNT;
const MID_Y = BAR_H / 2;

function TabGlyph({ index }: { index: number }) {
  if (index === 0) return <HouseFill size={23} />;
  if (index === 1) return <Search size={21} strokeWidth={2.7} />;
  if (index === 2) return <BellFill size={23} />;
  return <PersonFill size={22} />;
}

export default function GooeyTab({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(0);
  const [bounces, setBounces] = useState<number[]>([0, 0, 0, 0]);
  const head = useMotionValue(0);
  const tail = useMotionValue(0);

  const select = (index: number) => {
    if (index === selected) return;
    haptics.selection();
    setBounces((b) => b.map((v, i) => (i === index ? v + 1 : v)));
    setSelected(index);
    animate(head, index, spring(ctx.n("response"), 0.72));
    animate(tail, index, delayed(spring(ctx.n("response") * 1.5, 0.8), ctx.n("lag")));
  };

  useAutoplay(ctx.isPreview, () => select((selected + 1) % COUNT), { every: 1.2 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 30 }}>
      <BlurReplace id={selected} transition={anim.easeInOut(0.2)}>
        <div style={{ fontFamily: fonts.text, fontSize: 22, lineHeight: "28px", fontWeight: 700, color: Palette.label, whiteSpace: "nowrap" }}>
          {ctx.t(...TITLES[selected])}
        </div>
      </BlurReplace>
      {ctx.isPreview && <NavigationScreenPlaceholder rows={2} showsTitle={false} />}
      <div style={{ position: "relative", width: BAR_W, height: BAR_H, flexShrink: 0 }}>
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: 999,
            background: Palette.elevated,
            boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 16px ${black(0.12)}`,
          }}
        />
        <GooeyLayer head={head} tail={tail} goo={ctx.n("goo")} />
        <div style={{ position: "absolute", inset: 0, display: "flex" }}>
          {TITLES.map((_, index) => (
            <div
              key={index}
              onClick={() => select(index)}
              style={{
                flex: 1,
                display: "grid",
                placeItems: "center",
                cursor: "pointer",
                color: index === selected ? "#fff" : Palette.secondaryLabel,
                transition: "color 0.2s ease-in-out",
              }}
            >
              <Bounce trigger={bounces[index]}>
                <TabGlyph index={index} />
              </Bounce>
            </div>
          ))}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap a tab" zh="点击任一标签" />
    </div>
  );
}

type MV = ReturnType<typeof useMotionValue<number>>;

/**
 * Head and tail blobs plus a neck, blurred by `goo` and alpha-thresholded at 0.5 (a metaball), used
 * as the mask of the indigo → violet → pink gradient.
 */
function GooeyLayer({ head, tail, goo }: { head: MV; tail: MV; goo: number }) {
  const uid = useId().replace(/:/g, "");
  const headX = useTransform(head, (h) => (h + 0.5) * SLOT);
  const tailX = useTransform(tail, (t) => (t + 0.5) * SLOT);
  const distance = useTransform(() => Math.abs(headX.get() - tailX.get()));
  const tailR = useTransform(distance, (d) => Math.max(25 - d * 0.08, 14));
  const neck = useTransform(distance, (d) => Math.max(22 - d * 0.12, 0));
  const bridgeX = useTransform(() => Math.min(headX.get(), tailX.get()));
  const bridgeY = useTransform(neck, (n) => MID_Y - n / 2);
  const bridgeR = useTransform(neck, (n) => n / 2);
  return (
    <svg width={BAR_W} height={BAR_H} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }} aria-hidden>
      <defs>
        <linearGradient id={`${uid}-g`} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0" stopColor={Palette.indigo} />
          <stop offset="0.5" stopColor={Palette.violet} />
          <stop offset="1" stopColor={Palette.pink} />
        </linearGradient>
        <filter id={`${uid}-f`} filterUnits="userSpaceOnUse" x={-60} y={-60} width={BAR_W + 120} height={BAR_H + 120} colorInterpolationFilters="sRGB">
          <feGaussianBlur stdDeviation={goo} />
          <feComponentTransfer>
            <feFuncR type="discrete" tableValues="1" />
            <feFuncG type="discrete" tableValues="1" />
            <feFuncB type="discrete" tableValues="1" />
            <feFuncA type="discrete" tableValues="0 1" />
          </feComponentTransfer>
          <feGaussianBlur stdDeviation={0.6} />
        </filter>
        <mask id={`${uid}-m`} maskUnits="userSpaceOnUse" x={-60} y={-60} width={BAR_W + 120} height={BAR_H + 120}>
          <g filter={`url(#${uid}-f)`}>
            <motion.circle cx={headX} cy={MID_Y} r={25} fill="#fff" />
            <motion.circle cx={tailX} cy={MID_Y} r={tailR} fill="#fff" />
            <motion.rect x={bridgeX} y={bridgeY} width={distance} height={neck} rx={bridgeR} fill="#fff" />
          </g>
        </mask>
      </defs>
      <rect x={0} y={0} width={BAR_W} height={BAR_H} fill={`url(#${uid}-g)`} mask={`url(#${uid}-m)`} />
    </svg>
  );
}
