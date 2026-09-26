/** gestures.charge-burst · 蓄力爆发 (Gestures+ChargeBurst.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { Zap } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, ease, fonts, hex, spring, useAutoplay, useClock, useElapsed, useHaptics, white, type DemoProps } from "../../kit";
import { useScript } from "./_a-common";

const RING_COLORS = [Palette.mint, Palette.sky, Palette.violet, Palette.pink];

function parse(c: string): [number, number, number] {
  const n = parseInt(c.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
/** Colour of the angular gradient at `t` (0…1 around the ring). */
function ringColor(t: number): string {
  const stops = RING_COLORS.map(parse);
  const x = Math.min(Math.max(t, 0), 1) * (stops.length - 1);
  const i = Math.min(Math.floor(x), stops.length - 2);
  const f = x - i;
  const c = stops[i].map((v, k) => Math.round(v + (stops[i + 1][k] - v) * f));
  return `rgb(${c[0]} ${c[1]} ${c[2]})`;
}

export default function ChargeBurst({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const script = useScript();
  const full = useScript();
  const charge = useMotionValue(0);
  const [c, setC] = useState(0);
  useMotionValueEvent(charge, "change", setC);
  const [isFull, setFull] = useState(false);
  const [burst, setBurst] = useState(0);
  const st = useRef({ pressing: false, held: false, start: 0, simulated: false });
  const s = st.current;
  const duration = ctx.n("duration");

  const beginPress = () => {
    s.pressing = true;
    s.start = performance.now();
    animate(charge, 1, anim.linear(duration));
    if (!s.simulated) haptics.tap("soft");
    full.cancel();
    full.after(duration, () => {
      if (!s.pressing) return;
      setFull(true);
      if (!s.simulated) haptics.tap("heavy");
    });
  };

  const endPress = () => {
    if (!s.pressing) return;
    s.pressing = false;
    full.cancel();
    const elapsed = (performance.now() - s.start) / 1000;
    setFull(false);
    if (elapsed >= duration - 0.02) {
      setBurst((b) => b + 1);
      if (!s.simulated) haptics.success();
      animate(charge, 0, spring(0.5, 0.45));
    } else {
      animate(charge, 0, spring(0.4, 0.85));
    }
  };

  const onDown = (e: React.PointerEvent<HTMLDivElement>) => {
    if (s.held) return;
    e.currentTarget.setPointerCapture(e.pointerId);
    s.held = true;
    script.cancel();
    s.pressing = false;
    setFull(false);
    if (s.simulated) {
      charge.stop();
      charge.set(0);
    }
    s.simulated = false;
    beginPress();
  };
  const onUp = () => {
    if (!s.held) return;
    s.held = false;
    endPress();
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (s.pressing || s.held) return;
      s.simulated = true;
      beginPress();
      script.cancel();
      script.after(duration + 0.35, endPress);
    },
    { every: duration + 1.6, delay: 0.4 },
  );

  const t = useClock(isFull);
  const jx = isFull ? Math.sin(t * 73) * 1.5 : 0;
  const jy = isFull ? Math.cos(t * 61) * 1.2 : 0;
  const p = Math.min(Math.max(c, 0), 1);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <div style={{ position: "relative", width: 240, height: 240, flexShrink: 0 }}>
        {burst > 0 && <Burst key={burst} count={ctx.i("particles")} seed={burst} />}
        <Ring progress={p} />
        <div
          onPointerDown={onDown}
          onPointerUp={onUp}
          onPointerCancel={() => {
            if (!s.held) return;
            s.held = false;
            if (!s.pressing) return;
            s.pressing = false;
            full.cancel();
            setFull(false);
            animate(charge, 0, spring(0.4, 0.85));
          }}
          style={{
            position: "absolute",
            left: 64,
            top: 64,
            width: 112,
            height: 112,
            borderRadius: "50%",
            transform: `translate(${jx}px, ${jy}px) scale(${1 - 0.1 * c})`,
            background: Palette.primary,
            boxShadow: `inset 0 0 0 1px ${white(0.25)}, 0 8px ${12 + 18 * c}px ${hex(Palette.violet, 0.3 + 0.4 * c)}`,
            display: "grid",
            placeItems: "center",
            color: "#fff",
            cursor: "pointer",
            touchAction: "none",
          }}
        >
          <Zap size={48} fill="currentColor" strokeWidth={1.5} strokeLinejoin="round" />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Press and hold, release when full" zh="长按蓄力，满格后松手" />
    </div>
  );
}

