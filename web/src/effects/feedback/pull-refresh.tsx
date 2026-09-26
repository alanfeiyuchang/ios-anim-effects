/** feedback.pull-refresh · 自定义下拉刷新 (Feedback+PullRefresh.swift) */
import { AnimatePresence, motion } from "motion/react";
import { ArrowDown } from "lucide-react";
import { useState } from "react";
import { Palette, spring, useClock, type DemoProps } from "../../kit";
import { DividerRow, RefreshHost } from "./refresh-host";

const SAMPLES: { initials: string; tint: string; name: [string, string]; message: [string, string] }[] = [
  { initials: "MJ", tint: Palette.pink, name: ["Mia Jensen", "米娅"], message: ["Loved the new prototype!", "新原型太棒了！"] },
  { initials: "DK", tint: Palette.sky, name: ["Daniel Kim", "金丹尼"], message: ["Can we sync at 3?", "三点对一下？"] },
  { initials: "SL", tint: Palette.mint, name: ["Sara Lopez", "萨拉"], message: ["Shipped the motion specs", "动效规范已交付"] },
  { initials: "RT", tint: Palette.amber, name: ["Ryo Tanaka", "田中亮"], message: ["Photos from the offsite", "团建照片来啦"] },
  { initials: "AN", tint: Palette.violet, name: ["Ava Novak", "艾娃"], message: ["Invoice approved", "报销已批准"] },
];

export default function PullRefresh({ ctx }: DemoProps) {
  const [armed, setArmed] = useState(false);
  const zh = ctx.lang === "zh";
  return (
    <RefreshHost
      ctx={ctx}
      threshold={ctx.n("resistance")}
      holdHeight={60}
      height={250}
      rowCount={4}
      clipIndicator={false}
      script={[0.7, 0.5, 14, 0.3, 0.35]}
      doneSpring={spring(0.5, 0.82)}
      insertion={{ initial: { scale: 0.92 }, origin: "50% 0%" }}
      onArmedChange={setArmed}
      renderRow={(item) => {
        const s = SAMPLES[item % SAMPLES.length];
        return (
          <DividerRow height={60} inset={64} scheme={ctx.scheme}>
            <div style={{ width: 38, height: 38, flexShrink: 0, borderRadius: "50%", background: `linear-gradient(rgb(255 255 255 / 0.14), transparent), ${s.tint}`, display: "grid", placeItems: "center", color: "#fff", fontSize: 12, fontWeight: 700 }}>
              {s.initials}
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 2, minWidth: 0 }}>
              <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{s.name[zh ? 1 : 0]}</span>
              <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, whiteSpace: "nowrap" }}>{s.message[zh ? 1 : 0]}</span>
            </div>
          </DividerRow>
        );
      }}
      indicator={({ pull, progress, refreshing }) => {
        const p = Math.min(progress, 1);
        return (
          <div style={{ position: "absolute", left: 136, top: Math.max(pull, 1) / 2 - 14, width: 28, height: 28, opacity: pull > 6 ? 1 : 0, transform: `scale(${0.6 + 0.4 * p})` }}>
            <AnimatePresence initial={false}>
              {refreshing ? (
                <motion.div key="spin" initial={{ scale: 0.6, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.6, opacity: 0 }} transition={spring(0.5, 0.82)} style={{ position: "absolute", inset: 0 }}>
                  <Spinner fps={ctx.isPreview ? 30 : undefined} />
                </motion.div>
              ) : (
                <motion.div key="dial" initial={{ scale: 0.6, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.6, opacity: 0 }} transition={spring(0.5, 0.82)} style={{ position: "absolute", inset: 0 }}>
                  <svg width={28} height={28} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
                    <defs>
                      <linearGradient id="pr-grad" x1="0" y1="0" x2="1" y2="1">
                        <stop offset="0" stopColor={Palette.indigo} />
                        <stop offset="1" stopColor={Palette.violet} />
                      </linearGradient>
                    </defs>
                    <circle cx={14} cy={14} r={14} fill="none" stroke="rgb(var(--ml-label-rgb) / 0.08)" strokeWidth={3} />
                    <circle cx={14} cy={14} r={14} fill="none" stroke="url(#pr-grad)" strokeWidth={3} strokeLinecap="round" pathLength={1} strokeDasharray={`${p} 2`} transform="rotate(-90 14 14)" style={{ opacity: p > 0.001 ? 1 : 0 }} />
                  </svg>
                  <motion.div animate={{ rotate: armed ? 180 : 0 }} transition={spring(0.3, 0.55)} style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: Palette.indigo }}>
                    <ArrowDown size={13} strokeWidth={3.2} />
                  </motion.div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        );
      }}
    />
  );
}

function Spinner({ fps }: { fps?: number }) {
  const t = useClock(true, fps) + performance.timeOrigin / 1000;
  const deg = ((t % 0.8) / 0.8) * 360;
  return (
    <svg width={28} height={28} style={{ overflow: "visible", transform: `rotate(${deg}deg)` }}>
      <defs>
        <linearGradient id="pr-spin" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor={Palette.indigo} />
          <stop offset="1" stopColor={Palette.violet} />
        </linearGradient>
      </defs>
      <circle cx={14} cy={14} r={14} fill="none" stroke="url(#pr-spin)" strokeWidth={3} strokeLinecap="round" pathLength={1} strokeDasharray="0.75 2" transform="rotate(0 14 14)" />
    </svg>
  );
}
