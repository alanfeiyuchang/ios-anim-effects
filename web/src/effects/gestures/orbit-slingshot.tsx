/** gestures.orbit-slingshot · 引力弹弓 (Gestures+OrbitSlingshot.swift) */
import { useEffect, useMemo, useRef } from "react";
import { DemoHint, Palette, alpha, useAutoplay, useHaptics, usePan, white, type DemoProps, type Point } from "../../kit";

const ARENA = 300;
const CENTER = { x: 150, y: 150 };
const PAD = { x: 150, y: 250 };
const BASE_G = 3_240_000;

function acceleration(p: Point, g: number): Point {
  const dx = CENTER.x - p.x;
  const dy = CENTER.y - p.y;
  const r2 = dx * dx + dy * dy + 400;
  const r = Math.sqrt(r2);
  const m = g / r2;
  return { x: (m * dx) / r, y: (m * dy) / r };
}

function advance(p: Point, v: Point, dt: number, g: number) {
  const a = acceleration(p, g);
  v.x += a.x * dt;
  v.y += a.y * dt;
  p.x += v.x * dt;
  p.y += v.y * dt;
}

interface OrbitFrame {
  position: Point;
  trail: Point[];
  flash: number;
  appear: number;
}

/** Frame-stepped orbital physics (OrbitModel), ported as-is. */
class OrbitModel {
  position: Point = { ...PAD };
  velocity: Point = { x: 0, y: 0 };
  isHeld = false;
  inFlight = false;
  private trail: Point[] = [];
  private flash = 0;
  private appear = 1;
  private lastDate: number | null = null;
  private pendingVelocity: Point | null = null;

  launch(from: Point, v: Point) {
    this.position = { ...from };
    this.velocity = { ...v };
    this.isHeld = false;
    this.inFlight = true;
    this.pendingVelocity = null;
    this.lastDate = null;
  }

  relaunch(v: Point) {
    if (this.isHeld) return;
    if (this.inFlight || this.appear < 1) {
      if (this.inFlight) this.respawn(false);
      this.pendingVelocity = v;
    } else {
      this.launch(PAD, v);
    }
  }

  grab() {
    this.isHeld = true;
    this.pendingVelocity = null;
  }

  cancelHold(at: Point) {
    this.position = { ...at };
    this.isHeld = false;
    this.lastDate = null;
  }

  private respawn(flashStar: boolean) {
    this.position = { ...PAD };
    this.velocity = { x: 0, y: 0 };
    this.inFlight = false;
    this.trail = [];
    this.appear = 0;
    if (flashStar) this.flash = 1;
  }

  step(date: number, g: number, maxTrail: number): OrbitFrame {
    const raw = this.lastDate === null ? 0 : date - this.lastDate;
    this.lastDate = date;
    const dt = Math.min(Math.max(raw, 0), 1 / 30);
    this.flash *= Math.exp(-dt * 5);
    this.appear = Math.min(this.appear + dt / 0.35, 1);
    if (this.pendingVelocity && !this.inFlight && !this.isHeld && this.appear >= 1) this.launch(PAD, this.pendingVelocity);

    if (this.inFlight && !this.isHeld && dt > 0) {
      advance(this.position, this.velocity, dt / 2, g);
      advance(this.position, this.velocity, dt / 2, g);
      this.trail.push({ ...this.position });
      const r = Math.hypot(this.position.x - CENTER.x, this.position.y - CENTER.y);
      const p = this.position;
      if (r < 24) this.respawn(true);
      else if (!(p.x >= -20 && p.x < ARENA + 20 && p.y >= -20 && p.y < ARENA + 20)) this.respawn(false);
    } else if (this.trail.length) {
      this.trail.shift();
    }
    if (this.trail.length > maxTrail) this.trail.splice(0, this.trail.length - maxTrail);
    return { position: this.position, trail: this.trail, flash: this.flash, appear: this.appear };
  }
}

