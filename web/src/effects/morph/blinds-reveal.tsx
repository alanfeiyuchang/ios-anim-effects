/** morph.blinds-reveal · 百叶窗揭示 (Morph+BlindsReveal.swift) */
import { animate, useMotionValue } from "motion/react";
import { MoonStar, Sun, Sunrise } from "lucide-react";
import { useRef } from "react";
import { DemoHint, anim, black, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { useMV, vert } from "./_shared";

const scenes: { title: [string, string]; Icon: typeof Sun; fill: boolean; colors: string[] }[] = [
  { title: ["Dawn", "黎明"], Icon: Sunrise, fill: false, colors: ["#FFB36B", "#FF6B8B"] },
  { title: ["Day", "白昼"], Icon: Sun, fill: true, colors: ["#3AC4FF", "#4F7CFF"] },
  { title: ["Night", "夜晚"], Icon: MoonStar, fill: true, colors: ["#2B2F77", "#141432"] },
];
const W = 260;
const H = 300;

function slatPath(progress: number, slats: number, spread: number, vertical: boolean) {
  const span = Math.max(1 - spread, 0.05);
  const length = vertical ? W : H;
  const slat = length / slats;
  let d = "";
  for (let i = 0; i < slats; i++) {
    const start = slats > 1 ? (i / (slats - 1)) * spread : 0;
    const local = Math.min(Math.max((progress - start) / span, 0), 1);
    const size = slat * local + (local >= 1 ? 0.5 : 0);
    if (size <= 0) continue;
    const origin = i * slat + (slat - size) / 2;
    d += vertical ? `M${origin} 0H${origin + size}V${H}H${origin}Z` : `M0 ${origin}H${W}V${origin + size}H0Z`;
  }
  return d || "M0 0Z";
}

export default function BlindsReveal({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const target = useRef(0);
  const mv = useMotionValue(0);
  const step = useMV(mv);
  const lang = ctx.lang === "zh" ? 1 : 0;

  const advance = () => {
    haptics.tap("soft");
    target.current += 1;
    animate(mv, target.current, anim.curve(0.65, 0, 0.35, 1, ctx.n("duration")));
  };
  useAutoplay(ctx.isPreview, advance, { every: 1.7 });

  const s = Math.max(step, 0);
  const base = Math.floor(s);
  const t = s - base;
  const from = scenes[base % scenes.length];
  const to = scenes[(base + 1) % scenes.length];
  const d = slatPath(t, Math.max(ctx.i("slats"), 2), ctx.n("spread"), ctx.b("vertical"));

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div
        onClick={advance}
        style={{ position: "relative", width: W, height: H, borderRadius: 28, overflow: "hidden", boxShadow: `0 10px 18px ${black(0.18)}`, cursor: "pointer", flexShrink: 0 }}
      >
        <Scene scene={from} lang={lang} />
        <div style={{ position: "absolute", inset: 0, clipPath: `path('${d}')` }}>
          <Scene scene={to} lang={lang} />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap the card" zh="点击卡片" />
    </div>
  );
}

function Scene({ scene, lang }: { scene: (typeof scenes)[number]; lang: number }) {
  const { Icon } = scene;
  return (
    <div style={{ position: "absolute", inset: 0, background: vert(...scene.colors), display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14, color: "#fff" }}>
      <Icon size={70} strokeWidth={scene.fill ? 1.4 : 2.2} fill={scene.fill ? "currentColor" : "none"} />
      <span style={{ fontSize: 28, lineHeight: "34px", fontWeight: 700 }}>{scene.title[lang]}</span>
    </div>
  );
}
