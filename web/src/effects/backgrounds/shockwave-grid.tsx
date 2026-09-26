/** backgrounds.shockwave-grid · 冲击波点阵 (Backgrounds+ShockwaveGrid.swift) */
import { useRef } from "react";
import { Palette, useAutoplay, useHaptics, type DemoProps, type Point } from "../../kit";
import { BgHint, Layer, Stage, circle, nowSec, prep, randIn, sizeOf, useFrameLoop, useRatio, useTap } from "./_support";

interface Wave {
  x: number;
  y: number;
  born: number;
}

export default function ShockwaveGrid({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const low = useRef<HTMLCanvasElement>(null);
  const glow = useRef<HTMLCanvasElement>(null);
  const hot = useRef<HTMLCanvasElement>(null);
  const waves = useRef<Wave[]>([]);
  const haptics = useHaptics();
  const ratio = useRatio(root);

  const add = (p: Point) => {
    waves.current.push({ x: p.x, y: p.y, born: nowSec() });
    if (waves.current.length > 5) waves.current.splice(0, waves.current.length - 5);
  };

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    waves.current = waves.current.filter((wv) => now - wv.born <= 6);
    const live = waves.current;
    const pitch = Math.max(ctx.n("spacing"), 8);
    const speed = Math.max(ctx.n("waveSpeed"), 1);
    const omega = ctx.n("omega");
    const damping = ctx.n("damping");
    const dim = new Path2D();
    const mid = new Path2D();
    const hotPath = new Path2D();
    const cols = Math.floor(w / pitch) + 1;
    const rows = Math.floor(h / pitch) + 1;
    const ox = (w - (cols - 1) * pitch) / 2;
    const oy = (h - (rows - 1) * pitch) / 2;
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const bx = ox + c * pitch;
        const by = oy + r * pitch;
        let dx = 0;
        let dy = 0;
        let energy = 0;
        for (const wave of live) {
          const vx = bx - wave.x;
          const vy = by - wave.y;
          const distance = Math.max(Math.hypot(vx, vy), 0.001);
          const tau = now - wave.born - distance / speed;
          if (tau <= 0) continue;
          const falloff = 1 / (1 + distance / 180);
          const env = Math.exp(-damping * tau) * falloff;
          if (env <= 0.004) continue;
          const amount = 9 * env * Math.sin(omega * tau);
          dx += (vx / distance) * amount;
          dy += (vy / distance) * amount;
          energy += Math.abs(amount);
        }
        const radius = 1.3 + Math.min(energy, 8) * 0.2;
        const target = energy < 0.8 ? dim : energy < 3 ? mid : hotPath;
        circle(target, bx + dx, by + dy, radius);
      }
    }
    const gl = prep(low.current, w, h, k);
    if (gl) {
      gl.fillStyle = "rgba(255,255,255,0.22)";
      gl.fill(dim);
      gl.fillStyle = "rgba(58,196,255,0.85)";
      gl.fill(mid);
    }
    const gg = prep(glow.current, w, h, k);
    if (gg) {
      gg.fillStyle = Palette.sky;
      gg.fill(hotPath);
    }
    const gh = prep(hot.current, w, h, k);
    if (gh) {
      gh.fillStyle = "#fff";
      gh.fill(hotPath);
    }
  });

  const tap = useTap((p) => {
    haptics.tap("rigid");
    add(p);
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      const { w, h } = sizeOf(root.current);
      add({ x: randIn(0.2, 0.8) * w, y: randIn(0.2, 0.8) * h });
    },
    { every: 1.8, delay: 0.3 },
  );

  return (
    <Stage rootRef={root} background="radial-gradient(circle 260px at 50% 50%, #141827, #07080D)" handlers={tap}>
      <Layer canvasRef={low} />
      <Layer canvasRef={glow} blur={4} />
      <Layer canvasRef={hot} />
      <BgHint ctx={ctx} en="Tap anywhere to send a shockwave" zh="点击任意位置发出冲击波" />
    </Stage>
  );
}
