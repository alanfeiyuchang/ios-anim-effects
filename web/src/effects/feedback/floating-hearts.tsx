/** feedback.floating-hearts · 飘心 (Feedback+BadgeVariations.swift) */
import { motion } from "motion/react";
import { Eye, Heart, MicVocal } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, glass, pressHandlers, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";

interface FloatHeart { id: number; born: number; phase: number; size: number; color: string }
const COLORS = [Palette.pink, Palette.red, Palette.coral, Palette.violet, Palette.amber];

export default function FloatingHearts({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const hearts = useRef<FloatHeart[]>([]);
  const nextID = useRef(0);
  const [likes, setLikes] = useState(1284);
  const [pressed, setPressed] = useState(false);
  const [, setTick] = useState(0);
  const life = Math.max(ctx.n("life"), 0.3);
  const sway = ctx.n("sway");
  const rise = ctx.n("rise");
  const fps = ctx.isPreview ? 30 : undefined;
  const running = useRef(false);

  const loop = () => {
    if (running.current) return;
    running.current = true;
    let last = 0;
    const step = (ms: number) => {
      const now = performance.now() / 1000;
      hearts.current = hearts.current.filter((h) => now - h.born <= life);
      if (!hearts.current.length) {
        running.current = false;
        setTick((t) => t + 1);
        return;
      }
      if (!fps || ms - last >= 1000 / fps - 1) {
        last = ms;
        setTick((t) => t + 1);
      }
      requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  };
  useEffect(() => () => void (hearts.current = []), []);

  const spawn = () => {
    const now = performance.now() / 1000;
    hearts.current = [...hearts.current.filter((h) => now - h.born <= life), { id: nextID.current, born: now, phase: Math.random() * 2 * Math.PI, size: 24 + Math.random() * 10, color: COLORS[nextID.current % COLORS.length] }];
    nextID.current += 1;
    setLikes((l) => l + 1);
    haptics.tap("soft");
    loop();
  };

  useAutoplay(ctx.isPreview, spawn, { every: 0.32, delay: 0.3 });
  const now = performance.now() / 1000;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ position: "relative", width: 280, height: 300, flexShrink: 0, borderRadius: 26, overflow: "hidden", boxShadow: "0 10px 18px rgb(0 0 0 / 0.15)", background: "linear-gradient(#2B1A4F, #6E3A8C, #E0708A)" }}>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: "rgb(255 255 255 / 0.18)" }}>
          <MicVocal size={96} strokeWidth={1.2} />
        </div>
        <div style={{ position: "absolute", left: 14, top: 14, display: "flex", alignItems: "center", gap: 8 }}>
          <motion.span
            animate={{ opacity: [1, 0.65] }}
            transition={{ duration: 0.8, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
            style={{ fontSize: 11, lineHeight: "13px", fontWeight: 800, color: "#fff", padding: "4px 8px", borderRadius: 999, background: Palette.red }}
          >
            LIVE
          </motion.span>
          <span style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 11, fontWeight: 600, color: "rgb(255 255 255 / 0.9)" }}>
            <Eye size={12} strokeWidth={2.4} />
            2.4k
          </span>
        </div>
        <div style={{ position: "absolute", right: 22, bottom: 30, width: 0, height: 0, pointerEvents: "none" }}>
          {hearts.current.map((h) => {
            const age = now - h.born;
            const u = Math.min(Math.max(age / life, 0), 1);
            const eased = 1 - (1 - u) * (1 - u);
            const pop = age < 0.15 ? (age / 0.15) * 1.15 : age < 0.3 ? 1.15 - ((age - 0.15) / 0.15) * 0.15 : 1;
            const x = sway * Math.sin(age * 3 + h.phase) * Math.min(age / 0.3, 1);
            const y = -rise * eased;
            return (
              <div
                key={h.id}
                style={{ position: "absolute", right: 0, bottom: 0, transform: `translate(${x}px, ${y}px) scale(${pop})`, transformOrigin: "50% 50%", opacity: 1 - u * u, color: h.color, filter: `drop-shadow(0 0 4px ${alpha(h.color, 0.4)})` }}
              >
                <Heart size={h.size} fill="currentColor" strokeWidth={0} />
              </div>
            );
          })}
        </div>
        <motion.button
          type="button"
          onClick={spawn}
          {...pressHandlers(setPressed)}
          animate={{ scale: pressed ? 0.88 : 1 }}
          transition={spring(0.25, 0.5)}
          style={{ position: "absolute", right: 16, bottom: 16, display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}
        >
          <div style={{ width: 46, height: 46, borderRadius: "50%", ...glass("ultraThin", "dark"), display: "grid", placeItems: "center", color: Palette.pink }}>
            <Heart size={22} fill="currentColor" strokeWidth={0} />
          </div>
          <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 700, color: "#fff" }}>
            <NumericText value={likes} text={likes.toLocaleString("en-US")} />
          </span>
        </motion.button>
      </div>
      <DemoHint ctx={ctx} en="Tap the heart repeatedly" zh="连续点击爱心" />
    </div>
  );
}
