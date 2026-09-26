/** cards.swipe-stack · 滑动卡片堆 (Cards+SwipeStack.swift) */
import { animate, useMotionValue } from "motion/react";
import { Flower2, Heart, Mountain, Music, Utensils, Waves, X, type LucideIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, clamp, fonts, spring, useAutoplay, useHaptics, usePan, white, type DemoContext, type DemoProps } from "../../kit";
import { Stage, diag, predictEnd, tr, useMV, type LText } from "./shared";

interface Profile {
  name: string;
  detail: LText;
  Icon: LucideIcon;
  filled: boolean;
  colors: string[];
}

const profiles: Profile[] = [
  { name: "Maya, 27", detail: ["Product designer · 2 km", "产品设计师 · 2 公里"], Icon: Flower2, filled: false, colors: ["#FFB36B", "#FF5F8F"] },
  { name: "Leo, 31", detail: ["Climber · 5 km", "攀岩爱好者 · 5 公里"], Icon: Mountain, filled: true, colors: ["#4ED6A0", "#2A9DF4"] },
  { name: "Iris, 25", detail: ["Musician · 1 km", "音乐人 · 1 公里"], Icon: Music, filled: false, colors: ["#A46BFF", "#6E7BFF"] },
  { name: "Kai, 29", detail: ["Surfer · 8 km", "冲浪者 · 8 公里"], Icon: Waves, filled: false, colors: ["#3AC4FF", "#4F7CFF"] },
  { name: "Nora, 33", detail: ["Chef · 3 km", "主厨 · 3 公里"], Icon: Utensils, filled: false, colors: ["#FFC247", "#FF7A45"] },
];

export default function SwipeStack({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [order, setOrder] = useState([0, 1, 2, 3, 4]);
  const ox = useMotionValue(0);
  const oy = useMotionValue(0);
  const [flinging, setFlinging] = useState(false);
  const flingingRef = useRef(false);
  const held = useRef(false);
  const autoDirection = useRef(-1);
  const script = useRef(0);
  useEffect(() => () => window.clearTimeout(script.current), []);

  const x = useMV(ox);
  const y = useMV(oy);
  const threshold = ctx.n("threshold");
  const progress = Math.min(Math.abs(x) / threshold, 1);

  const fling = (direction: number) => {
    if (flingingRef.current) return;
    flingingRef.current = true;
    setFlinging(true);
    if (direction > 0) haptics.success();
    else haptics.tap("medium");
    const t = spring(ctx.n("response"), 0.86);
    animate(ox, direction * 520, t);
    animate(oy, oy.get() + 60, t);
    window.setTimeout(() => {
      setOrder((o) => [...o.slice(1), o[0]]);
      ox.jump(0);
      oy.jump(0);
      flingingRef.current = false;
      setFlinging(false);
    }, 320);
  };

  const snapBack = () => {
    const t = spring(0.45, ctx.n("snap"));
    animate(ox, 0, t);
    animate(oy, 0, t);
  };

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (flingingRef.current) return;
        if (!held.current) {
          held.current = true;
          window.clearTimeout(script.current);
        }
        ox.jump(translation.x);
        oy.jump(translation.y);
      },
      onEnd: ({ translation, velocity }) => {
        if (!held.current || flingingRef.current) return;
        held.current = false;
        const predicted = predictEnd(translation.x, velocity.x);
        if (Math.abs(translation.x) > threshold || Math.abs(predicted) > threshold * 2) fling(predicted >= 0 ? 1 : -1);
        else snapBack();
      },
    },
    10,
  );

  const buttonFling = (direction: number) => {
    if (held.current) return;
    window.clearTimeout(script.current);
    fling(direction);
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (held.current || flingingRef.current) return;
      autoDirection.current *= -1;
      const direction = autoDirection.current;
      const t = spring(0.5, 0.8);
      animate(ox, direction * 80, t);
      animate(oy, -6, t);
      window.clearTimeout(script.current);
      script.current = window.setTimeout(() => fling(direction), 550);
    },
    { every: 1.7 },
  );

  return (
    <Stage gap={16}>
      <div style={{ position: "relative", width: 200, height: 284, flexShrink: 0 }}>
        {order.map((id, depth) => {
          const isTop = depth === 0;
          const slot = Math.max(depth - progress, 0);
          const rotation = isTop ? (x / 220) * ctx.n("rotation") : 0;
          const appear = depth < 3 ? 1 : depth === 3 ? progress : 0;
          return (
            <div
              key={id}
              {...(isTop && !flinging ? pan : {})}
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                zIndex: order.length - depth,
                opacity: appear,
                transform: isTop
                  ? `translate(${x}px, ${y}px) rotate(${rotation}deg)`
                  : `translateY(${slot * 22}px) scale(${1 - slot * 0.06})`,
                transformOrigin: isTop ? "50% 100%" : "50% 50%",
                pointerEvents: isTop && !flinging ? "auto" : "none",
                touchAction: "none",
                cursor: isTop ? "grab" : undefined,
              }}
            >
              <SwipeCard profile={profiles[id]} like={isTop ? x / threshold : 0} ctx={ctx} />
            </div>
          );
        })}
      </div>
      <div style={{ display: "flex", gap: 36 }}>
        <ActionButton Icon={X} color={Palette.red} amount={x < 0 ? progress : 0} onClick={() => buttonFling(-1)} />
        <ActionButton Icon={Heart} filled color={Palette.green} amount={x > 0 ? progress : 0} onClick={() => buttonFling(1)} />
      </div>
      <DemoHint ctx={ctx} en="Swipe the card or tap a button" zh="滑动卡片或点按钮" />
    </Stage>
  );
}

