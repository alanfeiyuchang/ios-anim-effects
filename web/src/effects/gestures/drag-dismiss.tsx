/** gestures.drag-dismiss · 下拉关闭 (Gestures+DragDismiss.swift) */
import { animate, motion, useMotionValue, useTransform, type MotionValue, type Transition } from "motion/react";
import { Images } from "lucide-react";
import { useRef } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, black, clamp, rubberBand, spring, useAutoplay, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";
import { colorGradient, predictedEnd, useScript } from "./_a-common";

const CARD = { w: 220, h: 260 };
const GRID = [Palette.indigo, Palette.coral, Palette.mint, Palette.amber, Palette.sky, Palette.pink, Palette.violet, Palette.green, Palette.blue];

export default function DragDismiss({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const resetTimer = useScript();
  const st = useRef({ held: false, dismissed: false, base: { x: 0, y: 0 } as Point, anchor: { x: 0.5, y: 0.5 } });
  const s = st.current;
  // The rendered values (SwiftUI animates each modifier value between states).
  const scale = useMotionValue(1);
  const ox = useMotionValue(0);
  const oy = useMotionValue(0);
  const radius = useMotionValue(14);
  const opacity = useMotionValue(1);
  const dim = useMotionValue(0.28);
  const originX = useMotionValue(0.5);
  const originY = useMotionValue(0.5);

  /** Values for a given drag translation while the card is up. */
  const valuesFor = (drag: Point) => {
    const progress = clamp(drag.y / 300);
    return {
      scale: 1 - progress * ctx.n("shrink"),
      radius: 14 + progress * 30,
      x: drag.x * 0.6,
      y: drag.y < 0 ? rubberBand(drag.y, 40) : drag.y,
      dim: 0.28 * (1 - progress),
      opacity: 1,
    };
  };
  const apply = (v: ReturnType<typeof valuesFor>, t?: Transition) => {
    const pairs: [MotionValue<number>, number][] = [
      [scale, v.scale],
      [radius, v.radius],
      [ox, v.x],
      [oy, v.y],
      [dim, v.dim],
      [opacity, v.opacity],
    ];
    for (const [mv, value] of pairs) {
      if (t) animate(mv, value, t);
      else {
        mv.stop();
        mv.set(value);
      }
    }
  };

  const dismiss = (haptic = true) => {
    if (haptic) haptics.tap("medium");
    s.dismissed = true;
    apply({ scale: 0.35, radius: 14, x: 0, y: 150, dim: 0, opacity: 0 }, spring(0.45, 0.85));
    resetTimer.cancel();
    resetTimer.after(1.1, () => {
      s.dismissed = false;
      apply(valuesFor({ x: 0, y: 0 }), spring(0.55, 0.82));
    });
  };

  const pan = usePan(
    {
      onStart: ({ translation, start }) => {
        if (s.dismissed) return;
        // Only a drag that starts downward or sideways takes the card; an upward swipe is left alone.
        if (translation.y < 0 && Math.abs(translation.y) > Math.abs(translation.x)) return;
        s.held = true;
        s.base = translation;
        script.cancel();
        const ax = clamp(start.x / CARD.w);
        const ay = clamp(start.y / CARD.h);
        originX.set(ax);
        originY.set(ay);
        s.anchor = { x: ax, y: ay };
      },
      onChange: ({ translation }) => {
        if (!s.held || s.dismissed) return;
        apply(valuesFor({ x: translation.x - s.base.x, y: translation.y - s.base.y }));
      },
      onEnd: ({ translation, velocity }) => {
        if (!s.held) return;
        s.held = false;
        if (s.dismissed) return;
        const t = { x: translation.x - s.base.x, y: translation.y - s.base.y };
        if (t.y > ctx.n("threshold") || predictedEnd(t, velocity).y > 320) dismiss();
        else apply(valuesFor({ x: 0, y: 0 }), spring(0.42, 0.78));
      },
    },
    10,
  );

  useAutoplay(
    ctx.isPreview,
    () => {
      if (s.held || s.dismissed) return;
      originX.set(0.5);
      originY.set(0.3);
      apply(valuesFor({ x: 14, y: 170 }), anim.easeInOut(0.6));
      script.cancel();
      script.after(0.65, () => dismiss(false));
    },
    { every: 2.8, delay: 0.5 },
  );

  const transformOrigin = useTransform(() => `${originX.get() * 100}% ${originY.get() * 100}%`);
  const dimBg = useTransform(dim, (d) => black(d));

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ position: "relative", width: 290, height: 300, flexShrink: 0 }}>
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: 26,
            overflow: "hidden",
            padding: 8,
            display: "grid",
            gridTemplateColumns: "repeat(3, 1fr)",
            gridTemplateRows: "repeat(3, 1fr)",
            gap: 8,
          }}
        >
          {GRID.map((c, i) => (
            <div key={i} style={{ borderRadius: 14, background: colorGradient(c), opacity: 0.75 }} />
          ))}
          <motion.div style={{ position: "absolute", inset: 0, background: dimBg }} />
        </div>
        <motion.div
          {...pan}
          style={{
            ...pan.style,
            position: "absolute",
            left: (290 - CARD.w) / 2,
            top: (300 - CARD.h) / 2,
            width: CARD.w,
            height: CARD.h,
            x: ox,
            y: oy,
            scale,
            transformOrigin,
            opacity,
            borderRadius: radius,
            overflow: "hidden",
            background: Palette.elevated,
            boxShadow: `0 14px 24px ${black(0.25)}`,
            display: "flex",
            flexDirection: "column",
            gap: 12,
            cursor: "grab",
          }}
        >
          <div style={{ height: 124, flexShrink: 0, background: Palette.ocean, display: "grid", placeItems: "center", color: white(0.9) }}>
            <Images size={42} strokeWidth={2.2} />
          </div>
          <div style={{ padding: "0 16px", display: "flex", flexDirection: "column", gap: 10 }}>
            <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{ctx.t("Coastline", "海岸线")}</div>
            <PlaceholderLines count={2} />
          </div>
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Pull the card down" zh="向下拖动卡片" />
    </div>
  );
}
