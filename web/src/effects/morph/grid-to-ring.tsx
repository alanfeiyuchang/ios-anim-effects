/** morph.grid-to-ring · 网格变环形 (Morph+GridToRing.swift) */
import { motion } from "motion/react";
import { Book, Calendar, Camera, CloudSun, Gamepad2, Heart, Map, MessageCircle, Music, Phone, Settings, ShoppingCart } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, anim, delayed, fonts, hex, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { sheen } from "./_shared";

const symbols: [typeof Heart, boolean][] = [
  [MessageCircle, true],
  [Phone, true],
  [Camera, false],
  [Music, false],
  [Map, false],
  [Calendar, false],
  [CloudSun, false],
  [Gamepad2, false],
  [Book, false],
  [ShoppingCart, false],
  [Heart, true],
  [Settings, false],
];
const COUNT = 12;

const gridPoint = (i: number) => ({ x: ((i % 4) - 1.5) * 64, y: (Math.floor(i / 4) - 1) * 64 });
const ringAngle = (i: number) => (i / COUNT) * 360 - 90;
const ringPoint = (i: number) => {
  const r = (ringAngle(i) * Math.PI) / 180;
  return { x: Math.cos(r) * 110, y: Math.sin(r) * 110 };
};

export default function GridToRing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [ring, setRing] = useState(false);
  const stagger = ctx.n("stagger");

  const toggle = () => {
    haptics.tap("medium");
    setRing((r) => !r);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.8 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div onClick={toggle} style={{ position: "relative", width: 300, height: 300, cursor: "pointer", flexShrink: 0 }}>
        <motion.div
          initial={false}
          animate={{ scale: ring ? 1 : 0.6, opacity: ring ? 1 : 0 }}
          transition={ring ? delayed(spring(0.45, 0.7), stagger * COUNT) : anim.easeOut(0.15)}
          style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2 }}
        >
          <span style={{ fontFamily: fonts.rounded, fontSize: 34, lineHeight: "41px", fontWeight: 700, fontVariantNumeric: "tabular-nums" }}>{COUNT}</span>
          <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("apps", "个应用")}</span>
        </motion.div>
        {symbols.map(([Icon, fill], index) => {
          const position = ring ? ringPoint(index) : gridPoint(index);
          const outward = ringAngle(index) + 90;
          const shortest = outward > 180 ? outward - 360 : outward;
          const angle = ring && ctx.b("orient") ? shortest : 0;
          const order = ring ? index : COUNT - 1 - index;
          const color = Palette.spectrum[index % Palette.spectrum.length];
          return (
            <motion.div
              key={index}
              initial={false}
              animate={{ x: position.x, y: position.y, rotate: angle }}
              transition={delayed(spring(ctx.n("response"), 0.72), order * stagger)}
              style={{
                position: "absolute",
                left: 150 - 24,
                top: 150 - 24,
                width: 48,
                height: 48,
                borderRadius: 13,
                background: sheen(color),
                boxShadow: `0 3px 6px ${hex(color, 0.35)}`,
                display: "grid",
                placeItems: "center",
                color: "#fff",
              }}
            >
              <Icon size={22} strokeWidth={2.3} fill={fill ? "currentColor" : "none"} />
            </motion.div>
          );
        })}
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 12 }}>
        <DemoHint ctx={ctx} en="Tap to rearrange" zh="点击重新排列" />
      </div>
    </div>
  );
}
