/** backgrounds.light-leak · 胶片漏光 (Backgrounds+AmbientGradients.swift) */
import { useRef } from "react";
import { useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, clampv, ellipse, fract, nowSec, prep, rand, rgba, sizeOf, useFrameLoop, useModel, useRatio } from "./_support";

const PALETTES = [
  [0xffb347, 0xff6a3d, 0xff3d7f, 0xffe3b0],
  [0x6fd6ff, 0x7b61ff, 0xff8fb1, 0xc8f0ff],
  [0xff9ac9, 0xffc2a1, 0xd37bff, 0xffe6f0],
];

class LeakModel {
  clock = new BackgroundClock();
  burnStart = -100;
  burn(now: number) {
    const e = now - this.burnStart;
    return e < 0 ? 0 : Math.exp(-e * 2.2);
  }
}

/** Overscan so the 36 pt blur doesn't darken the stage edges. */
const PAD = 70;

function drawLeak(g: CanvasRenderingContext2D, w: number, h: number, index: number, t: number, color: number) {
  const period = 7 + 4 * rand(index, 41);
  const cycle = t / period + rand(index, 42);
  const p = fract(cycle);
  const seed = index * 31 + Math.floor(cycle);
  const wave = Math.sin(p * Math.PI);
  const env = wave * wave;
  const travel = index % 2 === 0 ? -0.4 + 1.8 * p : 1.4 - 1.8 * p;
  const x = travel * w;
  const y = h * (0.15 + 0.7 * rand(seed, 43));
  const angle = -0.5 + 0.35 * rand(seed, 44);
  const length = w * (0.8 + 0.5 * rand(seed, 46));
  const thickness = h * (0.22 + 0.2 * rand(seed, 47));
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.fillStyle = rgba(color, 0.75 * env);
  g.beginPath();
  ellipse(g, -length / 2, -thickness / 2, length, thickness);
  g.fill();
  g.fillStyle = `rgba(255,255,255,${0.35 * env})`;
  g.beginPath();
  ellipse(g, -length / 2 + length * 0.3, -thickness / 2 + thickness * 0.3, length * 0.4, thickness * 0.4);
  g.fill();
  g.restore();
}

export default function LightLeak({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new LeakModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const t = model.clock.advance(now, ctx.n("speed"));
    const g = prep(canvas.current, w + PAD * 2, h + PAD * 2, Math.min(ratio(), 2));
    if (!g || !canvas.current) return;
    const step = Math.floor(t * 12);
    const jitter = (rand(step, 45) - 0.5) * 2;
    // Centred on 90 % so the flicker swings both ways (±8 % at full flicker).
    canvas.current.style.opacity = String(clampv(0.9 + ctx.n("flicker") * 0.08 * jitter, 0, 1));
    g.translate(PAD, PAD);
    g.globalCompositeOperation = "lighter";
    const colors = PALETTES[clampv(ctx.i("palette"), 0, 2)];
    for (let i = 0; i < 4; i++) drawLeak(g, w, h, i, t, colors[i % colors.length]);
    const burn = model.burn(now);
    if (burn > 0.002) {
      g.fillStyle = rgba(0xffb36b, 0.55 * burn);
      g.fillRect(-40, -40, w + 80, h + 80);
    }
  });

  const burn = () => {
    model.burnStart = nowSec();
  };
  useAutoplay(ctx.isPreview, burn, { every: 4.0, delay: 1.2 });

  return (
    <Stage
      rootRef={root}
      background="linear-gradient(to bottom right, #1A0F14, #2B1A22, #0E0B10)"
      handlers={{
        onClick: () => {
          haptics.tap("medium");
          burn();
        },
      }}
    >
      <Layer canvasRef={canvas} blur={36} style={{ left: -PAD, top: -PAD, width: `calc(100% + ${PAD * 2}px)`, height: `calc(100% + ${PAD * 2}px)` }} />
      <SampleTitle title={ctx.t("Golden Hour", "黄金时刻")} subtitle={ctx.t("Shot on film · 35 mm", "胶片拍摄 · 35 毫米")} size={30} />
      <BgHint ctx={ctx} en="Tap to burn the film" zh="点击烧光胶片" />
    </Stage>
  );
}
