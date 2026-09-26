/** backgrounds.intelligence-glow · 智能边缘光 (Backgrounds+IntelligenceGlow.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Sparkles } from "lucide-react";
import { useRef, useState } from "react";
import { anim, useAutoplay, useHaptics, useLatest, useTimeouts, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Stage, rgba, useFrameLoop, useModel } from "./_support";

const PALETTES: number[][] = [
  [0xbc82f3, 0xf5b9ea, 0x8d9fff, 0xaa6eee, 0xff6778, 0xffba71, 0xc686ff, 0xbc82f3],
  [0x2e6bff, 0x00d4ff, 0x7a2bff, 0xff2e93, 0x2e6bff],
  [0xff7a45, 0xffc247, 0xff4d5e, 0xff5fa2, 0xff7a45],
];

class GlowModel {
  clock = new BackgroundClock();
  energy = 0;
  step(now: number, speed: number, active: boolean) {
    const t = this.clock.advance(now, speed * (1 + this.energy * 1.5));
    this.energy += ((active ? 1 : 0) - this.energy) * this.clock.follow(7);
    return t;
  }
}

/** (lineWidth factor, blur, degrees(t), opacity(energy)) per stacked stroke, back to front. */
const LAYERS: { width: (w: number) => number; blur: number; deg: (t: number) => number; opacity: (e: number) => number }[] = [
  { width: (w) => w * 5, blur: 28, deg: (t) => t * 40 + 200, opacity: (e) => 0.55 + 0.35 * e },
  { width: (w) => w * 3, blur: 14, deg: (t) => -t * 55 + 120, opacity: () => 0.8 },
  { width: (w) => w * 1.4, blur: 5, deg: (t) => t * 70 + 40, opacity: () => 0.9 },
  { width: (w) => Math.max(w * 0.5, 1.5), blur: 0, deg: (t) => t * 90, opacity: () => 1 },
];

export default function IntelligenceGlow({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const layers = useRef<(HTMLDivElement | null)[]>([]);
  const model = useModel(() => new GlowModel());
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [active, setActive] = useState(false);
  const activeRef = useLatest(active);
  const tapToken = useRef(0);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const t = model.step(now, ctx.n("speed"), activeRef.current);
    const e = model.energy;
    const w = ctx.n("width") * (1 + e * 0.9 + 0.12 * Math.sin(t * 2.1));
    const colors = PALETTES[Math.min(Math.max(ctx.i("style"), 0), 2)];
    const stops = colors.map((c, i) => `${rgba(c)} ${((i / (colors.length - 1)) * 360).toFixed(2)}deg`).join(", ");
    LAYERS.forEach((layer, i) => {
      const el = layers.current[i];
      if (!el) return;
      // SwiftUI angles start at 3 o'clock; CSS conic gradients at 12.
      el.style.background = `conic-gradient(from ${(layer.deg(t) + 90).toFixed(2)}deg, ${stops})`;
      el.style.padding = `${layer.width(w).toFixed(2)}px`;
      el.style.opacity = String(layer.opacity(e));
    });
  });

  const toggle = () => setActive((a) => !a);
  const pulseOnce = () => {
    if (activeRef.current) return;
    const token = tapToken.current;
    toggle();
    after(1.6, () => {
      if (token === tapToken.current && activeRef.current) toggle();
    });
  };
  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? toggle() : pulseOnce()), { every: 2.6 });

  return (
    <Stage
      rootRef={root}
      background="#08080D"
      handlers={{
        onClick: () => {
          haptics.tap();
          tapToken.current += 1;
          toggle();
        },
      }}
    >
      {LAYERS.map((layer, i) => (
        // CSS masks after filtering, so the blur sits on a wrapper around the masked stroke.
        <div key={i} style={{ position: "absolute", inset: 0, filter: layer.blur ? `blur(${layer.blur}px)` : undefined, pointerEvents: "none" }}>
          <div
            ref={(el) => {
              layers.current[i] = el;
            }}
            style={{
              position: "absolute",
              inset: 0,
              borderRadius: 30,
              WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
              WebkitMaskComposite: "xor",
              mask: "linear-gradient(#000 0 0) content-box exclude, linear-gradient(#000 0 0)",
            }}
          />
        </div>
      ))}
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 10,
          color: "rgb(255 255 255 / 0.92)",
          pointerEvents: "none",
        }}
      >
        <motion.span
          animate={active ? { opacity: [1, 0.35, 1] } : { opacity: 1 }}
          transition={active ? { duration: 1.1, repeat: Infinity, ease: "easeInOut" } : { duration: 0.2 }}
          style={{ display: "grid" }}
        >
          <Sparkles size={32} strokeWidth={1.9} fill="currentColor" />
        </motion.span>
        <div style={{ position: "relative", height: 25, width: 240 }}>
          <AnimatePresence initial={false}>
            <motion.div
              key={active ? "thinking" : "ask"}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={anim.smoothD(0.3)}
              style={{ position: "absolute", inset: 0, textAlign: "center", fontSize: 20, lineHeight: "25px", fontWeight: 600 }}
            >
              {active ? ctx.t("Thinking…", "思考中…") : ctx.t("Ask anything", "有什么可以帮你")}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
      <BgHint ctx={ctx} en="Tap to start listening" zh="点击开始聆听" />
    </Stage>
  );
}
