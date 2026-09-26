/** buttons.soft-press · 新拟态按压 (Buttons+SoftPress.swift) */
import { motion } from "motion/react";
import { Moon, Power, Radio, Wifi, type LucideIcon } from "lucide-react";
import { useId, useRef, useState } from "react";
import { DemoHint, Palette, SymbolBounce, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { useLatchedPress } from "./_a-kit";

const TONES = {
  light: { base: "#E3E7EE", highlight: "#FFFFFF", shade: "167 179 198" },
  dark: { base: "#2A2D34", highlight: "#3A3E47", shade: "18 20 24" },
};
const SYMBOLS: LucideIcon[] = [Power, Wifi, Radio, Moon];

export default function SoftPress({ ctx }: DemoProps) {
  const { after } = useTimeouts();
  const [on, setOn] = useState([false, true, false, false]);
  const [bounces, setBounces] = useState([0, 0, 0, 0]);
  const [pulsed, setPulsed] = useState<number | null>(null);
  const step = useRef(0);
  const latch = ctx.b("latch");
  const tone = TONES[ctx.scheme];

  const toggle = (index: number) => {
    if (!latch) {
      setBounces((b) => b.map((v, i) => (i === index ? v + 1 : v)));
      return;
    }
    const now = !on[index];
    setOn((o) => o.map((v, i) => (i === index ? now : v)));
    if (now) setBounces((b) => b.map((v, i) => (i === index ? v + 1 : v)));
  };

  const pulse = (index: number) => {
    toggle(index);
    setPulsed(index);
    after(0.3, () => setPulsed((p) => (p === index ? null : p)));
  };

  useAutoplay(ctx.isPreview, () => {
    const index = step.current % 4;
    step.current += 1;
    if (latch) toggle(index);
    else pulse(index);
  }, { every: 0.9, delay: 0.3 });

  const key = (index: number, size: number, corner: number, glyph: number) => (
    <SoftKey
      key={index}
      Icon={SYMBOLS[index]}
      filled={index === 3}
      lit={latch ? on[index] : pulsed === index}
      bounce={bounces[index]}
      size={size}
      corner={corner}
      glyph={glyph}
      depth={ctx.n("depth")}
      response={ctx.n("response")}
      tone={tone}
      onTap={() => toggle(index)}
    />
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div
        style={{
          width: 290,
          padding: "30px 0",
          borderRadius: 34,
          background: tone.base,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 26,
        }}
      >
        {key(0, 116, 58, 38)}
        <div style={{ display: "flex", gap: 22 }}>
          {key(1, 58, 18, 20)}
          {key(2, 58, 18, 20)}
          {key(3, 58, 18, 20)}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the keys" zh="点击按键" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function SoftKey({
  Icon,
  filled,
  lit,
  bounce,
  size,
  corner,
  glyph,
  depth,
  response,
  tone,
  onTap,
}: {
  Icon: LucideIcon;
  filled: boolean;
  lit: boolean;
  bounce: number;
  size: number;
  corner: number;
  glyph: number;
  depth: number;
  response: number;
  tone: (typeof TONES)["dark"];
  onTap: () => void;
}) {
  const haptics = useHaptics();
  const { held, handlers } = useLatchedPress({ onPress: () => haptics.tap("soft") });
  const inset = held || lit;
  const half = depth / 2;
  const t = spring(response, 0.75);
  const gradID = "soft-grad-" + useId().replace(/[^a-zA-Z0-9]/g, "");
  const paint = lit ? `url(#${gradID})` : Palette.secondaryLabel;
  const iconSize = glyph * 1.1;
  return (
    <motion.button
      type="button"
      {...handlers}
      onClick={onTap}
      initial={false}
      animate={{ scale: held ? 0.97 : 1 }}
      transition={t}
      style={{ position: "relative", width: size, height: size, display: "grid", placeItems: "center" }}
    >
      <motion.div
        initial={false}
        animate={{ opacity: inset ? 0 : 1 }}
        transition={t}
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: corner,
          background: tone.base,
          boxShadow: `${half}px ${half}px ${depth * 1.6}px rgb(${tone.shade} / 0.8), ${-half}px ${-half}px ${depth * 1.6}px ${tone.highlight}`,
        }}
      />
      <motion.div
        initial={false}
        animate={{ opacity: inset ? 1 : 0 }}
        transition={t}
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: corner,
          background: tone.base,
          boxShadow: `inset ${half * 0.7}px ${half * 0.7}px ${depth * 1.0}px rgb(${tone.shade} / 0.9), inset ${-half * 0.7}px ${-half * 0.7}px ${depth * 1.0}px ${tone.highlight}`,
        }}
      />
      <SymbolBounce trigger={bounce} style={{ position: "relative" }}>
        <Icon size={iconSize} strokeWidth={2.3} color={paint} fill={filled ? paint : "none"}>
          <defs>
            <linearGradient id={gradID} gradientUnits="userSpaceOnUse" x1="2" y1="2" x2="22" y2="22">
              <stop offset="0" stopColor={Palette.indigo} />
              <stop offset="1" stopColor={Palette.violet} />
            </linearGradient>
          </defs>
        </Icon>
      </SymbolBounce>
    </motion.button>
  );
}