function ActionButton({ Icon, filled, color, amount, onClick }: { Icon: LucideIcon; filled?: boolean; color: string; amount: number; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        width: 50,
        height: 50,
        borderRadius: "50%",
        display: "grid",
        placeItems: "center",
        background: `linear-gradient(${colorAlpha(color, amount)}, ${colorAlpha(color, amount)}), ${Palette.elevated}`,
        boxShadow: `0 4px 8px ${black(0.1)}`,
        transform: `scale(${1 + amount * 0.18})`,
        color: amount > 0.99 ? "#fff" : color,
      }}
    >
      <Icon size={21} strokeWidth={3} fill={filled ? "currentColor" : "none"} />
    </button>
  );
}

const colorAlpha = (hexColor: string, a: number) => {
  const n = parseInt(hexColor.slice(1), 16);
  return `rgb(${(n >> 16) & 255} ${(n >> 8) & 255} ${n & 255} / ${a})`;
};

function SwipeCard({ profile, like, ctx }: { profile: Profile; like: number; ctx: DemoContext }) {
  const stampOpacity = (amount: number) => clamp((amount - 0.6) / 0.4);
  const { Icon } = profile;
  return (
    <div style={{ width: 200, height: 250, borderRadius: 26, boxShadow: `0 8px 14px ${black(0.16)}` }}>
      <div style={{ position: "relative", width: 200, height: 250, borderRadius: 26, overflow: "hidden", background: diag(profile.colors) }}>
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", transform: "translateY(-26px)", color: white(0.92), filter: `drop-shadow(0 6px 10px ${black(0.12)})` }}>
          <Icon size={80} strokeWidth={profile.filled ? 0.6 : 1.2} fill={profile.filled ? "currentColor" : "none"} />
        </div>
        <div style={{ position: "absolute", inset: 0, background: `linear-gradient(transparent 50%, ${black(0.5)})` }} />
        <div style={{ position: "absolute", left: 0, bottom: 0, padding: 16, color: "#fff", display: "flex", flexDirection: "column", gap: 3 }}>
          <span style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{profile.name}</span>
          <span style={{ fontSize: 13, lineHeight: "18px", fontWeight: 500, opacity: 0.85 }}>{tr(ctx, profile.detail)}</span>
        </div>
        <Stamp text={ctx.t("LIKE", "喜欢")} color={Palette.green} angle={-14} opacity={stampOpacity(like)} side="left" />
        <Stamp text={ctx.t("NOPE", "无感")} color={Palette.red} angle={14} opacity={stampOpacity(-like)} side="right" />
      </div>
    </div>
  );
}

function Stamp({ text, color, angle, opacity, side }: { text: string; color: string; angle: number; opacity: number; side: "left" | "right" }) {
  return (
    <div
      style={{
        position: "absolute",
        top: 18,
        [side]: 18,
        opacity,
        transform: `rotate(${angle}deg)`,
        fontFamily: fonts.rounded,
        fontSize: 24,
        lineHeight: "29px",
        fontWeight: 800,
        letterSpacing: 2,
        color,
        padding: "3px 10px",
        borderRadius: 8,
        background: white(0.18),
        boxShadow: `inset 0 0 0 3.5px ${color}`,
      }}
    >
      {text}
    </div>
  );
}
