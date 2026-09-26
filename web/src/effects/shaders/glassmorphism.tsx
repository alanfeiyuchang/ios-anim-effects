/** shader.glassmorphism · 磨砂玻璃材质 (Shaders+Glass.swift — pure materials, no Metal) */
import { animate, motion, useMotionValue, useTransform, type MotionValue } from "motion/react";
import { Nfc } from "lucide-react";
import { useRef } from "react";
import { Palette, clamp, fonts, glass, spring, textStyle, useAutoplay, useClock, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { randIn, useHoldDrag } from "./_shared";
import { BottomHint } from "./_stage";

const CARD_W = 250;
const CARD_H = 160;

export default function Glassmorphism({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const dx = useMotionValue(0);
  const dy = useMotionValue(0);
  const generation = useRef(0);
  const { after } = useTimeouts();
  const material = (["ultraThin", "thin", "regular"] as const)[ctx.i("material")] ?? "ultraThin";

  const to = (x: number, y: number, t: ReturnType<typeof spring>) => {
    animate(dx, x, t);
    animate(dy, y, t);
  };
  const hold = useHoldDrag(0.25, {
    onArm: () => {
      generation.current += 1;
      haptics.tap("soft");
    },
    onDrag: ({ translation }) => to(translation.x, translation.y, spring(0.25, 0.8)),
    onEnd: () => {
      if (dx.get() === 0 && dy.get() === 0) return;
      to(0, 0, spring(0.5, 0.7));
    },
  });

  /** Simulated drag: tilt toward a random corner, then spring back flat. */
  const tiltAndSettle = () => {
    generation.current += 1;
    const token = generation.current;
    to(randIn(-110, 110), randIn(-90, 90), spring(0.8, 0.7));
    after(0.8, () => {
      if (token !== generation.current) return;
      to(0, 0, spring(0.5, 0.7));
    });
  };
  useAutoplay(ctx.isPreview, tiltAndSettle, { every: 1.8, delay: 0.2 });

  const nx = useTransform(dx, (v) => clamp(v / 140, -1, 1));
  const ny = useTransform(dy, (v) => clamp(v / 140, -1, 1));
  const maxTilt = ctx.n("maxTilt");
  const rotateY = useTransform(nx, (v) => v * maxTilt);
  const rotateX = useTransform(ny, (v) => v * maxTilt);
  const shadow = useTransform([nx, ny] as MotionValue<number>[], ([x, y]: number[]) => `${-x * 10}px ${16 - y * 6}px 24px rgb(0 0 0 / 0.25)`);

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div
        style={{
          position: "absolute",
          inset: 14,
          borderRadius: 26,
          overflow: "hidden",
          background: "linear-gradient(to bottom right, #1B1464, #4A1D96, #A3165F)",
          transform: "translateZ(0)",
        }}
      >
        <Orbs nx={nx} ny={ny} fps={ctx.isPreview ? 30 : undefined} />
      </div>
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", perspective: CARD_W / 0.6 }}>
        <motion.div style={{ rotateY, transformStyle: "preserve-3d" }}>
          <motion.div style={{ rotateX: useTransform(rotateX, (v) => -v) }}>
            <motion.div style={{ position: "relative", width: CARD_W, height: CARD_H, borderRadius: 24, boxShadow: shadow }}>
              <div style={{ position: "absolute", inset: 0, borderRadius: 24, ...glass(material, "dark") }} />
              <Sheen nx={nx} ny={ny} />
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  padding: 22,
                  display: "flex",
                  flexDirection: "column",
                  gap: 14,
                  color: "#fff",
                }}
              >
                <div style={{ display: "flex", alignItems: "center" }}>
                  <span style={{ width: 28, height: 28, borderRadius: "50%", background: "#fff", display: "grid", placeItems: "center", color: "#3b2a7a" }}>
                    <Nfc size={18} strokeWidth={2.6} />
                  </span>
                  <span style={{ flex: 1 }} />
                  <span style={{ fontFamily: fonts.rounded, fontSize: 18, fontWeight: 800, fontStyle: "italic" }}>PLUS</span>
                </div>
                <div style={{ flex: 1 }} />
                <div style={{ fontFamily: fonts.mono, fontSize: 22, fontWeight: 600, lineHeight: "26px" }}>•••• 2046</div>
                <div style={{ ...textStyle.footnote, fontWeight: 500, opacity: 0.8 }}>{ctx.t("Motionary Member", "Motionary 会员卡")}</div>
              </div>
              <svg width={CARD_W} height={CARD_H} style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
                <defs>
                  <linearGradient id="ml-glassmorphism-rim" x1="0" y1="0" x2="1" y2="1">
                    <stop offset="0" stopColor="#fff" stopOpacity={0.6} />
                    <stop offset="1" stopColor="#fff" stopOpacity={0.1} />
                  </linearGradient>
                </defs>
                <rect x={0.5} y={0.5} width={CARD_W - 1} height={CARD_H - 1} rx={23.5} fill="none" stroke="url(#ml-glassmorphism-rim)" strokeWidth={1} />
              </svg>
              <div {...hold} style={{ position: "absolute", inset: 0, borderRadius: 24, cursor: "grab", ...hold.style }} />
            </motion.div>
          </motion.div>
        </motion.div>
      </div>
      <BottomHint ctx={ctx} en="Press the card, then drag to tilt" zh="按住卡片片刻再拖动使其倾斜" bottom={22} dark />
    </div>
  );
}

