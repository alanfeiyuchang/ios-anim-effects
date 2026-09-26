/** navigation.parallax-drawer · 视差抽屉 (Navigation+ParallaxDrawer.swift) */
import { animate, useMotionValue } from "motion/react";
import { Folder, House, Inbox, Menu, Settings, Star, type LucideIcon } from "lucide-react";
import { useRef } from "react";
import { DemoHint, Palette, PlaceholderLines, clamp, rubberBand, spring, useAutoplay, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { colorGradient, predicted, useMotionNumber, useNavPan } from "./nav-util";

const TRAVEL = 170;

const parallaxMenu: [LucideIcon, boolean, string, string][] = [
  [House, true, "Home", "首页"],
  [Inbox, false, "Inbox", "收件箱"],
  [Star, true, "Starred", "星标"],
  [Folder, true, "Projects", "项目"],
  [Settings, false, "Settings", "设置"],
];

export default function ParallaxDrawer({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const progress = useMotionValue(0);
  const value = useMotionNumber(progress);
  const dragStart = useRef<number | null>(null);

  const settle = (open: boolean) => {
    haptics.tap(open ? "medium" : "light");
    animate(progress, open ? 1 : 0, spring(ctx.n("response"), 0.84));
  };

  const pan = useNavPan(
    {
      onChange: (s) => {
        if (dragStart.current === null) {
          dragStart.current = progress.get();
          progress.stop();
        }
        const raw = dragStart.current + s.translation.x / TRAVEL;
        if (raw > 1) progress.set(1 + rubberBand((raw - 1) * TRAVEL, 30) / TRAVEL);
        else if (raw < 0) progress.set(rubberBand(raw * TRAVEL, 16) / TRAVEL);
        else progress.set(raw);
      },
      onEnd: (s) => {
        const start = dragStart.current ?? progress.get();
        dragStart.current = null;
        const projected = s ? start + predicted(s).x / TRAVEL : progress.get();
        settle(projected > 0.5);
      },
    },
    { axis: "horizontal" },
  );

  useAutoplay(ctx.isPreview, () => settle(progress.get() < 0.5), { every: 1.7 });

  const p = clamp(value);
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        {...pan}
        style={{ position: "relative", width: 250, height: 320, flexShrink: 0, borderRadius: 34, overflow: "hidden", boxShadow: "0 10px 18px rgb(0 0 0 / 0.18)", isolation: "isolate" }}
      >
        <MenuLayer ctx={ctx} progress={value} />
        <div
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            width: 250,
            height: 320,
            transform: `translateX(${TRAVEL * value}px)`,
            borderRadius: 22 * p + 2,
            boxShadow: p > 0 ? `-4px 0 20px rgb(0 0 0 / ${0.35 * p})` : undefined,
          }}
        >
          <div
            style={{
              position: "absolute",
              inset: 0,
              borderRadius: 22 * p + 2,
              overflow: "hidden",
              background: Palette.elevated,
              padding: 16,
              display: "flex",
              flexDirection: "column",
              gap: 14,
            }}
          >
            <div style={{ display: "flex", alignItems: "center" }}>
              <button
                type="button"
                onClick={() => settle(progress.get() < 0.5)}
                style={{ width: 36, height: 36, borderRadius: "50%", background: Palette.surface, display: "grid", placeItems: "center", color: Palette.label }}
              >
                <Menu size={18} strokeWidth={2.4} />
              </button>
              <span style={{ flex: 1, textAlign: "center", fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{ctx.t("Feed", "动态")}</span>
              <span style={{ width: 36, height: 36 }} />
            </div>
            {[0, 1, 2].map((index) => (
              <div key={index} style={{ display: "flex", alignItems: "center", gap: 10, padding: 12, borderRadius: 16, background: Palette.surface }}>
                <div style={{ width: 34, height: 34, borderRadius: "50%", background: colorGradient(Palette.spectrum[index + 2]), flexShrink: 0 }} />
                <div style={{ flex: 1 }}>
                  <PlaceholderLines count={2} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag the page right" zh="向右拖动页面" />
    </div>
  );
}

function MenuLayer({ ctx, progress }: { ctx: DemoContext; progress: number }) {
  const p = clamp(progress);
  const parallax = ctx.n("parallax");
  const depth = ctx.n("depth");
  const layerOffset = -TRAVEL * parallax * (1 - p);
  const scale = depth + (1 - depth) * p;
  const rowProgress = (index: number) => {
    const s = Math.min(ctx.n("stagger"), 0.15);
    const span = Math.max(1 - s * parallaxMenu.length, 0.2);
    return clamp((p - s * index) / span);
  };
  return (
    <div style={{ position: "absolute", inset: 0, background: "linear-gradient(180deg, #0F3A3C, #071B20)" }}>
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          paddingTop: 28,
          paddingLeft: 20,
          display: "flex",
          flexDirection: "column",
          gap: 6,
          alignItems: "flex-start",
          color: "#fff",
          transformOrigin: "0% 50%",
          transform: `translateX(${layerOffset}px) scale(${scale})`,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10, paddingBottom: 14, opacity: rowProgress(0) }}>
          <div style={{ width: 38, height: 38, borderRadius: "50%", background: Palette.sunset }} />
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 700 }}>Mia Chen</span>
            <span style={{ fontSize: 12, lineHeight: "16px", opacity: 0.6 }}>{ctx.t("Designer", "设计师")}</span>
          </div>
        </div>
        {parallaxMenu.map(([Icon, filled, en, zh], index) => {
          const local = rowProgress(index + 1);
          return (
            <div
              key={en}
              style={{ display: "flex", alignItems: "center", gap: 12, padding: "9px 0", opacity: local, transform: `translateX(${-30 * (1 - local)}px)` }}
            >
              <span style={{ width: 22, display: "grid", placeItems: "center" }}>
                <Icon size={16} strokeWidth={2.4} fill={filled ? "currentColor" : "none"} />
              </span>
              <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{ctx.t(en, zh)}</span>
            </div>
          );
        })}
      </div>
      <div style={{ position: "absolute", inset: 0, background: "#000", opacity: 0.5 * (1 - p), pointerEvents: "none" }} />
    </div>
  );
}
