/** showcase.fog-wipe · 擦除雾气 (TravelFogWipe.swift) */
import { motion } from "motion/react";
import { CloudFog, Hand, RotateCcw } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { anim, fonts, useHaptics, usePan, type DemoProps } from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow } from "./signature";

const W = 280;
const H = 260;
const HOLD = 1.2;

type Stroke = { points: { x: number; y: number }[]; touched: number; isDemo: boolean };

/** Same drawing as `LandscapeArt(seed: 1)` (dusk coast), rendered into a canvas so it can be blurred. */
function paintLandscape(g: CanvasRenderingContext2D, w: number, h: number) {
  const sky = g.createLinearGradient(0, 0, 0, h);
  ["#2B2E5A", "#E0785A", "#F5C27A"].forEach((c, i) => sky.addColorStop(i / 2, c));
  g.fillStyle = sky;
  g.fillRect(0, 0, w, h);
  const r = (w * 0.22) / 2;
  g.save();
  g.shadowColor = "rgb(255 226 168 / 0.8)";
  g.shadowBlur = 40;
  g.fillStyle = "#FFE2A8";
  g.beginPath();
  g.arc(w * 0.47, h * 0.34, r, 0, Math.PI * 2);
  g.fill();
  g.restore();
  const ridges = ["#6A4B6E", "#3B2C4A", "#1C1726"];
  for (let layer = 0; layer < 3; layer++) {
    const seed = 7 + layer * 3;
    const base = 0.5 + layer * 0.14;
    const amp = 0.2 - layer * 0.04;
    g.fillStyle = ridges[layer];
    g.beginPath();
    g.moveTo(0, h);
    for (let i = 0; i <= 9; i++) {
      const n = Math.sin(seed * 12.9898 + i * 78.233) * 43758.5453;
      const j = n - Math.floor(n);
      const y = base - amp * (i % 2 === 0 ? j * 0.5 : 0.6 + j * 0.4);
      g.lineTo((w * i) / 9, h * y);
    }
    g.lineTo(w, h);
    g.closePath();
    g.fill();
  }
}

