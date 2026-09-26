/** icons.hamburger-morph · 菜单 ↔ 关闭形变 (Icons+Hamburger.swift) */
import { motion } from "motion/react";
import { Calendar, ChevronRight, Utensils } from "lucide-react";
import { useState, type ReactNode } from "react";
import { DemoHint, Palette, anim, delayed, fonts, glass, spring, textStyle, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { Glyph, SYM, circ, gear, rrect, sym, tintGradient, type GlyphDef } from "./_icons-kit";

const FIGURE_RUN: GlyphDef = [
  { d: circ(14.8, 3.5, 2.3), mode: "solid" },
  {
    d: "M12.8 7.4 10.4 13.2M10.4 13.2l3.8 2.4-1 5.4M10.4 13.2 8.2 17l-3.8 1.4M12.6 8l3.6 2.6 2.8-1M12.6 8 9 8.6l-2.4 3",
    mode: "stroke",
    sw: 2.7,
  },
];
const HOUSE_FILL: GlyphDef = [
  {
    d: "M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z",
    cut: { d: rrect(9.6, 13.4, 4.8, 8.6, 1), fill: true },
  },
];
const BOOKS_FILL: GlyphDef = [{ d: rrect(2.6, 4, 4.4, 17, 1) + rrect(8.2, 2.6, 4.4, 18.4, 1) + "M14.3 5.4 17.9 4.4l3.9 15.4-3.6 1Z", sw: 0.8 }];
const GEAR_FILL: GlyphDef = [{ d: gear(12, 12, 10.4, 7.8, 8, 3.2), mode: "solid", evenodd: true }];

const ITEMS: { en: string; zh: string; def: GlyphDef; tint: string }[] = [
  { en: "Home", zh: "首页", def: HOUSE_FILL, tint: Palette.indigo },
  { en: "Library", zh: "资料库", def: BOOKS_FILL, tint: Palette.violet },
  { en: "Favorites", zh: "收藏", def: SYM.heartFill, tint: Palette.pink },
  { en: "Settings", zh: "设置", def: GEAR_FILL, tint: Palette.sky },
];


export default function HamburgerMorph({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpen] = useState(false);
  const toggle = () => {
    setOpen((o) => !o);
    haptics.tap("light");
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.6 });
  const response = ctx.n("response");

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        style={{
          width: 300,
          height: 318,
          padding: 14,
          display: "flex",
          flexDirection: "column",
          gap: 12,
          background: Palette.surface,
          borderRadius: 28,
          overflow: "hidden",
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 10px 18px rgb(0 0 0 / 0.12)`,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <button
            type="button"
            onClick={toggle}
            style={{
              width: 52,
              height: 52,
              borderRadius: "50%",
              ...glass("regular"),
              boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 ${open ? 6 : 4}px ${open ? 12 : 8}px rgb(0 0 0 / ${open ? 0.16 : 0.08})`,
              transition: "box-shadow 0.3s",
              display: "grid",
              placeItems: "center",
              flexShrink: 0,
            }}
          >
            <HamburgerIcon open={open} response={response} damping={ctx.n("damping")} sequenced={ctx.b("sequenced")} spin={ctx.b("spin")} />
          </button>
          <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
            <span style={{ ...textStyle.title3, fontWeight: 700 }}>{ctx.t("Today", "今天")}</span>
            <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{ctx.t("Tuesday, June 9", "6月9日 星期二")}</span>
          </div>
          <div style={{ flex: 1 }} />
          <div style={{ width: 34, height: 34, borderRadius: "50%", background: Palette.sunset, display: "grid", placeItems: "center", color: "#fff", ...textStyle.subheadline, fontWeight: 700 }}>
            M
          </div>
        </div>
        <div style={{ position: "relative" }}>
          <motion.div
            animate={{ opacity: open ? 0.35 : 1, filter: `blur(${open ? 2 : 0}px)` }}
            transition={anim.easeOut(0.25)}
            style={{ pointerEvents: "none" }}
          >
            <Feed zh={ctx.lang === "zh"} />
          </motion.div>
          <div style={{ position: "absolute", left: 0, top: 0, width: 210, display: "flex", flexDirection: "column", gap: 6, pointerEvents: open ? "auto" : "none" }}>
            {ITEMS.map((item, i) => {
              const order = open ? i : ITEMS.length - 1 - i;
              const lead = open ? 0.1 : 0;
              return (
                <motion.div
                  key={i}
                  onClick={toggle}
                  initial={false}
                  animate={{ opacity: open ? 1 : 0, filter: `blur(${open ? 0 : 4}px)`, scale: open ? 1 : 0.9, y: open ? 0 : -14 - i * 8 }}
                  transition={delayed(spring(response, 0.8), lead + order * 0.045)}
                  style={{ transformOrigin: "50% 0%", cursor: "pointer" }}
                >
                  <MenuRow title={ctx.t(item.en, item.zh)} tint={item.tint} icon={<Glyph def={item.def} size={15} />} />
                </motion.div>
              );
            })}
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap the menu button" zh="点击菜单按钮" />
    </div>
  );
}

