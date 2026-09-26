/** inputs.thermostat-dial (Inputs+ThermostatDial.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, clamp, ease, fonts, mix, progress, spring, springAt, springDB, textStyle, useAutoplay, useElapsed, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";

const SIZE = 230;
const BOX = SIZE + 40;
const LO = 10;
const HI = 30;
const TICKS = 54;
const TARGETS = [26, 17.5, 23, 14, 21.5];
const C = BOX / 2;

/** The track's angular gradient (sky → blue → violet → coral over 270°), sampled per segment. */
const STOPS = [
  [0x3a, 0xc4, 0xff],
  [0x4f, 0x7c, 0xff],
  [0xa4, 0x6b, 0xff],
  [0xff, 0x7a, 0x5c],
];
function gradientAt(f: number) {
  const x = clamp(f) * (STOPS.length - 1);
  const i = Math.min(Math.floor(x), STOPS.length - 2);
  const t = x - i;
  return `rgb(${STOPS[i].map((v, k) => Math.round(v + (STOPS[i + 1][k] - v) * t)).join(" ")})`;
}

export default function ThermostatDial({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [temperature, setTempState] = useState(21.5);
  const tempRef = useRef(21.5);
  const bead = useMotionValue(21.5);
  const [beadT, setBeadT] = useState(21.5);
  useMotionValueEvent(bead, "change", setBeadT);
  const [releases, setReleases] = useState(0);
  const lastAngle = useRef<number | null>(null);
  const step = useRef(0);
  const increment = ctx.i("step") === 0 ? 0.5 : 1;
  const leash = spring(ctx.n("leash"), 0.55);

  const setTemperature = (v: number) => {
    tempRef.current = v;
    setTempState(v);
    animate(bead, v, leash);
  };

  const pan = usePan({
    onChange: ({ location }) => {
      const dx = location.x - C;
      const dy = location.y - C;
      if (Math.hypot(dx, dy) <= 30) return;
      let angle = (Math.atan2(dy, dx) * 180) / Math.PI - 135;
      while (angle < 0) angle += 360;
      if (angle > 270) {
        if (lastAngle.current !== null) angle = lastAngle.current > 135 ? 270 : 0;
        else angle = angle > 315 ? 0 : 270;
      }
      if (lastAngle.current !== null && Math.abs(angle - lastAngle.current) > 180) return;
      lastAngle.current = angle;
      const raw = LO + (angle / 270) * (HI - LO);
      const nv = clamp(Math.round(raw / increment) * increment, LO, HI);
      if (nv === tempRef.current) return;
      haptics.selection();
      setTemperature(nv);
    },
    onEnd: () => {
      if (lastAngle.current === null) return;
      lastAngle.current = null;
      setReleases((r) => r + 1);
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      setTemperature(TARGETS[step.current % TARGETS.length]);
      step.current += 1;
      after(0.6, () => setReleases((r) => r + 1));
    },
    { every: 1.6, delay: 0.3 },
  );

  const fraction = (beadT - LO) / (HI - LO);
  const setFraction = (temperature - LO) / (HI - LO);
  const heating = temperature >= 21;
  const intensity = ctx.n("glow");
  const beadTick = Math.round(fraction * (TICKS - 1));
  const stagger = ctx.n("stagger");
  const r = SIZE / 2;
  const polar = (deg: number, rad: number) => [C + rad * Math.cos((deg * Math.PI) / 180), C + rad * Math.sin((deg * Math.PI) / 180)];
  const arc = (from: number, to: number) => {
    const [x0, y0] = polar(from, r);
    const [x1, y1] = polar(to, r);
    return `M${x0} ${y0} A${r} ${r} 0 ${to - from > 180 ? 1 : 0} 1 ${x1} ${y1}`;
  };
  const sweep = 270 * clamp(fraction);
  const segs = Math.max(1, Math.ceil(sweep / 4));
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div {...pan} style={{ ...pan.style, position: "relative", width: BOX, height: BOX, borderRadius: "50%", flexShrink: 0, transform: ctx.isPreview ? "scale(0.9)" : undefined, cursor: "grab" }}>
        {/* glow */}
        <div style={{ position: "absolute", left: C - SIZE * 0.35, top: C - SIZE * 0.35, width: SIZE * 0.7, height: SIZE * 0.7, filter: "blur(50px)" }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.sky, opacity: heating ? 0 : intensity, transition: "opacity 0.6s ease-in-out" }} />
          <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.coral, opacity: heating ? intensity : 0, transition: "opacity 0.6s ease-in-out" }} />
        </div>
        {Array.from({ length: TICKS }, (_, i) => (
          <Tick key={i} index={i} lit={i <= beadTick} delay={Math.abs(i - beadTick) * stagger} trigger={releases} />
        ))}
        <svg width={BOX} height={BOX} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
          <path d={arc(135, 405)} fill="none" style={{ stroke: Palette.labelAlpha(0.1) }} strokeWidth={14} strokeLinecap="round" />
          {sweep > 0.01 &&
            Array.from({ length: segs }, (_, i) => {
              const a0 = (sweep * i) / segs;
              const a1 = Math.min(sweep, (sweep * (i + 1)) / segs + 0.6);
              return (
                <path
                  key={i}
                  d={arc(135 + a0, 135 + a1)}
                  fill="none"
                  stroke={gradientAt((a0 + a1) / 2 / 270)}
                  strokeWidth={14}
                  strokeLinecap={i === 0 || i === segs - 1 ? "round" : "butt"}
                />
              );
            })}
        </svg>
        {/* setpoint ring */}
        <Orbit angle={135 + 270 * setFraction}>
          <div style={{ width: 20, height: 20, borderRadius: "50%", boxShadow: `inset 0 0 0 2px ${Palette.labelAlpha(0.45)}` }} />
        </Orbit>
        <Orbit angle={135 + 270 * fraction}>
          <div style={{ width: 24, height: 24, borderRadius: "50%", background: "#fff", boxShadow: "0 2px 4px rgb(0 0 0 / 0.25)" }} />
        </Orbit>
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2, pointerEvents: "none" }}>
          <div style={{ display: "grid", placeItems: "center" }}>
            <AnimatePresence initial={false}>
              <motion.span
                key={heating ? "heat" : "cool"}
                initial={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
                animate={{ opacity: 1, filter: "blur(0px)", scale: 1 }}
                exit={{ opacity: 0, filter: "blur(4px)", scale: 0.9 }}
                transition={springDB(0.5, 0)}
                style={{ gridArea: "1 / 1", ...textStyle.caption, fontWeight: 600, color: heating ? Palette.coral : Palette.blue, whiteSpace: "nowrap" }}
              >
                {heating ? (zh ? "制热至" : "Heating to") : zh ? "制冷至" : "Cooling to"}
              </motion.span>
            </AnimatePresence>
          </div>
          <NumericText value={temperature} text={`${temperature.toFixed(1)}°`} style={{ fontFamily: fonts.rounded, fontSize: 46, fontWeight: 600, lineHeight: "54px" }} />
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Drag around the ring" zh="沿圆环拖动" style={{ paddingBottom: 14 }} />
    </div>
  );
}

