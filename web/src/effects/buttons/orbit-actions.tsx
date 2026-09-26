/** buttons.orbit-actions · 环绕轨道操作 (Buttons+OrbitActions.swift) */
import { animate, motion, useMotionValue, useTransform, type MotionValue } from "motion/react";
import { Navigation, Sparkles } from "lucide-react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { DemoHint, Palette, anim, delayed, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { CameraFill } from "./_b-icons";
import { colorGradient } from "./_b-kit";
import { BOUNCY, PressButton, cubicKF, springKF, track, useSince, useSvgID } from "./_a-kit";

const g = (d: ReactNode) => (
  <svg viewBox="0 0 24 24" width={19} height={19}>
    {d}
  </svg>
);
const MicFill = () =>
  g(
    <>
      <rect x="8.5" y="2" width="7" height="12.5" rx="3.5" fill="currentColor" />
      <path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21M9 21h6" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" />
    </>,
  );
const PhotoFill = () =>
  g(
    <path
      fillRule="evenodd"
      d="M5 3.5h14A2.5 2.5 0 0 1 21.5 6v12a2.5 2.5 0 0 1-2.5 2.5H5A2.5 2.5 0 0 1 2.5 18V6A2.5 2.5 0 0 1 5 3.5Zm3 3.2a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8ZM4.5 17.6l4.4-4.6 3 3 3.6-4.4 4 6H4.5Z"
      fill="currentColor"
    />,
  );
const DocFill = () => g(<path d="M6.5 2h7.2c.5 0 1 .2 1.4.6l4.3 4.3c.4.4.6.9.6 1.4V20a2 2 0 0 1-2 2H6.5a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2Z" fill="currentColor" />);

const SATELLITES = [
  { Icon: () => <CameraFill size={19} />, color: Palette.coral },
  { Icon: MicFill, color: Palette.pink },
  { Icon: PhotoFill, color: Palette.mint },
  { Icon: () => <Navigation size={17} fill="currentColor" strokeWidth={1.5} style={{ transform: "rotate(0deg)" }} />, color: Palette.sky },
  { Icon: DocFill, color: Palette.amber },
];

