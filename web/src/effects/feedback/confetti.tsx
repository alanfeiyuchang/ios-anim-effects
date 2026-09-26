/** feedback.confetti · 彩纸礼花 (Feedback+Confetti.swift) */
import { Sparkles } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, useAutoplay, useElapsed, useHaptics, type DemoProps } from "../../kit";
import { SPRINGS, track } from "./shared";

const DRAG = 2.2;
const LIFE = 2.6;
const COLORS = Palette.spectrum;
const rand = (a: number, b: number) => a + Math.random() * (b - a);

interface Piece { vx: number; vy: number; color: string; w: number; h: number; spin: number; flutter: number; phase: number; kind: number }
interface Burst { id: number; start: number; gravity: number; pieces: Piece[] }

function makePieces(count: number, spreadDeg: number): Piece[] {
  const spread = (spreadDeg * Math.PI) / 180;
  return Array.from({ length: Math.max(count, 1) }, () => {
    const angle = -Math.PI / 2 + rand(-spread, spread);
    const speed = rand(300, 700);
    const kind = Math.floor(Math.random() * 3);
    return {
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      color: COLORS[Math.floor(Math.random() * COLORS.length)],
      w: kind === 1 ? 7 : rand(6, 9),
      h: kind === 1 ? 7 : kind === 2 ? rand(12, 16) : rand(8, 11),
      spin: rand(-9, 9),
      flutter: rand(6, 14),
      phase: rand(0, 2 * Math.PI),
      kind,
    };
  });
}

export default function Confetti({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const canvas = useRef<HTMLCanvasElement>(null);
  const bursts = useRef<Burst[]>([]);
  const nextID = useRef(0);
  const [pops, setPops] = useState(0);
  const W = 340;
  const H = ctx.isPreview ? 340 : 400;

  useEffect(() => {
    const el = canvas.current;
    if (!el) return;
    const dpr = Math.max(2, window.devicePixelRatio || 1);
    el.width = W * dpr;
    el.height = H * dpr;
    const g = el.getContext("2d")!;
    let raf = 0;
    let last = 0;
    const frame = (nowMs: number) => {
      raf = requestAnimationFrame(frame);
      if (ctx.isPreview && nowMs - last < 1000 / 30 - 1) return;
      last = nowMs;
      const now = performance.now() / 1000;
      g.setTransform(dpr, 0, 0, dpr, 0, 0);
      g.clearRect(0, 0, W, H);
      const ox = W / 2;
      const oy = H / 2 + 40;
      for (const b of bursts.current) {
        const age = now - b.start;
        if (age < 0 || age >= LIFE) continue;
        const decay = 1 - Math.exp(-DRAG * age);
        g.globalAlpha = Math.min(1, (LIFE - age) / 0.6);
        for (const p of b.pieces) {
          const x = ox + (p.vx / DRAG) * decay;
          const y = oy + (b.gravity / DRAG) * age + ((p.vy - b.gravity / DRAG) / DRAG) * decay;
          g.save();
          g.translate(x, y);
          g.rotate(p.spin * age + p.phase);
          g.scale(Math.cos(p.flutter * age + p.phase), 1);
          g.fillStyle = p.color;
          if (p.kind === 1) {
            g.beginPath();
            g.ellipse(0, 0, p.w / 2, p.h / 2, 0, 0, Math.PI * 2);
            g.fill();
          } else if (p.kind === 2) {
            g.beginPath();
            g.roundRect(-p.w / 2, -p.h / 2, p.w, p.h, 2);
            g.fill();
          } else g.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
          g.restore();
        }
      }
      g.globalAlpha = 1;
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [ctx.isPreview, H]);

  const fire = () => {
    const now = performance.now() / 1000;
    bursts.current = [
      ...bursts.current.filter((b) => now - b.start < LIFE),
      { id: nextID.current++, start: now, gravity: 800 * ctx.n("gravity"), pieces: makePieces(ctx.i("count"), ctx.n("spread")) },
    ];
    setPops((p) => p + 1);
    haptics.tap("heavy");
  };

  useAutoplay(ctx.isPreview, fire, { every: 2.6, delay: 0.4 });

  const e = useElapsed(pops, 0.9, true);
  const scale = e < 0 ? 1 : track(e, 1, [{ cubic: 0.9, d: 0.08 }, { cubic: 1.08, d: 0.14 }, { spring: 1, d: 0.4, ...SPRINGS.bouncy }]);

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <canvas ref={canvas} style={{ position: "absolute", left: 0, top: 0, width: W, height: H, pointerEvents: "none" }} />
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", pointerEvents: "none" }}>
        <button
          type="button"
          onClick={fire}
          style={{
            pointerEvents: "auto",
            transform: `translateY(40px) scale(${scale})`,
            display: "flex",
            alignItems: "center",
            gap: 8,
            height: 52,
            padding: "0 24px",
            borderRadius: 26,
            background: Palette.sunset,
            color: "#fff",
            fontSize: 17,
            fontWeight: 600,
            boxShadow: `0 7px 14px ${alpha(Palette.coral, 0.4)}`,
          }}
        >
          <Sparkles size={17} strokeWidth={2.2} />
          {ctx.t("Celebrate", "庆祝一下")}
        </button>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 20, display: "flex", justifyContent: "center" }}>
        <DemoHint ctx={ctx} en="Tap Celebrate" zh="点击“庆祝”" />
      </div>
    </div>
  );
}
