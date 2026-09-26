/** navigation.side-drawer-3d · 3D 侧边抽屉 (Navigation+SideDrawer.swift) */
import { animate, useMotionValue } from "motion/react";
import { ChartColumn, House, Inbox, Menu, Send, Settings, Star, Users, Footprints, type LucideIcon } from "lucide-react";
import { useRef } from "react";
import { DemoHint, Palette, clamp, rubberBand, spring, useAutoplay, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { predicted, useMotionNumber, useNavPan } from "./nav-util";

const TRAVEL = 150;
const W = 250;
const H = 320;

const drawerItems: [LucideIcon, string, string][] = [
  [House, "Home", "首页"],
  [Inbox, "Inbox", "收件箱"],
  [Star, "Starred", "星标"],
  [ChartColumn, "Insights", "洞察"],
  [Settings, "Settings", "设置"],
];

export default function SideDrawer3D({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const progress = useMotionValue(0);
  const p = useMotionNumber(progress);
  const dragStart = useRef<number | null>(null);

  const settle = (open: boolean) => {
    haptics.tap(open ? "medium" : "light");
    animate(progress, open ? 1 : 0, spring(ctx.n("response"), 0.82));
  };
  const toggle = () => settle(progress.get() < 0.5);

  const pan = useNavPan(
    {
      onChange: (s) => {
        const start = dragStart.current ?? progress.get();
        if (dragStart.current === null) {
          dragStart.current = progress.get();
          progress.stop();
        }
        const raw = start + s.translation.x / TRAVEL;
        if (raw > 1) progress.set(1 + rubberBand((raw - 1) * TRAVEL, 30) / TRAVEL);
        else if (raw < 0) progress.set(rubberBand(raw * TRAVEL, 20) / TRAVEL);
        else progress.set(raw);
      },
      onEnd: (s) => {
        const start = dragStart.current ?? progress.get();
        dragStart.current = null;
        const projected = s ? start + predicted(s).x / TRAVEL : progress.get();
        settle(projected > 0.5);
      },
    },
    { axis: "horizontal", minimumDistance: 10 },
  );

  useAutoplay(ctx.isPreview, toggle, { every: 1.8 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        {...pan}
        style={{
          position: "relative",
          width: W,
          height: H,
          flexShrink: 0,
          borderRadius: 34,
          overflow: "hidden",
          boxShadow: "0 10px 18px rgb(0 0 0 / 0.18)",
          background: "linear-gradient(135deg, #1A1F4D, #3B2A7A)",
          isolation: "isolate",
        }}
      >
        <DrawerMenu progress={p} ctx={ctx} />
        <Page ctx={ctx} p={p} ghost onMenu={toggle} />
        <Page ctx={ctx} p={p} ghost={false} onMenu={toggle} />
      </div>
      <DemoHint ctx={ctx} en="Tap ☰ or drag right to open the menu" zh="点击 ☰ 或向右拖动打开菜单" />
    </div>
  );
}

function Page({ ctx, p: raw, ghost, onMenu }: { ctx: DemoContext; p: number; ghost: boolean; onMenu: () => void }) {
  const p = clamp(raw, -0.1, 1.1);
  const depth = ghost ? 0.7 : 1;
  const scale = 1 - (1 - ctx.n("scale")) * p * (ghost ? 1.18 : 1);
  const shown = clamp(p);
  const radius = 26 * shown + 1;
  const alpha = ghost ? 0.35 * shown : 1;
  const shadowAlpha = ghost ? 0 : 0.3 * shown;
  const degrees = ctx.n("angle") * p * depth;
  // rotation3DEffect(anchor: .leading, perspective: 0.6): the projection distance is max(w, h) / perspective.
  const persp = Math.max(W, H) / 0.6;
  const transform = [
    `translateX(${TRAVEL * p * depth}px)`,
    `translate(0px, ${H / 2}px)`,
    `perspective(${persp}px)`,
    `rotateY(${degrees}deg)`,
    `translate(0px, ${-H / 2}px)`,
    `translate(${W / 2}px, ${H / 2}px)`,
    `scale(${scale})`,
    `translate(${-W / 2}px, ${-H / 2}px)`,
  ].join(" ");
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        transformOrigin: "0 0",
        transform,
        opacity: alpha,
        pointerEvents: ghost ? "none" : undefined,
        borderRadius: radius,
        boxShadow: shadowAlpha > 0 ? `-6px 10px 24px rgb(0 0 0 / ${shadowAlpha})` : undefined,
      }}
    >
      <div style={{ position: "absolute", inset: 0, borderRadius: radius, overflow: "hidden" }}>
        <DrawerPage ctx={ctx} onMenu={onMenu} />
      </div>
    </div>
  );
}

