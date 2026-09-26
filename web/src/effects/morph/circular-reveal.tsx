/** morph.circular-reveal · 圆形揭示 (Morph+CircularReveal.swift) */
import { animate, useMotionValue } from "motion/react";
import { Bold, Contrast, Moon, MoonStar, Sparkles, Sun } from "lucide-react";
import { Fragment, useRef, useState } from "react";
import { Palette, alpha, anim, glass, hex, localPoint, springDB, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { useMV, useSize } from "./_shared";

export default function CircularReveal({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const root = useRef<HTMLDivElement>(null);
  const size = useSize(root, { width: 340, height: ctx.isPreview ? 340 : 400 });
  const [baseDark, setBaseDark] = useState(false);
  const [origin, setOrigin] = useState({ x: 0, y: 0 });
  const animating = useRef(false);
  const mv = useMotionValue(0);
  const progress = useMV(mv);
  const lang = ctx.lang === "zh" ? 1 : 0;

  const transition = () => {
    const duration = ctx.n("duration");
    switch (ctx.i("curve")) {
      case 1:
        return anim.easeOut(duration);
      case 2:
        return springDB(duration, 0);
      default:
        return anim.curve(0.7, 0, 0.2, 1, duration);
    }
  };

  const reveal = (point: { x: number; y: number }) => {
    if (animating.current) return;
    haptics.tap();
    animating.current = true;
    setOrigin(point);
    animate(mv, 1, transition()).then(() => {
      setBaseDark((d) => !d);
      mv.set(0);
      animating.current = false;
    });
  };
  useAutoplay(ctx.isPreview, () => reveal({ x: size.width - 46, y: 46 }), { every: 1.8 });

  const farthest = Math.max(
    Math.hypot(origin.x, origin.y),
    Math.hypot(size.width - origin.x, origin.y),
    Math.hypot(origin.x, size.height - origin.y),
    Math.hypot(size.width - origin.x, size.height - origin.y),
  );
  const r = farthest * progress;

  return (
    <div ref={root} onClick={(e) => root.current && reveal(localPoint(e, root.current))} style={{ position: "absolute", inset: 0, cursor: "pointer" }}>
      <ThemePanel dark={baseDark} lang={lang} />
      <div style={{ position: "absolute", inset: 0, clipPath: `circle(${Math.max(r, 0)}px at ${origin.x}px ${origin.y}px)` }}>
        <ThemePanel dark={!baseDark} lang={lang} />
      </div>
      {!ctx.isPreview && (
        <div style={{ position: "absolute", left: 0, right: 0, bottom: 14, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
          <span
            style={{
              padding: "6px 12px",
              borderRadius: 999,
              ...glass("thin"),
              fontSize: 13,
              lineHeight: "18px",
              fontWeight: 500,
              color: Palette.secondaryLabel,
            }}
          >
            {ctx.t("Tap anywhere to switch theme", "点击任意位置切换主题")}
          </span>
        </div>
      )}
    </div>
  );
}

function ThemePanel({ dark, lang }: { dark: boolean; lang: number }) {
  const ink = dark ? "#ffffff" : "#1B1D2A";
  const rows: [typeof Bold, [string, string], boolean, boolean][] = [
    [Bold, ["Bold Text", "粗体文本"], true, false],
    [Contrast, ["Automatic", "自动切换"], dark, false],
    [Moon, ["Night Shift", "夜览"], dark, false],
    [Contrast, ["Increase Contrast", "增强对比度"], false, true],
    [Sparkles, ["Reduce Motion", "减弱动态效果"], false, false],
  ];
  return (
    <div
      className={dark ? "ml-dark" : "ml-light"}
      style={{
        position: "absolute",
        inset: 0,
        padding: "22px 22px 0",
        display: "flex",
        flexDirection: "column",
        gap: 18,
        color: ink,
        background: dark ? "linear-gradient(#0E1024, #262B57)" : "linear-gradient(#FFF8EE, #E9EEFF)",
      }}
    >
      <div style={{ display: "flex", alignItems: "center" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <span style={{ fontSize: 22, lineHeight: "28px", fontWeight: 700 }}>{lang ? "外观" : "Appearance"}</span>
          <span style={{ fontSize: 15, lineHeight: "20px", opacity: 0.6 }}>
            {dark ? (lang ? "夜间模式" : "Night mode") : lang ? "日间模式" : "Day mode"}
          </span>
        </div>
        <span style={{ flex: 1 }} />
        <span style={{ width: 48, height: 48, borderRadius: 24, background: alpha(ink, 0.08), display: "grid", placeItems: "center", color: dark ? Palette.amber : Palette.coral }}>
          {dark ? <MoonStar size={24} fill="currentColor" strokeWidth={1.4} /> : <Sun size={25} fill="currentColor" strokeWidth={2.4} />}
        </span>
      </div>
      <div style={{ padding: "0 14px", borderRadius: 18, background: alpha(ink, 0.05) }}>
        {rows.map(([Icon, title, on, flip], i) => (
          <Fragment key={i}>
            {i > 0 && <div style={{ height: 0.5, background: alpha(ink, 0.1) }} />}
            <div style={{ height: 46, display: "flex", alignItems: "center", gap: 12 }}>
              <span style={{ width: 22, display: "grid", placeItems: "center", opacity: 0.7, transform: flip ? "scaleX(-1)" : undefined }}>
                <Icon size={17} strokeWidth={2.2} />
              </span>
              <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500 }}>{title[lang]}</span>
              <span style={{ flex: 1 }} />
              <span
                style={{
                  width: 42,
                  height: 26,
                  borderRadius: 13,
                  background: on ? Palette.mint : alpha(ink, 0.15),
                  padding: 3,
                  display: "flex",
                  justifyContent: on ? "flex-end" : "flex-start",
                }}
              >
                <span style={{ width: 20, height: 20, borderRadius: 10, background: "#fff", boxShadow: `0 1px 2px ${hex(0, 0.15)}` }} />
              </span>
            </div>
          </Fragment>
        ))}
      </div>
    </div>
  );
}
