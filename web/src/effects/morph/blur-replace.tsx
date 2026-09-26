/** morph.blur-replace · 模糊替换 (Morph+BlurReplace.swift) */
import { AnimatePresence, animate, motion, useMotionValue } from "motion/react";
import { Headphones, Moon, Timer } from "lucide-react";
import { useLayoutEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, black, demoCard, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { blurReplace, useMV } from "./_shared";
import { CheckCircleFill, type SymbolComponent } from "./_symbols";

interface IslandState {
  Icon: SymbolComponent;
  fill: boolean;
  tint: string;
  title: [string, string];
  detail: [string, string];
}

const states: IslandState[] = [
  { Icon: Headphones, fill: false, tint: "#ffffff", title: ["AirPods Pro", "AirPods Pro"], detail: ["Connected · 82%", "已连接 · 82%"] },
  { Icon: Timer, fill: false, tint: Palette.amber, title: ["Timer", "计时器"], detail: ["04:59 remaining", "剩余 04:59"] },
  { Icon: CheckCircleFill, fill: true, tint: Palette.green, title: ["Payment complete", "支付完成"], detail: ["$18.00 to Studio", "已向工作室支付 ¥128.00"] },
  { Icon: Moon, fill: true, tint: Palette.violet, title: ["Focus on", "专注模式"], detail: ["Notifications silenced", "通知已静音"] },
];

export default function BlurReplace({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [index, setIndex] = useState(0);
  const lang = ctx.lang === "zh" ? 1 : 0;
  const state = states[index % states.length];
  const spr = spring(ctx.n("response"), 0.8);
  const variants = blurReplace(ctx.i("style") === 0 ? "downUp" : "upUp");
  const sizer = useRef<HTMLDivElement>(null);
  const widthMV = useMotionValue(-1);
  const width = useMV(widthMV);

  // The hidden sizing copy's width drives the capsule, which springs instead of snapping.
  useLayoutEffect(() => {
    const w = sizer.current?.offsetWidth ?? 0;
    if (widthMV.get() < 0) widthMV.set(w);
    else animate(widthMV, w, spr);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [index, lang]);

  const advance = () => {
    haptics.selection();
    setIndex((i) => i + 1);
  };
  useAutoplay(ctx.isPreview, advance, { every: 1.6 });

  const content = (s: IslandState) => (
    <div style={{ display: "flex", alignItems: "center", gap: 10, whiteSpace: "nowrap", fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>
      <span style={{ display: "grid", color: s.tint }}>
        <s.Icon size={17} strokeWidth={2.4} fill={s.fill ? "currentColor" : "none"} />
      </span>
      <span style={{ color: "#fff" }}>{s.title[lang]}</span>
    </div>
  );
  const tileTint = state.tint === "#ffffff" ? Palette.indigo : state.tint;

  return (
    <div onClick={advance} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 34, cursor: "pointer" }}>
      <div style={{ position: "absolute", visibility: "hidden", pointerEvents: "none" }}>
        <div ref={sizer} style={{ display: "inline-block" }}>
          {content(state)}
        </div>
      </div>
      <div
        style={{
          position: "relative",
          height: 40,
          width: Math.max(width, 0) + 36,
          borderRadius: 20,
          background: "#000",
          overflow: "hidden",
          boxShadow: `0 6px 12px ${black(0.25)}`,
          flexShrink: 0,
        }}
      >
        <AnimatePresence initial={false}>
          <motion.div
            key={index}
            {...variants}
            transition={spr}
            style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}
          >
            {content(state)}
          </motion.div>
        </AnimatePresence>
      </div>
      <div style={{ ...demoCard(28), width: 230, height: 170, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14, flexShrink: 0 }}>
        <div style={{ position: "relative", height: 56, width: 60, display: "grid", placeItems: "center" }}>
          <AnimatePresence initial={false} mode="popLayout">
            <motion.span
              key={index}
              initial={{ scale: 0.4, opacity: 0, filter: "blur(4px)" }}
              animate={{ scale: 1, opacity: 1, filter: "blur(0px)", color: tileTint }}
              exit={{ scale: 0.4, opacity: 0, filter: "blur(4px)" }}
              transition={anim.snappyD(0.35)}
              style={{ display: "grid", color: tileTint }}
            >
              <state.Icon size={50} strokeWidth={2.2} fill={state.fill ? "currentColor" : "none"} />
            </motion.span>
          </AnimatePresence>
        </div>
        <div style={{ position: "relative", height: 46, width: 230 }}>
          <AnimatePresence initial={false}>
            <motion.div
              key={index}
              {...variants}
              transition={spr}
              style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}
            >
              <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{state.title[lang]}</span>
              <span style={{ fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel }}>{state.detail[lang]}</span>
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 14 }}>
        <DemoHint ctx={ctx} en="Tap to change state" zh="点击切换状态" />
      </div>
    </div>
  );
}
