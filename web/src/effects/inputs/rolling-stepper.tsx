/** inputs.rolling-stepper (Inputs+RollingStepper.swift) */
import { motion } from "motion/react";
import { Minus, Plus } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, demoCard, ease, fonts, mix, progress, spring, springAt, textStyle, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { LandscapeArt } from "../showcase/signature";
import { Divider, PressScale } from "./_a-common";

const MIN = 1;

export default function RollingStepper({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const maximum = Math.max(ctx.i("max"), 1);
  const [value, setValueState] = useState(2);
  const valueRef = useRef(2);
  const [nudge, setNudge] = useState(0);
  const [nudgeT, setNudgeT] = useState(spring(0.3, 0.8));
  const [limitHits, setLimitHits] = useState(0);
  const [limitSide, setLimitSide] = useState(1);
  const [flash, setFlash] = useState(false);
  const direction = useRef(1);
  const setValue = (v: number) => {
    valueRef.current = v;
    setValueState(v);
  };

  useEffect(() => {
    if (valueRef.current > maximum) setValue(maximum);
  }, [maximum]);

  const hitLimit = (side: number) => {
    haptics.tap("rigid");
    setLimitSide(side);
    setLimitHits((h) => h + 1);
    setFlash(true);
    after(0.25, () => setFlash(false));
  };

  const change = (delta: number) => {
    const target = valueRef.current + delta;
    if (target < MIN || target > maximum) {
      hitLimit(delta);
      return;
    }
    haptics.tap();
    setValue(target);
    setNudgeT(spring(ctx.n("response"), 0.8));
    setNudge(delta * ctx.n("nudge"));
    after(0.12, () => {
      setNudgeT(spring(0.4, 0.6));
      setNudge(0);
    });
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const v = valueRef.current;
      if (v >= maximum && direction.current > 0) {
        hitLimit(1);
        direction.current = -1;
        return;
      }
      if (v <= MIN && direction.current < 0) {
        hitLimit(-1);
        direction.current = 1;
        return;
      }
      change(direction.current);
    },
    { every: 0.7, delay: 0.4 },
  );

  const zh = ctx.lang === "zh";
  const total = zh ? 1680 + value * 320 : 240 + value * 45;

  // Limit bump: cubic to 8 (80 ms), snappy spring to −3 (140 ms), bouncy spring home (400 ms).
  const t = useElapsed(limitHits, 0.62, true);
  let shift = 0;
  if (t >= 0) {
    if (t < 0.08) shift = 8 * ease.inOut(progress(t, 0, 0.08));
    else if (t < 0.22) shift = mix(8, -3, springAt(t - 0.08, 0.14, 0.85));
    else if (t < 0.62) shift = mix(-3, 0, springAt(t - 0.22, 0.4, 0.7));
  }

  const stepButton = (kind: "minus" | "plus", enabled: boolean, action: () => void) => (
    <PressScale scale={0.88} onClick={action} style={{ width: 40, height: 40 }}>
      <div
        style={{
          width: 40,
          height: 40,
          borderRadius: "50%",
          display: "grid",
          placeItems: "center",
          position: "relative",
          color: enabled ? "#fff" : Palette.secondaryLabel,
          transition: "color 0.2s ease-out",
        }}
      >
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.labelAlpha(0.08) }} />
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.ocean, opacity: enabled ? 1 : 0, transition: "opacity 0.2s ease-out" }} />
        <span style={{ position: "relative", display: "grid" }}>{kind === "minus" ? <Minus size={17} strokeWidth={3} /> : <Plus size={17} strokeWidth={3} />}</span>
      </div>
    </PressScale>
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 310, padding: 18, display: "flex", flexDirection: "column", gap: 14 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ position: "relative", width: 52, height: 52, borderRadius: 12, overflow: "hidden", flexShrink: 0 }}>
            <LandscapeArt seed={2} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ ...textStyle.headline }}>{zh ? "湖畔小木屋" : "Lakeside Cabin"}</span>
            <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{zh ? "2 晚 · 7月8日 – 10日" : "2 nights · Jul 8 – 10"}</span>
          </div>
        </div>
        <Divider />
        <div style={{ display: "flex", alignItems: "center" }}>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ ...textStyle.subheadline, fontWeight: 600 }}>{zh ? "入住人数" : "Guests"}</span>
            <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>{zh ? `最多 ${maximum} 人` : `Up to ${maximum}`}</span>
          </div>
          <div style={{ flex: 1 }} />
          <div style={{ display: "flex", alignItems: "center", gap: 8, padding: 5, borderRadius: 30, background: Palette.labelAlpha(0.05), boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }}>
            {stepButton("minus", value > MIN, () => change(-1))}
            <motion.div initial={false} animate={{ x: nudge }} transition={nudgeT} style={{ width: 48, display: "flex", justifyContent: "center" }}>
              <div style={{ transform: `translateX(${shift * limitSide}px)` }}>
                <NumericText
                  value={value}
                  style={{
                    fontFamily: fonts.rounded,
                    fontSize: 30,
                    fontWeight: 700,
                    lineHeight: "36px",
                    color: flash ? Palette.red : Palette.label,
                    transition: flash ? "color 0.1s ease-out" : "color 0.35s ease-in",
                  }}
                />
              </div>
            </motion.div>
            {stepButton("plus", value < maximum, () => change(1))}
          </div>
        </div>
        <Divider />
        <div style={{ display: "flex", alignItems: "baseline" }}>
          <span style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.secondaryLabel }}>{zh ? "总价" : "Total"}</span>
          <div style={{ flex: 1 }} />
          <NumericText value={total} text={(zh ? "¥" : "$") + total.toLocaleString("en-US")} style={{ fontFamily: fonts.rounded, ...textStyle.title3, fontWeight: 700 }} />
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap + or −, then push past the limits" zh="点击加减，再试试超出上下限" style={{ paddingBottom: 16 }} />
    </div>
  );
}