export default function FogWipe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const canvas = useRef<HTMLCanvasElement>(null);
  const strokes = useRef<Stroke[]>([]);
  const drawing = useRef(false);
  const demoRunning = useRef(false);
  const demoTimers = useRef<number[]>([]);
  const [hintVisible, setHintVisible] = useState(true);
  const params = useRef({ brush: 44, frost: 9, regrow: true, regrowTime: 3.5, preview: false });
  params.current = { brush: ctx.n("brush"), frost: ctx.n("frost"), regrow: ctx.b("regrow"), regrowTime: ctx.n("regrowTime"), preview: ctx.isPreview };

  const syncHint = () => setHintVisible(!drawing.current && strokes.current.length === 0);

  // The fog: the photo blurred like a system material, a faint white wash, holes erased along strokes.
  useEffect(() => {
    const el = canvas.current;
    if (!el) return;
    const dpr = Math.max(2, window.devicePixelRatio || 1);
    el.width = W * dpr;
    el.height = H * dpr;
    const g = el.getContext("2d")!;
    const sharp = document.createElement("canvas");
    sharp.width = W * dpr;
    sharp.height = H * dpr;
    const sg = sharp.getContext("2d")!;
    sg.scale(dpr, dpr);
    paintLandscape(sg, W, H);
    const blurred = document.createElement("canvas");
    blurred.width = W * dpr;
    blurred.height = H * dpr;
    const holes = document.createElement("canvas");
    holes.width = W * dpr;
    holes.height = H * dpr;
    const hg = holes.getContext("2d")!;
    let lastFrost = -1;
    let raf = 0;
    let last = 0;

    const strokePath = (c: CanvasRenderingContext2D, pts: { x: number; y: number }[], alpha: number, brush: number) => {
      if (alpha <= 0 || pts.length === 0) return;
      c.fillStyle = c.strokeStyle = `rgb(255 255 255 / ${alpha})`;
      c.beginPath();
      c.arc(pts[0].x, pts[0].y, brush / 2, 0, Math.PI * 2);
      c.fill();
      if (pts.length < 2) return;
      c.lineWidth = brush;
      c.lineCap = "round";
      c.lineJoin = "round";
      c.beginPath();
      c.moveTo(pts[0].x, pts[0].y);
      for (const p of pts.slice(1)) c.lineTo(p.x, p.y);
      c.stroke();
    };

    const frame = (nowMs: number) => {
      raf = requestAnimationFrame(frame);
      const p = params.current;
      if (p.preview && nowMs - last < 1000 / 30 - 1) return;
      last = nowMs;
      const now = nowMs / 1000;
      if (p.frost !== lastFrost) {
        lastFrost = p.frost;
        const bg = blurred.getContext("2d")!;
        bg.setTransform(1, 0, 0, 1, 0, 0);
        bg.clearRect(0, 0, blurred.width, blurred.height);
        const blur = p.frost < 10 ? 18 : p.frost < 18 ? 22 : p.frost < 25 ? 26 : 30;
        bg.filter = `blur(${blur * dpr}px)`;
        // Oversize a little so the blur never darkens the edges.
        const m = blur * 2 * dpr;
        bg.drawImage(sharp, -m, -m, blurred.width + 2 * m, blurred.height + 2 * m);
        bg.filter = "none";
        const tint = p.frost < 10 ? 0.16 : p.frost < 18 ? 0.24 : p.frost < 25 ? 0.32 : 0.42;
        bg.fillStyle = `rgb(255 255 255 / ${tint + 0.02 + p.frost / 300})`;
        bg.fillRect(0, 0, blurred.width, blurred.height);
        const grad = bg.createLinearGradient(0, 0, 0, blurred.height);
        grad.addColorStop(0, "rgb(255 255 255 / 0.1)");
        grad.addColorStop(0.5, "rgb(255 255 255 / 0)");
        grad.addColorStop(1, "rgb(255 255 255 / 0.05)");
        bg.fillStyle = grad;
        bg.fillRect(0, 0, blurred.width, blurred.height);
      }
      g.setTransform(1, 0, 0, 1, 0, 0);
      g.globalCompositeOperation = "source-over";
      g.clearRect(0, 0, el.width, el.height);
      g.drawImage(blurred, 0, 0);

      hg.setTransform(1, 0, 0, 1, 0, 0);
      hg.clearRect(0, 0, holes.width, holes.height);
      hg.setTransform(dpr, 0, 0, dpr, 0, 0);
      hg.filter = `blur(${p.brush * 0.22 * dpr}px)`;
      const regrowAfter = p.regrow ? p.regrowTime : null;
      let any = false;
      for (const s of strokes.current) {
        const regrow = regrowAfter ?? (s.isDemo ? p.regrowTime : null);
        const age = now - s.touched - HOLD;
        const alpha = regrow === null || age <= 0 ? 1 : Math.max(0, 1 - age / regrow);
        strokePath(hg, s.points, alpha, p.brush);
        any = true;
      }
      if (p.preview) {
        // Preview only: a wavy stroke draws itself across the photo, then the fog regrows.
        const t = now % 4.2;
        const progress = Math.min(t / 2, 1);
        const fade = t < 2.8 ? 1 : Math.max(0, 1 - (t - 2.8) / 1.2);
        const count = Math.floor(48 * progress);
        if (count > 1) {
          const pts = Array.from({ length: count + 1 }, (_, i) => {
            const u = i / 48;
            return { x: W * (0.1 + 0.8 * u), y: H * (0.5 + 0.2 * Math.sin(u * Math.PI * 3)) };
          });
          strokePath(hg, pts, fade, p.brush);
          any = true;
        }
      }
      hg.filter = "none";
      if (any) {
        g.globalCompositeOperation = "destination-out";
        g.drawImage(holes, 0, 0);
        g.globalCompositeOperation = "source-over";
      }
      // Drop strokes once fully re-fogged.
      if (!drawing.current && !demoRunning.current && strokes.current.length) {
        const before = strokes.current.length;
        strokes.current = strokes.current.filter((s) => {
          const regrow = regrowAfter ?? (s.isDemo ? p.regrowTime : null);
          return regrow === null || now - s.touched <= HOLD + regrow + 0.1;
        });
        if (strokes.current.length !== before) syncHint();
      }
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Detail stage: a ghost finger wipes one wavy stroke so the gesture is self-explanatory.
  useEffect(() => {
    if (ctx.isPreview) return;
    const timers = demoTimers.current;
    timers.push(
      window.setTimeout(() => {
        const point = (i: number) => {
          const u = i / 36;
          return { x: W * (0.12 + 0.76 * u), y: H * (0.56 + 0.15 * Math.sin(u * Math.PI * 2.5)) };
        };
        demoRunning.current = true;
        const stroke: Stroke = { points: [point(0)], touched: performance.now() / 1000, isDemo: true };
        strokes.current.push(stroke);
        syncHint();
        for (let i = 1; i <= 36; i++) {
          timers.push(
            window.setTimeout(() => {
              if (!demoRunning.current) return;
              stroke.points.push(point(i));
              stroke.touched = performance.now() / 1000;
              if (i === 36) demoRunning.current = false;
            }, i * 28),
          );
        }
      }, 700),
    );
    return () => {
      timers.forEach(clearTimeout);
      demoTimers.current = [];
      demoRunning.current = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const endStroke = () => {
    if (!drawing.current) return;
    drawing.current = false;
    syncHint();
  };

  const pan = usePan({
    onChange: ({ location }) => {
      if (demoRunning.current) {
        demoTimers.current.forEach(clearTimeout);
        demoRunning.current = false;
      }
      const now = performance.now() / 1000;
      const last = strokes.current[strokes.current.length - 1];
      if (drawing.current && last) {
        last.points.push(location);
        last.touched = now;
      } else {
        drawing.current = true;
        strokes.current.push({ points: [location], touched: now, isDemo: false });
        syncHint();
        haptics.tap("soft");
      }
    },
    onEnd: endStroke,
  });

  const reset = () => {
    haptics.tap();
    demoTimers.current.forEach(clearTimeout);
    demoRunning.current = false;
    strokes.current = [];
    syncHint();
  };

  const zh = ctx.lang === "zh";
  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
        <div {...pan} style={{ ...signatureCard(), width: W, height: H, flexShrink: 0, touchAction: "none", cursor: "crosshair" }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: 26, overflow: "hidden" }}>
            <LandscapeArt seed={1} />
            <canvas ref={canvas} style={{ position: "absolute", inset: 0, width: W, height: H }} />
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(rgb(0 0 0 / 0.34), transparent 50%)" }} />
            <div style={{ position: "absolute", inset: 0, padding: 16, display: "flex", flexDirection: "column", pointerEvents: "none" }}>
              <div style={{ display: "flex", alignItems: "flex-start" }}>
                <div style={{ display: "flex", flexDirection: "column", gap: 2, filter: "drop-shadow(0 1px 6px rgb(0 0 0 / 0.3))" }}>
                  <span style={signatureEyebrow()}>{zh ? "精选目的地" : "Featured"}</span>
                  <span style={{ fontFamily: fonts.rounded, fontSize: 22, fontWeight: 700, color: "#fff", lineHeight: "26px" }}>{zh ? "蔚蓝海岸" : "Azure Coast"}</span>
                </div>
                <span style={{ flex: 1 }} />
                <span style={{ width: 34, height: 34, borderRadius: "50%", background: "rgb(0 0 0 / 0.25)", display: "grid", placeItems: "center", color: "#fff" }}>
                  <CloudFog size={16} strokeWidth={2.4} />
                </span>
              </div>
              <span style={{ flex: 1 }} />
              <motion.div
                initial={false}
                animate={{ opacity: hintVisible ? 1 : 0 }}
                transition={anim.easeOut(0.3)}
                style={{ alignSelf: "center", display: "flex", alignItems: "center", gap: 8, padding: "8px 12px", borderRadius: 999, background: "rgb(0 0 0 / 0.35)", color: "#fff", fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, lineHeight: "14px" }}
              >
                <Hand size={13} strokeWidth={2.4} />
                {zh ? "随意拖动，擦去雾气" : "Drag anywhere to wipe the fog"}
              </motion.div>
            </div>
          </div>
          <SignatureRim />
        </div>
        {!ctx.isPreview && (
          <button
            type="button"
            onClick={reset}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 6,
              padding: "8px 14px",
              borderRadius: 999,
              background: Signature.cardHigh,
              boxShadow: `inset 0 0 0 1px ${Signature.hairline}`,
              color: "#fff",
              fontSize: 13,
              fontWeight: 600,
              lineHeight: "18px",
            }}
          >
            <RotateCcw size={13} strokeWidth={2.6} />
            {zh ? "重新起雾" : "Fog it up again"}
          </button>
        )}
      </div>
    </SignatureStage>
  );
}
