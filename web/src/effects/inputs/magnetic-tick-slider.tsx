/** inputs.magnetic-tick-slider (Inputs+MagneticTickSlider.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, clamp, demoCard, fonts, spring, textStyle, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";

const WIDTH = 260;

export default function MagneticTickSlider({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const stops = Math.max(ctx.i("stops"), 2);
  const spacing = WIDTH / (stops - 1);
  const finger = useMotionValue(86.7);
  const [fingerX, setFingerX] = useState(86.7);
  useMotionValueEvent(finger, "change", setFingerX);
  const [dragging, setDraggingState] = useState(false);
  const draggingRef = useRef(false);
  const lastStop = useRef(2);
  const previewStep = useRef(0);
  const previewDirection = useRef(1);
  const introRun = useRef(0);
  const setDragging = (v: boolean) => {
    draggingRef.current = v;
    setDraggingState(v);
  };

  const nearest = (x: number) => clamp(Math.round(x / spacing), 0, stops - 1);
  const interactive = spring(0.18, 0.7);

  useEffect(() => {
    finger.jump(nearest(finger.get()) * spacing);
    setFingerX(finger.get());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stops]);

  const settle = () => {
    animate(finger, nearest(finger.get()) * spacing, spring(ctx.n("response"), 0.6));
    setDragging(false);
  };

  const previewTick = () => {
    const phase = previewStep.current % 3;
    previewStep.current += 1;
    const current = nearest(finger.get());
    if (phase === 0) {
      if (current >= stops - 1) previewDirection.current = -1;
      if (current <= 0) previewDirection.current = 1;
    }
    const base = current * spacing;
    const dir = previewDirection.current;
    if (phase === 0) {
      setDragging(true);
      animate(finger, clamp(base + dir * spacing * 0.4, 0, WIDTH), interactive);
    } else if (phase === 1) animate(finger, clamp(base + dir * spacing * 0.65, 0, WIDTH), interactive);
    else settle();
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (ctx.isPreview) previewTick();
      else {
        introRun.current += 1;
        const run = introRun.current;
        [0, 0.55, 1.1].forEach((d) => after(d, () => run === introRun.current && previewTick()));
      }
    },
    { every: 0.55, delay: 0.3 },
  );

  const pan = usePan({
    onChange: ({ location }) => {
      introRun.current += 1;
      const x = clamp(location.x, 0, WIDTH);
      animate(finger, x, interactive);
      if (!draggingRef.current) setDragging(true);
      const s = nearest(x);
      if (s !== lastStop.current) {
        lastStop.current = s;
        haptics.selection();
      }
    },
    onEnd: () => draggingRef.current && settle(),
  });

  // Magnetic pull toward the nearest tick, smoothstepped over half a spacing.
  const k = nearest(fingerX);
  const d = fingerX - k * spacing;
  const p = Math.max(0, 1 - Math.abs(d) / (spacing / 2));
  const thumb = fingerX - d * ctx.n("strength") * p * p * (3 - 2 * p);
  const scale = 0.7 + (k / Math.max(stops - 1, 1)) * 0.8;
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: WIDTH + 36, padding: 18, display: "flex", flexDirection: "column", gap: 18 }}>
        <div style={{ display: "flex", alignItems: "center" }}>
          <span style={{ ...textStyle.headline }}>{zh ? "文字大小" : "Text Size"}</span>
          <div style={{ flex: 1 }} />
          <motion.span
            initial={false}
            animate={{ scale }}
            transition={spring(0.35, 0.7)}
            style={{ height: 40, display: "flex", alignItems: "center", transformOrigin: "100% 50%", fontFamily: fonts.rounded, fontSize: 22, fontWeight: 600, color: Palette.indigo }}
          >
            Aa
          </motion.span>
        </div>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", color: Palette.secondaryLabel, fontWeight: 600, lineHeight: 1 }}>
          {zh ? <span style={{ fontSize: 11, height: 17, display: "flex", alignItems: "flex-end" }}>小</span> : <TextSizeGlyph small />}
          {zh ? <span style={{ fontSize: 14, height: 17, display: "flex", alignItems: "flex-end" }}>大</span> : <TextSizeGlyph />}
        </div>
        <div {...pan} style={{ ...pan.style, position: "relative", width: WIDTH, height: 44, cursor: "pointer" }}>
          <div style={{ position: "absolute", left: 0, right: 0, top: 19, height: 6, borderRadius: 3, background: Palette.labelAlpha(0.1) }} />
          <div style={{ position: "absolute", left: 0, top: 19, height: 6, borderRadius: 3, width: Math.max(thumb, 6), background: Palette.primary }} />
          {Array.from({ length: stops }, (_, i) => {
            const x = i * spacing;
            const near = Math.max(0, 1 - Math.abs(x - thumb) / 40);
            const h = 8 + 10 * near;
            return (
              <div
                key={i}
                style={{ position: "absolute", left: x - 1, top: 22 + 18 - h / 2, width: 2, height: h, borderRadius: 1, background: i === k ? Palette.indigo : Palette.labelAlpha(0.25) }}
              />
            );
          })}
          <motion.div
            animate={{ scale: dragging ? 1.12 : 1 }}
            transition={dragging ? interactive : spring(ctx.n("response"), 0.6)}
            style={{ position: "absolute", left: thumb - 14, top: 8, width: 28, height: 28, borderRadius: "50%", background: "#fff", boxShadow: "0 2px 5px rgb(0 0 0 / 0.2)" }}
          />
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag slowly and feel each stop" zh="慢慢拖动，感受每个档位" style={{ paddingBottom: 18 }} />
    </div>
  );
}

/** SF `textformat.size.smaller` / `.larger`: a large and a small "A". */
function TextSizeGlyph({ small }: { small?: boolean }) {
  return (
    <span style={{ display: "inline-flex", alignItems: "baseline", gap: 0.5, fontFamily: fonts.text, fontWeight: 600, height: 17 }}>
      <span style={{ fontSize: small ? 10 : 16 }}>A</span>
      <span style={{ fontSize: small ? 16 : 10 }}>A</span>
    </span>
  );
}
