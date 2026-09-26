/** icons.padlock · 挂锁解锁 (Icons+Padlock.swift) */
import { motion } from "motion/react";
import { useState } from "react";
import { DemoHint, Palette, anim, delayed, hex, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { C, Glyph, L, Replace, SYM, sym, track, useSince } from "./_icons-kit";

const SHACKLE_W = 50;
const SHACKLE_H = 62;
const LINE = 10;

export default function Padlock({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [unlocked, setUnlocked] = useState(false);
  const [pulses, setPulses] = useState(0);
  const swivel = ctx.i("style") === 0;
  const s = spring(ctx.n("response"), 0.62);

  const t = useSince(pulses, 0.9);
  const pulseScale = t < 0 ? 0.8 : track(t, 0.8, [L(0.8, 0.26), C(1.8, 0.6)]);
  const pulseOpacity = t < 0 ? 0 : track(t, 0, [L(0, 0.25), L(0.6, 0.01), C(0, 0.6)]);

  /** `scripted`: the delayed haptics stay silent for autoplay and the detail intro. */
  const toggle = (scripted = false) => {
    const next = !unlocked;
    setUnlocked(next);
    if (next) {
      setPulses((p) => p + 1);
      after(0.25, () => !scripted && haptics.success());
    } else {
      after(0.4, () => !scripted && haptics.tap("rigid"));
    }
  };
  useAutoplay(ctx.isPreview, () => toggle(true), { every: 1.8 });

  const colorDelay = unlocked ? 0.22 : swivel ? 0.3 : 0.1;
  const r = (SHACKLE_W - LINE) / 2;
  const shackle = `M${LINE / 2} ${SHACKLE_H}V${LINE / 2 + r}A${r} ${r} 0 0 1 ${SHACKLE_W - LINE / 2} ${LINE / 2 + r}V${SHACKLE_H - 10}`;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 26 }}>
      <div onClick={() => toggle()} style={{ position: "relative", width: 200, height: 190, cursor: "pointer" }}>
        {ctx.b("pulse") && (
          <div
            style={{
              position: "absolute",
              left: 35,
              top: 30 + 8,
              width: 130,
              height: 130,
              borderRadius: "50%",
              boxShadow: `inset 0 0 0 3px ${Palette.green}`,
              transform: `scale(${pulseScale})`,
              opacity: pulseOpacity,
            }}
          />
        )}
        <motion.div
          initial={false}
          animate={{ y: unlocked ? -44 : -30 }}
          transition={delayed(s, unlocked ? 0.1 : swivel ? 0.24 : 0)}
          style={{ position: "absolute", left: 100 - SHACKLE_W / 2, top: 95 - SHACKLE_H / 2, width: SHACKLE_W, height: SHACKLE_H, perspective: 220 }}
        >
          <motion.svg
            width={SHACKLE_W}
            height={SHACKLE_H}
            viewBox={`-6 -6 ${SHACKLE_W + 12} ${SHACKLE_H + 12}`}
            initial={false}
            animate={{ rotateY: unlocked && swivel ? -180 : 0 }}
            transition={delayed(s, unlocked ? 0.22 : 0)}
            style={{ overflow: "visible", transformOrigin: `${LINE / 2}px 50%`, width: SHACKLE_W + 12, height: SHACKLE_H + 12, margin: -6 }}
          >
            <defs>
              <linearGradient id="padlock-steel" x1="0" y1="0" x2={SHACKLE_W} y2="0" gradientUnits="userSpaceOnUse">
                <stop offset="0" stopColor={hex(0xd9dee8)} />
                <stop offset="1" stopColor={hex(0x8c94a6)} />
              </linearGradient>
            </defs>
            <path d={shackle} fill="none" stroke="url(#padlock-steel)" strokeWidth={LINE} strokeLinecap="round" />
          </motion.svg>
        </motion.div>
        <div style={{ position: "absolute", left: 100 - 42, top: 95 + 20 - 33, width: 84, height: 66 }}>
          {[false, true].map((state) => (
            <motion.div
              key={String(state)}
              initial={false}
              animate={{ opacity: unlocked === state ? 1 : 0 }}
              transition={delayed(anim.smoothD(0.35), colorDelay)}
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: 18,
                background: state ? `linear-gradient(135deg, ${Palette.mint}, ${Palette.green})` : `linear-gradient(135deg, ${Palette.indigo}, ${Palette.violet})`,
                boxShadow: `inset 0 0 0 1px rgb(255 255 255 / 0.3), 0 8px 16px ${state ? "rgb(52 199 123 / 0.35)" : "rgb(110 123 255 / 0.35)"}`,
              }}
            />
          ))}
          <motion.div
            initial={false}
            animate={{ rotate: unlocked ? 90 : 0 }}
            transition={delayed(spring(0.25, 0.7), unlocked ? 0 : 0.36)}
            style={{ position: "absolute", left: 42 - 7, top: 33 - 12, width: 14, height: 24, display: "flex", flexDirection: "column", alignItems: "center" }}
          >
            <div style={{ width: 14, height: 14, borderRadius: "50%", background: "rgb(0 0 0 / 0.28)", flexShrink: 0 }} />
            <div style={{ width: 6, height: 13, marginTop: -3, borderRadius: "0 0 2px 2px", background: "rgb(0 0 0 / 0.28)", flexShrink: 0 }} />
          </motion.div>
        </div>
      </div>
      <div
        style={{
          position: "relative",
          display: "flex",
          alignItems: "center",
          gap: 6,
          ...textStyle.subheadline,
          fontWeight: 600,
          color: unlocked ? Palette.green : Palette.secondaryLabel,
          transition: "color 0.3s",
        }}
      >
        <Replace k={unlocked ? "open" : "closed"}>
          <Glyph def={unlocked ? SYM.lockOpenFill : SYM.lockFill} size={sym(15)} />
        </Replace>
        <span style={{ display: "grid" }}>
          {[false, true].map((state) => (
            <motion.span key={String(state)} initial={false} animate={{ opacity: unlocked === state ? 1 : 0 }} transition={anim.snappy} style={{ gridArea: "1 / 1", whiteSpace: "nowrap" }}>
              {state ? ctx.t("Unlocked", "已解锁") : ctx.t("Locked", "已锁定")}
            </motion.span>
          ))}
        </span>
        <DemoHint ctx={ctx} en="Tap the lock" zh="点击挂锁" style={{ position: "absolute", left: "50%", bottom: -26, transform: "translateX(-50%)", whiteSpace: "nowrap" }} />
      </div>
    </div>
  );
}
