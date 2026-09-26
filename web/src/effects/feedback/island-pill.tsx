/** feedback.island-pill · 灵动岛提示 (Feedback+Toast.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Camera, CreditCard, Flashlight, Headphones, Timer, type LucideIcon } from "lucide-react";
import { useEffect, useState } from "react";
import { DemoHint, Palette, SymbolBounce, anim, delayed, ease, fonts, hex, mix, spring, springAt, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";

const ACTIVITIES: { Icon: LucideIcon; fill?: boolean; tint: string; title: [string, string]; value: [string, string] }[] = [
  { Icon: Headphones, tint: Palette.green, title: ["Connected", "已连接"], value: ["82%", "82%"] },
  { Icon: CreditCard, tint: Palette.sky, title: ["Payment", "支付"], value: ["Done ✓", "完成 ✓"] },
  { Icon: Timer, tint: Palette.amber, title: ["Timer", "计时器"], value: ["0:00", "0:00"] },
];

export default function IslandPill({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [event, setEvent] = useState<number | null>(null);
  const [next, setNext] = useState(0);
  const [pulses, setPulses] = useState(0);
  const [transition, setTransition] = useState(spring(0.45, 0.62));

  const fire = () => {
    clearAll();
    const index = next % ACTIVITIES.length;
    setNext((n) => n + 1);
    haptics.success();
    setTransition(spring(ctx.n("response"), ctx.n("damping")));
    setEvent(index);
    setPulses((p) => p + 1);
    after(ctx.n("hold"), () => {
      setTransition(spring(0.4, 0.85));
      setEvent(null);
    });
  };

  useAutoplay(ctx.isPreview, fire, { every: ctx.n("hold") + 1.4, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        onClick={fire}
        style={{
          position: "relative",
          width: 316,
          height: 300,
          borderRadius: 44,
          overflow: "hidden",
          flexShrink: 0,
          cursor: "pointer",
          boxShadow: `0 14px 24px ${hex(0x4b3aa8, 0.28)}`,
        }}
      >
        <LockScreen zh={ctx.lang === "zh"} />
        <div style={{ position: "absolute", left: 0, right: 0, top: 11, display: "flex", justifyContent: "center" }}>
          <AlertPill event={event} pulses={pulses} zh={ctx.lang === "zh"} transition={transition} />
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 44, boxShadow: "inset 0 0 0 1px rgb(0 0 0 / 0.12)", pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Tap the screen to send an event" zh="点击屏幕推送一条事件" />
    </div>
  );
}

function LockScreen({ zh }: { zh: boolean }) {
  const quick = (Icon: LucideIcon) => (
    <div style={{ width: 44, height: 44, borderRadius: "50%", background: "rgb(0 0 0 / 0.28)", display: "grid", placeItems: "center", color: "#fff" }}>
      <Icon size={18} strokeWidth={2.2} fill="currentColor" />
    </div>
  );
  return (
    <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, #2B2F77, #6E4BD8, #E86BB0)" }}>
      <div style={{ position: "absolute", inset: 0, background: "radial-gradient(220px circle at 85% 10%, rgb(255 255 255 / 0.28), transparent)" }} />
      <div style={{ position: "absolute", inset: 0, paddingTop: 108, display: "flex", flexDirection: "column", alignItems: "center", color: "rgb(255 255 255 / 0.92)" }}>
        <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "9月23日 星期三" : "Wednesday, September 23"}</div>
        <div style={{ fontFamily: fonts.rounded, fontSize: 66, lineHeight: "79px", fontWeight: 700, fontVariantNumeric: "tabular-nums" }}>9:41</div>
        <div style={{ flex: 1 }} />
        <div style={{ alignSelf: "stretch", display: "flex", justifyContent: "space-between", padding: "0 26px 20px" }}>
          {quick(Flashlight)}
          {quick(Camera)}
        </div>
      </div>
    </div>
  );
}

function AlertPill({ event, pulses, zh, transition }: { event: number | null; pulses: number; zh: boolean; transition: ReturnType<typeof spring> }) {
  const open = event !== null;
  // keyframeAnimator: CubicKeyframe(1.07, 0.14) then SpringKeyframe(1, 0.5, .bouncy).
  const t = useElapsed(pulses, 0.8, true);
  const scale = t < 0 ? 1 : t < 0.14 ? mix(1, 1.07, ease.inOut(t / 0.14)) : mix(1.07, 1, springAt(t - 0.14, 0.5, 0.7));
  return (
    <div style={{ transform: `scale(${scale})` }}>
      <motion.div
        initial={false}
        animate={{
          width: open ? 250 : 124,
          height: open ? 44 : 36,
          boxShadow: open ? "0 8px 16px rgb(0 0 0 / 0.3)" : "0 3px 6px rgb(0 0 0 / 0.12)",
        }}
        transition={transition}
        style={{ position: "relative", borderRadius: 999, background: "#000", overflow: "hidden" }}
      >
        <AnimatePresence>
          {event !== null && (
            <motion.div
              key={`${pulses}`}
              initial={{ opacity: 0, scale: 0.7 }}
              animate={{ opacity: 1, scale: 1, transition: delayed(anim.smoothD(0.3), 0.1) }}
              exit={{ opacity: 0, transition: anim.easeIn(0.12) }}
              style={{ position: "absolute", left: "50%", top: "50%", marginLeft: -125, marginTop: -22, width: 250, height: 44, padding: "0 16px", display: "flex", alignItems: "center", gap: 8 }}
            >
              <BounceGlyph index={event} />
              <span style={{ fontSize: 15, fontWeight: 600, color: "#fff" }}>{ACTIVITIES[event].title[zh ? 1 : 0]}</span>
              <span style={{ flex: 1 }} />
              <span style={{ fontSize: 15, fontWeight: 600, fontVariantNumeric: "tabular-nums", color: ACTIVITIES[event].tint }}>{ACTIVITIES[event].value[zh ? 1 : 0]}</span>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </div>
  );
}

/** Bounces itself once, 100 ms after insertion (as the delayed insertion lands). */
function BounceGlyph({ index }: { index: number }) {
  const [bounces, setBounces] = useState(0);
  useEffect(() => {
    const id = window.setTimeout(() => setBounces(1), 100);
    return () => window.clearTimeout(id);
  }, []);
  const { Icon, fill, tint } = ACTIVITIES[index];
  return (
    <SymbolBounce trigger={bounces} style={{ color: tint }}>
      <Icon size={18} strokeWidth={2.4} fill={fill ? "currentColor" : "none"} />
    </SymbolBounce>
  );
}
