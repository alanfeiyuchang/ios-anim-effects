/** navigation.elastic-drawer · 弹性抽屉 (Navigation+ElasticDrawer.swift) */
import { animate, useMotionValue } from "motion/react";
import { Bookmark, Flame, Settings, Sparkles, type LucideIcon } from "lucide-react";
import { useRef } from "react";
import { DemoHint, Palette, anim, clamp, hex, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { predicted, useMotionNumber, useNavPan } from "./nav-util";

const OPEN_WIDTH = 190;
const W = 250;
const H = 320;

const items: [LucideIcon, boolean, string, string][] = [
  [Sparkles, false, "For You", "推荐"],
  [Flame, true, "Trending", "热门"],
  [Bookmark, true, "Saved", "收藏"],
  [Settings, false, "Settings", "设置"],
];

/** `BulgeDrawerShape`: the drawer's right edge with a Bézier bulge (or dent) centred at `bulgeY`. */
function bulgePath(width: number, bulge: number, bulgeY: number) {
  const edge = Math.max(width, 0);
  const spread = 110;
  const top = bulgeY - spread;
  const bottom = bulgeY + spread;
  return [
    `M0 0`,
    `L${edge} 0`,
    `L${edge} ${top}`,
    `C${edge} ${top + spread * 0.45} ${edge + bulge} ${bulgeY - spread * 0.4} ${edge + bulge} ${bulgeY}`,
    `C${edge + bulge} ${bulgeY + spread * 0.4} ${edge} ${bottom - spread * 0.45} ${edge} ${bottom}`,
    `L${edge} ${H}`,
    `L0 ${H}`,
    `Z`,
  ].join(" ");
}

export default function ElasticDrawer({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const widthMV = useMotionValue(0);
  const bulgeMV = useMotionValue(0);
  const bulgeYMV = useMotionValue(160);
  const width = useMotionNumber(widthMV);
  const bulge = useMotionNumber(bulgeMV);
  const bulgeY = useMotionNumber(bulgeYMV);
  const dragStart = useRef<number | null>(null);
  const ignoring = useRef(false);
  const run = useRef(0);

  const openness = clamp(width / OPEN_WIDTH);

  const settle = (open: boolean, buzz = true) => {
    run.current += 1;
    if (buzz) haptics.tap(open ? "medium" : "light");
    const t = spring(0.55, ctx.n("damping"));
    animate(widthMV, open ? OPEN_WIDTH : 0, t);
    animate(bulgeMV, 0, t);
  };

  const pan = useNavPan(
    {
      onChange: (s) => {
        if (ignoring.current) return;
        if (dragStart.current === null && widthMV.get() < OPEN_WIDTH / 2 && s.start.x > widthMV.get() + 44) {
          ignoring.current = true;
          return;
        }
        if (dragStart.current === null) {
          dragStart.current = widthMV.get();
          run.current += 1;
          widthMV.stop();
          bulgeMV.stop();
          bulgeYMV.stop();
        }
        const raw = dragStart.current + s.translation.x * 0.8;
        const clamped = clamp(raw, 0, OPEN_WIDTH + 20);
        const lead = s.location.x - clamped;
        const limit = ctx.n("bulge");
        widthMV.set(clamped);
        if (s.translation.x < 0) bulgeMV.set(-Math.min(Math.abs(lead) * 0.5, limit * 0.6));
        else bulgeMV.set(clamp(lead * 0.5, -limit * 0.6, limit));
        bulgeYMV.set(clamp(s.location.y, 40, H - 40));
      },
      onEnd: (s) => {
        if (ignoring.current) {
          ignoring.current = false;
          return;
        }
        const start = dragStart.current ?? widthMV.get();
        dragStart.current = null;
        const projected = s ? start + predicted(s).x * 0.8 : widthMV.get();
        settle(projected > OPEN_WIDTH / 2);
      },
    },
    { axis: "horizontal" },
  );

  /** Preview: pull out with a bulge, then let go; or push it closed. */
  const simulatePull = () => {
    // Autoplay is always silent, so the settle in the completion stays quiet too.
    run.current += 1;
    const token = run.current;
    const opening = widthMV.get() <= OPEN_WIDTH / 2;
    const t = anim.easeOut(opening ? 0.28 : 0.2);
    animate(widthMV, OPEN_WIDTH * (opening ? 0.6 : 0.55), t).then(() => {
      if (token !== run.current) return;
      settle(opening, false);
    });
    animate(bulgeMV, opening ? ctx.n("bulge") : -ctx.n("bulge") * 0.5, t);
    animate(bulgeYMV, opening ? 130 : 200, t);
  };
  useAutoplay(ctx.isPreview, simulatePull, { every: 1.9 });

  const path = bulgePath(width, bulge, bulgeY);
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        {...pan}
        style={{ position: "relative", width: W, height: H, flexShrink: 0, borderRadius: 34, overflow: "hidden", boxShadow: "0 10px 18px rgb(0 0 0 / 0.18)", isolation: "isolate" }}
      >
        {/* Page */}
        <div style={{ position: "absolute", inset: 0, background: Palette.elevated, padding: "28px 18px 18px", display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{ctx.t("Discover", "发现")}</div>
          {[0, 1, 2].map((index) => (
            <div key={index} style={{ height: 64, borderRadius: 16, background: hex(Palette.spectrum[index + 1], 0.25), flexShrink: 0 }} />
          ))}
        </div>
        <div style={{ position: "absolute", inset: 0, background: "#000", opacity: ctx.b("dim") ? 0.3 * openness : 0, pointerEvents: "none" }} />
        {/* Drawer membrane */}
        <svg width={W} height={H} style={{ position: "absolute", left: 0, top: 0, overflow: "visible", pointerEvents: "none", filter: `drop-shadow(4px 0 14px ${hex(Palette.indigo, 0.4)})` }}>
          <defs>
            <linearGradient id="elastic-drawer-fill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor={Palette.violet} />
              <stop offset="1" stopColor={Palette.indigo} />
            </linearGradient>
          </defs>
          <path d={path} fill="url(#elastic-drawer-fill)" />
        </svg>
        <div style={{ position: "absolute", inset: 0, clipPath: `path("${path}")`, pointerEvents: "none" }}>
          <div
            style={{
              paddingTop: 44,
              paddingLeft: 22,
              display: "flex",
              flexDirection: "column",
              gap: 18,
              color: "#fff",
              opacity: openness,
              transform: `translateX(${(openness - 1) * 40}px)`,
            }}
          >
            {items.map(([Icon, filled, en, zh]) => (
              <div key={en} style={{ display: "flex", alignItems: "center", gap: 12, fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>
                <span style={{ width: 20, display: "grid", placeItems: "center" }}>
                  <Icon size={15} strokeWidth={2.4} fill={filled ? "currentColor" : "none"} />
                </span>
                {ctx.t(en, zh)}
              </div>
            ))}
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Drag from the left edge" zh="从左边缘向右拖动" />
    </div>
  );
}
