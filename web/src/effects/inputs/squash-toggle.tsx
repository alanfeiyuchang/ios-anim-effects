/** inputs.squash-toggle · 弹性形变开关 (Inputs+SquashToggle.swift) */
import { motion, type Transition } from "motion/react";
import { BellDot, Bell, Check, X } from "lucide-react";
import { useRef, useState } from "react";
import {
  DemoHint,
  Palette,
  delayed,
  demoCard,
  localPoint,
  spring,
  textStyle,
  useAutoplay,
  useHaptics,
  useLatest,
  useSilently,
  useTimeouts,
  type DemoProps,
} from "../../kit";
import { CheckCircleFill, FadeText, SymbolSwap, systemGray } from "./_a-common";

const TRACK_W = 84;
const TRACK_H = 48;
const INSET = 5;
const KNOB = TRACK_H - INSET * 2;

export default function SquashToggle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const silently = useSilently();
  const { after } = useTimeouts();
  const [isOn, setIsOn] = useState(false);
  const [pressing, setPressing] = useState(false);
  const [transition, setTransition] = useState<Transition>(spring(0.25, 0.7));
  const pressingRef = useLatest(pressing);

  const press = () => {
    if (pressingRef.current) return;
    pressingRef.current = true;
    setTransition(spring(0.25, 0.7));
    setPressing(true);
  };
  const release = () => {
    haptics.tap();
    setTransition(spring(ctx.n("response"), ctx.n("damping")));
    setIsOn((v) => !v);
    setPressing(false);
    pressingRef.current = false;
  };
  const cancelPress = () => {
    if (!pressingRef.current) return;
    setTransition(spring(ctx.n("response"), ctx.n("damping")));
    setPressing(false);
    pressingRef.current = false;
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      press();
      after(0.3, () => silently(release));
    },
    { every: 1.3, delay: 0.4 },
  );

  const zh = ctx.lang === "zh";
  const w = KNOB * (pressing ? ctx.n("stretch") : 1);
  const h = KNOB * (pressing ? 0.9 : 1);
  const left = isOn ? TRACK_W - INSET - w : INSET;
  const touch = useRef<number | null>(null);

  const toggle = (
    <div
      onPointerDown={(e) => {
        e.currentTarget.setPointerCapture(e.pointerId);
        touch.current = e.pointerId;
        press();
      }}
      onPointerUp={(e) => {
        if (touch.current !== e.pointerId) return;
        touch.current = null;
        const p = localPoint(e, e.currentTarget);
        if (p.x >= -30 && p.y >= -30 && p.x <= TRACK_W + 30 && p.y <= TRACK_H + 30) release();
        else cancelPress();
      }}
      onPointerCancel={() => {
        touch.current = null;
        cancelPress();
      }}
      style={{ position: "relative", width: TRACK_W, height: TRACK_H, flexShrink: 0, borderRadius: TRACK_H / 2, cursor: "pointer" }}
    >
      <div style={{ position: "absolute", inset: 0, borderRadius: TRACK_H / 2, background: Palette.labelAlpha(0.12) }} />
      <motion.div
        initial={false}
        animate={{ opacity: isOn ? 1 : 0 }}
        transition={transition}
        style={{ position: "absolute", inset: 0, borderRadius: TRACK_H / 2, background: `linear-gradient(90deg, ${Palette.mint}, ${Palette.green})` }}
      />
      <motion.div
        initial={false}
        animate={{ left, width: w, height: h, top: (TRACK_H - h) / 2 }}
        transition={transition}
        style={{
          position: "absolute",
          borderRadius: 999,
          background: "#fff",
          boxShadow: "0 3px 6px rgb(0 0 0 / 0.18)",
          display: "grid",
          placeItems: "center",
          color: isOn ? Palette.green : `color-mix(in srgb, ${systemGray} 60%, transparent)`,
        }}
      >
        <SymbolSwap k={isOn ? "on" : "off"}>{isOn ? <Check size={14} strokeWidth={3.4} /> : <X size={14} strokeWidth={3.4} />}</SymbolSwap>
      </motion.div>
    </div>
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 310, padding: 16, display: "flex", flexDirection: "column", gap: 14 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div
            style={{
              width: 38,
              height: 38,
              borderRadius: 10,
              background: `linear-gradient(${Palette.amber}, ${Palette.coral})`,
              display: "grid",
              placeItems: "center",
              color: "#fff",
            }}
          >
            <SymbolSwap k={isOn ? "badge" : "bell"}>
              {isOn ? <BellDot size={19} fill="currentColor" strokeWidth={1.6} /> : <Bell size={19} fill="currentColor" strokeWidth={1.6} />}
            </SymbolSwap>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2, flex: 1, minWidth: 0 }}>
            <span style={{ ...textStyle.headline }}>{zh ? "通知" : "Notifications"}</span>
            <FadeText
              text={isOn ? (zh ? "已开启 · 即时" : "On · Instant") : zh ? "已关闭" : "Off"}
              style={{ ...textStyle.caption, color: Palette.secondaryLabel }}
            />
          </div>
          {toggle}
        </div>
        <div style={{ height: 1, background: Palette.stroke }} />
        {[ctx.t("Sounds", "声音"), ctx.t("Lock screen", "锁定屏幕")].map((title, row) => {
          const t = delayed(spring(0.4, 0.7), isOn ? 0.12 + row * 0.06 : 0);
          return (
            <motion.div
              key={row}
              initial={false}
              animate={{ opacity: isOn ? 1 : 0.4 }}
              transition={t}
              style={{ display: "flex", alignItems: "center", height: 22 }}
            >
              <span style={{ ...textStyle.subheadline }}>{title}</span>
              <div style={{ flex: 1 }} />
              <motion.span
                initial={false}
                animate={{ scale: isOn ? 1 : 0.5, opacity: isOn ? 1 : 0 }}
                transition={t}
                style={{ display: "grid", color: Palette.green }}
              >
                <CheckCircleFill size={19} />
              </motion.span>
            </motion.div>
          );
        })}
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press, hold, then release the switch" zh="按住开关再松手" style={{ paddingBottom: 18 }} />
    </div>
  );
}
