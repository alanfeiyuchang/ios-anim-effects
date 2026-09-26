/** gestures.pip-snap · 画中画吸附 (Gestures+PiPSnap.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { Play } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, black, spring, useAutoplay, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";
import { DashedBorder, predictedEnd, useScript } from "./_a-common";

const SCREEN = { w: 232, h: 320 };
const WIN = { w: 104, h: 66 };
const INSET = 12;

function origin(corner: number): Point {
  const x = corner % 2 === 0 ? INSET : SCREEN.w - INSET - WIN.w;
  const y = corner < 2 ? INSET + 18 : SCREEN.h - INSET - WIN.h;
  return { x, y };
}

function nearest(p: Point): number {
  let best = 0;
  let bestDistance = Infinity;
  for (let c = 0; c < 4; c++) {
    const o = origin(c);
    const d = Math.hypot(o.x - p.x, o.y - p.y);
    if (d < bestDistance) {
      bestDistance = d;
      best = c;
    }
  }
  return best;
}

export default function PiPSnap({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const [target, setTarget] = useState(3);
  const [isDragging, setDragging] = useState(false);
  const cornerRef = useRef(3);
  const targetRef = useRef(3);
  const held = useRef(false);
  const x = useMotionValue(origin(3).x);
  const y = useMotionValue(origin(3).y);

  const projected = (translation: Point, velocity: Point): Point => {
    const o = origin(cornerRef.current);
    const m = ctx.n("momentum");
    const predicted = predictedEnd(translation, velocity);
    return { x: o.x + translation.x + (predicted.x - translation.x) * m, y: o.y + translation.y + (predicted.y - translation.y) * m };
  };

  const snap = (next: number, haptic = true) => {
    const changed = next !== cornerRef.current;
    const s = spring(ctx.n("response"), ctx.n("damping"));
    const o = origin(next);
    animate(x, o.x, s);
    animate(y, o.y, s);
    cornerRef.current = next;
    targetRef.current = next;
    setTarget(next);
    setDragging(false);
    if (changed && haptic) haptics.tap("medium");
  };

  const pan = usePan({
    onChange: ({ translation, velocity }) => {
      if (!held.current) {
        held.current = true;
        script.cancel();
        x.stop();
        y.stop();
        setDragging(true);
      }
      const o = origin(cornerRef.current);
      x.set(o.x + translation.x);
      y.set(o.y + translation.y);
      const next = nearest(projected(translation, velocity));
      if (next !== targetRef.current) {
        targetRef.current = next;
        setTarget(next);
      }
    },
    onEnd: ({ translation, velocity }) => {
      if (!held.current) return;
      held.current = false;
      snap(nearest(projected(translation, velocity)));
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (held.current) return;
      const options = [0, 1, 2, 3].filter((c) => c !== cornerRef.current);
      const next = options[Math.floor(Math.random() * options.length)];
      setDragging(true);
      targetRef.current = next;
      setTarget(next);
      script.cancel();
      script.after(0.35, () => snap(next, false));
    },
    { every: 1.6 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ position: "relative", width: SCREEN.w, height: SCREEN.h, flexShrink: 0 }}>
        <PhoneScreen />
        {[0, 1, 2, 3].map((index) => {
          const o = origin(index);
          return (
            <motion.div
              key={index}
              initial={false}
              animate={{ opacity: isDragging ? 1 : 0, backgroundColor: Palette.labelAlpha(index === target ? 0.08 : 0) }}
              transition={{
                opacity: isDragging ? spring(0.3, 0.75) : spring(ctx.n("response"), ctx.n("damping")),
                backgroundColor: anim.easeOut(0.15),
              }}
              style={{ position: "absolute", left: o.x, top: o.y, width: WIN.w, height: WIN.h, borderRadius: 14 }}
            >
              <DashedBorder width={WIN.w} height={WIN.h} radius={14} color={Palette.labelAlpha(0.25)} dash={[4, 4]} />
            </motion.div>
          );
        })}
        <motion.div {...pan} style={{ ...pan.style, position: "absolute", left: 0, top: 0, x, y, width: WIN.w, height: WIN.h, cursor: "grab" }}>
          <PiPWindow isDragging={isDragging} />
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Throw the window toward a corner" zh="把小窗甩向任意角落" />
    </div>
  );
}

function PhoneScreen() {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: 36,
        background: Palette.elevated,
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 10px 18px ${black(0.1)}`,
        padding: "10px 18px 20px",
        display: "flex",
        flexDirection: "column",
        gap: 14,
      }}
    >
      <div style={{ alignSelf: "center", width: 64, height: 18, borderRadius: 9, background: Palette.labelAlpha(0.9) }} />
      <div style={{ height: 96, borderRadius: 16, background: Palette.labelAlpha(0.06) }} />
      <PlaceholderLines count={4} />
    </div>
  );
}

function PiPWindow({ isDragging }: { isDragging: boolean }) {
  return (
    <motion.div
      initial={false}
      animate={{
        scale: isDragging ? 1.05 : 1,
        boxShadow: `0 ${isDragging ? 12 : 6}px ${isDragging ? 20 : 12}px ${black(isDragging ? 0.32 : 0.22)}`,
      }}
      transition={spring(0.3, 0.75)}
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: 14,
        background: `linear-gradient(135deg, ${Palette.violet}, ${Palette.blue}, ${Palette.sky})`,
        display: "grid",
        placeItems: "center",
        color: white(0.95),
      }}
    >
      <Play size={22} fill="currentColor" strokeWidth={0} />
      <div style={{ position: "absolute", left: 10, right: 10, bottom: 8, height: 3, borderRadius: 1.5, background: white(0.35) }}>
        <div style={{ width: 36, height: 3, borderRadius: 1.5, background: "#fff" }} />
      </div>
    </motion.div>
  );
}

