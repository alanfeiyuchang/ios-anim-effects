/** navigation.stacked-sheets · 层叠面板 (Navigation+StackedSheets.swift) */
import { motion } from "motion/react";
import { X } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { colorGradient } from "./nav-util";

const W = 250;
const H = 330;
const titles: [string, string][] = [
  ["Library", "资料库"],
  ["Album", "专辑"],
  ["Share", "分享"],
];
const actions: [string, string][] = [
  ["Open album", "打开专辑"],
  ["Share…", "分享…"],
  ["Done", "完成"],
];
const tints = [Palette.indigo, Palette.pink, Palette.mint];

export default function StackedSheets({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [depth, setDepthState] = useState(0);
  const depthRef = useRef(0);
  const autoStep = useRef(0);
  const sp = spring(ctx.n("response"), ctx.n("damping"));

  const setDepth = (value: number) => {
    const clamped = Math.min(Math.max(value, 0), 2);
    if (clamped === depthRef.current) return;
    haptics.tap(clamped > depthRef.current ? "medium" : "light");
    depthRef.current = clamped;
    setDepthState(clamped);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const sequence = [1, 2, 1, 0];
      setDepth(sequence[autoStep.current % sequence.length]);
      autoStep.current += 1;
    },
    { every: 1.2 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ position: "relative", width: W, height: H, flexShrink: 0, borderRadius: 34, overflow: "hidden", background: "#000", boxShadow: "0 10px 18px rgb(0 0 0 / 0.18)", isolation: "isolate" }}>
        {[0, 1, 2].map((index) => {
          const visible = index <= depth;
          const behind = Math.max(depth - index, 0);
          const scale = Math.pow(ctx.n("scale"), behind);
          const topInset = index === 0 ? 0 : 34;
          // The root page sinks a little; sheets underneath lift so their top edge peeks out.
          const lift = index === 0 ? behind * -12 : behind * 10;
          const y = visible ? topInset - lift : H + 20;
          const radius = index === 0 && behind === 0 ? 34 : 24;
          const dim = Math.min(behind * 0.12, 0.3);
          return (
            <motion.div
              key={index}
              initial={false}
              animate={{ y, scale, borderRadius: radius }}
              transition={sp}
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                width: W,
                height: H - topInset,
                transformOrigin: "50% 0%",
                overflow: "hidden",
                background: index === 0 ? Palette.surface : Palette.elevated,
                boxShadow: index === 0 ? undefined : "0 -2px 12px rgb(0 0 0 / 0.2)",
                pointerEvents: index === depth ? "auto" : "none",
              }}
            >
              <div style={{ padding: `${index === 0 ? 26 : 10}px 18px 0`, display: "flex", flexDirection: "column", gap: 14 }}>
                {index > 0 && <div style={{ alignSelf: "center", width: 36, height: 5, borderRadius: 2.5, background: Palette.secondaryLabel, opacity: 0.4 }} />}
                <div style={{ display: "flex", alignItems: "center", minHeight: 28 }}>
                  <span style={{ flex: 1, fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{ctx.t(...titles[index])}</span>
                  {index > 0 && (
                    <button
                      type="button"
                      onClick={() => setDepth(index - 1)}
                      style={{ width: 28, height: 28, borderRadius: "50%", background: Palette.surface, display: "grid", placeItems: "center", color: Palette.label }}
                    >
                      <X size={13} strokeWidth={3.2} />
                    </button>
                  )}
                </div>
                <div style={{ height: 90, borderRadius: 16, background: colorGradient(tints[index]) }} />
                <PlaceholderLines count={2} />
                <button
                  type="button"
                  onClick={() => setDepth(index < 2 ? index + 1 : index - 1)}
                  style={{ height: 42, borderRadius: 21, background: tints[index], color: "#fff", fontSize: 15, fontWeight: 600, width: "100%" }}
                >
                  {ctx.t(...actions[index])}
                </button>
              </div>
              <motion.div
                initial={false}
                animate={{ opacity: dim }}
                transition={sp}
                style={{ position: "absolute", inset: 0, background: "#000", pointerEvents: "none" }}
              />
            </motion.div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap the buttons to push and pop" zh="点击按钮推入或关闭" />
    </div>
  );
}
