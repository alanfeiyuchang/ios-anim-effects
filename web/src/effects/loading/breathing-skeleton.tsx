/** loading.breathing-skeleton · 呼吸骨架屏 (Loading+PlaceholderVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, delayed, demoCard, spring, useClock, type DemoProps } from "../../kit";
import { previewFps, primary, useTask } from "./shared";

const SAMPLES = [
  { initials: "AK", colors: [Palette.sky, Palette.blue], en: "Alex Kim", zh: "金亚历", pen: "Final specs attached", pzh: "最终规格已附上", time: "9:41" },
  { initials: "MJ", colors: [Palette.pink, Palette.violet], en: "Mia Jensen", zh: "米娅", pen: "Can we move the sync?", pzh: "同步会能改时间吗？", time: "9:12" },
  { initials: "SL", colors: [Palette.mint, Palette.green], en: "Sara Lopez", zh: "萨拉", pen: "Invoice #2031 paid", pzh: "发票 #2031 已付款", time: "8:57" },
];

export default function BreathingSkeleton({ ctx }: DemoProps) {
  const [loaded, setLoaded] = useState(false);
  const [run, setRun] = useState(0);
  useTask(run, async (task) => {
    setLoaded(false);
    await task.sleep(ctx.n("wait"));
    setLoaded(true);
    await task.sleep(2.4);
    if (ctx.isPreview) setRun((r) => r + 1);
  });
  const zh = ctx.lang === "zh";
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ ...demoCard(), width: 288, padding: "6px 0" }}>
        {SAMPLES.map((s, index) => {
          const t = delayed(spring(0.45, 0.85), loaded ? index * 0.08 : 0);
          return (
            <div key={index}>
              <div style={{ position: "relative", height: 64 }}>
                <AnimatePresence initial={false}>
                  {loaded ? (
                    <motion.div key="row" initial={{ y: 12, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ opacity: 0, transition: t }} transition={t} style={{ position: "absolute", inset: 0 }}>
                      <div style={{ height: "100%", padding: "0 14px", display: "flex", alignItems: "center", gap: 12 }}>
                        <div
                          style={{
                            width: 40,
                            height: 40,
                            borderRadius: "50%",
                            background: `linear-gradient(${s.colors.join(", ")})`,
                            display: "grid",
                            placeItems: "center",
                            color: "#fff",
                            fontSize: 12,
                            fontWeight: 700,
                            flexShrink: 0,
                          }}
                        >
                          {s.initials}
                        </div>
                        <div style={{ display: "flex", flexDirection: "column", gap: 3, minWidth: 0 }}>
                          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? s.zh : s.en}</span>
                          <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{zh ? s.pzh : s.pen}</span>
                        </div>
                        <div style={{ flex: 1 }} />
                        <span style={{ fontSize: 11, lineHeight: "13px", fontVariantNumeric: "tabular-nums", color: Palette.tertiaryLabel }}>{s.time}</span>
                      </div>
                    </motion.div>
                  ) : (
                    <motion.div key="skeleton" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, transition: t }} transition={t} style={{ position: "absolute", inset: 0 }}>
                      <BreathRow index={index} period={Math.max(ctx.n("period"), 0.2)} stagger={ctx.n("stagger")} preview={ctx.isPreview} />
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
              {index < 2 && <div style={{ marginLeft: 66, height: 0.5, background: primary(0.18) }} />}
            </div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap to reload" zh="点击重新加载" />
    </div>
  );
}

function BreathRow({ index, period, stagger, preview }: { index: number; period: number; stagger: number; preview: boolean }) {
  useClock(true, previewFps(preview));
  const t = performance.now() / 1000 - index * stagger;
  const wave = 0.5 - 0.5 * Math.cos((2 * Math.PI * t) / period);
  const fill = primary(0.06 + 0.1 * wave);
  return (
    <div style={{ height: "100%", padding: "0 14px", display: "flex", alignItems: "center", gap: 12 }}>
      <div style={{ width: 40, height: 40, borderRadius: "50%", background: fill, flexShrink: 0 }} />
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        <div style={{ width: 110, height: 11, borderRadius: 5.5, background: fill }} />
        <div style={{ width: 170, height: 9, borderRadius: 4.5, background: fill }} />
      </div>
    </div>
  );
}
