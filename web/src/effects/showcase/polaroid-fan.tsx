/** showcase.polaroid-fan · 拍立得扇形展开 (TravelPolaroidFan.swift) */
import { motion, type Transition } from "motion/react";
import { GalleryVerticalEnd } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, delayed, fonts, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard } from "./signature";

const SEEDS = [3, 1, 2, 0];
const CAPTIONS = [
  { en: "Wadi Rum", zh: "瓦迪拉姆" },
  { en: "Nice, 7pm", zh: "尼斯 · 傍晚" },
  { en: "Braies", zh: "布拉耶斯" },
  { en: "Tyrol", zh: "蒂罗尔" },
];
const REST_TILT = [-5, 4, -2, 6];
const COUNT = SEEDS.length;

export default function PolaroidFan({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  const [fanned, setFanned] = useState(false);
  const [focused, setFocused] = useState<number | null>(null);
  const step = useRef(0);
  // Which value changed decides the animation (`.animation(_, value: fanned)` vs `.animation(_, value: focused)`).
  const [driver, setDriver] = useState<"fan" | "focus">("fan");
  const fan = (v: boolean) => {
    setDriver("fan");
    setFanned(v);
  };
  const focus = (v: number | null) => setFocused(v);

  const tap = (index: number) => {
    haptics.tap();
    if (!fanned) fan(true);
    else if (focused === index) {
      focus(null);
      fan(false);
    } else {
      setDriver("focus");
      focus(index);
    }
  };

  const collapse = () => {
    if (!fanned) return;
    haptics.tap("soft");
    focus(null);
    fan(false);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const s = step.current % 3;
      if (s === 0) fan(true);
      else if (s === 1) {
        setDriver("focus");
        focus(2);
      } else {
        focus(null);
        fan(false);
      }
      step.current += 1;
    },
    { every: 1.6 },
  );

  const spread = ctx.n("spread");
  const gap = ctx.n("gap");

  return (
    <SignatureStage>
      <div onClick={collapse} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
        <div style={{ flex: 1 }} />
        <div style={{ position: "relative", width: 340, height: 200, flexShrink: 0 }}>
          {SEEDS.map((seed, index) => {
            const rel = index - (COUNT - 1) / 2;
            const isFocused = focused === index;
            const isDimmed = focused !== null && !isFocused;
            const angle = !fanned ? REST_TILT[index % REST_TILT.length] : isFocused ? 0 : rel * spread;
            const x = fanned && !isFocused ? rel * gap : 0;
            const y = !fanned ? index * -2 : isFocused ? -18 : Math.abs(rel) * 8;
            const scale = isFocused ? 1.18 : isDimmed ? 0.9 : 1;
            const t: Transition = driver === "fan" ? delayed(spring(0.5, 0.72), index * ctx.n("stagger")) : spring(0.4, 0.75);
            return (
              <motion.div
                key={index}
                initial={false}
                animate={{ x, y, rotate: angle }}
                transition={t}
                onClick={(e) => {
                  e.stopPropagation();
                  tap(index);
                }}
                style={{ position: "absolute", left: 170 - 64, top: 100 - 78.5, transformOrigin: "50% 100%", zIndex: isFocused ? 10 : index, cursor: "pointer" }}
              >
                <motion.div
                  initial={false}
                  animate={{
                    scale,
                    filter: isDimmed ? "brightness(0.72)" : "brightness(1)",
                    boxShadow: isFocused ? "0 14px 22px rgb(0 0 0 / 0.55)" : "0 6px 10px rgb(0 0 0 / 0.3)",
                  }}
                  transition={t}
                  style={{ borderRadius: 6 }}
                >
                  <Polaroid seed={seed} caption={zh ? CAPTIONS[index].zh : CAPTIONS[index].en} zh={zh} />
                </motion.div>
              </motion.div>
            );
          })}
        </div>
        <div style={{ ...signatureCard(18), padding: "9px 14px", display: "flex", alignItems: "center", gap: 8, fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, lineHeight: "15px" }}>
          <GalleryVerticalEnd size={13} strokeWidth={2.6} color={Signature.accent} />
          <span style={{ color: "#fff" }}>{zh ? "夏日旅行 · 4 张回忆" : "Summer trip · 4 memories"}</span>
          <SignatureRim radius={18} />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap to fan out, then tap a photo" zh="点击展开，再点一张照片" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Polaroid({ seed, caption, zh }: { seed: number; caption: string; zh: boolean }) {
  return (
    <div style={{ width: 128, padding: 8, paddingBottom: 14, borderRadius: 6, background: Signature.paper, display: "flex", flexDirection: "column", alignItems: "center", gap: 8 }}>
      <div style={{ position: "relative", width: 112, height: 112, borderRadius: 3, overflow: "hidden" }}>
        <LandscapeArt seed={seed} />
      </div>
      <span style={{ fontFamily: zh ? fonts.text : fonts.serif, fontStyle: "italic", fontSize: 12, fontWeight: 500, color: "rgb(11 11 13 / 0.75)", lineHeight: "15px", whiteSpace: "nowrap" }}>{caption}</span>
    </div>
  );
}
