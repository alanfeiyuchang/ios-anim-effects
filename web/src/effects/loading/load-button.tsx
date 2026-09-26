/** loading.load-button · 加载按钮 (Loading+LoadButton.swift) */
import { AnimatePresence, motion } from "motion/react";
import { ArrowRight } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import {
  DemoHint,
  Palette,
  alpha,
  cubicBezier,
  mix,
  pressHandlers,
  progress,
  spring,
  springAt,
  useAutoplay,
  useHaptics,
  type DemoProps,
} from "../../kit";
import { angular, GradientArc, TrimPath, usePhase, previewFps, useTriggerElapsed } from "./shared";

type Phase = "idle" | "loading" | "success";

const SIDE = 58;
const cubic = cubicBezier(0.42, 0, 0.58, 1);

export default function LoadButton({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [phase, setPhase] = useState<Phase>("idle");
  const [successCount, setSuccessCount] = useState(0);
  const [pressed, setPressed] = useState(false);
  const phaseRef = useRef<Phase>("idle");
  phaseRef.current = phase;
  const token = useRef(0);
  const timers = useRef<number[]>([]);
  const muted = useRef(false);
  useEffect(() => () => timers.current.forEach(clearTimeout), []);

  const morph = spring(ctx.n("response"), ctx.n("damping"));
  const [morphing, setMorphing] = useState(morph);

  const start = () => {
    if (phaseRef.current !== "idle") return;
    const wait = ctx.n("duration");
    token.current += 1;
    const current = token.current;
    haptics.tap("medium");
    // Delayed feedback stays silent when the tap was simulated (autoplay / intro).
    const quiet = muted.current;
    setMorphing(morph);
    setPhase("loading");
    timers.current.forEach(clearTimeout);
    timers.current = [
      window.setTimeout(() => {
        if (token.current !== current) return;
        setMorphing(spring(0.4, 0.7));
        setPhase("success");
        setSuccessCount((c) => c + 1);
        if (!quiet) haptics.success();
        timers.current.push(
          window.setTimeout(() => {
            if (token.current !== current) return;
            setMorphing(morph);
            setPhase("idle");
          }, 1300),
        );
      }, wait * 1000),
    ];
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      muted.current = true;
      start();
      muted.current = false;
    },
    { every: ctx.n("duration") + 3.0, delay: 0.5 },
  );

  const collapsed = phase !== "idle";
  const title = ctx.t("Place Order", "提交订单");

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 30 }}>
      <Pop trigger={successCount} showRing={ctx.b("ring")}>
        <motion.button
          type="button"
          onClick={start}
          {...pressHandlers(setPressed)}
          animate={{ scale: pressed ? 0.96 : 1, filter: pressed ? "brightness(0.96)" : "brightness(1)" }}
          transition={spring(0.28, 0.6)}
          style={{ display: "block" }}
        >
          <motion.div
            initial={false}
            animate={{
              width: collapsed ? SIDE : 240,
              boxShadow: `0 9px 16px ${alpha(phase === "success" ? Palette.green : Palette.indigo, 0.4)}`,
            }}
            transition={morphing}
            style={{ position: "relative", height: SIDE, borderRadius: SIDE / 2, overflow: "hidden", background: Palette.primary }}
          >
            <motion.div
              initial={false}
              animate={{ opacity: phase === "success" ? 1 : 0 }}
              transition={morphing}
              style={{ position: "absolute", inset: 0, background: `linear-gradient(135deg, #4BE08F, ${Palette.green})` }}
            />
            <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
              <motion.div
                initial={false}
                animate={{ opacity: collapsed ? 0 : 1, scale: collapsed ? 0.8 : 1, filter: `blur(${collapsed ? 8 : 0}px)` }}
                transition={morphing}
                style={{ display: "flex", alignItems: "center", gap: 8, color: "#fff", whiteSpace: "nowrap" }}
              >
                <span style={{ fontSize: 17, fontWeight: 600, lineHeight: "22px" }}>{title}</span>
                <ArrowRight size={16} strokeWidth={2.8} />
              </motion.div>
            </div>
            <AnimatePresence>
              {phase === "loading" && (
                <motion.div
                  key="arc"
                  initial={{ scale: 0.3, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  exit={{ scale: 0.3, opacity: 0 }}
                  transition={morphing}
                  style={{ position: "absolute", left: "50%", top: "50%", width: 26, height: 26, marginLeft: -13, marginTop: -13 }}
                >
                  <SpinnerArc preview={ctx.isPreview} />
                </motion.div>
              )}
            </AnimatePresence>
            <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
              <CheckTrim on={phase === "success"} />
            </div>
          </motion.div>
        </motion.button>
      </Pop>
      <DemoHint ctx={ctx} en="Tap the button" zh="点击按钮" />
    </div>
  );
}

/** The success keyframes: scale 1 → 0.86 → 1.14 → bouncy 1, and a ring radiating to 190 %. */
function Pop({ trigger, showRing, children }: { trigger: number; showRing: boolean; children: React.ReactNode }) {
  const t = useTriggerElapsed(trigger, 0.8);
  let scale = 1;
  let ring = 1;
  let ringOpacity = 0;
  if (t >= 0) {
    if (t < 0.1) scale = mix(1, 0.86, cubic(t / 0.1));
    else if (t < 0.26) scale = mix(0.86, 1.14, cubic((t - 0.1) / 0.16));
    else scale = mix(1.14, 1, springAt(t - 0.26, 0.5, 0.7));
    const r = cubic(progress(t, 0, 0.7));
    ring = mix(1, 1.9, r);
    ringOpacity = mix(0.8, 0, r);
  }
  return (
    <div style={{ position: "relative", display: "grid", placeItems: "center" }}>
      <div
        style={{
          position: "absolute",
          left: "50%",
          top: "50%",
          width: SIDE,
          height: SIDE,
          margin: -SIDE / 2,
          borderRadius: "50%",
          boxShadow: `inset 0 0 0 1px ${Palette.green}, 0 0 0 1px ${Palette.green}`,
          transform: `scale(${ring})`,
          opacity: showRing ? ringOpacity : 0,
        }}
      />
      <div style={{ transform: `scale(${scale})` }}>{children}</div>
    </div>
  );
}

/** A 260° white arc with a transparent tail, spinning once every 0.9 s. */
function SpinnerArc({ preview }: { preview: boolean }) {
  const t = usePhase(1, previewFps(preview));
  const angle = ((t % 0.9) / 0.9) * 360;
  return (
    <GradientArc
      size={26}
      lineWidth={3}
      from={0.03}
      to={0.74}
      background={angular(["rgb(255 255 255 / 0)", "#fff"], 0, 266)}
      rotate={angle}
    />
  );
}

function CheckTrim({ on }: { on: boolean }) {
  const [trim, setTrim] = useState(0);
  const target = on ? 1 : 0;
  useEffect(() => {
    const from = trim;
    const duration = on ? 0.35 : 0.12;
    const delay = on ? 0.08 : 0;
    const curve = on ? cubicBezier(0, 0, 0.58, 1) : cubicBezier(0.42, 0, 1, 1);
    let raf = 0;
    const t0 = performance.now();
    const step = (now: number) => {
      const p = progress((now - t0) / 1000, delay, duration);
      setTrim(mix(from, target, curve(p)));
      if (p < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [on]);
  const w = 22;
  const h = 17;
  const d = `M ${w * 0.04} ${h * 0.55} L ${w * 0.37} ${h - h * 0.04} L ${w - w * 0.03} ${h * 0.06}`;
  return <TrimPath d={d} width={w} height={h} trim={trim} color="#fff" lineWidth={3.5} />;
}
