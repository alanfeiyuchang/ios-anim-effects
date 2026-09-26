/** morph.folder-open · 文件夹展开 (Morph+FolderOpen.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useTransform } from "motion/react";
import { Aperture, Brush, Calendar, Compass, Image, Map, MessageCircle, Music, NotebookText, Settings, Signature, WandSparkles } from "lucide-react";
import { useEffect, useState } from "react";
import { DemoHint, Palette, black, glass, hex, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { LayoutRoot, vert } from "./_shared";

interface App {
  Icon: typeof Music;
  fill?: boolean;
  colors: string[];
  name: [string, string];
}

const homeApps: App[] = [
  { Icon: MessageCircle, fill: true, colors: [Palette.green, Palette.mint], name: ["Messages", "信息"] },
  { Icon: Compass, colors: [Palette.sky, Palette.blue], name: ["Safari", "Safari"] },
  { Icon: Music, colors: [Palette.pink, Palette.red], name: ["Music", "音乐"] },
  { Icon: Image, colors: [Palette.amber, Palette.coral], name: ["Photos", "照片"] },
  { Icon: Calendar, colors: [Palette.red, Palette.coral], name: ["Calendar", "日历"] },
  { Icon: Map, colors: [Palette.mint, Palette.green], name: ["Maps", "地图"] },
  { Icon: NotebookText, colors: [Palette.amber, "#FFD66B"], name: ["Notes", "备忘录"] },
  { Icon: Settings, colors: ["#8E8E93", "#5A5A60"], name: ["Settings", "设置"] },
];

const folderApps: App[] = [
  { Icon: Brush, colors: [Palette.violet, Palette.pink], name: ["Sketch", "草图"] },
  { Icon: Aperture, colors: [Palette.indigo, Palette.sky], name: ["Lens", "镜头"] },
  { Icon: WandSparkles, colors: [Palette.pink, Palette.coral], name: ["Motion", "动效"] },
  { Icon: Signature, colors: [Palette.mint, Palette.sky], name: ["Ink", "墨迹"] },
];

const SCREEN = 316;

export default function FolderOpen({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpen] = useState(false);
  const lang = ctx.lang === "zh" ? 1 : 0;
  const spr = spring(ctx.n("response"), ctx.n("damping"));
  const recede = open && ctx.b("recede");

  // Blur and fade of the receding icons ride the same spring; at rest they are cleared entirely
  // (a lingering `filter` / opacity would cut the folder's glass off from the wallpaper).
  const r = useMotionValue(0);
  useEffect(() => {
    const controls = animate(r, recede ? 1 : 0, spr);
    return () => controls.stop();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [recede]);
  const gridFilter = useTransform(r, (v) => (v < 0.002 ? "none" : `blur(${Math.max(0, 6 * v)}px)`));
  const gridOpacity = useTransform(r, (v) => (v < 0.002 ? 1 : 1 - 0.55 * v));
  const gridScale = useTransform(r, (v) => 1 - 0.12 * v);

  const setOpenTo = (value: boolean) => {
    if (value === open) return;
    haptics.tap(value ? "medium" : "light");
    setOpen(value);
  };
  useAutoplay(ctx.isPreview, () => setOpenTo(!open), { every: 1.8 });

  const label = (text: string) => (
    <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 500, color: "#fff", whiteSpace: "nowrap", textShadow: `0 1px 2px ${black(0.25)}` }}>{text}</span>
  );

  return (
    <LayoutRoot style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        style={{
          position: "relative",
          width: SCREEN,
          height: SCREEN,
          borderRadius: 38,
          overflow: "hidden",
          boxShadow: `0 14px 24px ${hex(0x4b3aa8, 0.28)}`,
          flexShrink: 0,
        }}
      >
        <Wallpaper />
        <motion.div initial={false} animate={{ opacity: open ? 0.15 : 0 }} transition={spr} style={{ position: "absolute", inset: 0, background: "#000" }} />
        <motion.div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            gap: 16,
            scale: gridScale,
            filter: gridFilter,
            opacity: gridOpacity,
          }}
        >
          {[0, 1, 2].map((row) => (
            <div key={row} style={{ display: "flex", gap: 14 }}>
              {[0, 1, 2].map((column) => {
                const slot = row * 3 + column;
                if (slot === 4) {
                  return (
                    <div key={slot} style={{ width: 80, display: "flex", flexDirection: "column", alignItems: "center", gap: 5 }}>
                      {open ? (
                        <div style={{ width: 56, height: 56 }} />
                      ) : (
                        <div onClick={() => setOpenTo(true)} style={{ position: "relative", width: 56, height: 56, cursor: "pointer" }}>
                          <motion.div
                            layoutId="folder"
                            transition={spr}
                            style={{ position: "absolute", inset: 0, borderRadius: 14, ...glass("ultraThin") }}
                          />
                          <div style={{ position: "absolute", inset: 0, display: "grid", gridTemplateColumns: "20px 20px", gap: 4, alignContent: "center", justifyContent: "center" }}>
                            {folderApps.map((app, index) => (
                              <motion.div key={index} layoutId={`app-${index}`} transition={spr} style={{ width: 20, height: 20, borderRadius: 5 }}>
                                <AppIcon app={app} />
                              </motion.div>
                            ))}
                          </div>
                        </div>
                      )}
                      <span style={{ opacity: open ? 0 : 1, transition: "opacity 0.3s" }}>{label(lang ? "创作" : "Create")}</span>
                    </div>
                  );
                }
                const app = homeApps[slot < 4 ? slot : slot - 1];
                return (
                  <div key={slot} style={{ width: 80, display: "flex", flexDirection: "column", alignItems: "center", gap: 5 }}>
                    <div style={{ width: 56, height: 56, borderRadius: 13, boxShadow: `0 3px 5px ${black(0.18)}` }}>
                      <AppIcon app={app} />
                    </div>
                    {label(app.name[lang])}
                  </div>
                );
              })}
            </div>
          ))}
        </motion.div>
        {open && <div onClick={() => setOpenTo(false)} style={{ position: "absolute", inset: 0 }} />}
        <AnimatePresence>
          {open && (
            <motion.div
              key="panel"
              style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14, pointerEvents: "none" }}
            >
              <motion.span
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                transition={spr}
                style={{ fontSize: 22, lineHeight: "28px", fontWeight: 700, color: "#fff", textShadow: `0 2px 6px ${black(0.2)}` }}
              >
                {lang ? "创作" : "Create"}
              </motion.span>
              <div style={{ position: "relative", width: 212, height: 212, flexShrink: 0, pointerEvents: "auto" }}>
                <motion.div layoutId="folder" transition={spr} style={{ position: "absolute", inset: 0, borderRadius: 34, ...glass("ultraThin") }} />
                <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
                  {[0, 1].map((row) => (
                    <div key={row} style={{ display: "flex", gap: 26 }}>
                      {[0, 1].map((column) => {
                        const index = row * 2 + column;
                        const app = folderApps[index];
                        return (
                          <div key={index} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
                            <motion.div
                              layoutId={`app-${index}`}
                              transition={spr}
                              style={{ width: 58, height: 58, borderRadius: 14, boxShadow: `0 3px 5px ${black(0.18)}` }}
                            >
                              <AppIcon app={app} />
                            </motion.div>
                            <motion.span initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 6 }} transition={spr}>
                              {label(app.name[lang])}
                            </motion.span>
                          </div>
                        );
                      })}
                    </div>
                  ))}
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
      <DemoHint ctx={ctx} en="Tap the folder" zh="点击文件夹" />
    </LayoutRoot>
  );
}

function AppIcon({ app }: { app: App }) {
  const { Icon } = app;
  return (
    <div style={{ width: "100%", height: "100%", borderRadius: "inherit", background: vert(...app.colors), display: "grid", placeItems: "center", color: "#fff" }}>
      <Icon style={{ width: "50%", height: "50%" }} strokeWidth={2.4} fill={app.fill ? "currentColor" : "none"} />
    </div>
  );
}

function Wallpaper() {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        background: [
          `radial-gradient(200px circle at 15% 10%, ${white(0.22)}, transparent)`,
          `radial-gradient(220px circle at 85% 90%, ${hex(Palette.amber, 0.45)}, transparent)`,
          `linear-gradient(to bottom right, #1D2671, #6E4BD8, #E86BB0)`,
        ].join(", "),
      }}
    />
  );
}