function DrawerMenu({ progress, ctx }: { progress: number; ctx: DemoContext }) {
  const reveal = (index: number) => {
    const start = 0.15 + index * 0.08;
    const local = clamp((progress - start) / 0.45);
    return { opacity: local, transform: `translateX(${-20 * (1 - local)}px)` };
  };
  return (
    <div style={{ position: "absolute", left: 24, top: 24, display: "flex", flexDirection: "column", gap: 18, alignItems: "flex-start", color: "#fff" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, ...reveal(0) }}>
        <div style={{ width: 38, height: 38, borderRadius: "50%", background: Palette.sunset, display: "grid", placeItems: "center", fontSize: 17, fontWeight: 600 }}>A</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>Alex Chen</span>
          <span style={{ fontSize: 12, lineHeight: "16px", opacity: 0.6 }}>{ctx.t("Pro plan", "专业版")}</span>
        </div>
      </div>
      {drawerItems.map(([Icon, en, zh], index) => (
        <div
          key={en}
          style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 15, lineHeight: "20px", fontWeight: 500, ...reveal(index + 1), opacity: reveal(index + 1).opacity * (index === 0 ? 1 : 0.75) }}
        >
          <span style={{ width: 20, display: "grid", placeItems: "center" }}>
            <Icon size={16} strokeWidth={2.4} fill={Icon === ChartColumn || Icon === Inbox ? "none" : "currentColor"} />
          </span>
          {ctx.t(en, zh)}
        </div>
      ))}
    </div>
  );
}

const agenda: [LucideIcon, string, string, string, string][] = [
  [Users, Palette.violet, "Design review", "设计评审", "10:00"],
  [Send, Palette.sky, "Ship motion specs", "发布动效规范", "14:30"],
  [Footprints, Palette.coral, "Evening run", "傍晚跑步", "18:00"],
];

function DrawerPage({ ctx, onMenu }: { ctx: DemoContext; onMenu: () => void }) {
  return (
    <div style={{ position: "absolute", inset: 0, padding: 16, display: "flex", flexDirection: "column", gap: 12, background: Palette.background, color: Palette.label }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <button
          type="button"
          onClick={onMenu}
          style={{ width: 38, height: 38, borderRadius: "50%", background: Palette.labelAlpha(0.07), display: "grid", placeItems: "center", color: Palette.label }}
        >
          <Menu size={18} strokeWidth={2.4} />
        </button>
        <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{ctx.t("Home", "首页")}</span>
      </div>
      <div style={{ position: "relative", height: 90, borderRadius: 20, background: Palette.aurora, flexShrink: 0 }}>
        <div style={{ position: "absolute", left: 14, bottom: 14, display: "flex", flexDirection: "column", gap: 2, color: "#fff" }}>
          <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, whiteSpace: "nowrap" }}>{ctx.t("Good morning, Alex", "早上好，Alex")}</span>
          <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, opacity: 0.85, whiteSpace: "nowrap" }}>{ctx.t("3 things on today", "今天有 3 项安排")}</span>
        </div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {agenda.map(([Icon, color, en, zh, time]) => (
          <div key={en} style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{ width: 28, height: 28, borderRadius: 8, background: `color-mix(in srgb, ${color} 14%, transparent)`, color, display: "grid", placeItems: "center", flexShrink: 0 }}>
              <Icon size={13} strokeWidth={2.6} fill={Icon === Send ? "currentColor" : "none"} />
            </div>
            <span style={{ flex: 1, minWidth: 0, fontSize: 15, lineHeight: "20px", fontWeight: 500, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{ctx.t(en, zh)}</span>
            <span style={{ marginLeft: 4, fontSize: 12, lineHeight: "16px", fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>{time}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