/** SeededStars: 64-bit LCG with wrapping multiplication. */
function seededStars(seed: number) {
  const M = (1n << 64n) - 1n;
  let state = (BigInt(seed) * 0x9e3779b97f4a7c15n) & M;
  return () => {
    state = (state * 6364136223846793005n + 1442695040888963407n) & M;
    return Number((state >> 33n) & 0xffffffn) / 0xffffff;
  };
}

const DPR = () => Math.max(typeof window !== "undefined" ? window.devicePixelRatio : 2, 2);

export default function OrbitSlingshot({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const model = useRef(new OrbitModel()).current;
  const anchor = useRef<Point | null>(null);
  const pull = useRef<Point>({ x: 0, y: 0 });
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const moonRef = useRef<HTMLDivElement>(null);
  const glowRef = useRef<HTMLDivElement>(null);
  const coreRef = useRef<HTMLDivElement>(null);
  const params = useRef({ g: 0, trail: 0, power: 0 });
  params.current = { g: BASE_G * ctx.n("gravity"), trail: ctx.i("trail"), power: ctx.n("power") };

  const launchVelocity = () => ({ x: -pull.current.x * params.current.power, y: -pull.current.y * params.current.power });

  useEffect(() => {
    const canvas = canvasRef.current!;
    const dpr = DPR();
    canvas.width = ARENA * dpr;
    canvas.height = ARENA * dpr;
    const c = canvas.getContext("2d")!;
    let raf = 0;
    let last = 0;
    const minInterval = ctx.isPreview ? 1000 / 30 : 0;
    const sky = "58 196 255";
    const draw = (now: number) => {
      raf = requestAnimationFrame(draw);
      if (minInterval && now - last < minInterval - 1) return;
      last = now;
      const t = now / 1000;
      const { g, trail: maxTrail } = params.current;
      const frame = model.step(t, g, maxTrail);
      c.setTransform(dpr, 0, 0, dpr, 0, 0);
      c.clearRect(0, 0, ARENA, ARENA);
      const count = frame.trail.length;
      frame.trail.forEach((p, i) => {
        const k = (i + 1) / Math.max(count, 1);
        const r = 1 + 5 * k;
        c.fillStyle = `rgb(${sky} / ${0.5 * k})`;
        c.beginPath();
        c.arc(p.x, p.y, r, 0, Math.PI * 2);
        c.fill();
      });
      const start = anchor.current;
      if (start) {
        const moon = { x: start.x + pull.current.x, y: start.y + pull.current.y };
        c.strokeStyle = white(0.6);
        c.lineWidth = 2;
        c.lineCap = "round";
        c.setLineDash([4, 5]);
        c.beginPath();
        c.moveTo(start.x, start.y);
        c.lineTo(moon.x, moon.y);
        c.stroke();
        c.setLineDash([]);
        const p = { ...moon };
        const v = launchVelocity();
        const dots: Point[] = [];
        for (let i = 0; i < 60; i++) {
          advance(p, v, 1 / 30, g);
          if (i % 2 === 1) dots.push({ ...p });
        }
        dots.forEach((d, i) => {
          const fade = 1 - i / Math.max(dots.length, 1);
          c.fillStyle = white(0.75 * fade);
          c.beginPath();
          c.arc(d.x, d.y, 2, 0, Math.PI * 2);
          c.fill();
        });
      }
      // Star
      const pulse = 0.5 + 0.5 * Math.sin(t * 2.2);
      if (glowRef.current) glowRef.current.style.transform = `scale(${0.9 + 0.12 * pulse + 0.5 * frame.flash})`;
      if (coreRef.current) coreRef.current.style.boxShadow = `0 0 ${14 + 20 * frame.flash}px ${alpha(Palette.amber, 0.9)}`;
      // Moon
      const pos = start ? { x: start.x + pull.current.x, y: start.y + pull.current.y } : frame.position;
      if (moonRef.current) {
        moonRef.current.style.transform = `translate(${pos.x - 21}px, ${pos.y - 21}px) scale(${start ? 1.15 : 1})`;
        moonRef.current.style.opacity = String(frame.appear);
      }
    };
    raf = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(raf);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ctx.isPreview, model]);

  const release = (completed: boolean) => {
    const start = anchor.current;
    if (!start) return;
    if (completed) {
      model.launch({ x: start.x + pull.current.x, y: start.y + pull.current.y }, launchVelocity());
      haptics.tap("medium");
    } else {
      model.cancelHold(start);
    }
    anchor.current = null;
    pull.current = { x: 0, y: 0 };
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      if (!anchor.current) {
        anchor.current = { ...model.position };
        model.grab();
        haptics.tap("light");
      }
      const length = Math.hypot(translation.x, translation.y);
      const scale = length > 90 ? 90 / length : 1;
      pull.current = { x: translation.x * scale, y: translation.y * scale };
    },
    onEnd: () => release(true),
  });

  const autoLaunch = () => {
    if (anchor.current) return;
    const side = Math.random() < 0.5 ? 1 : -1;
    model.relaunch({ x: side * (150 + Math.random() * 65), y: -40 + Math.random() * 60 });
  };
  useAutoplay(ctx.isPreview, autoLaunch, { every: 5.0, delay: 0.3 });

  const starField = useMemo(() => {
    const next = seededStars(7);
    return Array.from({ length: 60 }, () => {
      const x = next() * ARENA;
      const y = next() * ARENA;
      const r = 0.5 + next() * 1.2;
      const o = 0.25 + 0.5 * next();
      return { x, y, r, o };
    });
  }, []);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
      <div style={{ position: "relative", width: ARENA, height: ARENA, flexShrink: 0, borderRadius: 34, overflow: "hidden", isolation: "isolate" }}>
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(#0E1230, #1B1340)" }} />
        <svg width={ARENA} height={ARENA} style={{ position: "absolute", inset: 0 }}>
          {starField.map((s, i) => (
            <ellipse key={i} cx={s.x + s.r / 2} cy={s.y + s.r / 2} rx={s.r / 2} ry={s.r / 2} fill={white(s.o)} />
          ))}
        </svg>
        <div style={{ position: "absolute", inset: 0, borderRadius: 34, boxShadow: `inset 0 0 0 1px ${white(0.08)}` }} />
        <canvas ref={canvasRef} style={{ position: "absolute", inset: 0, width: ARENA, height: ARENA, pointerEvents: "none" }} />
        {/* Star */}
        <div style={{ position: "absolute", left: CENTER.x - 70, top: CENTER.y - 70, width: 140, height: 140, pointerEvents: "none" }}>
          <div
            ref={glowRef}
            style={{ position: "absolute", inset: 0, borderRadius: "50%", background: `radial-gradient(circle closest-side, ${alpha(Palette.amber, 0.55)} 10px, transparent 70px)` }}
          />
          <div
            ref={coreRef}
            style={{
              position: "absolute",
              left: 48,
              top: 48,
              width: 44,
              height: 44,
              borderRadius: "50%",
              background: `radial-gradient(circle closest-side, #fff 2px, ${Palette.amber} 13px, ${Palette.coral} 24px)`,
            }}
          />
        </div>
        {/* Moon */}
        <div ref={moonRef} {...pan} style={{ position: "absolute", left: 0, top: 0, width: 42, height: 42, padding: 10, borderRadius: "50%", touchAction: "none", cursor: "grab", transform: `translate(${PAD.x - 21}px, ${PAD.y - 21}px)` }}>
          <div
            style={{
              width: 22,
              height: 22,
              borderRadius: "50%",
              background: `linear-gradient(135deg, ${Palette.sky}, ${Palette.blue})`,
              boxShadow: `inset 0 0 0 1px ${white(0.4)}, 0 0 8px ${alpha(Palette.sky, 0.7)}`,
            }}
          />
        </div>
      </div>
      <DemoHint ctx={ctx} en="Pull the moon back and release" zh="向后拉动卫星再松手" />
    </div>
  );
}