/** A child placed on the track's circle at `angle` (SwiftUI degrees: 0 = 3 o'clock, clockwise). */
function Orbit({ angle, children }: { angle: number; children: React.ReactNode }) {
  const rad = (angle * Math.PI) / 180;
  return (
    <div
      style={{
        position: "absolute",
        left: C + (SIZE / 2) * Math.cos(rad),
        top: C + (SIZE / 2) * Math.sin(rad),
        transform: "translate(-50%, -50%)",
        pointerEvents: "none",
      }}
    >
      {children}
    </div>
  );
}

function Tick({ index, lit, delay, trigger }: { index: number; lit: boolean; delay: number; trigger: number }) {
  const lead = 0.001 + delay;
  const t = useElapsed(trigger, lead + 0.52, true);
  let s = 1;
  if (t >= 0 && t > lead && t < lead + 0.52) s = t < lead + 0.12 ? mix(1, 1.8, ease.inOut(progress(t, lead, 0.12))) : mix(1.8, 1, springAt(t - lead - 0.12, 0.4, 0.7));
  const angle = 135 + (270 * index) / (TICKS - 1);
  const radius = SIZE / 2 + 24;
  return (
    <div
      style={{
        position: "absolute",
        left: C - 5 + radius,
        top: C - 1,
        width: 10,
        height: 2,
        transformOrigin: `${5 - radius}px 1px`,
        transform: `rotate(${angle}deg)`,
      }}
    >
      <div
        style={{
          width: 10,
          height: 2,
          borderRadius: 1,
          background: Palette.labelAlpha(lit ? 0.55 : 0.15),
          transform: `scaleX(${s})`,
          transformOrigin: "0% 50%",
        }}
      />
    </div>
  );
}
