/** inputs.grow-scrubber (Inputs+GrowScrubber.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { AudioLines } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, clamp, demoCard, spring, springDB, textStyle, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";

const WIDTH = 270;
const DURATION = 222;
type Rate = "full" | "half" | "fine";
const FACTOR: Record<Rate, number> = { full: 1, half: 0.5, fine: 0.25 };
const LABEL: Record<Rate, [string, string]> = {
  full: ["Hi-Speed Scrubbing", "高速拖动"],
  half: ["Half-Speed Scrubbing", "半速拖动"],
  fine: ["Fine Scrubbing", "精细拖动"],
};
const clock = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;

export default function GrowScrubber({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const progress = useMotionValue(0.36);
  const [p, setP] = useState(0.36);
  useMotionValueEvent(progress, "change", setP);
  const [grabbed, setGrabbedState] = useState(false);
  const grabbedRef = useRef(false);
  const [rate, setRateState] = useState<Rate>("full");
  const rateRef = useRef<Rate>("full");
  const [releaseT, setReleaseT] = useState(false);
  const lastX = useRef(0);
  const step = useRef(0);
  const setGrabbed = (v: boolean) => {
    grabbedRef.current = v;
    setGrabbedState(v);
  };
  const setRate = (r: Rate) => {
    rateRef.current = r;
    setRateState(r);
  };
  const fine = ctx.b("fine");
  const rateFor = (depth: number): Rate => (!fine ? "full" : depth > 90 ? "fine" : depth > 40 ? "half" : "full");

  const endScrub = () => {
    if (!grabbedRef.current) return;
    setReleaseT(true);
    setGrabbed(false);
    setRate("full");
  };

  const pan = usePan({
    onChange: ({ location, translation }) => {
      if (!grabbedRef.current) {
        setReleaseT(false);
        setGrabbed(true);
        lastX.current = location.x;
        haptics.tap("soft");
      }
      const r = rateFor(translation.y);
      if (r !== rateRef.current) {
        setRate(r);
        haptics.selection();
      }
      const dx = location.x - lastX.current;
      lastX.current = location.x;
      progress.stop();
      progress.set(clamp(progress.get() + (dx / WIDTH) * FACTOR[rateRef.current]));
    },
    onEnd: endScrub,
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      step.current += 1;
      const forward = step.current % 2 === 1;
      setReleaseT(false);
      setGrabbed(true);
      setRate("full");
      animate(progress, forward ? 0.62 : 0.3, springDB(0.6, 0));
      after(0.7, () => {
        if (fine) setRate("half");
        animate(progress, progress.get() + (forward ? 0.05 : -0.05), springDB(0.6, 0));
        after(0.8, () => {
          setReleaseT(true);
          setGrabbed(false);
          setRate("full");
        });
      });
    },
    { every: 2.4, delay: 0.3 },
  );

  const t = releaseT ? springDB(0.35, 0) : spring(ctx.n("response"), 0.8);
  const h = grabbed ? ctx.n("thickness") : 6;
  const elapsed = Math.floor(p * DURATION);
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(26), width: WIDTH + 36, padding: 18, display: "flex", flexDirection: "column", gap: 14 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 46, height: 46, borderRadius: 10, background: Palette.aurora, display: "grid", placeItems: "center", color: "#fff" }}>
            <AudioLines size={19} strokeWidth={2.4} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ ...textStyle.subheadline, fontWeight: 600 }}>{zh ? "北方之光" : "Northern Lights"}</span>
            <span style={{ ...textStyle.caption, color: Palette.secondaryLabel }}>Aster Vale</span>
          </div>
        </div>
        <div {...pan} style={{ ...pan.style, height: 30, display: "flex", alignItems: "center", cursor: "grab" }}>
          <motion.div
            initial={false}
            animate={{ height: h, scaleX: grabbed ? 1.04 : 1, boxShadow: `0 4px 8px rgb(0 0 0 / ${grabbed ? 0.12 : 0})` }}
            transition={t}
            style={{ position: "relative", width: WIDTH, borderRadius: 999 }}
          >
            <div style={{ position: "absolute", inset: 0, borderRadius: 999, background: Palette.labelAlpha(0.1) }} />
            <div
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                bottom: 0,
                borderRadius: 999,
                width: Math.max(WIDTH * p, h),
                background: grabbed ? Palette.label : Palette.secondaryLabel,
                transition: "background-color 0.3s",
              }}
            />
          </motion.div>
        </div>
        <motion.div
          initial={false}
          animate={{ y: grabbed ? 6 : 0 }}
          transition={t}
          style={{
            display: "flex",
            alignItems: "center",
            ...textStyle.caption,
            fontWeight: grabbed ? 700 : 500,
            fontVariantNumeric: "tabular-nums",
            color: grabbed ? Palette.label : Palette.secondaryLabel,
          }}
        >
          <span>{clock(elapsed)}</span>
          <div style={{ flex: 1 }} />
          <div style={{ display: "grid", placeItems: "center" }}>
            <AnimatePresence initial={false}>
              {grabbed && fine && (
                <motion.span
                  key={rate}
                  initial={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
                  animate={{ opacity: 1, filter: "blur(0px)", scale: 1 }}
                  exit={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
                  transition={springDB(0.25, 0)}
                  style={{ gridArea: "1 / 1", ...textStyle.caption2, fontWeight: 700, color: Palette.indigo, padding: "3px 8px", borderRadius: 10, background: alpha(Palette.indigo, 0.12), whiteSpace: "nowrap" }}
                >
                  {zh ? LABEL[rate][1] : LABEL[rate][0]}
                </motion.span>
              )}
            </AnimatePresence>
          </div>
          <div style={{ flex: 1 }} />
          <span>-{clock(DURATION - elapsed)}</span>
        </motion.div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Hold the bar, then slide your finger down" zh="按住进度条，再把手指往下移" style={{ paddingBottom: 18 }} />
    </div>
  );
}
