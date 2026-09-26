/** icons.search-close · 放大镜 → 关闭 (Icons+SearchClose.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useTransform } from "motion/react";
import { useEffect, useState } from "react";
import { DemoHint, Palette, spring, textStyle, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";

const W = 24;
const mixP = (a: [number, number], b: [number, number], t: number): [number, number] => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];

/** progress 0 = magnifier, 1 = X. */
function glyphPath(progress: number) {
  const p = Math.min(Math.max(progress, 0), 1.08);
  const c = W * 0.42;
  const radius = W * 0.27;
  const diag = 0.70710678;
  let path = "";
  // Lens: an arc that starts at the handle (45°) and shrinks away from it.
  const lens = Math.max(0, 1 - p);
  if (lens > 0.001) {
    const sweep = 360 * lens;
    const pt = (deg: number) => {
      const a = (deg * Math.PI) / 180;
      return `${(c + radius * Math.cos(a)).toFixed(3)} ${(c + radius * Math.sin(a)).toFixed(3)}`;
    };
    const mid = 45 + sweep / 2;
    path += `M${pt(45)}A${radius} ${radius} 0 0 1 ${pt(mid)}A${radius} ${radius} 0 0 1 ${pt(45 + sweep)}`;
  }
  // Handle → "\" diagonal.
  const t = Math.min(p, 1);
  const hs = mixP([c + radius * diag, c + radius * diag], [W * 0.2, W * 0.2], t);
  const he = mixP([W * 0.86, W * 0.86], [W * 0.8, W * 0.8], t);
  path += `M${hs[0]} ${hs[1]}L${he[0]} ${he[1]}`;
  // "/" diagonal grows from the centre after 40%.
  const grow = Math.max(0, (p - 0.4) / 0.6);
  if (grow > 0.001) {
    const half = W * 0.3 * grow;
    path += `M${W / 2 + half} ${W / 2 - half}L${W / 2 - half} ${W / 2 + half}`;
  }
  return path;
}

export default function SearchClose({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpen] = useState(false);
  const response = ctx.n("response");
  const damping = ctx.n("damping");
  const s = spring(response, damping);
  const progress = useMotionValue(0);
  const d = useTransform(progress, glyphPath);
  useEffect(() => {
    const a = animate(progress, open ? 1 : 0, spring(response, damping));
    return () => a.stop();
  }, [open, response, damping, progress]);

  const toggle = () => {
    haptics.tap("light");
    setOpen((o) => !o);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.8 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <motion.div
        initial={false}
        animate={{ width: open ? 270 : 56 }}
        transition={s}
        style={{ position: "relative", height: 56, borderRadius: 28, boxShadow: `0 8px 16px rgb(0 0 0 / 0.14)`, display: "flex", alignItems: "center", gap: 10 }}
      >
        <div style={{ position: "absolute", inset: 0, borderRadius: 28, background: Palette.primary }} />
        <motion.div initial={false} animate={{ opacity: open ? 1 : 0 }} transition={s} style={{ position: "absolute", inset: 0, borderRadius: 28, background: Palette.elevated }} />
        <div style={{ position: "absolute", inset: 0, borderRadius: 28, boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }} />
        <div style={{ position: "relative", flex: 1, minWidth: 0, overflow: "hidden", height: 56, display: "flex", alignItems: "center" }}>
          <AnimatePresence>
            {open && (
              <motion.div
                initial={{ opacity: 0, x: -12 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -12 }}
                transition={s}
                style={{ display: "flex", alignItems: "center", gap: 2, paddingLeft: 20, whiteSpace: "nowrap", ...textStyle.body }}
              >
                <span style={{ color: Palette.tertiaryLabel }}>{ctx.t("Search places", "搜索地点")}</span>
                <Caret />
              </motion.div>
            )}
          </AnimatePresence>
        </div>
        <button type="button" onClick={toggle} style={{ position: "relative", width: 56, height: 56, flexShrink: 0, display: "grid", placeItems: "center" }}>
          <svg width={24} height={24} viewBox="0 0 24 24" style={{ overflow: "visible" }}>
            <motion.path
              d={d}
              fill="none"
              stroke={open ? Palette.secondaryLabel : "#fff"}
              strokeWidth={ctx.n("weight")}
              strokeLinecap="round"
              strokeLinejoin="round"
              style={{ transition: "stroke 0.3s" }}
            />
          </svg>
        </button>
      </motion.div>
      <DemoHint ctx={ctx} en="Tap the icon" zh="点击图标" />
    </div>
  );
}

function Caret() {
  useClock(true, 4);
  const on = Math.floor(Date.now() / 500) % 2 === 0;
  return <div style={{ width: 2, height: 20, background: Palette.indigo, opacity: on ? 1 : 0 }} />;
}
