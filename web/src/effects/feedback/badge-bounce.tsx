/** feedback.badge-bounce · 角标弹跳 (Feedback+Badges.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Bell, Minus, Plus } from "lucide-react";
import { useRef, useState, type ReactNode } from "react";
import { DemoHint, NumericText, Palette, SymbolBounce, alpha, fonts, spring, useAutoplay, useElapsed, useHaptics, type DemoProps } from "../../kit";
import { track } from "./shared";

export default function BadgeBounce({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [count, setCount] = useState(3);
  const [rings, setRings] = useState(0);
  const countRef = useRef(count);
  countRef.current = count;

  const add = () => {
    haptics.tap();
    setRings((r) => r + 1);
    setCount((c) => c + 1);
  };
  const remove = () => {
    if (countRef.current <= 0) return;
    haptics.selection();
    setCount((c) => c - 1);
  };

  useAutoplay(ctx.isPreview, () => (countRef.current >= 12 ? setCount(0) : add()), { every: 1.1, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 30 }}>
      <Tile count={count} rings={rings} swell={ctx.n("swell")} bounce={ctx.n("bounce")} onTap={add} />
      <div style={{ display: "flex", gap: 14 }}>
        <RoundButton onClick={remove}>
          <Minus size={18} strokeWidth={2.6} />
        </RoundButton>
        <RoundButton onClick={add}>
          <Plus size={18} strokeWidth={2.6} />
        </RoundButton>
      </div>
      <DemoHint ctx={ctx} en="Tap + or the app tile" zh="点击 + 或应用图块" />
    </div>
  );
}

function RoundButton({ onClick, children }: { onClick: () => void; children: ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{ width: 48, height: 48, borderRadius: "50%", background: Palette.elevated, display: "grid", placeItems: "center", boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 4px 8px rgb(0 0 0 / 0.08)` }}
    >
      {children}
    </button>
  );
}

function Tile({ count, rings, swell, bounce, onTap }: { count: number; rings: number; swell: number; bounce: number; onTap: () => void }) {
  return (
    <div onClick={onTap} style={{ position: "relative", width: 84, height: 84, flexShrink: 0, cursor: "pointer" }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: 22, background: Palette.sunset, boxShadow: `0 8px 14px ${alpha(Palette.coral, 0.35)}`, display: "grid", placeItems: "center", color: "#fff" }}>
        <SymbolBounce trigger={rings} kind="wiggle">
          <Bell size={36} fill="currentColor" strokeWidth={1.6} />
        </SymbolBounce>
      </div>
      <AnimatePresence initial={false}>
        {count > 0 && (
          <motion.div
            key="badge"
            initial={{ scale: 0, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0, opacity: 0 }}
            transition={spring(0.35, 0.8)}
            style={{ position: "absolute", left: 80, top: 0, width: 0, height: 0 }}
          >
            <Badge count={count} rings={rings} swell={swell} bounce={bounce} />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function Badge({ count, rings, swell, bounce }: { count: number; rings: number; swell: number; bounce: number }) {
  const t = useElapsed(rings, 1.2, true);
  const idle = t < 0;
  const damping = bounce >= 0 ? 1 - bounce : 1 / (1 + bounce);
  const scale = idle ? 1 : track(t, 1, [{ cubic: swell, d: 0.12 }, { spring: 1, d: 0.5, response: 0.5, damping }]);
  const y = idle ? 0 : track(t, 0, [{ cubic: -6, d: 0.12 }, { spring: 0, d: 0.5, response: 0.5, damping }]);
  const ring = idle ? 1 : track(t, 1, [{ move: 1 }, { cubic: 2.1, d: 0.55 }]);
  const ringOpacity = idle ? 0 : track(t, 0, [{ move: 0.7 }, { cubic: 0, d: 0.55 }]);
  return (
    <div style={{ position: "absolute", left: 0, top: 0, transform: `translate(-50%, -50%) translateY(${y}px) scale(${scale})` }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: 999, boxShadow: `inset 0 0 0 2px ${Palette.red}`, transform: `scale(${ring})`, opacity: ringOpacity }} />
      <div
        style={{
          position: "relative",
          minWidth: 28,
          height: 28,
          padding: "0 8px",
          borderRadius: 999,
          background: Palette.red,
          boxShadow: `inset 0 0 0 2.5px ${Palette.surface}`,
          display: "grid",
          placeItems: "center",
          color: "#fff",
          fontFamily: fonts.rounded,
          fontSize: 15,
          fontWeight: 700,
        }}
      >
        <NumericText value={count} text={count > 99 ? "99+" : String(count)} />
      </div>
    </div>
  );
}