function MenuRow({ title, tint, icon }: { title: string; tint: string; icon: ReactNode }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 12,
        padding: "0 10px",
        height: 42,
        background: Palette.elevated,
        borderRadius: 13,
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 4px 8px rgb(0 0 0 / 0.06)`,
      }}
    >
      <div style={{ width: 28, height: 28, borderRadius: 8, background: tintGradient(tint), display: "grid", placeItems: "center", color: "#fff" }}>{icon}</div>
      <span style={{ ...textStyle.subheadline, fontWeight: 600 }}>{title}</span>
      <div style={{ flex: 1 }} />
      <ChevronRight size={12} strokeWidth={3.4} color={Palette.tertiaryLabel} />
    </div>
  );
}

function Feed({ zh }: { zh: boolean }) {
  const row = (title: string, detail: string, icon: ReactNode, tint: string) => (
    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: 8, background: Palette.elevated, borderRadius: 14 }}>
      <div style={{ width: 30, height: 30, borderRadius: 9, background: tintGradient(tint), display: "grid", placeItems: "center", color: "#fff" }}>{icon}</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
        <span style={{ ...textStyle.subheadline, fontWeight: 600 }}>{title}</span>
        <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{detail}</span>
      </div>
    </div>
  );
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      <div style={{ position: "relative", height: 104, borderRadius: 18, overflow: "hidden", background: `linear-gradient(135deg, ${Palette.indigo}, ${Palette.violet})` }}>
        <div style={{ position: "absolute", right: 16, top: 0, bottom: 0, display: "grid", placeItems: "center", color: "rgb(255 255 255 / 0.25)" }}>
          <Glyph def={FIGURE_RUN} size={sym(54)} />
        </div>
        <div style={{ position: "absolute", left: 14, bottom: 14, display: "flex", flexDirection: "column", gap: 2, color: "#fff" }}>
          <span style={{ ...textStyle.headline }}>{zh ? "晨跑" : "Morning run"}</span>
          <span style={{ ...textStyle.caption, fontWeight: 500, opacity: 0.85 }}>{zh ? "5.2 公里 · 28 分钟 · 新纪录" : "5.2 km · 28 min · new best"}</span>
        </div>
      </div>
      {row(zh ? "设计评审" : "Design review", zh ? "10:30 · B 工作室" : "10:30 · Studio B", <Calendar size={15} strokeWidth={2.6} />, Palette.coral)}
      {row(zh ? "和 Mia 午餐" : "Lunch with Mia", zh ? "12:45 · 露台" : "12:45 · Terrace", <Utensils size={15} strokeWidth={2.6} />, Palette.mint)}
    </div>
  );
}

function HamburgerIcon({ open, response, damping, sequenced, spin }: { open: boolean; response: number; damping: number; sequenced: boolean; spin: boolean }) {
  const s = spring(response, damping);
  const gap = sequenced ? 0.12 : 0;
  const bar = (rotation: number, offset: number) => (
    <motion.div
      initial={false}
      animate={{ rotate: open ? rotation : 0, y: open ? 0 : offset }}
      transition={{ rotate: delayed(s, open ? gap : 0), y: delayed(s, open ? 0 : gap) }}
      style={{ position: "absolute", left: 0, top: 0, width: 24, height: 3, borderRadius: 1.5, background: Palette.label }}
    />
  );
  return (
    <motion.div
      initial={false}
      animate={{ rotate: spin && open ? 180 : 0 }}
      transition={delayed(s, open ? gap : 0)}
      style={{ position: "relative", width: 24, height: 3, fontFamily: fonts.text }}
    >
      {bar(45, -7)}
      <motion.div
        initial={false}
        animate={{ scaleX: open ? 0.01 : 1, opacity: open ? 0 : 1 }}
        transition={s}
        style={{ position: "absolute", left: 0, top: 0, width: 24, height: 3, borderRadius: 1.5, background: Palette.label }}
      />
      {bar(-45, 7)}
    </motion.div>
  );
}
