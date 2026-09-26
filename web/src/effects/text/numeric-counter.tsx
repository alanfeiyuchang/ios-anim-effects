/** text.numeric-counter · 数字滚动 (Text+NumericCounter.swift) */
import { AnimatePresence, motion } from "motion/react";
import { ArrowDownRight, ArrowUpRight, Minus, Plus } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, alpha, anim, demoCard, fonts, glass, springDB, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { RollingText, formatNumber, randInt } from "./_text-kit";

export default function NumericCounter({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [balance, setBalance] = useState(12_480.5);
  const [followers, setFollowers] = useState(48_210);
  const [lastDelta, setLastDelta] = useState(1_204.1);
  const isFollowers = ctx.i("style") === 1;
  const value = isFollowers ? followers : balance;
  const transition = springDB(ctx.n("duration"), ctx.n("bounce"));

  const formatted = isFollowers ? formatNumber(Math.trunc(followers)) : (ctx.lang === "zh" ? "¥" : "$") + formatNumber(balance, 2);
  const magnitude = Math.abs(lastDelta);
  const deltaText = (lastDelta >= 0 ? "+" : "−") + (isFollowers ? formatNumber(Math.trunc(magnitude)) : formatNumber(magnitude, 2));

  const bump = (up: boolean) => {
    const direction = up ? 1 : -1;
    const delta = isFollowers ? direction * randInt(12, 480) : direction * (randInt(1_200, 240_000) / 100);
    setLastDelta(delta);
    if (isFollowers) setFollowers((f) => Math.max(0, f + delta));
    else setBalance((b) => Math.max(0, b + delta));
    haptics.selection();
  };

  useAutoplay(ctx.isPreview, () => bump(randInt(0, 3) !== 0), { every: 1.5 });

  const isUp = lastDelta >= 0;
  const tone = isUp ? Palette.green : Palette.red;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <div style={{ ...demoCard(26), width: 284, padding: 22, display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 10 }}>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, color: Palette.secondaryLabel }}>
          {isFollowers ? ctx.t("Followers", "粉丝") : ctx.t("Total balance", "账户余额")}
        </span>
        <RollingText
          value={value}
          text={formatted}
          transition={transition}
          style={{ fontFamily: fonts.rounded, fontSize: 44, fontWeight: 600, lineHeight: "52px", color: Palette.label }}
        />
        <motion.div
          animate={{ backgroundColor: alpha(tone, 0.14), color: tone }}
          transition={transition}
          style={{ display: "flex", alignItems: "center", gap: 4, padding: "5px 10px", borderRadius: 999 }}
        >
          <span style={{ position: "relative", display: "grid", width: 12, height: 12 }}>
            <AnimatePresence mode="popLayout" initial={false}>
              <motion.span
                key={isUp ? "up" : "down"}
                initial={{ scale: 0.4, opacity: 0, filter: "blur(2px)" }}
                animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                exit={{ scale: 0.4, opacity: 0, filter: "blur(2px)" }}
                transition={anim.snappyD(0.3)}
                style={{ display: "grid" }}
              >
                {isUp ? <ArrowUpRight size={12} strokeWidth={3.2} /> : <ArrowDownRight size={12} strokeWidth={3.2} />}
              </motion.span>
            </AnimatePresence>
          </span>
          <RollingText value={lastDelta} text={deltaText} transition={transition} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }} />
        </motion.div>
      </div>
      <div style={{ display: "flex", gap: 14 }}>
        <StepButton onClick={() => bump(false)}>
          <Minus size={21} strokeWidth={2.6} />
        </StepButton>
        <StepButton onClick={() => bump(true)}>
          <Plus size={21} strokeWidth={2.6} />
        </StepButton>
      </div>
      <DemoHint ctx={ctx} en="Tap + or −" zh="点击 + 或 −" />
    </div>
  );
}

function StepButton({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        width: 56,
        height: 56,
        borderRadius: "50%",
        display: "grid",
        placeItems: "center",
        color: Palette.label,
        ...glass("regular"),
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
      }}
    >
      {children}
    </button>
  );
}
