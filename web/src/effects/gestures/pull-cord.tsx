/** gestures.pull-cord · 拉绳开关 (Gestures+PullCord.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useTransform } from "motion/react";
import { Sofa } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, black, hex, rubberBand, spring, useAutoplay, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";
import { useScript } from "./_a-common";

const C = 160;
const ANCHOR = { x: 34, y: -92 };
const REST = 90;
const HOOK_Y = C - 181;

/** `LampShade`: a trapezoid, 28 % inset at the top. */
const shade = (w: number, h: number) => `M${w * 0.28} 0 L${w - w * 0.28} 0 L${w} ${h} L0 ${h} Z`;

export default function PullCord({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const swayTask = useScript();
  const px = useMotionValue(0);
  const py = useMotionValue(0);
  const sway = useMotionValue(0);
  const [pullY, setPullY] = useState(0);
  const [dragging, setDragging] = useState(false);
  const [isOn, setOn] = useState(false);
  const st = useRef({ held: false, scripted: false, on: false });
  const s = st.current;
  const threshold = ctx.n("threshold");
  const armed = pullY >= threshold;
  const lastArmed = useRef(armed);
  useEffect(() => {
    if (armed !== lastArmed.current) {
      lastArmed.current = armed;
      if (armed && !s.scripted) haptics.tap("rigid");
    }
  }, [armed, haptics, s]);

  const setPull = (p: Point, t?: ReturnType<typeof spring>) => {
    setPullY(p.y);
    if (t) {
      animate(px, p.x, t);
      animate(py, p.y, t);
    } else {
      px.stop();
      py.stop();
      px.set(p.x);
      py.set(p.y);
    }
  };

  const release = (canToggle = true) => {
    const isArmed = canToggle && py.get() >= ctx.n("threshold");
    setDragging(false);
    setPull({ x: 0, y: 0 }, spring(0.35, ctx.n("damping")));
    if (!isArmed) return;
    s.on = !s.on;
    setOn(s.on);
    animate(sway, 4, spring(0.18, 0.9));
    swayTask.cancel();
    swayTask.after(0.12, () => animate(sway, 0, spring(0.6, 0.25)));
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!s.held) {
        s.held = true;
        script.cancel();
        setDragging(true);
        s.scripted = false;
      }
      setPull({
        x: rubberBand(translation.x, 24),
        y: translation.y > 0 ? rubberBand(translation.y, 120, 0.9) : rubberBand(translation.y, 12),
      });
    },
    onEnd: () => {
      if (!s.held) return;
      s.held = false;
      release(true);
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (s.held) return;
      s.scripted = true;
      setPull({ x: -8 + Math.random() * 16, y: ctx.n("threshold") + 30 }, anim.easeIn(0.4));
      setDragging(true);
      script.cancel();
      script.after(0.5, () => release());
    },
    { every: 2.2 },
  );

  const on = anim.easeInOut(0.35);
  const endX = useTransform(px, (x) => C + ANCHOR.x + x);
  const endY = useTransform(py, (y) => C + ANCHOR.y + REST + y);
  const cord = useTransform(() => `M${C + ANCHOR.x} ${C + ANCHOR.y} L${endX.get()} ${endY.get()}`);
  const beadX = useTransform(endX, (x) => x - 23);
  const beadY = useTransform(endY, (y) => y + 9 - 23);

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div style={{ position: "relative", width: 320, height: 320 }}>
        {/* Room */}
        <div style={{ position: "absolute", left: C - 40 - 50, top: C + 90 - 30, width: 100, height: 60, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 4 }}>
          <motion.div initial={false} animate={{ color: isOn ? Palette.coral : Palette.labelAlpha(0.18) }} transition={on} style={{ display: "grid" }}>
            <Sofa size={42} fill="currentColor" strokeWidth={1.4} />
          </motion.div>
          <span style={{ position: "relative", display: "grid", fontSize: 12, lineHeight: "16px", fontWeight: 800, letterSpacing: 2, color: Palette.secondaryLabel, marginRight: -2 }}>
            <AnimatePresence initial={false}>
              <motion.span key={isOn ? "on" : "off"} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={on} style={{ gridArea: "1 / 1", textAlign: "center" }}>
                {isOn ? ctx.t("ON", "开") : ctx.t("OFF", "关")}
              </motion.span>
            </AnimatePresence>
          </span>
        </div>
        {/* Rig: everything that hangs from the hook sways together. */}
        <motion.div style={{ position: "absolute", inset: 0, rotate: sway, transformOrigin: `${C}px ${HOOK_Y}px` }}>
          <motion.svg
            width={300}
            height={220}
            initial={false}
            animate={{ opacity: isOn ? 1 : 0 }}
            transition={on}
            style={{ position: "absolute", left: C - 150, top: C + 30 - 110, pointerEvents: "none" }}
          >
            <defs>
              <linearGradient id="pull-cord-cone" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor={hex(Palette.amber, 0.4)} />
                <stop offset="1" stopColor={hex(Palette.amber, 0)} />
              </linearGradient>
            </defs>
            <path d={shade(300, 220)} fill="url(#pull-cord-cone)" />
          </motion.svg>
          {/* Lamp: rod, shade, bulb (VStack spacing −6, centred 128 pt above the middle). */}
          <div style={{ position: "absolute", left: C - 1, top: HOOK_Y, width: 2, height: 40, background: Palette.labelAlpha(0.4) }} />
          <motion.div
            initial={false}
            animate={{
              background: isOn ? `radial-gradient(circle closest-side, #fff 1px, ${Palette.amber} 13px)` : `radial-gradient(circle closest-side, rgb(142 142 147 / 0.4) 1px, rgb(142 142 147 / 0.4) 13px)`,
              boxShadow: `0 0 30px ${hex(Palette.amber, isOn ? 0.9 : 0)}`,
            }}
            transition={on}
            style={{ position: "absolute", left: C - 13, top: HOOK_Y + 40 - 6 + 52 - 6, width: 26, height: 26, borderRadius: "50%" }}
          />
          <svg width={110} height={52} style={{ position: "absolute", left: C - 55, top: HOOK_Y + 34 }}>
            <defs>
              <linearGradient id="pull-cord-shade" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor={Palette.coral} />
                <stop offset="1" stopColor={Palette.pink} />
              </linearGradient>
            </defs>
            <path d={shade(110, 52)} fill="url(#pull-cord-shade)" />
          </svg>
          <svg width={320} height={320} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
            <motion.path d={cord} stroke={Palette.labelAlpha(0.45)} strokeWidth={1.5} strokeLinecap="round" fill="none" />
          </svg>
          <motion.div {...pan} style={{ ...pan.style, position: "absolute", left: 0, top: 0, x: beadX, y: beadY, width: 46, height: 46, borderRadius: "50%", display: "grid", placeItems: "center", cursor: "grab" }}>
            <motion.div
              initial={false}
              animate={{ scale: armed ? 1.25 : dragging ? 1.1 : 1 }}
              transition={spring(0.25, 0.6)}
              style={{
                width: 18,
                height: 18,
                borderRadius: "50%",
                background: `linear-gradient(${Palette.amber}, ${Palette.coral})`,
                boxShadow: `inset 0 0 0 1px ${white(0.4)}, 0 2px 3px ${black(0.2)}`,
              }}
            />
          </motion.div>
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Pull the bead down" zh="向下拉动拉珠" style={{ position: "absolute", left: 0, right: 0, bottom: 4 }} />
    </div>
  );
}
