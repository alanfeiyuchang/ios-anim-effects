/** gestures.magnetic-snap · 磁吸网格 (Gestures+MagneticSnap.swift) */
import { animate, motion, useMotionValue, type Transition } from "motion/react";
import { Zap } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, spring, useAutoplay, useHaptics, usePan, white, alpha, type DemoProps, type Point } from "../../kit";

const SPACING = 92;
const TILE = 62;

const anchor = (index: number): Point => ({ x: ((index % 3) - 1) * SPACING, y: (Math.floor(index / 3) - 1) * SPACING });
const distance = (a: Point, b: Point) => Math.hypot(a.x - b.x, a.y - b.y);
function nearest(p: Point) {
  let best = 0;
  let bestD = Infinity;
  for (let i = 0; i < 9; i++) {
    const d = distance(p, anchor(i));
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}

export default function MagneticSnap({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const home = useRef(4);
  const drag = useRef<Point>({ x: 0, y: 0 });
  const held = useRef(false);
  const hoverRef = useRef<number | null>(null);
  const script = useRef<number | null>(null);
  const [dragging, setDragging] = useState(false);
  const [hover, setHover] = useState<number | null>(null);
  const [trans, setTrans] = useState<Transition>(spring(0.25, 0.7));
  const x = useMotionValue(0);
  const y = useMotionValue(0);

  useEffect(() => () => {
    if (script.current) window.clearTimeout(script.current);
  }, []);

  const rawPoint = (): Point => {
    const o = anchor(home.current);
    return { x: o.x + drag.current.x, y: o.y + drag.current.y };
  };
  const attracted = (raw: Point, index: number): Point => {
    const target = anchor(index);
    const radius = Math.max(ctx.n("radius"), 1);
    const d = distance(raw, target);
    if (d >= radius) return raw;
    const pull = ctx.n("strength") * (1 - d / radius);
    return { x: raw.x + (target.x - raw.x) * pull, y: raw.y + (target.y - raw.y) * pull };
  };
  const shown = () => {
    const raw = rawPoint();
    return attracted(raw, nearest(raw));
  };
  const moveTo = (t?: Transition) => {
    const p = shown();
    if (t) {
      animate(x, p.x, t);
      animate(y, p.y, t);
    } else {
      x.stop();
      y.stop();
      x.set(p.x);
      y.set(p.y);
    }
  };
  const setHoverTo = (h: number | null) => {
    hoverRef.current = h;
    setHover(h);
  };

  const takeOver = () => {
    if (script.current === null) return;
    window.clearTimeout(script.current);
    script.current = null;
    home.current = nearest(rawPoint());
    drag.current = { x: 0, y: 0 };
    setHoverTo(null);
    moveTo();
  };

  const release = (completed: boolean) => {
    const landing = completed ? nearest(rawPoint()) : home.current;
    const t = spring(0.38, ctx.n("damping"));
    setTrans(t);
    home.current = landing;
    drag.current = { x: 0, y: 0 };
    setDragging(false);
    setHoverTo(null);
    moveTo(t);
    if (completed) haptics.tap("medium");
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!held.current) {
        held.current = true;
        takeOver();
        setTrans(spring(0.25, 0.7));
        setDragging(true);
      }
      drag.current = translation;
      moveTo();
      const point = rawPoint();
      const candidate = nearest(point);
      const inRange = distance(point, anchor(candidate)) < ctx.n("radius");
      const newHover = inRange ? candidate : null;
      if (newHover !== hoverRef.current) {
        setTrans(spring(0.3, 0.6));
        setHoverTo(newHover);
        if (newHover !== null) haptics.selection();
      }
    },
    onEnd: () => {
      if (!held.current) return;
      held.current = false;
      release(true);
    },
  });

  const simulate = () => {
    if (held.current) return;
    let target = Math.floor(Math.random() * 9);
    if (target === home.current) target = (home.current + 4) % 9;
    const from = anchor(home.current);
    const to = anchor(target);
    const jx = Math.random() * 52 - 26;
    const jy = Math.random() * 52 - 26;
    const t = anim.easeInOut(0.6);
    setTrans(t);
    drag.current = { x: to.x - from.x + jx, y: to.y - from.y + jy };
    setDragging(true);
    setHoverTo(target);
    moveTo(t);
    if (script.current) window.clearTimeout(script.current);
    script.current = window.setTimeout(() => {
      script.current = null;
      const s = spring(0.38, ctx.n("damping"));
      setTrans(s);
      home.current = target;
      drag.current = { x: 0, y: 0 };
      setDragging(false);
      setHoverTo(null);
      moveTo(s);
    }, 700);
  };
  useAutoplay(ctx.isPreview, simulate, { every: 1.6 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ position: "relative", width: 300, height: 300 }}>
        {Array.from({ length: 9 }, (_, i) => {
          const p = anchor(i);
          return <MagnetAnchor key={i} active={hover === i} at={p} trans={trans} />;
        })}
        <motion.div
          {...pan}
          style={{ position: "absolute", left: 150 - TILE / 2, top: 150 - TILE / 2, width: TILE, height: TILE, x, y, touchAction: "none", cursor: "grab" }}
        >
          <motion.div
            animate={{
              scale: dragging ? 1.08 : 1,
              boxShadow: dragging ? `0 12px 18px ${alpha(Palette.sky, 0.45)}` : `0 6px 10px ${alpha(Palette.sky, 0.3)}`,
            }}
            initial={false}
            transition={trans}
            style={{
              width: TILE,
              height: TILE,
              borderRadius: 18,
              background: `linear-gradient(135deg, ${Palette.mint}, ${Palette.sky})`,
              display: "grid",
              placeItems: "center",
              color: "#fff",
              boxShadow: `0 6px 10px ${alpha(Palette.sky, 0.3)}`,
            }}
          >
            <div style={{ position: "absolute", inset: 0, borderRadius: 18, boxShadow: `inset 0 0 0 1px ${white(0.3)}` }} />
            <Zap size={22} fill="currentColor" strokeWidth={0} />
          </motion.div>
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Drag the tile near another dot" zh="把方块拖向其他圆点" style={{ position: "absolute", left: 0, right: 0, bottom: 6 }} />
    </div>
  );
}

function MagnetAnchor({ active, at, trans }: { active: boolean; at: Point; trans: Transition }) {
  return (
    <div style={{ position: "absolute", left: 150 - 35 + at.x, top: 150 - 35 + at.y, width: 70, height: 70, display: "grid", placeItems: "center", pointerEvents: "none" }}>
      <motion.div
        initial={false}
        animate={{
          scale: active ? 1 : 0.4,
          borderColor: alpha(Palette.mint, active ? 0.9 : 0),
          backgroundColor: alpha(Palette.mint, active ? 0.14 : 0),
        }}
        transition={trans}
        style={{ position: "absolute", left: 18, top: 18, width: 34, height: 34, borderRadius: "50%", border: "2px solid", borderColor: alpha(Palette.mint, 0) }}
      />
      <div style={{ position: "absolute", left: 31, top: 31, width: 8, height: 8, borderRadius: "50%", background: Palette.labelAlpha(0.18) }} />
      <motion.div
        initial={false}
        animate={{ opacity: active ? 1 : 0 }}
        transition={trans}
        style={{ position: "absolute", left: 31, top: 31, width: 8, height: 8, borderRadius: "50%", background: Palette.mint }}
      />
    </div>
  );
}
