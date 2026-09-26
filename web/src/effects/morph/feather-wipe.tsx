/** morph.feather-wipe · 羽化视差擦除 (Morph+FeatherWipe.swift) */
import { animate, useMotionValue } from "motion/react";
import { Activity, Sparkles, TramFront } from "lucide-react";
import { useRef } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, black, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { sheen, useMV } from "./_shared";

const articles: { kicker: [string, string]; title: [string, string]; Icon: typeof Sparkles; fill: boolean; tint: string }[] = [
  { kicker: ["Design", "设计"], title: ["The quiet power of springs", "弹簧曲线的静默力量"], Icon: Activity, fill: false, tint: Palette.violet },
  { kicker: ["Travel", "旅行"], title: ["Twelve hours in Kyoto", "京都十二小时"], Icon: TramFront, fill: false, tint: Palette.coral },
  { kicker: ["Science", "科学"], title: ["Why the sky turns violet", "天空为何会变紫"], Icon: Sparkles, fill: true, tint: Palette.mint },
];
const W = 260;
const H = 300;

export default function FeatherWipe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const target = useRef(0);
  const mv = useMotionValue(0);
  const step = useMV(mv);
  const lang = ctx.lang === "zh" ? 1 : 0;
  const feather = ctx.n("feather");
  const angle = ctx.n("angle");
  const parallax = ctx.n("parallax");

  const advance = () => {
    haptics.tap("soft");
    target.current += 1;
    animate(mv, target.current, anim.curve(0.16, 1, 0.3, 1, ctx.n("duration")));
  };
  useAutoplay(ctx.isPreview, advance, { every: 1.6 });

  const s = Math.max(step, 0);
  const base = Math.floor(s);
  const t = Math.min(Math.max(s - base, 0), 1);
  const from = articles[base % articles.length];
  const to = articles[(base + 1) % articles.length];

  // The mask is a 2W-wide rectangle rotated by `angle`, its right edge at `edge` (from the card centre),
  // blurred by `feather`: a linear ramp across that slanted edge.
  const margin = 90 + feather * 2;
  const edge = -W / 2 - margin + t * (W + margin * 2);
  const a = (angle * Math.PI) / 180;
  const n = { x: Math.cos(a), y: Math.sin(a) };
  // Right edge midpoint (card-centre coordinates): rect centre (edge − W, 0) plus the rotated half width.
  const e = { x: edge - W + W * n.x, y: W * n.y };
  const d0 = e.x * n.x + e.y * n.y;
  const cssAngle = 90 + angle;
  const L = Math.abs(W * Math.sin((cssAngle * Math.PI) / 180)) + Math.abs(H * Math.cos((cssAngle * Math.PI) / 180));
  const soft = Math.max(feather, 0.5);
  const mask = `linear-gradient(${cssAngle}deg, #000 ${L / 2 + d0 - soft}px, transparent ${L / 2 + d0 + soft}px)`;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div
        onClick={advance}
        style={{
          position: "relative",
          width: W,
          height: H,
          borderRadius: 28,
          overflow: "hidden",
          boxShadow: `0 10px 18px ${black(0.15)}`,
          cursor: "pointer",
          flexShrink: 0,
        }}
      >
        <div style={{ position: "absolute", inset: 0, background: Palette.elevated, filter: t > 0 ? `brightness(${1 - 0.25 * t})` : undefined }}>
          <div style={{ position: "absolute", inset: 0, transform: `translateX(${-24 * t}px)` }}>
            <Card article={from} lang={lang} />
          </div>
        </div>
        <div style={{ position: "absolute", inset: 0, background: Palette.elevated, WebkitMaskImage: mask, maskImage: mask }}>
          <div style={{ position: "absolute", inset: 0, transform: `translateX(${parallax * (1 - t)}px)` }}>
            <Card article={to} lang={lang} />
          </div>
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 28, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Tap the card" zh="点击卡片" />
    </div>
  );
}

function Card({ article, lang }: { article: (typeof articles)[number]; lang: number }) {
  const { Icon } = article;
  return (
    <div style={{ position: "absolute", inset: 0, padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
      <div style={{ height: 130, borderRadius: 20, background: sheen(article.tint), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
        <Icon size={48} strokeWidth={article.fill ? 1.4 : 2.4} fill={article.fill ? "currentColor" : "none"} />
      </div>
      <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 700, textTransform: "uppercase", color: article.tint }}>{article.kicker[lang]}</span>
      <span style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700, color: Palette.label }}>{article.title[lang]}</span>
      <PlaceholderLines count={2} />
    </div>
  );
}