function Ring({ progress }: { progress: number }) {
  const R = 84;
  const cx = 120;
  const cy = 120;
  const pt = (a: number) => [cx + R * Math.sin(a), cy - R * Math.cos(a)];
  const segments = [];
  const end = progress * Math.PI * 2;
  const n = Math.max(1, Math.ceil(progress * 90));
  if (progress > 0) {
    for (let i = 0; i < n; i++) {
      const a0 = (end * i) / n;
      const a1 = Math.min((end * (i + 1)) / n + 0.01, end);
      const [x0, y0] = pt(a0);
      const [x1, y1] = pt(a1);
      segments.push(<path key={i} d={`M${x0} ${y0} A${R} ${R} 0 0 1 ${x1} ${y1}`} stroke={ringColor((a0 + a1) / 2 / (Math.PI * 2))} />);
    }
  }
  const [ex, ey] = pt(end);
  return (
    <>
      <svg width={240} height={240} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        <circle cx={cx} cy={cy} r={R} fill="none" stroke={Palette.labelAlpha(0.08)} strokeWidth={8} />
        {progress > 0 && (
          <g fill="none" strokeWidth={8}>
            <circle cx={cx} cy={cy - R} r={4} fill={ringColor(0)} stroke="none" />
            {segments}
            <circle cx={ex} cy={ey} r={4} fill={ringColor(progress)} stroke="none" />
          </g>
        )}
      </svg>
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 36 + 168 - 16 + 30,
          textAlign: "center",
          fontFamily: fonts.rounded,
          fontSize: 13,
          lineHeight: "16px",
          fontWeight: 600,
          fontVariantNumeric: "tabular-nums",
          color: Palette.secondaryLabel,
        }}
      >
        {Math.round(progress * 100)}%
      </div>
    </>
  );
}

function Burst({ count, seed }: { count: number; seed: number }) {
  const t = useElapsed(seed, 0.8);
  const progress = ease.out(Math.min(t / 0.8, 1));
  const flash = ease.out(Math.min(t / 0.3, 1));
  const n = Math.max(count, 1);
  const random = (index: number, salt: number) => {
    const x = Math.sin((index * 131 + seed * 977 + salt * 53) * 12.9898) * 43758.5453;
    return x - Math.floor(x);
  };
  const ring = 120 + 220 * progress;
  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      <div
        style={{
          position: "absolute",
          left: 40,
          top: 40,
          width: 160,
          height: 160,
          borderRadius: "50%",
          background: `radial-gradient(circle closest-side, #fff, ${white(0)})`,
          transform: `scale(${0.6 + 0.8 * flash})`,
          opacity: 1 - flash,
          mixBlendMode: "plus-lighter",
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 120 - ring / 2,
          top: 120 - ring / 2,
          width: ring,
          height: ring,
          borderRadius: "50%",
          boxShadow: `0 0 0 ${(1 + 6 * (1 - progress)) / 2}px ${hex(Palette.sky, 1 - progress)}, inset 0 0 0 ${(1 + 6 * (1 - progress)) / 2}px ${hex(Palette.sky, 1 - progress)}`,
        }}
      />
      {Array.from({ length: n }, (_, index) => {
        const base = (index / n) * 2 * Math.PI;
        const angle = base + (random(index, 1) - 0.5) * 0.35;
        const speed = 0.7 + 0.6 * random(index, 2);
        const radius = 60 + 110 * progress * speed;
        const drop = 70 * progress * progress;
        const heading = Math.atan2(Math.sin(angle) * 110 * speed + 140 * progress, Math.cos(angle) * 110 * speed);
        const w = 4 + 12 * (1 - progress) * speed;
        const x = 120 + Math.cos(angle) * radius;
        const y = 120 + Math.sin(angle) * radius + drop;
        return (
          <div
            key={index}
            style={{
              position: "absolute",
              left: x - w / 2,
              top: y - 2.5,
              width: w,
              height: 5,
              borderRadius: 2.5,
              background: Palette.spectrum[index % Palette.spectrum.length],
              transform: `rotate(${heading}rad)`,
              opacity: 1 - progress,
            }}
          />
        );
      })}
    </div>
  );
}
