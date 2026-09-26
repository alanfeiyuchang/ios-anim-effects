/** icons.wifi-connect · Wi-Fi 连接 (Icons+WifiConnect.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, spring, textStyle, useAutoplay, useClock, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { arc } from "./_icons-kit";

type State = "off" | "searching" | "connected";

export default function WifiConnect({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  // On the detail stage start disconnected, so the intro tap plays search → connect → badge pop.
  const [state, setState] = useState<State>(ctx.isPreview ? "connected" : "off");
  const token = useRef(0);
  const stateRef = useRef(state);
  stateRef.current = state;
  useClock(state === "searching", 30);

  const step = Math.max(ctx.n("chase"), 0.02);
  const chase = state === "searching" ? Math.floor(performance.now() / 1000 / step) % 4 : state === "connected" ? 3 : 0;

  /** `scripted`: the delayed success haptic stays silent for autoplay and the detail intro. */
  const tap = (scripted = false) => {
    token.current += 1;
    haptics.tap("light");
    if (stateRef.current === "off") {
      setState("searching");
      const current = token.current;
      after(ctx.n("search"), () => {
        if (current !== token.current || stateRef.current !== "searching") return;
        if (!scripted) haptics.success();
        setState("connected");
      });
    } else {
      setState("off");
    }
  };
  useAutoplay(ctx.isPreview, () => tap(true), { every: 3.2 });

  const damping = ctx.n("damping");
  const zh = ctx.lang === "zh";
  const status = state === "off" ? (zh ? "未连接" : "Not connected") : state === "searching" ? (zh ? "正在搜索…" : "Searching…") : zh ? "已连接" : "Connected";

  return (
    <div
      onClick={() => tap()}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: 140, height: 110 }}>
        {[0, 1, 2].map((level) => {
          const radius = ((110 - 16) / 3) * (level + 1);
          const t = state === "connected" ? delayed(spring(0.35, damping), level * 0.06) : anim.easeOut(0.25);
          return (
            <motion.svg
              key={level}
              width={140}
              height={110}
              viewBox="0 0 140 110"
              initial={false}
              animate={{ scale: state === "connected" ? 1 : 0.88 }}
              transition={t}
              style={{ position: "absolute", inset: 0, overflow: "visible", transformOrigin: "50% 100%" }}
            >
              <path
                d={arc(70, 102, radius, 225, 315)}
                fill="none"
                strokeWidth={7}
                strokeLinecap="round"
                style={{
                  stroke: level < chase ? Palette.blue : Palette.labelAlpha(0.15),
                  transition: state === "searching" ? "none" : `stroke 0.25s ease-out ${state === "connected" ? level * 0.06 : 0}s`,
                }}
              />
            </motion.svg>
          );
        })}
        <div
          style={{
            position: "absolute",
            left: 64,
            top: 96,
            width: 12,
            height: 12,
            borderRadius: "50%",
            background: state === "off" ? Palette.labelAlpha(0.25) : Palette.blue,
            transition: "background 0.2s ease-out",
          }}
        />
        <AnimatePresence>
          {state === "connected" && (
            <motion.div
              initial={{ scale: 0.2, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.2, opacity: 0 }}
              transition={spring(0.35, damping)}
              style={{ position: "absolute", right: -10, top: -4, width: 26, height: 26 }}
            >
              <div style={{ position: "absolute", inset: 2, borderRadius: "50%", background: Palette.elevated }} />
              <svg width={26} height={26} viewBox="0 0 24 24" style={{ position: "absolute", inset: 0 }}>
                <circle cx={12} cy={12} r={10.4} fill={Palette.green} />
                <path d="M7.4 12.4l3.1 3.1 6.1-6.6" fill="none" stroke="#fff" strokeWidth={2.3} strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
        <span style={{ ...textStyle.headline }}>Studio 5G</span>
        <span style={{ display: "grid", ...textStyle.subheadline }}>
          <AnimatePresence initial={false}>
            <motion.span
              key={state}
              initial={{ opacity: 0, filter: "blur(2px)", y: 6 }}
              animate={{ opacity: 1, filter: "blur(0px)", y: 0 }}
              exit={{ opacity: 0, filter: "blur(2px)", y: -6 }}
              transition={anim.snappy}
              style={{ gridArea: "1 / 1", textAlign: "center", whiteSpace: "nowrap", color: state === "connected" ? Palette.green : Palette.secondaryLabel }}
            >
              {status}
            </motion.span>
          </AnimatePresence>
        </span>
      </div>
      <DemoHint ctx={ctx} en="Tap to connect / disconnect" zh="点击连接 / 断开" />
    </div>
  );
}
