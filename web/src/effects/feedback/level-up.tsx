/** feedback.level-up · 升级翻牌 (Feedback+SuccessVariations.swift) */
import { motion, useMotionValueEvent, useTransform } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, anim, demoCard, ease, fonts, spring, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { PrimaryCapsule, track, useAnimated } from "./shared";

const START_LEVEL = 4;

export default function LevelUp({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [xp, setXp] = useState(0.7);
  const [bar, barTo, barSet] = useAnimated(0.7);
  const [turnsMV, turnsTo] = useAnimated(0);
  const [turns, setTurns] = useState(0);
  useMotionValueEvent(turnsMV, "change", setTurns);
  const [gains, setGains] = useState(0);
  const [gleams, setGleams] = useState(0);
  const [flash, setFlash] = useState(false);
  const busy = useRef(false);
  const xpRef = useRef(0.7);
  const zh = ctx.lang === "zh";
  const gain = Math.max(ctx.i("gain"), 10);

  const complete = (buzz = true) => {
    if (busy.current) return;
    busy.current = true;
    const total = xpRef.current + gain / 100;
    setGains((g) => g + 1);
    clearAll();
    if (buzz) haptics.tap();
    const shown = Math.min(total, 1);
    xpRef.current = shown;
    setXp(shown);
    barTo(shown, anim.easeInOut(0.5));
    after(0.55, () => {
      if (total < 1) {
        busy.current = false;
        return;
      }
      setFlash(true);
      turnsTo(Math.round(turnsMV.get()) + 1, spring(ctx.n("response"), ctx.n("damping")));
      if (buzz) haptics.success();
      after(0.2, () => {
        setFlash(false);
        barSet(0);
        xpRef.current = 0;
        setXp(0);
        after(0.02, () => {
          xpRef.current = total - 1;
          setXp(total - 1);
          barTo(total - 1, anim.easeOut(0.45));
          after(0.25, () => {
            setGleams((g) => g + 1);
            after(0.5, () => (busy.current = false));
          });
        });
      });
    });
  };

  useAutoplay(ctx.isPreview, () => complete(false), { every: 2.6, delay: 0.5 });

  const fill = useTransform(bar, (v) => Math.max(10, 180 * Math.min(v, 1)));
  const passed = Math.floor(turns + 0.5);
  const mirrored = passed % 2 === 1;
  const g = useElapsed(gleams, 0.5, true);
  const gleamX = g < 0 || g >= 0.5 ? -70 : track(g, -70, [{ move: -60 }, { cubic: 60, d: 0.5 }]);
  const f = useElapsed(gains, 0.9, true);
  const floatY = f < 0 ? 0 : track(f, 0, [{ move: 0 }, { cubic: -40, d: 0.9 }]);
  const floatO = f < 0 ? 0 : f < 0.4 ? 1 : 1 - ease.inOut(Math.min((f - 0.4) / 0.5, 1));

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ ...demoCard(22), padding: 18, width: 298, display: "flex", flexDirection: "column", gap: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <div style={{ width: 56, height: 56, flexShrink: 0, perspective: 180, filter: `drop-shadow(0 5px 10px ${alpha(Palette.violet, 0.4)})` }}>
            <div style={{ position: "relative", width: 56, height: 56, transform: `rotateY(${turns * 180}deg)` }}>
              <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: `linear-gradient(135deg, ${Palette.violet}, ${Palette.indigo})`, boxShadow: "inset 0 0 0 2px rgb(255 255 255 / 0.35)", overflow: "hidden" }}>
                <div style={{ position: "absolute", left: 16 + gleamX, top: -17, width: 24, height: 90, transform: "rotate(25deg)", background: "linear-gradient(90deg, rgb(255 255 255 / 0), rgb(255 255 255 / 0.7), rgb(255 255 255 / 0))" }} />
              </div>
              <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", color: "#fff", fontFamily: fonts.rounded, transform: `scaleX(${mirrored ? -1 : 1})` }}>
                <span style={{ fontSize: 9, lineHeight: "11px", fontWeight: 800, opacity: 0.8 }}>LV</span>
                <span style={{ fontSize: 22, lineHeight: "24px", fontWeight: 800, fontVariantNumeric: "tabular-nums", marginTop: -2 }}>{START_LEVEL + passed}</span>
              </div>
            </div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "西班牙语 · 第 12 课" : "Spanish · Lesson 12"}</span>
            <div style={{ position: "relative", width: 180, height: 10, borderRadius: 5, background: Palette.labelAlpha(0.08) }}>
              <motion.div style={{ position: "absolute", left: 0, top: 0, height: 10, width: fill, borderRadius: 5, background: `linear-gradient(90deg, ${Palette.amber}, ${Palette.coral})` }} />
              <motion.div initial={false} animate={{ opacity: flash ? 0.8 : 0 }} transition={flash ? anim.easeOut(0.12) : anim.easeIn(0.25)} style={{ position: "absolute", inset: 0, borderRadius: 5, background: "#fff" }} />
            </div>
            <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, display: "flex" }}>
              <NumericText value={xp} text={String(Math.round(xp * 100))} />
              &nbsp;/ 100 XP
            </span>
          </div>
        </div>
        <div style={{ position: "relative" }}>
          <PrimaryCapsule onClick={() => complete()} height={48} style={{ width: "100%", justifyContent: "center", boxShadow: "none" }}>
            {zh ? "完成课程" : "Complete lesson"}
          </PrimaryCapsule>
          <div style={{ position: "absolute", left: 0, right: 0, top: 0, display: "flex", justifyContent: "center", pointerEvents: "none", transform: `translateY(${floatY}px)`, opacity: floatO }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 800, fontVariantNumeric: "tabular-nums", color: Palette.coral }}>+{gain} XP</span>
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap Complete lesson" zh="点击“完成课程”" />
    </div>
  );
}
