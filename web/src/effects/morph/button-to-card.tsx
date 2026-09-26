/** morph.button-to-card · 按钮变卡片 (Morph+ButtonToCard.swift) */
import { AnimatePresence, motion } from "motion/react";
import { AudioWaveform, Copy, Layers, SlidersHorizontal, Sparkles, WandSparkles, X } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, fonts, hex, spring, useAutoplay, useHaptics, useTimeouts, white, type DemoProps } from "../../kit";
import { LayoutRoot, Reveal, diag } from "./_shared";

export default function ButtonToCard({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [expanded, setExpanded] = useState(false);
  const [showContent, setShowContent] = useState(false);
  const spr = spring(ctx.n("response"), ctx.n("damping"));
  const zh = ctx.lang === "zh";

  const toggle = () => {
    haptics.tap("medium");
    if (expanded) {
      setShowContent(false);
      after(0.12, () => setExpanded(false));
    } else {
      setExpanded(true);
      // ProCard.onAppear { showContent = true }
      requestAnimationFrame(() => setShowContent(true));
    }
  };
  useAutoplay(ctx.isPreview, toggle, { every: 2.4 });

  const receded = expanded && ctx.b("recede");
  return (
    <LayoutRoot>
      <div style={{ position: "absolute", inset: 20 }}>
        <motion.div
          initial={false}
          animate={{ scale: receded ? 0.95 : 1, filter: `blur(${receded ? 6 : 0}px)`, opacity: receded ? 0.5 : 1 }}
          transition={spr}
          style={{ position: "absolute", inset: 0, transformOrigin: "50% 0%" }}
        >
          <BackdropList zh={zh} />
        </motion.div>
        <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, display: "flex", justifyContent: "center" }}>
          {expanded ? (
            <ProCard zh={zh} showContent={showContent} stagger={ctx.n("stagger")} spr={spr} onClose={toggle} />
          ) : (
            <ProPill zh={zh} spr={spr} onTap={toggle} />
          )}
        </div>
        <AnimatePresence>
          {!expanded && (
            <motion.div
              key="hint"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={spr}
              style={{ position: "absolute", left: 0, right: 0, bottom: 68, pointerEvents: "none" }}
            >
              <DemoHint ctx={ctx} en="Tap Go Pro" zh="点击“升级 Pro”" />
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </LayoutRoot>
  );
}

const headline = { fontFamily: fonts.text, fontSize: 17, lineHeight: "22px", fontWeight: 600, color: "#fff" } as const;

function ProPill({ zh, spr, onTap }: { zh: boolean; spr: ReturnType<typeof spring>; onTap: () => void }) {
  return (
    <button type="button" onClick={onTap} style={{ position: "relative", height: 54, padding: "0 28px", display: "flex", alignItems: "center", gap: 8, ...headline }}>
      <motion.div
        layoutId="bg"
        transition={spr}
        style={{ position: "absolute", inset: 0, borderRadius: 27, background: diag(Palette.indigo, Palette.violet), boxShadow: `0 8px 14px ${hex(Palette.indigo, 0.35)}` }}
      />
      <motion.span layoutId="icon" transition={spr} style={{ position: "relative", display: "grid" }}>
        <Sparkles size={19} strokeWidth={2.2} />
      </motion.span>
      <motion.span layoutId="title" transition={spr} style={{ position: "relative", whiteSpace: "nowrap" }}>
        {zh ? "升级 Pro" : "Go Pro"}
      </motion.span>
    </button>
  );
}

function ProCard({
  zh,
  showContent,
  stagger,
  spr,
  onClose,
}: {
  zh: boolean;
  showContent: boolean;
  stagger: number;
  spr: ReturnType<typeof spring>;
  onClose: () => void;
}) {
  const features: [typeof WandSparkles, string][] = zh
    ? [[WandSparkles, "全部 300+ 动效"], [SlidersHorizontal, "实时参数调节"], [Copy, "一键复制提示词"]]
    : [[WandSparkles, "All 300+ effects"], [SlidersHorizontal, "Live parameter tuning"], [Copy, "One-tap prompt copy"]];
  return (
    <div style={{ position: "relative", width: 300, padding: 22, display: "flex", flexDirection: "column", gap: 16 }}>
      <motion.div
        layoutId="bg"
        transition={spr}
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 30,
          overflow: "hidden",
          background: diag(Palette.indigo, Palette.violet),
          boxShadow: `0 14px 24px ${hex(Palette.indigo, 0.35)}`,
        }}
      >
        <div style={{ position: "absolute", inset: 0, background: `radial-gradient(220px circle at 0% 0%, ${white(0.28)}, transparent)` }} />
      </motion.div>
      <div style={{ position: "relative", display: "flex", alignItems: "center", gap: 8, ...headline }}>
        <motion.span layoutId="icon" transition={spr} style={{ display: "grid" }}>
          <Sparkles size={19} strokeWidth={2.2} />
        </motion.span>
        <motion.span layoutId="title" transition={spr} style={{ whiteSpace: "nowrap" }}>
          {zh ? "升级 Pro" : "Go Pro"}
        </motion.span>
        <div style={{ flex: 1 }} />
        <Reveal visible={showContent} delay={0.05}>
          <button
            type="button"
            onClick={onClose}
            style={{ width: 28, height: 28, borderRadius: 14, background: white(0.2), display: "grid", placeItems: "center", color: "#fff" }}
          >
            <X size={13} strokeWidth={3.2} />
          </button>
        </Reveal>
      </div>
      <div style={{ position: "relative", display: "flex", flexDirection: "column", gap: 12 }}>
        {features.map(([Icon, title], index) => (
          <Reveal key={index} visible={showContent} delay={0.08 + index * stagger}>
            <div style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 15, lineHeight: "20px", fontWeight: 500, color: white(0.92) }}>
              <span style={{ width: 22, display: "grid", placeItems: "center" }}>
                <Icon size={17} strokeWidth={2} />
              </span>
              {title}
            </div>
          </Reveal>
        ))}
      </div>
      <Reveal visible={showContent} delay={0.08 + 3 * stagger} style={{ position: "relative" }}>
        <button
          type="button"
          onClick={onClose}
          style={{
            width: "100%",
            height: 46,
            borderRadius: 23,
            background: "#fff",
            color: Palette.indigo,
            fontSize: 15,
            fontWeight: 600,
          }}
        >
          {zh ? "继续 · ¥28/月" : "Continue · $3.99/mo"}
        </button>
      </Reveal>
    </div>
  );
}

function BackdropList({ zh }: { zh: boolean }) {
  const rows: [typeof Sparkles, string[], string, string][] = [
    [Sparkles, [Palette.indigo, Palette.violet], zh ? "弹簧按钮" : "Spring Button", zh ? "按钮 · 3 个参数" : "Buttons · 3 params"],
    [Layers, [Palette.pink, Palette.coral], zh ? "钱包卡片堆叠" : "Wallet Stack", zh ? "卡片 · 4 个参数" : "Cards · 4 params"],
    [AudioWaveform, [Palette.mint, Palette.sky], zh ? "音频波形" : "Audio Wave", zh ? "加载 · 4 个参数" : "Loading · 4 params"],
  ];
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      {rows.map(([Icon, colors, title, sub], i) => (
        <div key={i} style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 44, height: 44, borderRadius: 12, background: diag(...colors), display: "grid", placeItems: "center", color: "#fff" }}>
            <Icon size={20} strokeWidth={2.3} fill={i === 1 ? "currentColor" : "none"} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{title}</span>
            <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{sub}</span>
          </div>
        </div>
      ))}
    </div>
  );
}