/** Diagonal specular sheen (clear → white 35 % → clear) sliding opposite the tilt. */
function Sheen({ nx, ny }: { nx: MotionValue<number>; ny: MotionValue<number> }) {
  const x1 = useTransform(nx, (v) => (0.2 - v * 0.5) * CARD_W);
  const x2 = useTransform(nx, (v) => (0.8 - v * 0.5) * CARD_W);
  const y1 = useTransform(ny, (v) => -v * 0.5 * CARD_H);
  const y2 = useTransform(ny, (v) => (1 - v * 0.5) * CARD_H);
  return (
    <svg width={CARD_W} height={CARD_H} style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      <defs>
        <motion.linearGradient id="ml-glassmorphism-sheen" gradientUnits="userSpaceOnUse" x1={x1} y1={y1} x2={x2} y2={y2}>
          <stop offset="0" stopColor="#fff" stopOpacity={0} />
          <stop offset="0.5" stopColor="#fff" stopOpacity={0.35} />
          <stop offset="1" stopColor="#fff" stopOpacity={0} />
        </motion.linearGradient>
      </defs>
      <rect width={CARD_W} height={CARD_H} rx={24} fill="url(#ml-glassmorphism-sheen)" />
    </svg>
  );
}

/** `GlassOrbs`: three blurred colour orbs on 7–12 s loops, shifted by the tilt parallax. */
function Orbs({ nx, ny, fps }: { nx: MotionValue<number>; ny: MotionValue<number>; fps?: number }) {
  const time = useClock(true, fps);
  const px = -nx.get() * 18;
  const py = -ny.get() * 18;
  const orb = (color: string, size: number, x: number, y: number) => (
    <div
      style={{
        position: "absolute",
        left: "50%",
        top: "50%",
        width: size,
        height: size,
        marginLeft: -size / 2 + x + px,
        marginTop: -size / 2 + y + py,
        borderRadius: "50%",
        background: color,
      }}
    />
  );
  return (
    <div style={{ position: "absolute", inset: -14, filter: "blur(30px)" }}>
      {orb(Palette.pink, 170, Math.cos(time / 1.4) * 70, Math.sin(time / 1.9) * 60 - 30)}
      {orb(Palette.sky, 180, Math.sin(time / 1.7) * 80 + 20, Math.cos(time / 1.3) * 50 + 40)}
      {orb(Palette.amber, 120, Math.cos(time / 1.1 + 2) * 90, Math.sin(time / 1.5 + 1) * 80)}
    </div>
  );
}