export default function OrbitActions({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [open, setOpen] = useState(false);
  const openRef = useRef(false);
  const [pulses, setPulses] = useState([0, 0, 0, 0, 0]);
  const step = useRef(0);
  const intro = useRef<(() => void) | null>(null);
  const stage = useRef<HTMLDivElement>(null);
  const radius = ctx.n("radius");
  const maskID = useSvgID("orbit-mask");

  const cancelIntro = () => {
    intro.current?.();
    intro.current = null;
  };
  useEffect(() => () => cancelIntro(), []);

  const setOpenState = (v: boolean) => {
    openRef.current = v;
    setOpen(v);
  };
  const toggle = (silent = false) => {
    setOpenState(!openRef.current);
    if (!silent) haptics.tap();
  };
  const pick = (index: number, silent = false) => {
    if (!openRef.current) return;
    setPulses((p) => p.map((v, i) => (i === index ? v + 1 : v)));
    if (!silent) haptics.success();
    after(0.25, () => setOpenState(false));
  };

  useAutoplay(ctx.isPreview, () => {
    if (ctx.isPreview) {
      if (openRef.current) pick(step.current % SATELLITES.length);
      else toggle();
      step.current += 1;
      return;
    }
    cancelIntro();
    if (!openRef.current) toggle(true);
    intro.current = after(1.3, () => {
      intro.current = null;
      pick(2, true);
    });
  }, { every: 1.4, delay: 0.4 });

  const ring = useMotionValue(0);
  useEffect(() => {
    animate(ring, open ? 1 : 0, anim.easeInOut(0.5));
  }, [open, ring]);
  const dash = useTransform(ring, (v) => `${v} 2`);
  const coreT = spring(0.5, 0.72);
  const circumference = 2 * Math.PI * radius;

  return (
    <div ref={stage} style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", left: "50%", top: "50%", width: 0, height: 0 }}>
        <svg width={radius * 2 + 4} height={radius * 2 + 4} style={{ position: "absolute", left: -radius - 2, top: -radius - 2, overflow: "visible" }}>
          <defs>
            <mask id={maskID}>
              <motion.circle
                cx={radius + 2}
                cy={radius + 2}
                r={radius}
                fill="none"
                stroke="#fff"
                strokeWidth={4}
                pathLength={1}
                transform={`rotate(-90 ${radius + 2} ${radius + 2})`}
                style={{ strokeDasharray: dash }}
              />
            </mask>
          </defs>
          <circle
            cx={radius + 2}
            cy={radius + 2}
            r={radius}
            fill="none"
            stroke={Palette.labelAlpha(0.18)}
            strokeWidth={1.5}
            strokeLinecap="round"
            strokeDasharray={`3 ${circumference / Math.round(circumference / 9) - 3}`}
            mask={`url(#${maskID})`}
          />
        </svg>
        {SATELLITES.map((s, index) => (
          <Satellite
            key={index}
            index={index}
            open={open}
            radius={radius}
            sweep={ctx.n("sweep")}
            stagger={ctx.n("stagger")}
            color={s.color}
            pulse={pulses[index]}
            onTap={() => {
              cancelIntro();
              pick(index);
            }}
          >
            <s.Icon />
          </Satellite>
        ))}
        <div style={{ position: "absolute", left: -34, top: -34 }}>
          <PressButton
            scale={0.9}
            dim={0.05}
            onClick={() => {
              cancelIntro();
              toggle();
            }}
            style={{ width: 68, height: 68, borderRadius: "50%", position: "relative" }}
          >
            <motion.div
              initial={false}
              animate={{ boxShadow: open ? "0px 0px 22px rgba(164, 107, 255, 0.6)" : "0px 0px 12px rgba(164, 107, 255, 0.35)" }}
              transition={coreT}
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: "50%",
                background: Palette.primary,
                display: "grid",
                placeItems: "center",
                color: "#fff",
              }}
            >
              <div style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.25)" }} />
              <motion.span initial={false} animate={{ rotate: open ? 180 : 0 }} transition={coreT} style={{ display: "grid" }}>
                <Sparkles size={28} strokeWidth={2.2} />
              </motion.span>
            </motion.div>
          </PressButton>
        </div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
        <DemoHint ctx={ctx} en="Tap the core, then a satellite" zh="点击核心，再点一个卫星" style={{ paddingBottom: 14 }} />
      </div>
    </div>
  );
}

function Satellite({
  index,
  open,
  radius,
  sweep,
  stagger,
  color,
  pulse,
  onTap,
  children,
}: {
  index: number;
  open: boolean;
  radius: number;
  sweep: number;
  stagger: number;
  color: string;
  pulse: number;
  onTap: () => void;
  children: ReactNode;
}) {
  const count = SATELLITES.length;
  const p = useMotionValue(0);
  const order = open ? index : count - 1 - index;
  useEffect(() => {
    animate(p, open ? 1 : 0, delayed(spring(0.5, 0.72), order * stagger));
  }, [open, p, order, stagger]);
  const home = (index / count) * 360;
  const transform = useSatelliteTransform(p, home, sweep, radius);
  const opacity = useTransform(p, (v) => Math.min(Math.max(v, 0), 1));
  const scale = track(useSince(pulse, 0.45), 1, [cubicKF(1.25, 0.1), springKF(1, 0.35, BOUNCY)]);
  return (
    <motion.div style={{ position: "absolute", left: -24, top: -24, width: 48, height: 48, transform, opacity, pointerEvents: open ? "auto" : "none" }}>
      <button
        type="button"
        onClick={onTap}
        style={{
          width: 48,
          height: 48,
          borderRadius: "50%",
          background: colorGradient(color),
          boxShadow: `0 4px 8px color-mix(in srgb, ${color} 40%, transparent)`,
          display: "grid",
          placeItems: "center",
          color: "#fff",
          transform: `scale(${scale})`,
        }}
      >
        {children}
      </button>
    </motion.div>
  );
}

function useSatelliteTransform(p: MotionValue<number>, home: number, sweep: number, radius: number) {
  return useTransform(p, (v) => {
    const angle = home - sweep * (1 - v);
    const r = radius * v;
    const s = 0.3 + 0.7 * v;
    return `scale(${s}) rotate(${angle}deg) translateY(${-r}px) rotate(${-angle}deg)`;
  });
}
