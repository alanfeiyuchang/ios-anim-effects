/** navigation.popout-drawer · 弹出式抽屉 (Navigation+PopoutDrawer.swift) */
import { motion, type TargetAndTransition } from "motion/react";
import { Calendar, ChartPie, LayoutGrid, Settings, Users, type LucideIcon } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, delayed, glass, hex, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";

const popoutItems: [LucideIcon, boolean, string, string][] = [
  [LayoutGrid, true, "Dashboard", "仪表盘"],
  [Users, true, "Team", "团队"],
  [Calendar, false, "Schedule", "日程"],
  [ChartPie, false, "Reports", "报表"],
  [Settings, false, "Settings", "设置"],
];

export default function PopoutDrawer({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpen] = useState(false);
  const sp = spring(ctx.n("response"), ctx.n("damping"));

  const toggle = () => {
    haptics.tap(open ? "light" : "medium");
    setOpen((o) => !o);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.6 });

  const bar = (style: TargetAndTransition) => (
    <motion.div
      initial={false}
      animate={style}
      transition={sp}
      style={{ position: "absolute", left: -8, top: -1.1, width: 16, height: 2.2, borderRadius: 1.1, background: Palette.label }}
    />
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ position: "relative", width: 250, height: 320, flexShrink: 0, borderRadius: 34, overflow: "hidden", boxShadow: "0 10px 18px rgb(0 0 0 / 0.18)", isolation: "isolate" }}>
        {/* Page */}
        <motion.div
          initial={false}
          animate={{ filter: `blur(${open ? 6 : 0}px)`, scale: open ? 0.96 : 1 }}
          transition={anim.easeInOut(0.3)}
          onClick={() => open && toggle()}
          style={{ position: "absolute", inset: 0 }}
        >
          <div style={{ position: "absolute", inset: 0, background: Palette.elevated, padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
            <div style={{ paddingLeft: 52, paddingTop: 6, fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{ctx.t("Overview", "概览")}</div>
            <div style={{ display: "flex", gap: 10 }}>
              {[Palette.indigo, Palette.mint].map((c) => (
                <div key={c} style={{ position: "relative", flex: 1, height: 76, borderRadius: 18, background: hex(c, 0.18) }}>
                  <div style={{ position: "absolute", left: 14, bottom: 14, width: 40, height: 6, borderRadius: 3, background: c }} />
                </div>
              ))}
            </div>
            <div style={{ height: 110, borderRadius: 18, background: Palette.surface, padding: 16, display: "flex", flexDirection: "column", justifyContent: "center" }}>
              <PlaceholderLines count={3} />
            </div>
          </div>
          <motion.div
            initial={false}
            animate={{ opacity: open ? 0.18 : 0 }}
            transition={anim.easeInOut(0.3)}
            style={{ position: "absolute", inset: 0, background: "#000", pointerEvents: "none" }}
          />
        </motion.div>
        {/* Panel */}
        <motion.div
          initial={false}
          animate={{ scale: open ? 1 : 0.2, opacity: open ? 1 : 0 }}
          transition={sp}
          style={{
            position: "absolute",
            left: 10,
            top: 10,
            width: 190,
            height: 250,
            transformOrigin: "0 0",
            pointerEvents: open ? "auto" : "none",
            borderRadius: 26,
            boxShadow: "0 10px 20px rgb(0 0 0 / 0.2)",
          }}
        >
          <div
            style={{
              position: "absolute",
              inset: 0,
              borderRadius: 26,
              ...glass("thin"),
              boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.25)",
              padding: "52px 10px 0",
              display: "flex",
              flexDirection: "column",
              gap: 4,
            }}
          >
            {popoutItems.map(([Icon, filled, en, zh], index) => (
              <motion.div
                key={en}
                initial={false}
                animate={{ opacity: open ? 1 : 0, filter: `blur(${open ? 0 : 4}px)`, y: open ? 0 : -8 }}
                transition={delayed(spring(0.35, 0.8), open ? 0.08 + index * ctx.n("stagger") : 0)}
                onClick={toggle}
                style={{ height: 36, padding: "0 10px", display: "flex", alignItems: "center", gap: 12, cursor: "pointer" }}
              >
                <span style={{ width: 22, display: "grid", placeItems: "center", color: Palette.indigo }}>
                  <Icon size={16} strokeWidth={2.4} fill={filled ? "currentColor" : "none"} />
                </span>
                <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{ctx.t(en, zh)}</span>
              </motion.div>
            ))}
          </div>
        </motion.div>
        {/* Menu button */}
        <button
          type="button"
          onClick={toggle}
          style={{
            position: "absolute",
            left: 14,
            top: 14,
            width: 38,
            height: 38,
            borderRadius: "50%",
            background: Palette.surface,
            boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
          }}
        >
          <div style={{ position: "absolute", left: 19, top: 19 }}>
            {bar({ rotate: open ? 45 : 0, y: open ? 0 : -5 })}
            {bar({ scaleX: open ? 0.1 : 1, opacity: open ? 0 : 1 })}
            {bar({ rotate: open ? -45 : 0, y: open ? 0 : 5 })}
          </div>
        </button>
      </div>
      <DemoHint ctx={ctx} en="Tap the menu button" zh="点击菜单按钮" />
    </div>
  );
}
