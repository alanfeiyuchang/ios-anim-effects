/** loading.install-pie · 应用安装饼图 (Loading+RingVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Camera, CloudSun, Map as MapIcon, MessageCircle, Music, Sparkles, type LucideIcon } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, anim, spring, useHaptics, type DemoProps } from "../../kit";
import { popScale, ringVarSimulate } from "./bar-shared";
import { useAnimatedNumber, useTask, useTriggerElapsed } from "./shared";

const APPS: { icon: LucideIcon; colors: string[]; en: string; zh: string; fill: boolean }[] = [
  { icon: MessageCircle, colors: [Palette.green, Palette.mint], en: "Messages", zh: "信息", fill: true },
  { icon: Camera, colors: ["#8E8E93", "#666666"], en: "Camera", zh: "相机", fill: true },
  { icon: Music, colors: [Palette.pink, Palette.red], en: "Music", zh: "音乐", fill: false },
  { icon: MapIcon, colors: [Palette.sky, Palette.mint], en: "Maps", zh: "地图", fill: true },
  { icon: Sparkles, colors: [Palette.indigo, Palette.violet], en: "Motion", zh: "Motion", fill: true },
  { icon: CloudSun, colors: [Palette.blue, Palette.sky], en: "Weather", zh: "天气", fill: true },
];

export default function InstallPie({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [run, setRun] = useState(0);
  const [installed, setInstalled] = useState(false);
  const [bounce, setBounce] = useState(0);
  const progress = useAnimatedNumber(0);
  const hole = useAnimatedNumber(17);

  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    setInstalled(false);
    hole.mv.jump(17);
    hole.target.current = 17;
    await ringVarSimulate(task, ctx.n("speed"), () => progress.target.current, progress.to);
    await task.sleep(0.2);
    hole.to(52, spring(ctx.n("response"), 0.8));
    await task.sleep(0.3);
    setInstalled(true);
    setBounce((b) => b + 1);
    if (live) haptics.success();
    await task.sleep(2.0);
    if (ctx.isPreview) setRun((r) => r + 1);
  });

  const pop = popScale(useTriggerElapsed(bounce, 0.8), 1.1, 0.14);
  const zh = ctx.lang === "zh";
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 20, cursor: "pointer" }}
    >
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 72px)", columnGap: 24, rowGap: 18 }}>
        {APPS.map((app, index) => {
          const target = index === 4;
          const Icon = app.icon;
          const label = target && !installed ? (zh ? "正在安装…" : "Installing…") : zh ? app.zh : app.en;
          return (
            <div key={index} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
              <div
                style={{
                  position: "relative",
                  width: 64,
                  height: 64,
                  borderRadius: 15,
                  overflow: "hidden",
                  background: `linear-gradient(${app.colors.join(", ")})`,
                  display: "grid",
                  placeItems: "center",
                  color: "#fff",
                  transform: target ? `scale(${pop})` : undefined,
                }}
              >
                <Icon size={30} fill={app.fill ? "currentColor" : "none"} strokeWidth={app.fill ? 1.6 : 2.6} />
                {target && <Scrim progress={progress.value} hole={hole.value} opacity={ctx.n("scrim")} />}
              </div>
              <span style={{ display: "grid", fontSize: 11, lineHeight: "13px", color: Palette.secondaryLabel, whiteSpace: "nowrap" }}>
                <AnimatePresence initial={false}>
                  <motion.span key={label} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={anim.easeInOut(0.3)} style={{ gridArea: "1 / 1", textAlign: "center" }}>
                    {label}
                  </motion.span>
                </AnimatePresence>
              </span>
            </div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap to reinstall" zh="点击重新安装" />
    </div>
  );
}

/** The dimmed icon with a pie wedge (then a round iris) cut out, even-odd filled. */
function Scrim({ progress, hole, opacity }: { progress: number; hole: number; opacity: number }) {
  const c = 32;
  const p = Math.min(Math.max(progress, 0), 1);
  let cut = "";
  if (hole > 17.5 || p >= 0.999) {
    cut = `M ${c + hole} ${c} A ${hole} ${hole} 0 1 1 ${c - hole} ${c} A ${hole} ${hole} 0 1 1 ${c + hole} ${c} Z`;
  } else if (p > 0.001) {
    const a0 = -Math.PI / 2;
    const a1 = a0 + p * 2 * Math.PI;
    cut = `M ${c} ${c} L ${c + hole * Math.cos(a0)} ${c + hole * Math.sin(a0)} A ${hole} ${hole} 0 ${p > 0.5 ? 1 : 0} 1 ${c + hole * Math.cos(a1)} ${c + hole * Math.sin(a1)} Z`;
  }
  return (
    <svg width={64} height={64} style={{ position: "absolute", inset: 0 }}>
      <path d={`M 0 0 H 64 V 64 H 0 Z ${cut}`} fillRule="evenodd" fill={`rgb(0 0 0 / ${opacity})`} />
      {hole <= 18 && <circle cx={c} cy={c} r={20} fill="none" stroke="rgb(255 255 255 / 0.85)" strokeWidth={1.5} />}
    </svg>
  );
}
