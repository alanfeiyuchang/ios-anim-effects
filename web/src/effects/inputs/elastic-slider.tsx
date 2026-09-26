/** inputs.elastic-slider · 弹性音量条 (Inputs+ElasticSlider.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform, type MotionValue } from "motion/react";
import { Music2 } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, clamp, demoCard, fonts, rubberBand, spring, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";
import { SpeakerWaves } from "./_b-common";

const W = 280;
const H = 56;

export default function ElasticSlider({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const value = useMotionValue(0.55);
  const stretch = useMotionValue(0);
  const [pct, setPct] = useState(55);
  const [level, setLevel] = useState(0.55);
  const [pressing, setPressing] = useState(false);
  const [pressT, setPressT] = useState(spring(0.3, 0.7));
  const [anchoredAtLeading, setAnchoredAtLeading] = useState(true);
  const g = useRef({ pressing: false, startValue: 0, atEdge: false, step: 0, leading: true });

  useMotionValueEvent(value, "change", (v) => {
    setPct(Math.round(v * 100));
    setLevel(v);
  });

  const scaleX = useTransform(stretch, (s) => 1 + (g.current.leading ? s : -s) / W);
  const scaleY = useTransform(stretch, (s) => 1 - ((g.current.leading ? s : -s) / H) * 0.25);
  const iconScale = useTransform(stretch, (s) => 1 + Math.abs(s) / 90);
  const fillWidth = useTransform(value, (v) => W * v);

  const setAnchor = (leading: boolean) => {
    g.current.leading = leading;
    setAnchoredAtLeading(leading);
  };
  const setPress = (p: boolean, t: ReturnType<typeof spring>) => {
    g.current.pressing = p;
    setPressT(t);
    setPressing(p);
  };

  const release = () => {
    if (!(g.current.pressing || stretch.get() !== 0 || g.current.atEdge)) return;
    g.current.atEdge = false;
    const t = spring(ctx.n("response"), ctx.n("damping"));
    animate(stretch, 0, t);
    setPress(false, t);
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!g.current.pressing) {
        g.current.startValue = value.get();
        value.stop();
        setPress(true, spring(0.3, 0.7));
      }
      const raw = g.current.startValue + translation.x / W;
      value.set(clamp(raw));
      const limit = ctx.n("limit");
      stretch.stop();
      if (raw > 1) {
        setAnchor(true);
        stretch.set(rubberBand((raw - 1) * W, limit));
      } else if (raw < 0) {
        setAnchor(false);
        stretch.set(rubberBand(raw * W, limit));
      } else stretch.set(0);
      const edge = raw >= 1 || raw <= 0;
      if (edge && !g.current.atEdge) haptics.tap("medium");
      g.current.atEdge = edge;
    },
    onEnd: release,
  });

  const overshoot = (target: number, amount: number) => {
    animate(value, target, anim.smoothD(0.35));
    setPress(true, anim.smoothD(0.35));
    setAnchor(amount >= 0);
    after(0.3, () => {
      animate(stretch, amount, anim.easeOut(0.18));
      after(0.25, release);
    });
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const phase = g.current.step % 4;
      g.current.step += 1;
      const limit = ctx.n("limit");
      if (phase === 0) animate(value, 0.7, anim.smoothD(0.6));
      else if (phase === 1) overshoot(1, limit * 0.85);
      else if (phase === 2) animate(value, 0.3, anim.smoothD(0.6));
      else overshoot(0, -limit * 0.85);
    },
    { every: 1.1, delay: 0.4 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), width: W + 32, padding: 16, display: "flex", flexDirection: "column", gap: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 46, height: 46, borderRadius: 12, background: Palette.sunset, display: "grid", placeItems: "center", color: "#fff" }}>
            <Music2 size={20} strokeWidth={2.4} fill="currentColor" />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label }}>{ctx.t("Midnight Drive", "午夜兜风")}</span>
            <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>Lumen · 3:42</span>
          </div>
          <span style={{ flex: 1 }} />
          <span style={{ fontFamily: fonts.rounded, fontSize: 15, fontWeight: 600, color: Palette.secondaryLabel, display: "inline-flex" }}>
            <NumericText value={pct} />%
          </span>
        </div>
        <motion.div animate={{ scale: pressing ? 1.03 : 1 }} transition={pressT} style={{ width: W, height: H }}>
          <motion.div
            {...pan}
            animate={{ boxShadow: `0 6px ${pressing ? 16 : 10}px rgb(79 124 255 / ${pressing ? 0.28 : 0.14})` }}
            transition={pressT}
            style={{
              ...pan.style,
              position: "relative",
              width: W,
              height: H,
              borderRadius: 20,
              overflow: "hidden",
              background: Palette.labelAlpha(0.08),
              scaleX,
              scaleY,
              originX: anchoredAtLeading ? 0 : 1,
              cursor: "grab",
            }}
          >
            <motion.div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: fillWidth, background: `linear-gradient(90deg, ${Palette.sky}, ${Palette.blue})` }} />
            <Speaker value={value} level={level} scale={iconScale} />
            <div style={{ position: "absolute", inset: 0, borderRadius: 20, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
          </motion.div>
        </motion.div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag past either end" zh="拖过任一端试试" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Speaker({ value, level, scale }: { value: MotionValue<number>; level: number; scale: MotionValue<number> }) {
  const color = W * value.get() > 46 ? "#fff" : Palette.secondaryLabel;
  return (
    <motion.div style={{ position: "absolute", left: 16, top: 0, bottom: 0, display: "flex", alignItems: "center", color, scale }}>
      <SpeakerWaves level={level} size={24} />
    </motion.div>
  );
}
