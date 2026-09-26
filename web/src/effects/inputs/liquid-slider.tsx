/** inputs.liquid-slider (Inputs+LiquidSlider.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { Droplet } from "lucide-react";
import { useId, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, clamp, fonts, spring, springDB, textStyle, useAutoplay, useClock, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";

const W = 96;
const H = 220;
const TARGETS = [0.8, 0.3, 0.62, 0.15, 0.9];

function wavePath(level: number, amplitude: number, phase: number, waves: number) {
  const surface = H - H * level;
  let d = `M0 ${H}`;
  for (let x = 0; x <= W + 4; x += 4) {
    const cx = Math.min(x, W);
    const y = surface + Math.sin((cx / W) * waves * 2 * Math.PI + phase) * amplitude;
    d += ` L${cx} ${y.toFixed(2)}`;
  }
  return `${d} L${W} ${H} Z`;
}

export default function LiquidSlider({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const gid = `a-liquid-${useId().replace(/:/g, "")}`;
  const level = useMotionValue(0.45);
  const slosh = useMotionValue(0);
  const [target, setTarget] = useState(0.45);
  const [dragging, setDragging] = useState(false);
  const draggingRef = useRef(false);
  const startLevel = useRef(0);
  const settleTimer = useRef<() => void>(() => {});
  const step = useRef(0);
  const t = useClock(true, ctx.isPreview ? 30 : undefined);
  const maxAmp = ctx.n("amplitude");

  const settle = () => animate(slosh, 0, spring(0.8, ctx.n("damping")));
  const endDrag = () => {
    if (!draggingRef.current) return;
    settleTimer.current();
    draggingRef.current = false;
    setDragging(false);
    settle();
  };

  const pan = usePan({
    onChange: ({ translation, velocity }) => {
      if (!draggingRef.current) {
        startLevel.current = level.get();
        draggingRef.current = true;
        setDragging(true);
      }
      const nl = clamp(startLevel.current - translation.y / H);
      if (Math.floor(nl * 10) !== Math.floor(level.get() * 10)) haptics.selection();
      level.stop();
      level.set(nl);
      setTarget(nl);
      const tg = Math.min(Math.abs(velocity.y) / 60, maxAmp);
      if (tg > Math.abs(slosh.get())) animate(slosh, tg, spring(0.2, 0.8));
      settleTimer.current();
      settleTimer.current = after(0.08, settle);
    },
    onEnd: endDrag,
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      const tg = TARGETS[step.current % TARGETS.length];
      step.current += 1;
      animate(level, tg, springDB(0.6, 0));
      setTarget(tg);
      animate(slosh, maxAmp * 0.8, spring(0.2, 0.8));
      after(0.45, settle);
    },
    { every: 1.7, delay: 0.3 },
  );

  const litres = Math.round(target * 20) / 10;
  const amp = 2 + clamp(slosh.get(), -maxAmp, maxAmp);
  const phase = t * ctx.n("speed") + 1000;
  const lv = level.get();
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", alignItems: "center", gap: 26 }}>
        <motion.div
          {...pan}
          animate={{ scale: dragging ? 1.03 : 1 }}
          transition={spring(0.3, 0.7)}
          style={{ ...pan.style, position: "relative", width: W, height: H, borderRadius: 28, cursor: "ns-resize", boxShadow: `0 8px 14px ${alpha(Palette.blue, 0.18)}` }}
        >
          <div style={{ position: "absolute", inset: 0, borderRadius: 28, overflow: "hidden", background: Palette.labelAlpha(0.05) }}>
            <svg width={W} height={H} style={{ position: "absolute", inset: 0 }}>
              <defs>
                <linearGradient id={gid} x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0" stopColor={Palette.sky} />
                  <stop offset="1" stopColor={Palette.blue} />
                </linearGradient>
              </defs>
              <path d={wavePath(lv, amp * 0.8, phase + 1.7, 1.3)} fill={alpha(Palette.sky, 0.45)} />
              <path d={wavePath(lv, amp, phase, 1)} fill={`url(#${gid})`} />
            </svg>
            <div style={{ position: "absolute", left: 10, top: 18, bottom: 18, width: 18, background: "linear-gradient(90deg, rgb(255 255 255 / 0.35), transparent)" }} />
          </div>
          <div style={{ position: "absolute", inset: 0, borderRadius: 28, boxShadow: `inset 0 0 0 1.5px ${Palette.labelAlpha(0.15)}`, pointerEvents: "none" }} />
        </motion.div>
        <div style={{ width: 130, display: "flex", flexDirection: "column", gap: 6 }}>
          <Droplet size={22} strokeWidth={1.5} fill={`url(#${gid}-o)`} stroke="none" style={{ overflow: "visible" }}>
            <defs>
              <linearGradient id={`${gid}-o`} x1="0" y1="0" x2="1" y2="1">
                <stop offset="0" stopColor={Palette.sky} />
                <stop offset="1" stopColor={Palette.blue} />
              </linearGradient>
            </defs>
          </Droplet>
          <span style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.secondaryLabel }}>{zh ? "今日饮水" : "Water today"}</span>
          <NumericText value={litres} text={`${litres.toFixed(1)} L`} style={{ fontFamily: fonts.rounded, fontSize: 34, fontWeight: 700, lineHeight: "41px" }} />
          <span style={{ ...textStyle.caption, fontWeight: 500, color: Palette.tertiaryLabel }}>{zh ? "目标 2.0 L" : "Goal 2.0 L"}</span>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag the glass up or down quickly" zh="在杯子上快速上下拖动" style={{ paddingBottom: 14 }} />
    </div>
  );
}
